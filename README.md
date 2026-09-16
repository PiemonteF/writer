<p align="center">
  <img src="Resources/Logo/logo.png" width="96" alt="Writer">
</p>

# Writer

Um local simples e sem AI. Se tiver, você sabe.

Pensamentos autênticos. Os seus.

Native Swift and AppKit. No Xcode project.

<p align="center">
  <img src="docs/screenshots/editor-light.png" width="720" alt="Writer in light mode">
</p>

Authorship, ⇧⌘A. What you typed stays black. What was pasted or generated is in color. Rewrite it and it becomes yours again.

<p align="center">
  <img src="docs/screenshots/authorship-light.png" width="720" alt="Authorship: your words in black, pasted AI in color">
</p>

## Run it

macOS 14 or later, and Xcode 16 at `/Applications/Xcode.app`. The Makefile points `DEVELOPER_DIR` at that copy because the Command Line Tools SwiftPM on this machine cannot link package manifests.

```sh
git clone https://github.com/PiemonteF/writer.git
cd writer
make run
```

That builds `build/Writer.app` and opens it. Other targets:

```sh
make app       # build only
make install   # copy to /Applications and open
make test      # pure-function tests
```

Open any `.md`, `.markdown`, or `.txt` file, or start typing in the untitled window.

## What it looks like

Night Mode, ⌥⌘N.

<img src="docs/screenshots/editor-dark.png" width="720" alt="Writer in night mode">

Syntax Highlight, ⇧⌘D. Nouns red, verbs blue, adjectives brown, adverbs magenta, conjunctions green.

<img src="docs/screenshots/syntax-dark.png" width="720" alt="Parts of speech colored in the editor">

Focus Mode, ⌘D. The current sentence stays, the rest recedes.

<img src="docs/screenshots/focus-light.png" width="720" alt="Focus mode on the current sentence">

Preview, ⌘R. Markdown on the left, HTML on the right.

<img src="docs/screenshots/preview-light.png" width="900" alt="Editor and preview side by side">

Style Check, ⌥⇧⌘D. Fillers, clichés, and redundancies are struck in the editor only. Double-click a struck phrase to select it.

<img src="docs/screenshots/style-check.png" width="720" alt="Style check striking weak phrases">

Library, ⌥⌘L. A folder of Markdown and text files, with search. File > Choose Library Folder. Default is `~/Documents/Writer`.

<img src="docs/screenshots/library-dark.png" width="820" alt="Library sidebar next to the editor">

## What it does

- Centered column, dimmed markup, bold headings, italic emphasis, monospaced code. Fonts are iA Writer Duo, Quattro, and Mono, bundled, SIL OFL.
- Typewriter Mode (⌥⌘T) keeps the caret line centered.
- Authorship (⇧⌘A). Paste as / Mark as live under Authors.
- Word count and reading time (⇧⌘C toggles the bar).
- Export to HTML or PDF. Copy HTML with ⌥⌘C.
- Format: Bold ⌘B, Italic ⌘I, Heading 1 to 3 (⌥⌘1 to ⌥⌘3), Body ⌥⌘0.
- Standard document behavior: autosave, versions, Open Recent, rename, duplicate, find (⌘F), spelling.

## Shortcuts

| Action | Key |
| --- | --- |
| Focus Mode | ⌘D |
| Preview | ⌘R |
| Night Mode | ⌥⌘N |
| Typewriter Mode | ⌥⌘T |
| Library | ⌥⌘L |
| Syntax Highlight | ⇧⌘D |
| Style Check | ⌥⇧⌘D |
| Authorship | ⇧⌘A |
| Word Count | ⇧⌘C |
| Copy HTML | ⌥⌘C |

## Layout

See `docs/DESIGN.md`.
