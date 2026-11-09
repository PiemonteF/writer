#!/usr/bin/env bash
# Install Writer into a Linux prefix so Omarchy/Walker (and any XDG launcher) sees it.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PREFIX="${PREFIX:-${HOME}/.local}"
BIN_SRC="${BIN_SRC:-$ROOT/linux/src-tauri/target/release/writer}"
ICON_SRC="$ROOT/linux/src-tauri/icons"
DESKTOP_IN="$ROOT/linux/packaging/writer.desktop.in"

usage() {
  cat <<EOF
Usage: $(basename "$0") [--prefix DIR] [--binary PATH] [--skip-build]

Install Writer for Omarchy / Arch (XDG desktop entry + icons + binary).

Defaults:
  PREFIX=$HOME/.local
  binary=$BIN_SRC

Environment:
  PREFIX   Install root (default: ~/.local)
  BIN_SRC  Path to the release binary
EOF
}

SKIP_BUILD=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --prefix)
      PREFIX="$2"
      shift 2
      ;;
    --binary)
      BIN_SRC="$2"
      shift 2
      ;;
    --skip-build)
      SKIP_BUILD=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ ! -x "$BIN_SRC" ]]; then
  if [[ "$SKIP_BUILD" -eq 1 ]]; then
    echo "Binary not found or not executable: $BIN_SRC" >&2
    exit 1
  fi
  echo "Building Writer release binary…"
  make -C "$ROOT" linux-app
fi

if [[ ! -x "$BIN_SRC" ]]; then
  echo "Binary still missing after build: $BIN_SRC" >&2
  exit 1
fi

BIN_DIR="$PREFIX/bin"
APP_DIR="$PREFIX/share/applications"
ICON_BASE="$PREFIX/share/icons/hicolor"
BIN_DST="$BIN_DIR/writer"
ICON_NAME="writer"

mkdir -p "$BIN_DIR" "$APP_DIR"
install -m 755 "$BIN_SRC" "$BIN_DST"

install_icon() {
  local size="$1" src="$2"
  local dest_dir="$ICON_BASE/${size}x${size}/apps"
  mkdir -p "$dest_dir"
  install -m 644 "$src" "$dest_dir/${ICON_NAME}.png"
}

install_icon 32 "$ICON_SRC/32x32.png"
install_icon 128 "$ICON_SRC/128x128.png"
install_icon 256 "$ICON_SRC/128x128@2x.png"
install_icon 512 "$ICON_SRC/icon.png"

# Omarchy-friendly absolute fallback next to .desktop (used if theme lookup lags)
mkdir -p "$APP_DIR/icons"
install -m 644 "$ICON_SRC/128x128.png" "$APP_DIR/icons/writer.png"

# Prefer theme icon name; absolute path works even before icon cache refresh.
ICON_REF="$ICON_NAME"
if [[ ! -f "$ICON_BASE/128x128/apps/${ICON_NAME}.png" ]]; then
  ICON_REF="$APP_DIR/icons/writer.png"
fi

sed -e "s|@BIN@|$BIN_DST|g" -e "s|@ICON@|$ICON_REF|g" \
  "$DESKTOP_IN" >"$APP_DIR/writer.desktop"
chmod 644 "$APP_DIR/writer.desktop"

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$APP_DIR" >/dev/null 2>&1 || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1 && [[ -d "$ICON_BASE" ]]; then
  gtk-update-icon-cache -q -t -f "$ICON_BASE" >/dev/null 2>&1 || true
fi

cat <<EOF
Installed Writer for the desktop launcher.

  Binary:  $BIN_DST
  Desktop: $APP_DIR/writer.desktop
  Icons:   $ICON_BASE/*/apps/writer.png

On Omarchy: press Super+Space and type “Writer”.
Ensure $BIN_DIR is on your PATH (Omarchy ~/.local/bin usually is).

Uninstall:
  rm -f $BIN_DST $APP_DIR/writer.desktop $APP_DIR/icons/writer.png
  rm -f $ICON_BASE/*/apps/writer.png
EOF
