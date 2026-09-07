"""Miku — notes MCP server.

Gives Miku the tools to read what she just heard and write it down. Notes are
Markdown files in a local folder; Notion comes later behind the same tools, so
nothing above this layer has to change.

The split matters: the transcript is written by the backend as it is recognised
(src/open_llm_vtuber/transcription/), independently of any model. These tools only
read it. So "anótalo" can succeed even when the language model is too small to
summarise well — save_transcript_as_note copies the words verbatim and the model
only has to choose a title.

Run:  uv run python mcp_servers/notes_server.py    (spawned over stdio by the MCP client)

Environment:
  MIKU_NOTES_DIR        Where notes are written.        Default: notes/
  MIKU_TRANSCRIPTS_DIR  Where dictation sessions live.  Default: transcripts/
"""

from __future__ import annotations

import json
import os
import re
import unicodedata
from datetime import datetime
from pathlib import Path
from typing import List, Optional

from mcp.server.fastmcp import FastMCP

mcp = FastMCP("notes")

NOTES_DIR = Path(os.environ.get("MIKU_NOTES_DIR", "notes")).expanduser()
TRANSCRIPTS_DIR = Path(
    os.environ.get("MIKU_TRANSCRIPTS_DIR", "transcripts")
).expanduser()

# Transcripts can run long; a small local model drowns if we hand it everything.
MAX_TRANSCRIPT_CHARS = 6000


# --------------------------------------------------------------------------- #
# helpers
# --------------------------------------------------------------------------- #
def _slug(text: str, max_len: int = 40) -> str:
    ascii_text = (
        unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode().lower()
    )
    return re.sub(r"[^a-z0-9]+", "-", ascii_text).strip("-")[:max_len] or "nota"


def _note_path(title: str) -> Path:
    return NOTES_DIR / f"{datetime.now():%Y-%m-%d}-{_slug(title)}.md"


def _find_note(title: str) -> Optional[Path]:
    """Most recent note whose filename matches the title's slug."""
    if not NOTES_DIR.is_dir():
        return None
    slug = _slug(title)
    matches = sorted(NOTES_DIR.glob(f"*-{slug}.md"), reverse=True)
    return matches[0] if matches else None


def _sessions() -> List[dict]:
    """Session metadata, newest first."""
    out = []
    if not TRANSCRIPTS_DIR.is_dir():
        return out
    for meta_file in TRANSCRIPTS_DIR.glob("*/meta.json"):
        try:
            out.append(json.loads(meta_file.read_text("utf-8")))
        except (json.JSONDecodeError, OSError):
            continue
    out.sort(key=lambda m: m.get("started_at", ""), reverse=True)
    return out


def _resolve(session_id: str) -> Optional[dict]:
    sessions = _sessions()
    if not sessions:
        return None
    if session_id.strip().lower() in ("", "latest", "ultima", "última", "last"):
        return sessions[0]
    for meta in sessions:
        if meta.get("id") == session_id:
            return meta
    return None


def _transcript_text(session_id: str) -> str:
    jsonl = TRANSCRIPTS_DIR / session_id / "transcript.jsonl"
    if not jsonl.exists():
        return ""
    parts = []
    for line in jsonl.read_text("utf-8").splitlines():
        line = line.strip()
        if line:
            try:
                parts.append(json.loads(line).get("text", "").strip())
            except json.JSONDecodeError:
                continue
    return " ".join(p for p in parts if p)


def _title_of(body: str, fallback: str) -> str:
    """Title from the front matter. The filename is for disk, not for speech."""
    for line in body.splitlines()[:8]:
        if line.startswith("title:"):
            return line.split(":", 1)[1].strip() or fallback
    return fallback


def _preview(body: str) -> str:
    """First line of actual content, past the front matter and the title."""
    lines = body.splitlines()
    if lines and lines[0].strip() == "---":
        end = next((i for i, ln in enumerate(lines[1:], 1) if ln.strip() == "---"), 0)
        lines = lines[end + 1 :]
    for line in lines:
        stripped = line.strip()
        if stripped and not stripped.startswith("#"):
            return stripped[:120]
    return "(vacía)"


