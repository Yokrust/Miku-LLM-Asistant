"""Benchmark del ASR: ¿aguanta el ritmo del habla?

Genera audio de prueba en español con el propio Piper del proyecto, lo trocea en
fragmentos del tamaño que usaría el segmentador de dictado, y mide cuánto tarda
sherpa-onnx whisper-small en transcribir cada uno.

Lo que importa es el RTF (real-time factor) = tiempo_de_proceso / duración_audio.
RTF < 1 significa que la transcripción va más rápido que el habla: la cola del
dictado se vacía sola. RTF > 1 significa que se acumula sin fin.

Uso:  uv run python scripts/bench_asr.py

Medido en un Mac M-series (2026-09-06) con whisper-small int8 en español:
  cpu/2 hilos  RTF 0.40-0.51   <- el mejor
  cpu/4 hilos  RTF 0.43-0.52
  cpu/8 hilos  RTF 0.50-0.59
  coreml/4     RTF 1.15-1.43   <- 2.5-3x MAS LENTO que CPU, no usar
"""

from __future__ import annotations

import subprocess
import sys
import time
from pathlib import Path

import numpy as np
import soundfile as sf

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / "src"))

# El audio de prueba es un artefacto de caché, no del repo.
OUT = REPO / "cache"
OUT.mkdir(exist_ok=True)
RAW_WAV = OUT / "bench_es_raw.wav"
WAV_16K = OUT / "bench_es_16k.wav"

# ~200 palabras de español neutro, frases de longitud variada, con números y
# nombres propios (lo que más se le atraganta a whisper-small).
PASSAGE = [
    "Buenos días, hoy vamos a revisar el estado del proyecto y los pendientes de la semana.",
    "El primer punto es la migración del servidor de transcripción, que quedó a medias el martes.",
    "Necesitamos decidir si seguimos con el modelo pequeño o si pasamos a uno más grande.",
    "Yael comentó que la latencia actual ronda los quince segundos por turno completo.",
    "Eso incluye reconocimiento de voz, el modelo de lenguaje y la síntesis de la respuesta.",
    "La propuesta es separar el camino de conversación del camino de transcripción larga.",
    "Así una grabación de cuarenta minutos no bloquea una petición de voz inmediata.",
    "El segundo punto son las notas: queremos que se guarden en Markdown desde el principio.",
    "Más adelante añadiremos Notion, pero la interfaz debe quedar abstracta desde ahora.",
    "El tercer punto es el permiso de grabación de pantalla, que hará falta para capturar el audio del sistema.",
    "Calculamos que eso llega hasta la fase seis, cuando la aplicación nativa ya gestione permisos.",
    "Por último, quedamos en medir el rendimiento real antes de comprometer el diseño de la cola.",
    "Si el factor de tiempo real supera el cero coma seis, habrá que bajar el tamaño del modelo.",
    "Nos vemos el jueves a las cuatro de la tarde para revisar los resultados.",
]


def log(msg: str) -> None:
    print(msg, flush=True)


# --------------------------------------------------------------------------- #
# 1. audio de prueba
# --------------------------------------------------------------------------- #
def make_test_audio() -> tuple[np.ndarray, int]:
    if WAV_16K.exists():
        audio, sr = sf.read(WAV_16K, dtype="float32")
        log(f"[audio] reutilizando {WAV_16K.name}: {len(audio) / sr:.1f}s @ {sr}Hz")
        return audio, sr

    import sherpa_onnx

    log("[audio] sintetizando español con Piper (sherpa-onnx)…")
    cfg = sherpa_onnx.OfflineTtsConfig(
        model=sherpa_onnx.OfflineTtsModelConfig(
            vits=sherpa_onnx.OfflineTtsVitsModelConfig(
                model=str(
                    REPO / "models/vits-piper-es_MX-claude-high/es_MX-claude-high.onnx"
                ),
                lexicon="",
                tokens=str(REPO / "models/vits-piper-es_MX-claude-high/tokens.txt"),
                data_dir=str(
                    REPO / "models/vits-piper-es_MX-claude-high/espeak-ng-data"
                ),
            ),
            provider="cpu",
            num_threads=4,
        ),
        max_num_sentences=1,
    )
    tts = sherpa_onnx.OfflineTts(cfg)

    pieces, sr = [], None
    t0 = time.perf_counter()
    for line in PASSAGE:
        out = tts.generate(line, sid=0, speed=1.0)
        sr = out.sample_rate
        pieces.append(np.asarray(out.samples, dtype=np.float32))
        # pausa corta entre frases, como en el habla real
        pieces.append(np.zeros(int(sr * 0.35), dtype=np.float32))
    raw = np.concatenate(pieces)
    log(f"[audio] Piper generó {len(raw) / sr:.1f}s en {time.perf_counter() - t0:.1f}s")

    sf.write(RAW_WAV, raw, sr)
    subprocess.run(
        [
            "ffmpeg",
            "-y",
            "-loglevel",
            "error",
            "-i",
            str(RAW_WAV),
            "-ar",
            "16000",
            "-ac",
            "1",
            str(WAV_16K),
        ],
        check=True,
    )
    audio, sr16 = sf.read(WAV_16K, dtype="float32")
    log(f"[audio] remuestreado a 16kHz mono: {len(audio) / sr16:.1f}s")
    return audio, sr16


