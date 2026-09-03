# Writer

A personal macOS clone of iA Writer. Native Swift, AppKit for the editor, no Xcode project: Swift Package Manager builds the binary and `scripts/build-app.sh` wraps it into `build/Writer.app`.

## Constraints

- Build with Command Line Tools only (`swift build`). `swift-tools-version: 5.9`, `swiftLanguageVersions: [.v5]` so AppKit code is not fighting strict concurrency. macOS 14 deployment target.
- No storyboards, no nibs. Windows and menus are built in code.
- Fonts ship in `Resources/Fonts` (iA Writer Duo S, Quattro S, Mono S, SIL OFL) and are registered at launch with `CTFontManagerRegisterFontsForURL(.process)`.
- Resources are copied by the build script into `Contents/Resources`, read via `Bundle.main`. Do not use SwiftPM `resources:`.

## Layout

```
Package.swift
Sources/Writer/
  main.swift                       NSApplication bootstrap, AppDelegate install, run loop
  App/AppDelegate.swift            font registration, appearance, untitled doc on launch
  App/MainMenu.swift               menu built from a MenuSpec table
  App/Preferences.swift            UserDefaults-backed settings, single source of truth
  Document/Document.swift          NSDocument for UTF-8 text (md, markdown, txt)
  Document/EditorWindowController.swift
  Editor/EditorViewController.swift  scroll view + EditorTextView + StatsBar
  Editor/EditorTextView.swift      NSTextView subclass: line width, typewriter, focus dimming
  Editor/Theme.swift               colors and fonts derived from Preferences + appearance
  Editor/StatsBar.swift            bottom bar: word count and reading time
  Markdown/MarkdownHighlighter.swift  text -> [Span], applied to NSTextStorage
  Text/TextStatistics.swift        words, characters, sentences, reading time (pure)
  Text/FocusRange.swift            sentence/paragraph range around the caret (pure)
Tests/WriterTests/                 pure-function tests: highlighter, statistics, focus range
Resources/Info.plist
Resources/Fonts/*.ttf
scripts/build-app.sh               swift build -c release, assemble .app, ad hoc codesign
Makefile                           app, run, test, clean
```

## Data shapes

Preferences is the only mutable app-level state. Everything else derives from it.

```swift
enum FocusMode: String, CaseIterable { case off, sentence, paragraph }
enum EditorFont: String, CaseIterable { case duo, quattro, mono; var familyName: String }
enum Appearance: String, CaseIterable { case system, light, dark }

final class Preferences {                      // UserDefaults-backed, posts .preferencesDidChange
    static let shared: Preferences
    var font: EditorFont            // default .duo
    var fontSize: CGFloat           // default 17
    var appearance: Appearance      // default .system
    var focusMode: FocusMode        // default .off
    var typewriter: Bool            // default false
    var showStats: Bool             // default true
    var lineLength: Int             // max characters per line, default 66
}

struct Theme {                                  // value, rebuilt on preference or appearance change
    let font, boldFont, italicFont, boldItalicFont, monoFont: NSFont
    let background, text, dimmedText, markup, accent, caret: NSColor
    let lineHeightMultiple: CGFloat  // 1.5
    let maxLineWidth: CGFloat        // lineLength * average glyph advance
    static func make(_ prefs: Preferences, dark: Bool) -> Theme
}
```

Colors, light: background #FCFCFC, text #1A1A1A, dimmed #BFBFBF, markup #8E9AA8, accent/caret #2F7CF6.
Colors, dark: background #1E1E1E, text #E6E6E6, dimmed #575757, markup #6C7885, accent/caret #4A90FF.

Markdown highlighting is a table of rules, not a hand-written parser.

```swift
enum MarkdownStyle { case heading(level: Int), strong, emphasis, code, codeBlock, link, url, markup, quote, listMarker, rule }
struct Span { let range: NSRange; let style: MarkdownStyle }

enum MarkdownHighlighter {
    static func spans(in text: String) -> [Span]                   // pure, whole document
    static func apply(_ spans: [Span], to storage: NSTextStorage, theme: Theme, in range: NSRange)
}
```

