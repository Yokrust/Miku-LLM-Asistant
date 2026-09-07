"""Comprobaciones de SileroSegmenter con voz real y ruido real (no gaussiano).

check_segmenter.py prueba DictationSegmenter con "voz" = ruido gaussiano a nivel
alto, porque a un detector por energía ruido fuerte y voz le parecen lo mismo.
Ese mismo truco no sirve aquí: Silero VAD clasifica por si el sonido *suena* a
voz, así que ruido gaussiano —por fuerte que esté— no cuela como habla (es
justamente el punto: verificado más abajo). Por eso este script sintetiza voz
de verdad con el propio Piper del proyecto.

Requiere los modelos descargados (uv run --no-sync python
scripts/download_miku_models.sh); si faltan, se salta con aviso en vez de
fallar — igual que build_segmenter() cae al detector por energía sin ellos.

Uso:  uv run --no-sync python scripts/check_vad_segmenter.py
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

import numpy as np

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / "src"))

from open_llm_vtuber.transcription.segmenter import SileroSegmenter  # noqa: E402

SR = 16000
VAD_MODEL = REPO / "models/silero-vad/silero_vad_v4.onnx"
PIPER_MODEL = REPO / "models/vits-piper-es_MX-claude-high/es_MX-claude-high.onnx"

if not VAD_MODEL.is_file() or not PIPER_MODEL.is_file():
    print(
        "[skip] faltan modelos (VAD y/o Piper). "
        "uv run --no-sync python scripts/download_miku_models.sh los instala."
    )
    raise SystemExit(0)

import sherpa_onnx  # noqa: E402  (solo hace falta si los modelos ya están)

rng = np.random.default_rng(3)

# --------------------------------------------------------------------------- #
# voz real, sintetizada una sola vez y reusada en todas las comprobaciones
# --------------------------------------------------------------------------- #
_tts = sherpa_onnx.OfflineTts(
    sherpa_onnx.OfflineTtsConfig(
        model=sherpa_onnx.OfflineTtsModelConfig(
            vits=sherpa_onnx.OfflineTtsVitsModelConfig(
                model=str(PIPER_MODEL),
                lexicon="",
                tokens=str(PIPER_MODEL.parent / "tokens.txt"),
                data_dir=str(PIPER_MODEL.parent / "espeak-ng-data"),
            ),
            provider="cpu",
            num_threads=2,
        ),
        max_num_sentences=1,
    )
)


def synth(text: str) -> np.ndarray:
    """Frase hablada de verdad, a 16kHz mono (Piper sintetiza a 22050Hz)."""
    out = _tts.generate(text, sid=0, speed=1.0)
    raw = REPO / "cache" / "_check_vad_raw.wav"
    out16 = REPO / "cache" / "_check_vad_16k.wav"
    raw.parent.mkdir(exist_ok=True)
    import soundfile as sf

    sf.write(raw, np.asarray(out.samples, dtype=np.float32), out.sample_rate)
    subprocess.run(
        [
            "ffmpeg",
            "-y",
            "-loglevel",
            "error",
            "-i",
            str(raw),
            "-ar",
            "16000",
            "-ac",
            "1",
            str(out16),
        ],
        check=True,
    )
    audio, sr = sf.read(out16, dtype="float32")
    assert sr == SR
    raw.unlink(missing_ok=True)
    out16.unlink(missing_ok=True)
    return audio


def noise(seconds: float, level: float) -> np.ndarray:
    """Ruido de banda ancha — a diferencia de check_segmenter.py, aquí NO es voz."""
    return (rng.standard_normal(int(SR * seconds)) * level).astype(np.float32)


def run(audio: np.ndarray, chunk: int = 4096):
    """Alimenta en trozos de 4096 muestras — lo que manda MikuController.swift,
    deliberadamente NO alineado a la ventana interna de 512 del modelo."""
    seg = SileroSegmenter(model_path=str(VAD_MODEL))
    out = []
    for i in range(0, len(audio), chunk):
        out.extend(seg.feed(audio[i : i + chunk]))
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


print("[preparando voz de prueba con Piper…]")
s1 = synth("Primera frase de la prueba.")
s2 = synth("Segunda frase, dicha después de una pausa.")
print(f"  s1: {len(s1) / SR:.2f}s   s2: {len(s2) / SR:.2f}s\n")

print(
    "[1] dos frases con pausa: dos fragmentos, en orden, con buena precisión de tiempos"
)
audio = np.concatenate(
    [noise(1.0, 0.003), s1, noise(1.0, 0.003), s2, noise(1.0, 0.003)]
)
chunks = run(audio)
for c in chunks:
    print(f"    [{c.start:5.2f}s -> {c.end:5.2f}s]  {c.end - c.start:.2f}s")
check("dos fragmentos", len(chunks) == 2, f"{len(chunks)}")
if len(chunks) == 2:
    esperado_s1 = 1.0  # noise(1.0) antes de s1
    esperado_s2 = 1.0 + len(s1) / SR + 1.0
    # min_speech_s=0.4 en el constructor: el VAD espera 0.4s de señal parecida a
    # voz antes de confirmar el inicio, así que ~0.3-0.4s de retraso es el
    # comportamiento esperado, no un fallo de precisión.
    check(
        "s1 empieza donde toca",
        approx(chunks[0].start, esperado_s1, 0.5),
        f"{chunks[0].start:.2f}s",
    )
    check(
        "s2 empieza donde toca",
        approx(chunks[1].start, esperado_s2, 0.5),
        f"{chunks[1].start:.2f}s",
    )
    check("orden temporal correcto", chunks[0].end <= chunks[1].start)

print(
    "\n[2] ruido fuerte SIN voz: cero fragmentos (esto es lo que falla en el detector por energía)"
)
loud_noise = noise(10.0, 0.05)  # más fuerte que una frase hablada normal
chunks = run(loud_noise)
check("cero fragmentos con solo ruido", len(chunks) == 0, f"{len(chunks)} fragmentos")

print(
    "\n[3] voz sepultada en ruido de fondo: se sigue detectando, con límites razonables"
)
audio = np.concatenate([noise(1.0, 0.01), s1, noise(1.0, 0.01)])
chunks = run(audio)
for c in chunks:
    print(f"    [{c.start:5.2f}s -> {c.end:5.2f}s]  {c.end - c.start:.2f}s")
check("un fragmento", len(chunks) == 1, f"{len(chunks)}")
if chunks:
    check(
        "cerca del inicio real de la voz",
        approx(chunks[0].start, 1.0, 0.5),
        f"{chunks[0].start:.2f}s",
    )

print("\n[4] silencio puro: cero fragmentos")
check("cero fragmentos", len(run(noise(8.0, 0.0002))) == 0)

print(
    "\n[5] tope duro: voz sintética repetida sin pausas reales > 22s se corta antes de los 30s de whisper"
)
repeticiones = max(
    16, int(24.0 / (len(s1) / SR)) + 1
)  # asegura > 22s de audio SIN pausas
larga = np.concatenate([s1] * repeticiones)
print(f"  ({repeticiones} repeticiones de s1 = {len(larga) / SR:.1f}s continuos)")
chunks = run(larga)
for c in chunks:
    print(f"    [{c.start:5.2f}s -> {c.end:5.2f}s]  {c.end - c.start:.2f}s")
check("se corta en más de un trozo", len(chunks) >= 2, f"{len(chunks)}")
check("ningún trozo llega a 30s", all(c.end - c.start < 30.0 for c in chunks))

print("\nRESULTADO:", "TODO OK" if ok else "HAY FALLOS")
raise SystemExit(0 if ok else 1)
