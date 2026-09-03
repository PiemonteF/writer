# Writer

A personal macOS clone of iA Writer. Native Swift and AppKit, no Xcode project.

## Build and install

```sh
make app          # builds build/Writer.app
make run          # builds and opens it
make test         # pure-function tests
cp -R build/Writer.app /Applications/
```

Requires Xcode 16 at `/Applications/Xcode.app` (the Makefile points `DEVELOPER_DIR` at it because the Command Line Tools copy of SwiftPM cannot link package manifests on this machine).

## What it does

- Markdown editor with iA Writer Duo, Quattro, and Mono (bundled, SIL OFL), a centered column, dimmed syntax characters, bold headings, italic emphasis, monospaced code.
- Focus Mode (⌘D) for the current sentence, or paragraph via View > Focus.
- Typewriter Mode (⌥⌘T) keeps the caret line centered.
- Night Mode (⌥⌘N), or View > Appearance to follow the system.
- Syntax Highlight (View > Syntax Highlight) colors nouns, verbs, adjectives, adverbs, and conjunctions.
- Word count and reading time (⇧⌘C toggles the bar).
- Preview (⌘R) renders HTML beside the editor.
- Library (⌥⌘L) lists the Markdown and text files in a folder, with search. Choose the folder via File > Choose Library Folder. Default is `~/Documents/Writer`.
- Export to HTML or PDF (File > Export), Copy HTML (⌥⌘C).
- Format: Bold ⌘B, Italic ⌘I, Heading 1 to 3 (⌥⌘1 to ⌥⌘3), Body ⌥⌘0.
- Standard document behavior: autosave, versions, Open Recent, rename, duplicate, find (⌘F), spelling.

## Layout

See `docs/DESIGN.md`.
