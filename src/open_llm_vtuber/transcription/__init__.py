"""Dictation and transcription.

The conversation pipeline (mic -> ASR -> LLM -> TTS) is tuned for latency: short
turns, spoken answer. Transcription is the opposite problem — long sessions where
nothing must be lost and Miku must *not* answer. So it runs on its own path:
its own ASR instance, its own queue, and its own storage.

The raw transcript is written to disk before any LLM sees it. Turning it into a
note is a separate, re-runnable step (see mcp_servers/notes_server.py).
"""

from .models import Segment, SessionMeta
from .segmenter import DictationSegmenter
from .service import DictationService
from .store import TranscriptStore

__all__ = [
    "DictationSegmenter",
    "DictationService",
    "Segment",
    "SessionMeta",
    "TranscriptStore",
]
