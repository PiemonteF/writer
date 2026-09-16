#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
. scripts/toolchain.sh
CONFIG="${1:-release}"
set -- -c "$CONFIG"
if [ "${UNIVERSAL:-0}" = 1 ]; then
    set -- "$@" --arch arm64 --arch x86_64
fi
swift build "$@"
BIN="$(swift build "$@" --show-bin-path)/Writer"
APP=build/Writer.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Writer"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp -R Resources/Fonts "$APP/Contents/Resources/Fonts"
cp Resources/preview.css "$APP/Contents/Resources/preview.css"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
# Ad-hoc signature only; no developer certificate or notarization required.
codesign --force --sign - "$APP" >/dev/null 2>&1
echo "$APP"
