# Writer

A personal macOS clone of iA Writer. Native Swift, AppKit for the editor, no Xcode project: Swift Package Manager builds the binary and `scripts/build-app.sh` wraps it into `build/Writer.app`.

## Constraints

- Built with SwiftPM using Xcode's toolchain (`DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`, exported by the Makefile and `scripts/toolchain.sh`). The Command Line Tools SwiftPM on this machine cannot link package manifests. `swift-tools-version: 5.9` keeps Swift 5 language mode. macOS 14 deployment target. One dependency: Ink, for Markdown to HTML.
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
  Markdown/MarkdownRenderer.swift  Markdown -> HTML body or full document (Ink)
  Preview/PreviewViewController.swift  WKWebView preview, PDF via createPDF
  Library/LibraryNode.swift        folder tree of md/txt files, search
  Library/LibraryViewController.swift  sidebar outline, folder watcher, opens documents
  Text/TextStatistics.swift        words, characters, sentences, reading time (pure)
  Text/FocusRange.swift            sentence/paragraph range around the caret (pure)
  Text/PartsOfSpeech.swift         NLTagger lexical classes -> [PartOfSpeechSpan] (pure)
  Text/StyleCheck.swift            fillers, clichés, redundancies -> [StyleSpan] (pure)
  Text/Authorship.swift            run-length author map, insert/delete/mark (pure)
  Text/AnnotationBlock.swift       Markdown Annotations trailer parse/render (pure)
Tests/WriterTests/                 pure-function tests: highlighter, renderer, statistics, focus range, parts of speech, style check, authorship
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
    var showAuthorship: Bool        // default false; ⇧⌘A
    var lineLength: Int             // max characters per line, default 66
    var highlightedParts: Set<PartOfSpeech>  // default empty; ⇧⌘D toggles all
    var styleChecks: Set<StyleIssue>         // default empty; ⌥⇧⌘D toggles all
    var libraryURL: URL             // default ~/Documents/Writer
    var showLibrary: Bool           // default false
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

Focus mode, parts-of-speech, style check, and authorship are one overlay of temporary attributes on the layout manager, never the text storage, so they never dirty the document. `applyOverlay()` clears the overlay, then either paints authorship (when `showAuthorship` is on) or part-of-speech colors (skipping code and URL spans). Style check then strikes matching fillers, clichés, and redundancies in `dimmedText`. Focus dimming is applied last. Authorship and syntax highlight are alternative views: authorship takes the color overlay when both would apply. Style check can run with either. Double-clicking a struck span selects the whole match.

Syntax colors follow iA Writer: nouns red, verbs blue, adjectives brown, adverbs magenta, conjunctions green. ⇧⌘D enables every part of speech; the Syntax Highlight submenu still toggles them one at a time.

Style check is a table of English phrases, longest match first, word-boundary, case-insensitive. Categories: filler (`actually`, `pretty much`), redundancy (`end result`, `unexpected surprise`), cliché (`think outside the box`). ⌥⇧⌘D enables every category. Strikes are editor-only: preview and export are untouched.

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
- View: Focus Mode ⌘D toggles sentence focus, Focus submenu (Sentence, Paragraph), Typewriter Mode ⌥⌘T, Night Mode ⌥⌘N cycles appearance, Syntax Highlight ⇧⌘D (submenu per part of speech), Style Check ⌥⇧⌘D (submenu: Fillers, Redundancies, Clichés), Authorship ⇧⌘A, Word Count ⇧⌘C toggles stats, Font submenu (Duo, Quattro, Mono), Bigger ⌘+, Smaller ⌘-.
- Authors: Show Authorship ⇧⌘A, Paste as AI / Mine / Reference, Mark Selection as AI / Mine / Reference.
- Window: Minimize, Zoom, Bring All to Front.

## Document

`Document: NSDocument` holds `text: String` and `authorship: Authorship`, reads and writes UTF-8, `autosavesInPlace` true, `canAsynchronouslyWrite` false. On write, if authorship is not all self-typed, an annotation trailer is appended (Markdown Annotations): a `---` block at EOF with `Annotations: 0,<graphemes> SHA-256 <hex>`, `@Self` / `&AI` / `*Reference` / `@Name` grapheme ranges, closed by `...`. The editor hides the trailer; preview and export use the body only. A hash mismatch (file edited elsewhere) drops authorship and treats the body as self-typed. `Info.plist` declares `net.daringfireball.markdown` and `public.plain-text` with `NSDocumentClass = Writer.Document` and `CFBundleTypeRole = Editor`. On launch with no documents, `applicationShouldOpenUntitledFile` returns true.

Authorship is a run-length map over UTF-16 units. Typing is `.selfTyped`. Paste (and drop) is `.ai` unless the clipboard carries Writer authorship, in which case those runs are preserved. `Paste as Mine` / `Paste as Reference` override the default. Marking a selection rewrites its runs. Typed characters that replace AI text become self-typed, so rewriting borrowed text makes it your own. When authorship is shown, self-typed text uses `theme.text`, AI words cycle a palette, other humans use muted tones, and reference text uses `dimmedText`. The stats bar prepends `You N%` (non-whitespace characters).

Window: 760 by 720 default, capped to the screen's visible area, frame autosaved as `EditorWindowFrame`; title bar shows document name, `titlebarAppearsTransparent`, full-size content view, background is the theme background, no toolbar.

## Verification

`make test` runs the pure-function tests. `make run` builds `build/Writer.app` and opens it. `make install` copies the bundle to `/Applications`. A screenshot of the running window is the acceptance artifact for anything visual: `scripts/screenshot.sh` finds the Writer window via `CGWindowListCopyWindowInfo` (a short Swift script) and calls `screencapture -l <id>`.

## Window

`EditorWindowController` owns an `NSSplitViewController` with three items: the library sidebar (collapsible, state in Preferences), the editor, and the preview (collapsed by default, per window). Preview (⌘R) widens the window to at least 1240 points and renders with `preview.css` from the bundle, so the bundled fonts load through relative `@font-face` URLs. Export PDF renders into an offscreen preview sized to A4 and calls `WKWebView.createPDF`.

## Later phases

Content blocks, a preferences window, an app icon.
