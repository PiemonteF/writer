import AppKit
import XCTest
@testable import Writer

final class EditorLayoutTests: XCTestCase {
    private func withEditor(_ text: String, _ check: (EditorViewController, NSWindow) -> Void) {
        let prefs = Preferences.shared
        let live = prefs.livePreview, outline = prefs.showOutline
        prefs.livePreview = true
        prefs.showOutline = true
        defer { prefs.livePreview = live; prefs.showOutline = outline }
        let editor = EditorViewController(text: text)
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 760, height: 600),
                              styleMask: [.titled], backing: .buffered, defer: false)
        window.contentViewController = editor
        window.layoutIfNeeded()
        editor.view.layoutSubtreeIfNeeded()
        check(editor, window)
    }

    func testTreeButtonsReceiveClicksAndNavigate() {
        let text = "# First\n" + String(repeating: "Body paragraph.\n", count: 60) + "## Destination\n" + String(repeating: "More text.\n", count: 60)
        withEditor(text) { editor, window in
            let tree = editor.view.subviews.compactMap { $0 as? HeadingTree }.first!
            func buttons(_ view: NSView) -> [NSButton] {
                view.subviews.flatMap { ($0 as? NSButton).map { [$0] } ?? buttons($0) }
            }
            let button = buttons(tree).first { $0.tag == 1 }!
            let point = button.convert(NSPoint(x: button.bounds.midX, y: button.bounds.midY), to: window.contentView)
            let hit = window.contentView!.hitTest(point)
            XCTAssertTrue(hit === button, "Heading row must receive clicks instead of the editor: \(String(describing: hit))")
            button.performClick(nil)
            let range = (text as NSString).range(of: "## Destination")
            XCTAssertEqual(editor.textView.selectedRange().location, range.location)
            let lm = editor.textView.layoutManager!
            lm.ensureLayout(for: editor.textView.textContainer!)
            let rect = lm.lineFragmentRect(forGlyphAt: lm.glyphIndexForCharacter(at: range.location), effectiveRange: nil)
                .offsetBy(dx: editor.textView.textContainerOrigin.x, dy: editor.textView.textContainerOrigin.y)
            XCTAssertTrue(editor.textView.visibleRect.intersects(rect))
            XCTAssertEqual(rect.minY - editor.textView.visibleRect.minY, 12, accuracy: 2)
        }
    }

    func testCodeContainersHaveThinEditableFencesAndQuotesHaveOneBorder() {
        let text = "Before\n```swift\nlet x = 1\n\nprint(x)\n```\n> One\n> Two\nAfter"
        withEditor(text) { editor, _ in
            let tv = editor.textView
            let lm = tv.layoutManager as! MarkdownLayoutManager
            tv.setSelectedRange(NSRange(location: (text as NSString).length, length: 0))
            lm.ensureLayout(for: tv.textContainer!)
            XCTAssertEqual(lm.codeBlockRanges.count, 1)
            XCTAssertEqual(lm.quoteRanges.count, 1)
            XCTAssertEqual(tv.renderedFences.count, 2)
            for range in tv.renderedFences {
                let rect = lm.lineFragmentRect(forGlyphAt: lm.glyphIndexForCharacter(at: range.location), effectiveRange: nil)
                XCTAssertGreaterThan(rect.height, 0)
                XCTAssertLessThanOrEqual(rect.height, 6)
            }
            let closing = tv.renderedFences.last!
            tv.setSelectedRange(NSRange(location: NSMaxRange(closing), length: 0))
            lm.ensureLayout(for: tv.textContainer!)
            XCTAssertNil(tv.textStorage?.attribute(.hiddenMarkdown, at: closing.location, effectiveRange: nil))
            tv.deleteBackward(nil)
            XCTAssertEqual(tv.string, (text as NSString).replacingCharacters(in: closing, with: ""))
        }
    }

    func testHitTestingMatchesRenderedLines() {
        let text = "Plain first [link](https://example.com/" + String(repeating: "path/", count: 80) + ")\n# Heading\nPlain next line\n## Second heading\nAnother plain line\n```swift\nlet x = 1\n```\nEnd"
        withEditor(text) { editor, window in
            let tv = editor.textView
            let lm = tv.layoutManager!
            let source = text as NSString
            tv.setSelectedRange(NSRange(location: source.length, length: 0))
            for label in ["Plain first", "Heading", "Plain next", "Second heading", "Another plain", "let x", "End"] {
                lm.ensureLayout(for: tv.textContainer!)
                let range = source.range(of: label)
                let glyph = lm.glyphIndexForCharacter(at: range.location)
                let line = lm.lineFragmentRect(forGlyphAt: glyph, effectiveRange: nil)
                let position = lm.location(forGlyphAt: glyph)
                let point = NSPoint(x: tv.textContainerOrigin.x + position.x + 2, y: tv.textContainerOrigin.y + line.midY)
                let index = tv.characterIndexForInsertion(at: point)
                XCTAssertEqual(source.lineRange(for: NSRange(location: index, length: 0)).location,
                               source.lineRange(for: range).location, "Click on \(label) hit character \(index)")
                let location = tv.convert(point, to: nil)
                let up = NSEvent.mouseEvent(with: .leftMouseUp, location: location, modifierFlags: [], timestamp: 0,
                    windowNumber: window.windowNumber, context: nil, eventNumber: 1, clickCount: 1, pressure: 0)!
                let down = NSEvent.mouseEvent(with: .leftMouseDown, location: location, modifierFlags: [], timestamp: 0,
                    windowNumber: window.windowNumber, context: nil, eventNumber: 0, clickCount: 1, pressure: 1)!
                NSApp.postEvent(up, atStart: true)
                tv.mouseDown(with: down)
                XCTAssertEqual(source.lineRange(for: tv.selectedRange()).location,
                               source.lineRange(for: range).location, "Mouse selection moved away from \(label)")
            }
        }
    }
}
