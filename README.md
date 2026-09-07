# Miku — LLM Assistant

**Miku** is a voice-activated AI assistant with a Live2D avatar, built for macOS.
Say **"Miku"** and talk to her naturally — she lives in your menu bar and on your
desktop as a floating character. She can hold a conversation, open apps and
control your Mac, and see through your camera when you ask her to.

The persona is modeled on **Hatsune Miku**. This is a personal, non-commercial
fan project.

> **Status: early development.** Built by forking and extending
> [Open-LLM-VTuber](https://github.com/Open-LLM-VTuber/Open-LLM-VTuber) (MIT).
> See the roadmap below.

## What it will do

- **Wake word** — always-on, on-device detection of the word "Miku"
  (Picovoice Porcupine). Saying it opens a short conversation window; after that
  you keep talking without repeating the name, and it closes again on silence.
- **Natural conversation** — hands-free: voice in, voice out.
- **Hybrid brain**
  - A local model (Ollama, Qwen2.5) for everyday chat — private, offline, no cost.
  - **Claude**, with native tool-calling, for anything that needs to *act*:
    multi-step tasks, tools, harder reasoning, vision.
  - A router chooses per turn.
- **Control your Mac** — open apps, URLs and files; change volume and brightness;
  media controls. More powerful actions (AppleScript, Shortcuts, shell) run only
  after an on-screen confirmation.
- **Vision** — Miku can look through the webcam on request to answer questions
  about what she sees.
- **Live2D avatar** — a floating, transparent desktop-pet window with lip-sync
  and expressions; also reachable from the menu bar.
- **Dictation and notes** — a second listening mode where Miku writes instead of
  answering: speech is transcribed as you talk, stored with timestamps, and saved
  as a Markdown note on request (Notion later, behind the same tools). Cuts on a
  real speech-detection model (Silero VAD), not raw loudness, so background
  noise — a café, a train — doesn't get mistaken for something you said.
- **Offline-first speech** — speech recognition and synthesis run locally.
- **Apple Silicon first** — targeted and tuned for macOS on M-series chips.

## Architecture

```
┌─────────────────────────────┐        ┌──────────────────────────────┐
│  Miku.app  (SwiftUI, macOS) │        │  Backend  (Python, FastAPI)  │
│  • menu bar + floating win  │  WS    │  • ASR (whisper, local)      │
│  • Porcupine wake word      │◄──────►│  • Router agent (chat/task)  │
│  • mic capture / playback   │        │  • TTS (piper, local)        │
│  • dictation mode           │        │  • Dictation → transcripts/  │
│  • WKWebView Live2D render  │        │  • MCP tool servers: macos / │
│  • Local Action Server      │◄─HTTP──┤    time / web-search / notes │
│    (allow-list + confirm)   │        └──────┬───────────────┬───────┘
└─────────────────────────────┘               │               │
                                         Ollama (chat)    Claude (tasks,
                                                           tools, vision)
```

- **Miku.app** — the native client. Owns the wake word, audio, the avatar
  window, and macOS control (it holds the system permissions and shows the
  confirmation dialogs).
- **Backend** — forked from Open-LLM-VTuber; the engine for speech, the LLM
  router, and tool orchestration over MCP (Model Context Protocol).
- **`mcp-macos`** — a thin MCP server that forwards tool calls from the LLM to
  Miku.app's local action server.
- **`mcp-notes`** — reads the transcripts the backend wrote and saves notes. The
  transcript is written without any model involved, so "write that down" works
  even when the local model is too small to summarise well.

## Roadmap

Functionality first; the visual/design pass comes last.

| Milestone | Goal |
|-----------|------|
| M0  | Voice-to-voice pipeline (local ASR + TTS + Ollama), tested via the web client |
| M1  | Hybrid router: chat → Ollama, task → Claude with tools |
| M2  | macOS control tools (open apps/URLs, volume, media) driven from the backend |
| M3  | Native app skeleton: menu bar, permissions, WebSocket client, audio |
| M4  | Wake word (Porcupine "Miku") + session window |
| N0  | Dictation: mic → transcript on disk → Markdown note (`notes` MCP server) |
| M5  | Floating Live2D avatar window (WKWebView + pixi-live2d-display) |
| M6  | Native macOS control + on-screen confirmation for powerful actions |
| M7  | Camera / vision |
| M8+ | Design: custom Miku Live2D model, voice, animations, menu-bar UI |

## Built on Open-LLM-VTuber

This project forks
[**Open-LLM-VTuber**](https://github.com/Open-LLM-VTuber/Open-LLM-VTuber) and
reuses its speech pipeline, agent framework, MCP integration, and Live2D message
protocol. Upstream is MIT-licensed; its original README is kept here as
[`README.Open-LLM-VTuber.md`](./README.Open-LLM-VTuber.md). Upstream changes can
be pulled through the `upstream` git remote.

## Disclaimer

Personal, non-commercial fan project. "Hatsune Miku" and related characters are
© Crypton Future Media, INC. This project is not affiliated with or endorsed by
Crypton Future Media. Live2D sample models bundled from upstream are subject to
the Live2D Free Material License Agreement (see
[`LICENSE-Live2D.md`](./LICENSE-Live2D.md)).

## License

MIT, inherited from Open-LLM-VTuber — see [`LICENSE`](./LICENSE).