Rules are `(NSRegularExpression, styleForWholeMatch, styleForMarkupGroups)` in one array. Block rules (heading lines, fenced code, quote lines, list markers, rules) run line by line; inline rules (strong, emphasis, code, links) run inside non-code lines. Markup characters (`#`, `*`, `_`, `` ` ``, `[`, `]`, `(`, `)`) get `.markup`.

Applying: on `NSTextStorageDelegate.textStorage(_:didProcessEditing:)`, recompute spans for the whole document when it is under 200 KB (measured in UTF-16 units), otherwise for the edited paragraph range only. Reset the affected range to base attributes (theme font, text color, paragraph style with line height), then layer spans. Attribute application is wrapped in `beginEditing`/`endEditing`.

Focus mode uses temporary attributes on the layout manager, never the text storage, so it never dirties the document.

```swift
enum FocusRange {
    static func range(mode: FocusMode, caret: Int, in text: NSString) -> NSRange?  // nil when off
}
```

Sentence uses `enumerateSubstrings(.bySentences)`; paragraph uses `paragraphRange(for:)`. On every selection change, clear temporary foreground color on the whole document and set `dimmedText` on everything outside the focus range. Focus mode also enables typewriter behavior in iA Writer; keep the two independent here and let the menu toggle both.

Typewriter mode keeps the caret line vertically centered. `EditorTextView` sets `textContainerInset` so top and bottom insets equal half the visible height, and on selection change scrolls so the caret rect's midpoint sits at the visible midpoint. Without typewriter, insets are 40pt top and bottom.

Line width: the text container width is `min(viewWidth - 2 * 24, theme.maxLineWidth)`, centered by horizontal inset. Recomputed on `viewDidEndLiveResize` and frame change.

Statistics are pure and computed off the main thread, debounced at 200 ms.

```swift
struct TextStatistics {
    let words, characters, sentences, paragraphs: Int
    var readingTime: TimeInterval   // words / 275 per minute, minimum 0
    static func compute(_ text: String) -> TextStatistics
}
```

The stats bar shows `1,234 words · 6 min` in the dimmed color, 11pt, right aligned, hidden when `showStats` is false.

## Menu

`MainMenu.swift` builds from a table. Each row is `(title, selector, key, modifiers)`; validation reads `Preferences.shared` and sets the checkmark. Recent documents come from a submenu holding a hidden item whose action is `clearRecentDocuments:`, which NSDocumentController populates.

- Writer: About, Preferences (⌘,) opens nothing yet, Hide, Quit.
- File: New ⌘N, Open ⌘O, Open Recent, Close ⌘W, Save ⌘S, Duplicate, Rename, Move To, Revert.
- Edit: Undo, Redo, Cut, Copy, Paste, Select All, Find (⌘F, `performFindPanelAction:`), Spelling.
- Format: Bold ⌘B wraps selection in `**`, Italic ⌘I wraps in `_`, Heading 1 to 3 (⌥⌘1..3) prefix line with `#`.
- View: Focus Mode ⌘D toggles sentence focus, Focus submenu (Sentence, Paragraph), Typewriter Mode ⌥⌘T, Night Mode ⌥⌘N cycles appearance, Word Count ⇧⌘C toggles stats, Font submenu (Duo, Quattro, Mono), Bigger ⌘+, Smaller ⌘-.
- Window: Minimize, Zoom, Bring All to Front.

## Document

`Document: NSDocument` holds `text: String`, reads and writes UTF-8, `autosavesInPlace` true, `canAsynchronouslyWrite` false. `Info.plist` declares `net.daringfireball.markdown` and `public.plain-text` with `NSDocumentClass = Writer.Document` and `CFBundleTypeRole = Editor`. On launch with no documents, `applicationShouldOpenUntitledFile` returns true.

Window: 760 by 900 default, title bar shows document name, `titlebarAppearsTransparent`, full-size content view, background is the theme background, no toolbar.

## Verification

`make test` runs the pure-function tests. `make run` builds `build/Writer.app` and opens it. A screenshot of the running window is the acceptance artifact for anything visual: `scripts/screenshot.sh` finds the Writer window via `CGWindowListCopyWindowInfo` (a short Swift script) and calls `screencapture -l <id>`.

## Later phases

Preview pane and export (WebKit, Markdown to HTML), library sidebar over a folder, parts-of-speech syntax highlight (NaturalLanguage), style check, app icon.
