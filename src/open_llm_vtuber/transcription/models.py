"""Data types shared by the transcription path."""

from __future__ import annotations

from dataclasses import dataclass, field, asdict
from typing import Any, Dict


@dataclass
class Segment:
    """One transcribed chunk of audio.

    `start` and `end` are seconds from the start of the session, taken from the
    audio itself (sample counts), not from wall clock — so they stay correct even
    when transcription lags behind the speaker.
    """

    index: int
    start: float
    end: float
    text: str

    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)

    @classmethod
    def from_dict(cls, d: Dict[str, Any]) -> "Segment":
        return cls(
            index=int(d["index"]),
            start=float(d["start"]),
            end=float(d["end"]),
            text=str(d["text"]),
        )


@dataclass
class SessionMeta:
    """Everything about a dictation session except the text itself."""

    id: str
    title: str
    source: str  # 'mic' | 'file' | 'system'
    started_at: str  # ISO 8601, local time
    ended_at: str | None = None
    audio_seconds: float = 0.0
    segment_count: int = 0
    language: str = ""
    extra: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)

    @classmethod
    def from_dict(cls, d: Dict[str, Any]) -> "SessionMeta":
        known = {f for f in cls.__dataclass_fields__}  # noqa: F821
        return cls(**{k: v for k, v in d.items() if k in known})