# --------------------------------------------------------------------------- #
# 2. medición
# --------------------------------------------------------------------------- #
def build_engine(provider: str, threads: int):
    from open_llm_vtuber.asr.sherpa_onnx_asr import VoiceRecognition

    m = REPO / "models/sherpa-onnx-whisper-small"
    return VoiceRecognition(
        model_type="whisper",
        whisper_encoder=str(m / "small-encoder.int8.onnx"),
        whisper_decoder=str(m / "small-decoder.int8.onnx"),
        tokens=str(m / "small-tokens.txt"),
        whisper_language="es",
        whisper_task="transcribe",
        num_threads=threads,
        provider=provider,
    )


def bench(engine, audio: np.ndarray, sr: int, chunk_s: int) -> tuple[float, float, str]:
    """Devuelve (rtf_medio, segundos_por_fragmento, primera_transcripción)."""
    n = int(chunk_s * sr)
    chunks = [audio[i : i + n] for i in range(0, len(audio), n)]
    chunks = [c for c in chunks if len(c) > sr]  # descarta la cola < 1s

    times, first = [], ""
    for i, c in enumerate(chunks):
        t0 = time.perf_counter()
        text = engine.transcribe_np(c)
        times.append(time.perf_counter() - t0)
        if i == 0:
            first = text.strip()

    avg = sum(times) / len(times)
    return avg / chunk_s, avg, first


def main() -> None:
    audio, sr = make_test_audio()
    total_s = len(audio) / sr

    configs = [("cpu", 2), ("cpu", 4), ("cpu", 8), ("coreml", 4)]
    chunk_sizes = [5, 10, 20, 30]

    log("\n" + "=" * 78)
    log(f"whisper-small int8 · español · audio de prueba {total_s:.0f}s")
    log("=" * 78)

    results = {}
    for provider, threads in configs:
        label = f"{provider}/{threads}t"
        try:
            t0 = time.perf_counter()
            engine = build_engine(provider, threads)
            load_s = time.perf_counter() - t0
            engine.transcribe_np(audio[: sr * 3])  # warmup, fuera de la medida
        except Exception as e:  # provider no disponible, modelo roto, etc.
            log(f"\n### {label}: NO DISPONIBLE ({type(e).__name__}: {e})")
            continue

        log(f"\n### {label}  (carga del modelo: {load_s:.1f}s)")
        log(
            f"{'fragmento':>12} | {'seg/frag':>9} | {'RTF':>6} | {'¿sigue el ritmo?':>18}"
        )
        log("-" * 60)
        for cs in chunk_sizes:
            rtf, per_chunk, first = bench(engine, audio, sr, cs)
            results[(label, cs)] = rtf
            verdict = (
                "sí" if rtf < 0.6 else ("justo" if rtf < 1.0 else "NO, se acumula")
            )
            log(f"{cs:>10}s | {per_chunk:>8.2f}s | {rtf:>6.2f} | {verdict:>18}")
            if cs == 20:
                log(f'   texto: "{first[:110]}…"')

        del engine

    log("\n" + "=" * 78)
    if results:
        best = min(results.items(), key=lambda kv: kv[1])
        log(f"Mejor RTF: {best[1]:.2f} con {best[0][0]} en fragmentos de {best[0][1]}s")
        hour = best[1] * 3600
        log(f"→ una hora de audio tardaría ~{hour / 60:.0f} min en transcribirse")
    log("=" * 78)


if __name__ == "__main__":
    main()
