import XCTest
import AppKit
@testable import Writer

final class LiveMarkdownTests: XCTestCase {
    func testSystemFontSelectionAndBundledFontReset() {
        let prefs = Preferences.shared
        let previousFamily = prefs.systemFont
        let previousFont = prefs.font
        defer { prefs.font = previousFont; prefs.systemFont = previousFamily }
        let delegate = AppDelegate()
        let item = NSMenuItem()
        item.representedObject = "Helvetica"
        delegate.setSystemFont(item)
        XCTAssertEqual(prefs.systemFont, "Helvetica")
        XCTAssertEqual(Theme.make(prefs, dark: false).font.familyName, "Helvetica")
        item.representedObject = EditorFont.mono
        delegate.setEditorFont(item)
        XCTAssertNil(prefs.systemFont)
        XCTAssertEqual(prefs.font, .mono)
    }

    func testTreeUsesUTF16OffsetsAndIgnoresFencedHeadings() {
        let text = "🙂\n# One\n## Two ##\n### Three\n#### Four\n````swift\n# Hidden\n```\n## Still hidden\n````\n# Last"
        let headings = MarkdownHeading.headings(in: text, spans: MarkdownHighlighter.spans(in: text))
        XCTAssertEqual(headings.map(\.title), ["One", "Two", "Three", "Last"])
        XCTAssertEqual(headings.map(\.level), [1, 2, 3, 1])
        XCTAssertEqual(headings.first?.range.location, 3)
    }

    func testRulesDeleteInOneOperationIncludingFollowingNewline() {
        for rule in ["---", "***", "_ _ _", "  - - -"] {
            let text = "🙂\n" + rule + "\nNext"
            let rules = LiveMarkdown.rules(in: text, spans: MarkdownHighlighter.spans(in: text))
            XCTAssertEqual(rules.count, 1)
            let end = 3 + (rule as NSString).length
            XCTAssertEqual(LiveMarkdown.ruleToDelete(in: text, selection: NSRange(location: end, length: 0), rules: rules), rules.first)
            XCTAssertEqual(LiveMarkdown.ruleToDelete(in: text, selection: NSRange(location: end + 1, length: 0), rules: rules), NSRange(location: 3, length: end - 2))
            XCTAssertNil(LiveMarkdown.ruleToDelete(in: text, selection: NSRange(location: end + 2, length: 0), rules: rules))
            XCTAssertNil(LiveMarkdown.ruleToDelete(in: text, selection: NSRange(location: end, length: 1), rules: rules))
        }
        let code = "```\n---\n```"
        XCTAssertTrue(LiveMarkdown.rules(in: code, spans: MarkdownHighlighter.spans(in: code)).isEmpty)
    }

    func testPresentationPreservesSourceAndRevealsActiveParagraph() {
        let text = "# Heading\n**bold** and [link](https://example.com)\n---\nEdit"
        let storage = NSTextStorage(string: text)
        let spans = MarkdownHighlighter.spans(in: text)
        let theme = Theme.make(.shared, dark: false)
        let all = NSRange(location: 0, length: storage.length)
        MarkdownHighlighter.apply(spans, to: storage, theme: theme, in: all)
        LiveMarkdown.apply(to: storage, spans: spans, selection: NSRange(location: storage.length, length: 0), theme: theme)
        XCTAssertEqual(storage.string, text)
        XCTAssertEqual(storage.attribute(.hiddenMarkdown, at: 0, effectiveRange: nil) as? Bool, true)
        XCTAssertGreaterThan((storage.attribute(.font, at: 2, effectiveRange: nil) as! NSFont).pointSize, theme.font.pointSize)
        MarkdownHighlighter.apply(spans, to: storage, theme: theme, in: all)
        LiveMarkdown.apply(to: storage, spans: spans, selection: NSRange(location: 0, length: 0), theme: theme)
        XCTAssertNil(storage.attribute(.hiddenMarkdown, at: 0, effectiveRange: nil))
    }

    func testLiteralCodeAndListPresentation() {
        let code = "`**literal** [link](url)`"
        let spans = MarkdownHighlighter.spans(in: code)
        XCTAssertFalse(spans.contains { $0.style == .strong || $0.style == .url })
        let prefs = Preferences.shared
        let previous = prefs.livePreview
        prefs.livePreview = true
        defer { prefs.livePreview = previous }
        let editor = EditorViewController(text: "# Title\n- item\n> quote\nDone")
        _ = editor.view
        editor.textView.setSelectedRange(NSRange(location: 27, length: 0))
        XCTAssertEqual(editor.textView.textStorage?.attribute(.markdownReplacement, at: 8, effectiveRange: nil) as? String, "•")
        XCTAssertEqual(editor.textView.textStorage?.attribute(.hiddenMarkdown, at: 15, effectiveRange: nil) as? Bool, true)
        XCTAssertEqual((editor.textView.layoutManager as? MarkdownLayoutManager)?.quoteRanges.count, 1)
    }

    func testLiveEditingAndRuleUndoKeepMarkdownAndAuthorship() {
        let prefs = Preferences.shared
        let previous = prefs.livePreview
        prefs.livePreview = true
        defer { prefs.livePreview = previous }
        let document = Document()
        let controller = EditorWindowController(document: document)
        document.addWindowController(controller)
        let editor = controller.editor
        _ = editor.view
        editor.load("# Heading\n---\nText")
        let tv = editor.textView
        tv.setSelectedRange(NSRange(location: 14, length: 0))
        document.undoManager?.beginUndoGrouping()
        tv.deleteBackward(nil)
        document.undoManager?.endUndoGrouping()
        XCTAssertEqual(tv.string, "# Heading\nText")
        XCTAssertEqual(editor.authorship.length, (tv.string as NSString).length)
        document.undoManager?.undo()
        XCTAssertEqual(tv.string, "# Heading\n---\nText")
        XCTAssertEqual(editor.authorship.length, (tv.string as NSString).length)
        tv.setSelectedRange(NSRange(location: (tv.string as NSString).length, length: 0))
        tv.insertText("!", replacementRange: tv.selectedRange())
        XCTAssertTrue(tv.string.hasSuffix("Text!"))
        prefs.livePreview = false
        XCTAssertTrue(tv.renderedRules.isEmpty)
        XCTAssertNil(tv.textStorage?.attribute(.hiddenMarkdown, at: 0, effectiveRange: nil))
    }
}
