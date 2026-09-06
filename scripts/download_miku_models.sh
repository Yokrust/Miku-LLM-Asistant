#!/usr/bin/env bash
# Download the local ASR + TTS models Miku uses (sherpa-onnx), into ./models/.
# Offline, Apple-friendly. Safe to re-run: it skips models that are already extracted.
#
# Usage:  bash scripts/download_miku_models.sh
set -euo pipefail

cd "$(dirname "$0")/.."
mkdir -p models

DL_BASE="https://github.com/k2-fsa/sherpa-onnx/releases/download"

fetch() {
  # $1 = subdir under a release, $2 = tarball name, $3 = release tag, $4 = expected dir
  local tag="$1" tarball="$2" outdir="models/$3"
  if [ -d "$outdir" ]; then
    echo "✓ $3 already present, skipping"
    return
  fi
  echo "↓ downloading $tarball ..."
  curl -fL --retry 3 -o "models/$tarball" "$DL_BASE/$tag/$tarball"
  echo "⇲ extracting $tarball ..."
  tar xjf "models/$tarball" -C models/
  rm -f "models/$tarball"
  echo "✓ $3 ready"
}

# ASR: multilingual Whisper small (good Spanish, fast on Apple Silicon)
fetch "asr-models" "sherpa-onnx-whisper-small.tar.bz2" "sherpa-onnx-whisper-small"

# TTS: Spanish (Mexico) Piper voice — placeholder Miku voice until M8
fetch "tts-models" "vits-piper-es_MX-claude-high.tar.bz2" "vits-piper-es_MX-claude-high"

echo
echo "All models ready under ./models/. Paths already wired in conf.yaml."
