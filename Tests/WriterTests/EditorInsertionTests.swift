import XCTest
import AppKit
@testable import Writer

final class EditorInsertionTests: XCTestCase {
    func testTypingMidLineKeepsWordsOnOneLine() {
        let text = "The quick brown fox jumps over the lazy dog and keeps running through the field.\nSecond paragraph sits below."
        let editor = EditorViewController(text: text)
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 820, height: 600), styleMask: [.titled], backing: .buffered, defer: false)
        window.contentViewController = editor
        window.layoutIfNeeded()
        editor.view.layoutSubtreeIfNeeded()
        let tv = editor.textView
        let lm = tv.layoutManager!
        func fragments() -> Int {
            lm.ensureLayout(for: tv.textContainer!)
            var n = 0
            lm.enumerateLineFragments(forGlyphRange: NSRange(location: 0, length: lm.numberOfGlyphs)) { _, _, _, _, _ in n += 1 }
            return n
        }
        let before = fragments()
        tv.setSelectedRange(NSRange(location: 20, length: 0))
        for word in ["alpha", "beta", "gamma"] {
            for ch in word + " " {
                tv.insertText(String(ch), replacementRange: tv.selectedRange())
            }
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        }
        XCTAssertEqual(tv.selectedRange(), NSRange(location: 37, length: 0))
        XCTAssertEqual(tv.string, "The quick brown fox alpha beta gamma jumps over the lazy dog and keeps running through the field.\nSecond paragraph sits below.")
        XCTAssertEqual(fragments(), before)
    }
}
