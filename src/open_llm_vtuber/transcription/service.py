"""Runs one dictation session: audio in, transcript on disk, segments pushed out.

The ASR instance used here is *not* the one the conversation uses. A dictation
session can queue minutes of audio, and sharing the engine would make a "Miku,
sube el volumen" wait behind it. The models are small enough that a second copy
is cheaper than the contention.

The queue is drained by a single worker, so segments are always written in the
order they were spoken, even when transcription falls behind.
"""

from __future__ import annotations

import asyncio
from typing import Awaitable, Callable, Dict, Optional

import numpy as np
from loguru import logger

from ..asr.asr_factory import ASRFactory
from ..asr.asr_interface import ASRInterface
from .models import Segment, SessionMeta
from .segmenter import AudioChunk, DictationSegmenter
from .store import TranscriptSession, TranscriptStore

# One dedicated engine per ASR model name, shared by every dictation session.
_engines: Dict[str, ASRInterface] = {}
_engine_lock = asyncio.Lock()

# How many chunks may pile up before we tell the user the machine is too slow.
BACKLOG_WARNING = 3


async def get_dictation_engine(asr_config) -> ASRInterface:
    """Build (once) the ASR instance reserved for transcription."""
    model_name = asr_config.asr_model
    async with _engine_lock:
        engine = _engines.get(model_name)
        if engine is None:
            logger.info(f"[dictado] cargando motor ASR dedicado: {model_name}")
            engine = await asyncio.to_thread(
                ASRFactory.get_asr_system,
                model_name,
                **getattr(asr_config, model_name).model_dump(),
            )
            _engines[model_name] = engine
        return engine


class DictationService:
    """Owns the segmenter, the queue and the open transcript for one session."""

    def __init__(
        self,
        engine: ASRInterface,
        store: TranscriptStore,
        on_segment: Optional[Callable[[Segment], Awaitable[None]]] = None,
        on_backlog: Optional[Callable[[int], Awaitable[None]]] = None,
    ) -> None:
        self._engine = engine
        self._store = store
        self._on_segment = on_segment
        self._on_backlog = on_backlog

        self._session: Optional[TranscriptSession] = None
        self._segmenter: Optional[DictationSegmenter] = None
        self._queue: Optional[asyncio.Queue] = None
        self._worker: Optional[asyncio.Task] = None
        self._next_index = 0
        self._warned_backlog = False

    @property
    def active(self) -> bool:
        return self._session is not None

    @property
    def meta(self) -> Optional[SessionMeta]:
        return self._session.meta if self._session else None

    # ----------------------------------------------------------------- start
    async def start(
        self, title: str = "", source: str = "mic", language: str = ""
    ) -> SessionMeta:
        if self.active:
            logger.warning("[dictado] ya había una sesión abierta; se cierra primero")
            await self.stop()

        self._session = self._store.create(
            title=title, source=source, language=language
        )
        self._segmenter = DictationSegmenter()
        self._queue = asyncio.Queue()
        self._next_index = 0
        self._warned_backlog = False
        self._worker = asyncio.create_task(self._drain())
        return self._session.meta

    # ------------------------------------------------------------------ feed
    async def feed(self, samples: np.ndarray) -> None:
        if not self.active or self._segmenter is None or self._queue is None:
            return
        for chunk in self._segmenter.feed(samples):
            await self._enqueue(chunk)

    # ------------------------------------------------------------------ stop
    async def stop(self) -> Optional[SessionMeta]:
        if not self.active:
            return None

        if self._segmenter is not None:
            tail = self._segmenter.flush()
            if tail is not None:
                await self._enqueue(tail)

        if self._queue is not None:
            await self._queue.put(None)  # sentinel: drain and finish
        if self._worker is not None:
            try:
                await self._worker
            except asyncio.CancelledError:
                pass

        session, self._session = self._session, None
        self._segmenter = self._queue = self._worker = None
        if session is not None:
            session.close()
            return session.meta
        return None

    async def cancel(self) -> None:
        """Drop the session without waiting for the queue (client disconnected)."""
        if self._worker is not None and not self._worker.done():
            self._worker.cancel()
            try:
                await self._worker
            except asyncio.CancelledError:
                pass
        if self._session is not None:
            self._session.close()
        self._session = self._segmenter = self._queue = self._worker = None

    # -------------------------------------------------------------- internals
    async def _enqueue(self, chunk: AudioChunk) -> None:
        assert self._queue is not None
        await self._queue.put(chunk)

        backlog = self._queue.qsize()
        if backlog >= BACKLOG_WARNING and not self._warned_backlog:
            self._warned_backlog = True
            logger.warning(
                f"[dictado] la transcripción va por detrás del habla ({backlog} fragmentos "
                "en cola). El texto llegará completo, pero con retraso."
            )
            if self._on_backlog:
                await self._on_backlog(backlog)
        elif backlog == 0:
            self._warned_backlog = False

    async def _drain(self) -> None:
        assert self._queue is not None
        while True:
            chunk = await self._queue.get()
            if chunk is None:
                return
            try:
                await self._transcribe(chunk)
            except Exception as e:  # never let one bad chunk kill the session
                logger.error(f"[dictado] fallo al transcribir un fragmento: {e}")

    async def _transcribe(self, chunk: AudioChunk) -> None:
        text = (await self._engine.async_transcribe_np(chunk.samples)).strip()
        if not text:
            return
        if self._session is None:
            return

        segment = Segment(
            index=self._next_index, start=chunk.start, end=chunk.end, text=text
        )
        self._next_index += 1
        self._session.append(segment)
        logger.debug(f"[dictado] [{segment.start:.1f}s] {text}")

        if self._on_segment:
            await self._on_segment(segment)
