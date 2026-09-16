#!/bin/sh
# Rebuild AppIcon.icns from Resources/Logo/logo.svg
set -eu
cd "$(dirname "$0")/.."
SVG=Resources/Logo/logo.svg
ICONSET=Resources/AppIcon.iconset
test -f "$SVG"
rm -rf "$ICONSET"
mkdir -p "$ICONSET"
while IFS=: read -r name size; do
	rsvg-convert -w "$size" -h "$size" -o "$ICONSET/$name" "$SVG"
done <<'SIZES'
icon_16x16.png:16
icon_16x16@2x.png:32
icon_32x32.png:32
icon_32x32@2x.png:64
icon_128x128.png:128
icon_128x128@2x.png:256
icon_256x256.png:256
icon_256x256@2x.png:512
icon_512x512.png:512
icon_512x512@2x.png:1024
SIZES
rsvg-convert -w 1024 -h 1024 -o Resources/Logo/logo.png "$SVG"
iconutil -c icns -o Resources/AppIcon.icns "$ICONSET"
echo Resources/AppIcon.icns
