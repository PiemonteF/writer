#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
. scripts/toolchain.sh
CONFIG="${1:-release}"
swift build -c "$CONFIG"
BIN="$(swift build -c "$CONFIG" --show-bin-path)/Writer"
APP=build/Writer.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Writer"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp -R Resources/Fonts "$APP/Contents/Resources/Fonts"
cp Resources/preview.css "$APP/Contents/Resources/preview.css"
codesign --force --sign - "$APP" >/dev/null 2>&1
echo "$APP"