def _write_note(path: Path, title: str, body: str, source: str = "") -> None:
    NOTES_DIR.mkdir(parents=True, exist_ok=True)
    front = [
        "---",
        f"title: {title}",
        f"created: {datetime.now().isoformat(timespec='seconds')}",
        "type: note",
    ]
    if source:
        front.append(f"source: {source}")
    front += ["---", "", f"# {title}", ""]
    path.write_text("\n".join(front) + "\n" + body.rstrip() + "\n", encoding="utf-8")


# --------------------------------------------------------------------------- #
# tools — read what was heard
# --------------------------------------------------------------------------- #
@mcp.tool()
def list_transcripts(limit: int = 5) -> str:
    """List recent dictation sessions (what Miku has listened to and transcribed)."""
    sessions = _sessions()[: max(1, limit)]
    if not sessions:
        return "No hay transcripciones todavía."
    lines = []
    for m in sessions:
        minutes = float(m.get("audio_seconds", 0)) / 60
        lines.append(
            f'- {m.get("id")} · "{m.get("title")}" · {minutes:.1f} min · '
            f"{m.get('segment_count', 0)} fragmentos"
        )
    return "\n".join(lines)


@mcp.tool()
def read_transcript(session_id: str = "latest") -> str:
    """Read the text of a dictation session. Use 'latest' for the most recent one."""
    meta = _resolve(session_id)
    if meta is None:
        return "Error: no encuentro esa transcripción."
    text = _transcript_text(meta["id"])
    if not text:
        return f"La sesión '{meta['title']}' está vacía (no se reconoció nada)."
    if len(text) > MAX_TRANSCRIPT_CHARS:
        text = text[:MAX_TRANSCRIPT_CHARS] + "\n\n[…transcripción recortada…]"
    return f'Transcripción "{meta["title"]}" ({meta["id"]}):\n\n{text}'


# --------------------------------------------------------------------------- #
# tools — write it down
# --------------------------------------------------------------------------- #
@mcp.tool()
def save_note(title: str, content: str) -> str:
    """Save a new note in Markdown. Use this when the user asks you to write something down."""
    if not title.strip():
        return "Error: la nota necesita un título."
    path = _note_path(title)
    _write_note(path, title.strip(), content)
    return f"Nota guardada: {path}"


@mcp.tool()
def append_to_note(title: str, content: str) -> str:
    """Add text to the end of an existing note. Creates it if there is none."""
    path = _find_note(title)
    if path is None:
        return save_note(title, content)
    with path.open("a", encoding="utf-8") as f:
        f.write("\n" + content.rstrip() + "\n")
    return f"Añadido a la nota: {path}"


@mcp.tool()
def save_transcript_as_note(title: str = "", session_id: str = "latest") -> str:
    """Save a dictation session as a note, word for word. No summarising."""
    meta = _resolve(session_id)
    if meta is None:
        return "Error: no encuentro esa transcripción."
    text = _transcript_text(meta["id"])
    if not text:
        return "Esa sesión no tiene texto que guardar."
    final_title = title.strip() or meta.get("title", "Transcripción")
    path = _note_path(final_title)
    _write_note(path, final_title, text, source=meta["id"])
    return f"Nota guardada: {path}"


@mcp.tool()
def search_notes(query: str = "") -> str:
    """Search your notes by text. Empty query lists the most recent ones."""
    if not NOTES_DIR.is_dir():
        return "Todavía no hay notas."
    notes = sorted(NOTES_DIR.glob("*.md"), reverse=True)
    if not notes:
        return "Todavía no hay notas."

    q = query.strip().lower()
    hits = []
    for path in notes:
        try:
            body = path.read_text("utf-8")
        except OSError:
            continue
        if not q or q in body.lower() or q in path.name.lower():
            title = _title_of(body, path.stem)
            hits.append(f"- {title}: {_preview(body)}")
        if len(hits) >= 10:
            break

    if not hits:
        return f"Ninguna nota menciona '{query}'."
    return "\n".join(hits)


if __name__ == "__main__":
    mcp.run()
