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

## Install like a normal desktop app (Omarchy)

From the repo root:

```sh
make linux-install
```

Installs the binary, icons, and an XDG `.desktop` entry under `~/.local` so **Walker** (`Super+Space`) lists **Writer**.

| File | Path |
| --- | --- |
| Binary | `~/.local/bin/writer` |
| Desktop entry | `~/.local/share/applications/writer.desktop` |
| Icons | `~/.local/share/icons/hicolor/{32,128,256,512}x…/apps/writer.png` |

Update: `git pull && make linux-install`  
Remove: `make linux-uninstall`

System-wide: `sudo make linux-install PREFIX=/usr`  
Arch package: `make linux-pkg` (needs `makepkg`)

Packaging sources:

- `linux/scripts/install-desktop.sh` — XDG install
- `linux/packaging/writer.desktop.in` — desktop template for user/system install
- `linux/src-tauri/writer.desktop` — Tauri Handlebars template for deb/rpm
- `linux/packaging/arch/PKGBUILD` — local Arch package

## Run without installing

```sh
make linux-run
```

Or from this directory:

```sh
cd linux
npm install
npm run tauri:dev
```

## Build bundles only

```sh
make linux-app
```

Release binary and bundles land under:

- `linux/src-tauri/target/release/writer`
- `linux/src-tauri/target/release/bundle/{deb,rpm,appimage}/`

## Features in this port

- Markdown editor with bundled iA Writer fonts (Duo / Quattro / Mono)
- Library sidebar (`~/Documents/Writer` by default)
- Live HTML preview
- Focus mode (sentence / paragraph)
- Style check (fillers, redundancies, clichés)
- Night mode, typewriter scrolling, word count / reading time
- Open / save `.md`, `.markdown`, `.txt`
- Desktop launcher integration (icon + `.desktop`)

Not yet ported from macOS: authorship coloring, parts-of-speech highlight, live Markdown (inline WYSIWYG), heading tree, PDF export.
