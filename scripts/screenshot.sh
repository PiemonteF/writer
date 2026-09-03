#!/bin/sh
# Usage: scripts/screenshot.sh out.png
set -eu
cd "$(dirname "$0")/.."
OUT="${1:?output path}"
ID="$(swift scripts/windowid.swift)"
[ -n "$ID" ] || { echo "no Writer window on screen" >&2; exit 1; }
screencapture -l "$ID" -o -x "$OUT"
echo "$OUT"
