"""On-disk storage for dictation sessions.

Layout, one directory per session:

    transcripts/
      2026-09-06_2312-reunion-de-equipo/
        meta.json         session metadata
        transcript.jsonl  one Segment per line, appended as it is recognised
        transcript.md     readable version, rewritten whenever a segment lands

`transcript.jsonl` is the source of truth and is flushed on every append: if the
process dies mid-session, everything already recognised survives.
"""

from __future__ import annotations

import json
import re
import unicodedata
from datetime import datetime
from pathlib import Path
from typing import Iterator, List, Optional

from loguru import logger

from .models import Segment, SessionMeta

DEFAULT_ROOT = Path("transcripts")


def slugify(text: str, max_len: int = 40) -> str:
    """ASCII, lowercase, hyphenated — safe for a directory name."""
    normalized = unicodedata.normalize("NFKD", text)
    ascii_text = normalized.encode("ascii", "ignore").decode("ascii").lower()
    slug = re.sub(r"[^a-z0-9]+", "-", ascii_text).strip("-")
    return slug[:max_len] or "sesion"


class TranscriptSession:
    """A single session directory, open for appending."""

    def __init__(self, directory: Path, meta: SessionMeta) -> None:
        self.dir = directory
        self.meta = meta
        self._segments: List[Segment] = []
        self._jsonl = self.dir / "transcript.jsonl"

    # ----------------------------------------------------------------- write
    def append(self, segment: Segment) -> None:
        self._segments.append(segment)
        self.meta.segment_count = len(self._segments)
        self.meta.audio_seconds = max(self.meta.audio_seconds, segment.end)

        with self._jsonl.open("a", encoding="utf-8") as f:
            f.write(json.dumps(segment.to_dict(), ensure_ascii=False) + "\n")

        self._write_meta()
        self._write_markdown()

    def close(self) -> None:
        self.meta.ended_at = datetime.now().isoformat(timespec="seconds")
        self._write_meta()
        self._write_markdown()
        logger.info(
            f"[transcripts] sesión cerrada {self.meta.id}: "
            f"{self.meta.segment_count} segmentos, {self.meta.audio_seconds:.0f}s de audio"
        )

    # ------------------------------------------------------------------ read
    @property
    def segments(self) -> List[Segment]:
        return list(self._segments)

    @property
    def text(self) -> str:
        return " ".join(s.text.strip() for s in self._segments if s.text.strip())

    # --------------------------------------------------------------- private
    def _write_meta(self) -> None:
        (self.dir / "meta.json").write_text(
            json.dumps(self.meta.to_dict(), ensure_ascii=False, indent=2),
            encoding="utf-8",
        )

    def _write_markdown(self) -> None:
        (self.dir / "transcript.md").write_text(
            render_markdown(self.meta, self._segments), encoding="utf-8"
        )


def _timestamp(seconds: float) -> str:
    total = int(seconds)
    return f"{total // 60:02d}:{total % 60:02d}"


def render_markdown(meta: SessionMeta, segments: List[Segment]) -> str:
    """Readable transcript with a YAML front-matter header."""
    head = [
        "---",
        f"title: {meta.title}",
        f"id: {meta.id}",
        f"source: {meta.source}",
        f"started_at: {meta.started_at}",
        f"ended_at: {meta.ended_at or ''}",
        f"duration_seconds: {meta.audio_seconds:.0f}",
        "type: transcript",
        "---",
        "",
        f"# {meta.title}",
        "",
    ]
    body = [
        f"**[{_timestamp(s.start)}]** {s.text.strip()}"
        for s in segments
        if s.text.strip()
    ]
    return "\n".join(head + body) + "\n"


class TranscriptStore:
    """Creates and finds session directories under a root."""

    def __init__(self, root: Path | str = DEFAULT_ROOT) -> None:
        self.root = Path(root)
        self.root.mkdir(parents=True, exist_ok=True)

    def create(
        self, title: str = "", source: str = "mic", language: str = ""
    ) -> TranscriptSession:
        now = datetime.now()
        title = title.strip() or f"Dictado {now.strftime('%d/%m/%Y %H:%M')}"
        session_id = f"{now.strftime('%Y-%m-%d_%H%M')}-{slugify(title)}"

        directory = self.root / session_id
        suffix = 2
        while directory.exists():  # two sessions in the same minute
            directory = self.root / f"{session_id}-{suffix}"
            suffix += 1
        directory.mkdir(parents=True)

        meta = SessionMeta(
            id=directory.name,
            title=title,
            source=source,
            started_at=now.isoformat(timespec="seconds"),
            language=language,
        )
        session = TranscriptSession(directory, meta)
        session._write_meta()
        logger.info(f"[transcripts] sesión nueva: {directory}")
        return session

    # ------------------------------------------------------------------ read
    def list_sessions(self, limit: int = 20) -> List[SessionMeta]:
        metas: List[SessionMeta] = []
        for meta_file in self.root.glob("*/meta.json"):
            try:
                metas.append(
                    SessionMeta.from_dict(json.loads(meta_file.read_text("utf-8")))
                )
            except (json.JSONDecodeError, OSError, TypeError) as e:
                logger.warning(f"[transcripts] meta ilegible en {meta_file}: {e}")
        metas.sort(key=lambda m: m.started_at, reverse=True)
        return metas[:limit]

    def read_segments(self, session_id: str) -> Iterator[Segment]:
        jsonl = self.root / session_id / "transcript.jsonl"
        if not jsonl.exists():
            return
        with jsonl.open(encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line:
                    yield Segment.from_dict(json.loads(line))

    def read_text(self, session_id: str) -> str:
        return " ".join(
            s.text.strip() for s in self.read_segments(session_id) if s.text.strip()
        )

    def latest_id(self) -> Optional[str]:
        sessions = self.list_sessions(limit=1)
        return sessions[0].id if sessions else None

    def resolve(self, session_id: str) -> Optional[str]:
        """Accept 'latest' / '' as an alias for the most recent session."""
        if session_id in ("", "latest", "última", "ultima"):
            return self.latest_id()
        return session_id if (self.root / session_id).is_dir() else None
