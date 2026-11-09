<p align="center">
  <img src="Resources/Logo/logo.png" width="96" alt="Writer">
</p>

# Writer

A simple place with no AI. If there is any, you know.

Authentic thoughts. Yours.

**Primary target: Omarchy / Arch Linux** (Tauri 2 + TypeScript + CodeMirror). The original macOS Swift/AppKit app remains in `Sources/` for reference.

<p align="center">
  <img src="docs/screenshots/editor-light.png" width="720" alt="Writer in light mode">
</p>

## Install on Omarchy (Arch)

### 1. Dependencies

```sh
sudo pacman -S --needed webkit2gtk-4.1 base-devel curl wget file openssl \
  appmenu-gtk-module libappindicator-gtk3 librsvg \
  rust nodejs npm
```

### 2. Build and install as a desktop app

```sh
git clone https://github.com/PiemonteF/writer.git
cd writer
make linux-install
```

That builds the release binary and installs:

| What | Where |
| --- | --- |
| Binary | `~/.local/bin/writer` |
| Launcher entry | `~/.local/share/applications/writer.desktop` |
| Icons | `~/.local/share/icons/hicolor/*/apps/writer.png` |

Open the app launcher (**Super+Space** / Walker), type **Writer**, and launch it.

`~/.local/bin` is already on `PATH` on a normal Omarchy setup. If `writer` is not found in a terminal, add this to your shell config:

```sh
export PATH="$HOME/.local/bin:$PATH"
```

### 3. Update

```sh
cd writer
git pull
make linux-install
```

### Uninstall

```sh
make linux-uninstall
```

### System-wide Arch package (optional)

```sh
make linux-pkg    # produces a .pkg.tar.zst under linux/packaging/arch/
# then: sudo pacman -U linux/packaging/arch/writer-*.pkg.tar.zst
```

Or install into `/usr` directly (needs root):

```sh
sudo make linux-install PREFIX=/usr
```

### Portable bundles

```sh
make linux-app
```

Artifacts:

- `linux/src-tauri/target/release/writer`
- `linux/src-tauri/target/release/bundle/{deb,rpm,appimage}/`

AppImage: `chmod +x *.AppImage && ./Writer_*.AppImage`. Deb/rpm include a `.desktop` entry when installed with their package managers.

### Dev run (no install)

```sh
make linux-run
```

Chrome-less like iA Writer: white page, no toolbar — **Ctrl+/** opens Commands. Library stays hidden until Alt+Ctrl+L.

Details: [`linux/README.md`](linux/README.md).

### What works on Linux

- Quiet white writing surface (iA Writer Duo / Quattro / Mono); night mode optional
- Library sidebar on demand (Alt+Ctrl+L)
- Preview (Ctrl+R)
- Focus Mode (Ctrl+D) — sentence / paragraph
- Style Check (Alt+Shift+Ctrl+D)
- Night Mode (Alt+Ctrl+N), Typewriter (Alt+Ctrl+T)
- Word count and reading time (Shift+Ctrl+C)
- In-app commands / shortcuts guide (Ctrl+/ or Ctrl+?)

Still Mac-only for now: authorship coloring, parts-of-speech highlight, live Markdown preview, heading tree, PDF export.

## macOS (legacy)

Requires macOS 14+ and Xcode 16 at `/Applications/Xcode.app`.

```sh
make macos-run    # build build/Writer.app and open
make macos-test   # Swift pure-function tests
```

Or download `Writer-macOS.zip` from [Releases](../../releases/latest).

Authorship, ⇧⌘A. What you typed stays black. What was pasted or generated is in color. Rewrite it and it becomes yours again.

## Shortcuts (Linux)

Press **Ctrl+/** or **Ctrl+?** for the full searchable guide — every action, key, and a short description. Filter with the search box; ↑↓ + Enter runs a command.

| Action | Key |
| --- | --- |
| Commands / shortcuts guide | Ctrl+/ or Ctrl+? |
| New / Open / Save | Ctrl+N / Ctrl+O / Ctrl+S |
| Focus Mode | Ctrl+D |
| Preview | Ctrl+R |
| Night Mode | Alt+Ctrl+N |
| Typewriter Mode | Alt+Ctrl+T |
| Library | Alt+Ctrl+L |
| Style Check | Alt+Shift+Ctrl+D |
| Word Count | Shift+Ctrl+C |
| Bigger / Smaller text | Ctrl+= / Ctrl+- |

Writer uses **Ctrl / Alt+Ctrl** only (no Super), so it stays clear of Omarchy/Hyprland compositor binds (Super+Space, Super+Ctrl+…, etc.).

## Layout

See `docs/DESIGN.md` (macOS architecture) and the Omarchy port notes in the project docs store.
