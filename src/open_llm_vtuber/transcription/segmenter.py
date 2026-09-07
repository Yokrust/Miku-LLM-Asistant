"""Cuts a continuous microphone stream into utterance-sized chunks.

Why this exists: the ASR is an *offline* recognizer. It transcribes a finished
piece of audio, so someone has to decide where a piece ends. Whisper also works
on a fixed 30-second window — anything longer is silently truncated — so a hard
cap below 30s is not a tuning knob, it is a correctness requirement.

The rule is: cut on a natural pause, and if the speaker never pauses, cut anyway
before the window overflows.

Detection is energy-based with an adaptive noise floor (no extra dependency;
silero-vad is not installed in this project). It is not trying to be a good VAD —
it only has to find the gaps between sentences, and for that RMS is enough.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import List

import numpy as np

SAMPLE_RATE = 16000

# A microphone in a normal room sits far below this. Capping the learned floor
# is what stops a long, unbroken stretch of speech from teaching the detector
# that speech *is* the silence.
MAX_NOISE_FLOOR = 0.01


@dataclass
class AudioChunk:
    """A cut of audio ready to transcribe, timestamped from the session start."""

    start: float
    end: float
    samples: np.ndarray


class DictationSegmenter:
    def __init__(
        self,
        sample_rate: int = SAMPLE_RATE,
        frame_ms: int = 30,
        silence_s: float = 0.7,
        min_speech_s: float = 0.6,
        max_chunk_s: float = 22.0,
        preroll_s: float = 0.3,
    ) -> None:
        """
        Args:
            silence_s: pause that ends an utterance.
            min_speech_s: how much actual *speech* a chunk needs before it is
                worth transcribing. Measured on voiced frames only: a cough plus
                its surrounding silence must not add up to a valid utterance,
                because whisper answers a cough with an invented sentence.
            max_chunk_s: hard cut for someone who does not pause. Must stay well
                under whisper's 30s window.
            preroll_s: silence kept before speech so the first phoneme is not
                clipped.
        """
        self.sample_rate = sample_rate
        self.frame = int(sample_rate * frame_ms / 1000)
        self.silence_frames = max(1, int(silence_s * 1000 / frame_ms))
        self.min_speech_samples = int(min_speech_s * sample_rate)
        self.max_samples = int(max_chunk_s * sample_rate)
        self.preroll_samples = int(preroll_s * sample_rate)

        self._pending = np.zeros(0, dtype=np.float32)  # frames not yet analysed
        self._buffer = np.zeros(0, dtype=np.float32)  # current utterance
        self._buffer_start = 0.0  # seconds, from session start
        self._consumed = 0  # samples fed so far
        self._silence_run = 0
        self._speech_samples = 0  # voiced samples in the current buffer
        self._has_speech = False
        self._noise_floor: float | None = None

    # ------------------------------------------------------------------ API
    def feed(self, samples: np.ndarray) -> List[AudioChunk]:
        """Push audio in; get back whatever chunks are now complete."""
        if samples.dtype != np.float32:
            samples = samples.astype(np.float32)
        self._pending = np.concatenate([self._pending, samples])

        chunks: List[AudioChunk] = []
        while len(self._pending) >= self.frame:
            frame, self._pending = (
                self._pending[: self.frame],
                self._pending[self.frame :],
            )
            chunk = self._push_frame(frame)
            if chunk is not None:
                chunks.append(chunk)
        return chunks

    def flush(self) -> AudioChunk | None:
        """End of session: emit whatever is buffered, however short."""
        if len(self._pending):
            self._buffer = np.concatenate([self._buffer, self._pending])
            self._consumed += len(self._pending)
            self._pending = np.zeros(0, dtype=np.float32)
        if not self._has_speech or self._speech_samples < self.min_speech_samples:
            self._reset_buffer()
            return None
        return self._emit()

    # -------------------------------------------------------------- internals
    def _push_frame(self, frame: np.ndarray) -> AudioChunk | None:
        rms = float(np.sqrt(np.mean(frame**2))) if len(frame) else 0.0
        is_speech = self._classify(rms)

        if not self._has_speech and not is_speech:
            # Still waiting for speech: keep only preroll_s of silence.
            self._buffer = np.concatenate([self._buffer, frame])[
                -self.preroll_samples :
            ]
            self._consumed += len(frame)
            self._buffer_start = (self._consumed - len(self._buffer)) / self.sample_rate
            return None

        self._buffer = np.concatenate([self._buffer, frame])
        self._consumed += len(frame)

        if is_speech:
            self._has_speech = True
            self._silence_run = 0
            self._speech_samples += len(frame)
        else:
            self._silence_run += 1

        long_enough = self._speech_samples >= self.min_speech_samples
        paused = self._silence_run >= self.silence_frames
        overflowing = len(self._buffer) >= self.max_samples

        if overflowing or (paused and long_enough):
            return self._emit()
        if paused and not long_enough:
            # A blip, not speech. Drop it and go back to waiting.
            self._reset_buffer()
        return None

    def _classify(self, rms: float) -> bool:
        """Speech if clearly above the room's noise floor.

        Minimum-statistics tracker: the floor drops to any quieter frame at once
        and only drifts up slowly, so it learns the room and not the speaker. A
        symmetric average would climb during sustained speech until it swallowed
        the voice and the segmenter went deaf.
        """
        if self._noise_floor is None:
            self._noise_floor = min(rms, MAX_NOISE_FLOOR)
        else:
            self._noise_floor = min(rms, self._noise_floor * 1.0008, MAX_NOISE_FLOOR)
        return rms > max(self._noise_floor * 3.0, 0.006)

    def _emit(self) -> AudioChunk:
        chunk = AudioChunk(
            start=self._buffer_start,
            end=self._buffer_start + len(self._buffer) / self.sample_rate,
            samples=self._buffer,
        )
        self._reset_buffer()
        return chunk

    def _reset_buffer(self) -> None:
        self._buffer = np.zeros(0, dtype=np.float32)
        self._buffer_start = self._consumed / self.sample_rate
        self._silence_run = 0
        self._speech_samples = 0
        self._has_speech = False
