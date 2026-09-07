"""Comprobaciones del segmentador de dictado (sin ASR, sin modelos, ~1s).

Ejercita las dos rutas de corte —pausa natural y tope duro— y los casos que
rompieron la primera versión:

  · voz continua larga: un suelo de ruido con media simétrica sube hasta el
    nivel de la voz y el detector se queda sordo a mitad de sesión.
  · una tos: si el mínimo mide el buffer entero (preroll + tos + silencio) en
    vez de la voz que contiene, se cuela y whisper devuelve una frase inventada.

Uso:  uv run python scripts/check_segmenter.py   (código de salida 0 = todo bien)
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))

from open_llm_vtuber.transcription.segmenter import DictationSegmenter  # noqa: E402

SR = 16000
rng = np.random.default_rng(7)


def speech(seconds: float) -> np.ndarray:
    """Ruido de banda ancha a nivel de voz."""
    return (rng.standard_normal(int(SR * seconds)) * 0.08).astype(np.float32)


def silence(seconds: float) -> np.ndarray:
    """Sala en silencio, con algo de ruido de fondo."""
    return (rng.standard_normal(int(SR * seconds)) * 0.0004).astype(np.float32)


def run(audio: np.ndarray, mic_chunk_s: float = 0.1):
    seg = DictationSegmenter()
    out = []
    step = int(SR * mic_chunk_s)
    for i in range(0, len(audio), step):
        out.extend(seg.feed(audio[i : i + step]))
    tail = seg.flush()
    if tail is not None:
        out.append(tail)
    return out


def approx(value: float, target: float, tol: float) -> bool:
    return abs(value - target) <= tol


ok = True


def check(label: str, condition: bool, detail: str = "") -> None:
    global ok
    print(
        f"  {'OK  ' if condition else 'FALLA'} {label}{(' — ' + detail) if detail else ''}"
    )
    ok = ok and condition


print("[1] corte por pausa (3 frases separadas por 1s de silencio)")
audio = np.concatenate(
    [
        silence(1.0),
        speech(2.0),
        silence(1.0),
        speech(3.0),
        silence(1.0),
        speech(1.8),
        silence(1.0),
    ]
)
chunks = run(audio)
for c in chunks:
    print(f"    [{c.start:5.2f}s -> {c.end:5.2f}s]  {c.end - c.start:.2f}s")
check("tres fragmentos", len(chunks) == 3, f"{len(chunks)}")
if len(chunks) == 3:
    for i, esperado in enumerate((2.0, 3.0, 1.8)):
        dur = chunks[i].end - chunks[i].start
        # el fragmento lleva preroll delante y hasta silence_s de cola
        check(
            f"fragmento {i} ~{esperado}s",
            approx(dur, esperado + 0.85, 0.45),
            f"{dur:.2f}s",
        )
    check(
        "empieza cerca de la voz",
        approx(chunks[0].start, 1.0, 0.35),
        f"{chunks[0].start:.2f}s",
    )

print("\n[2] corte por tope duro (35s hablando sin pausa)")
chunks = run(np.concatenate([silence(0.5), speech(35.0), silence(1.0)]))
for c in chunks:
    print(f"    [{c.start:5.2f}s -> {c.end:5.2f}s]  {c.end - c.start:.2f}s")
check("se parte en trozos", len(chunks) >= 2, f"{len(chunks)}")
check("ninguno supera 22s", all(c.end - c.start <= 22.05 for c in chunks))
check(
    "sin huecos entre trozos",
    all(approx(a.end, b.start, 0.02) for a, b in zip(chunks, chunks[1:])),
)
check("cubre casi todo el audio", chunks[-1].end >= 34.0, f"{chunks[-1].end:.2f}s")

print("\n[3] solo silencio: no debe emitir nada")
check("cero fragmentos", len(run(silence(10.0))) == 0)

print("\n[4] un golpe corto (tos de 0.2s): se descarta")
check(
    "cero fragmentos",
    len(run(np.concatenate([silence(1.0), speech(0.2), silence(2.0)]))) == 0,
)

print("\n[5] flush con voz a medias al parar")
seg = DictationSegmenter()
a = np.concatenate([silence(0.5), speech(4.0)])
for i in range(0, len(a), 1600):
    seg.feed(a[i : i + 1600])
tail = seg.flush()
check(
    "devuelve la cola",
    tail is not None,
    f"{tail.end - tail.start:.2f}s" if tail else "None",
)

print("\nRESULTADO:", "TODO OK" if ok else "HAY FALLOS")
raise SystemExit(0 if ok else 1)
