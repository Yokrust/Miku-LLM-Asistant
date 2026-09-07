#!/usr/bin/env bash
# Build Miku.app without Xcode: SwiftPM produces the binary, this script wraps it
# in a proper .app bundle and ad-hoc signs it so macOS will grant it microphone
# access. Xcode is not required — only the Command Line Tools.
#
# Usage:  ./build.sh [debug|release]     (default: debug)
set -euo pipefail
cd "$(dirname "$0")"

CONFIG="${1:-debug}"
APP="build/Miku.app"

echo "▸ compilando ($CONFIG)…"
swift build -c "$CONFIG"
BIN="$(swift build -c "$CONFIG" --show-bin-path)/Miku"

echo "▸ ensamblando $APP…"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Miku"
cp Resources/Info.plist "$APP/Contents/Info.plist"

# Ad-hoc signature. Enough for local development; a Developer ID is only needed
# to distribute the app to other machines.
echo "▸ firmando (ad-hoc)…"
codesign --force --sign - --timestamp=none "$APP" >/dev/null 2>&1

echo "✓ listo: $APP"
echo "  abrir con:  open $APP"
