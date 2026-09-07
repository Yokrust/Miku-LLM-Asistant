"""Miku — macOS control MCP server.

An stdio MCP server that lets Miku act on the Mac: open apps, URLs and files,
read/set the output volume, control media playback, and — behind an on-screen
confirmation — run AppleScript, Shortcuts, or shell commands.

M2: executed directly from the Python backend. In M6 the confirmation dialog and
the privileged actions move into the native Miku.app (which holds the TCC
permissions); this server then becomes a thin proxy to it.

Run:  uv run python mcp_servers/macos_server.py    (spawned over stdio by the MCP client)

Environment:
  MIKU_MACOS_NO_CONFIRM=1   Skip the confirmation dialog for guarded tools.
                            Testing only — never set this in normal use.
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys

from mcp.server.fastmcp import FastMCP

mcp = FastMCP("macos")

_RUN_TIMEOUT = 20  # seconds for a single subprocess call
_NO_CONFIRM = os.environ.get("MIKU_MACOS_NO_CONFIRM") == "1"


# --------------------------------------------------------------------------- #
# helpers
# --------------------------------------------------------------------------- #
def _run(args: list[str], timeout: int = _RUN_TIMEOUT) -> subprocess.CompletedProcess:
    """Run a command (list form, no shell) and capture output."""
    return subprocess.run(
        args, capture_output=True, text=True, timeout=timeout, check=False
    )


def _osascript(script: str, timeout: int = _RUN_TIMEOUT) -> tuple[bool, str]:
    """Run an AppleScript snippet. Returns (ok, stdout_or_stderr)."""
    proc = _run(["osascript", "-e", script], timeout=timeout)
    if proc.returncode == 0:
        return True, proc.stdout.strip()
    return False, (proc.stderr.strip() or proc.stdout.strip() or "AppleScript failed")


def _confirm(action_title: str, detail: str) -> bool:
    """Show a native confirmation dialog. Returns True only on explicit approval.

    This is the M2 stand-in for the confirmation UI that will live in Miku.app.
    """
    if _NO_CONFIRM:
        print(f"[macos] MIKU_MACOS_NO_CONFIRM=1 -> auto-approving: {action_title}", file=sys.stderr)
        return True

    shown = detail if len(detail) <= 600 else detail[:600] + "\n…(truncado)"
    prompt = f"{action_title}\n\n{shown}"
    script = (
        f"display dialog {json.dumps(prompt)} "
        f'with title "Miku quiere ejecutar una acción" '
        f'buttons {{"Denegar", "Permitir"}} default button "Denegar" '
        f"with icon caution giving up after 120"
    )
    ok, out = _osascript(script, timeout=130)
    return ok and "Permitir" in out


def _err(msg: str) -> str:
    return f"Error: {msg}"


# --------------------------------------------------------------------------- #
# safe tools (no confirmation)
# --------------------------------------------------------------------------- #
@mcp.tool()
def open_app(name: str) -> str:
    """Open (launch and focus) a macOS application by its name, e.g. "Safari", "Spotify", "Notes"."""
    name = name.strip()
    if not name:
        return _err("empty application name")
    proc = _run(["open", "-a", name])
    if proc.returncode == 0:
        return f"Abrí {name}."
    return _err(f"could not open '{name}': {proc.stderr.strip() or 'not found'}")


@mcp.tool()
def open_url(url: str) -> str:
    """Open a URL in the default browser. Only http(s) and mailto are allowed."""
    url = url.strip()
    if not (url.startswith("http://") or url.startswith("https://") or url.startswith("mailto:")):
        return _err("only http, https and mailto URLs are allowed")
    proc = _run(["open", url])
    return f"Abrí {url}." if proc.returncode == 0 else _err(proc.stderr.strip() or "open failed")


@mcp.tool()
def open_path(path: str) -> str:
    """Open a local file or folder with its default app (or reveal it in Finder)."""
    path = os.path.expanduser(path.strip())
    if not os.path.exists(path):
        return _err(f"path does not exist: {path}")
    proc = _run(["open", path])
    return f"Abrí {path}." if proc.returncode == 0 else _err(proc.stderr.strip() or "open failed")


@mcp.tool()
def list_running_apps() -> str:
    """List the names of the currently running foreground applications."""
    ok, out = _osascript(
        'tell application "System Events" to get name of every process '
        "whose background only is false"
    )
    if not ok:
        return _err(out)
    apps = sorted(a.strip() for a in out.split(",") if a.strip())
    return ", ".join(apps) if apps else "No hay apps en primer plano."


@mcp.tool()
def focus_app(name: str) -> str:
    """Bring an already-running application to the front, e.g. "Safari"."""
    name = name.strip()
    ok, out = _osascript(f'tell application {json.dumps(name)} to activate')
    return f"Puse {name} al frente." if ok else _err(out)


@mcp.tool()
def get_volume() -> str:
    """Get the current system output volume (0-100) and mute state."""
    ok, out = _osascript(
        'set v to output volume of (get volume settings)\n'
        'set m to output muted of (get volume settings)\n'
        'return (v as string) & "|" & (m as string)'
    )
    if not ok:
        return _err(out)
    vol, muted = (out.split("|") + ["", ""])[:2]
    return f"Volumen {vol}/100" + (" (silenciado)" if muted.strip() == "true" else "")


@mcp.tool()
def set_volume(level: int) -> str:
    """Set the system output volume. level is 0-100."""
    try:
        level = max(0, min(100, int(level)))
    except (TypeError, ValueError):
        return _err("level must be an integer between 0 and 100")
    ok, out = _osascript(f"set volume output volume {level}")
    return f"Volumen al {level}." if ok else _err(out)


@mcp.tool()
def media_control(action: str) -> str:
    """Control media playback. action is one of: play, pause, playpause, next, previous.

    Targets Spotify or Music, whichever is running.
    """
    action = action.strip().lower()
    verbs = {
        "play": "play",
        "pause": "pause",
        "playpause": "playpause",
        "next": "next track",
        "previous": "previous track",
        "prev": "previous track",
    }
    if action not in verbs:
        return _err("action must be play, pause, playpause, next or previous")
    verb = verbs[action]
    script = (
        'set out to ""\n'
        'tell application "System Events" to set spotify_running to (exists process "Spotify")\n'
        'tell application "System Events" to set music_running to (exists process "Music")\n'
        f'if spotify_running then\n    tell application "Spotify" to {verb}\n    set out to "Spotify"\n'
        f'else if music_running then\n    tell application "Music" to {verb}\n    set out to "Music"\n'
        'else\n    set out to "none"\nend if\n'
        "return out"
    )
    ok, out = _osascript(script)
    if not ok:
        return _err(out)
    if out == "none":
        return "No hay ningún reproductor abierto (Spotify o Música)."
    return f"{action} en {out}."


# --------------------------------------------------------------------------- #
# guarded tools (on-screen confirmation)
# --------------------------------------------------------------------------- #
@mcp.tool()
def run_applescript(script: str) -> str:
    """Run an arbitrary AppleScript. Shows a confirmation dialog before running.

    Use this only when no dedicated tool covers the request.
    """
    if not script.strip():
        return _err("empty script")
    if not _confirm("Ejecutar AppleScript", script):
        return "El usuario no autorizó la acción."
    ok, out = _osascript(script, timeout=60)
    return (out or "Listo.") if ok else _err(out)


@mcp.tool()
def run_shortcut(name: str, shortcut_input: str = "") -> str:
    """Run an Apple Shortcut by name, optionally passing text input. Confirmation required."""
    name = name.strip()
    if not name:
        return _err("empty shortcut name")
    if not shutil.which("shortcuts"):
        return _err("the 'shortcuts' CLI is not available")
    if not _confirm("Ejecutar Atajo (Shortcut)", name + (f"\nEntrada: {shortcut_input}" if shortcut_input else "")):
        return "El usuario no autorizó la acción."
    args = ["shortcuts", "run", name]
    inp = shortcut_input if shortcut_input else None
    proc = subprocess.run(args, input=inp, capture_output=True, text=True, timeout=60, check=False)
    if proc.returncode == 0:
        return proc.stdout.strip() or f"Ejecuté el atajo '{name}'."
    return _err(proc.stderr.strip() or f"shortcut '{name}' failed")


@mcp.tool()
def run_shell(command: str) -> str:
    """Run a shell command with /bin/zsh. Shows a confirmation dialog first.

    Powerful and irreversible actions are possible — the dialog shows the exact command.
    """
    command = command.strip()
    if not command:
        return _err("empty command")
    if not _confirm("Ejecutar comando de shell", command):
        return "El usuario no autorizó la acción."
    try:
        proc = subprocess.run(
            ["/bin/zsh", "-c", command],
            capture_output=True,
            text=True,
            timeout=60,
            check=False,
        )
    except subprocess.TimeoutExpired:
        return _err("command timed out after 60s")
    out = (proc.stdout or "").strip()
    errtxt = (proc.stderr or "").strip()
    tail = out[-1500:] if out else ""
    if proc.returncode == 0:
        return tail or "Listo (sin salida)."
    return _err(f"exit {proc.returncode}: {errtxt[-500:] or tail or 'no output'}")


if __name__ == "__main__":
    mcp.run()
