# Writer (Linux)

Native-feeling Markdown writing app for Omarchy / Arch Linux, built with **Tauri 2 + TypeScript + CodeMirror 6**.

This is the primary Writer target going forward. The macOS Swift/AppKit app remains under `Sources/` for reference.

## Dependencies (Omarchy / Arch)

```sh
sudo pacman -S --needed webkit2gtk-4.1 base-devel curl wget file openssl \
  appmenu-gtk-module libappindicator-gtk3 librsvg \
  rust nodejs npm
```

On Ubuntu/Debian (for CI or other distros):

```sh
sudo apt install -y libwebkit2gtk-4.1-dev build-essential curl wget file \
  libssl-dev libgtk-3-dev libayatana-appindicator3-dev librsvg2-dev
# plus Rust (rustup) and Node 20+
```

## Run

From the repo root:

```sh
make linux-run
```

Or from this directory:

```sh
cd linux
npm install
npm run tauri:dev
```

## Build

```sh
make linux-app
```

Release binary and bundles land under:

- `linux/src-tauri/target/release/writer`
- `linux/src-tauri/target/release/bundle/{deb,rpm,appimage}/`

Install the AppImage or package on Omarchy, or copy the `writer` binary somewhere on your `PATH`.

## Features in this port

- Markdown editor with bundled iA Writer fonts (Duo / Quattro / Mono)
- Library sidebar (`~/Documents/Writer` by default)
- Live HTML preview
- Focus mode (sentence / paragraph)
- Style check (fillers, redundancies, clichés)
- Night mode, typewriter scrolling, word count / reading time
- Open / save `.md`, `.markdown`, `.txt`

Not yet ported from macOS: authorship coloring, parts-of-speech highlight, live Markdown (inline WYSIWYG), heading tree, PDF export.
