import XCTest
@testable import Writer

final class FocusRangeTests: XCTestCase {
    let text = "One two. Three four. Five.\nSecond paragraph." as NSString

    func testOff() {
        XCTAssertNil(FocusRange.range(mode: .off, caret: 3, in: text))
    }

    func testSentenceContainingCaret() {
        XCTAssertEqual(FocusRange.range(mode: .sentence, caret: 11, in: text), NSRange(location: 9, length: 12))
    }

    func testSentenceAtStartAndEnd() {
        XCTAssertEqual(FocusRange.range(mode: .sentence, caret: 0, in: text), NSRange(location: 0, length: 9))
        XCTAssertEqual(FocusRange.range(mode: .sentence, caret: text.length, in: text), NSRange(location: 27, length: 17))
    }

    func testParagraph() {
        XCTAssertEqual(FocusRange.range(mode: .paragraph, caret: 30, in: text), NSRange(location: 27, length: 17))
        XCTAssertEqual(FocusRange.range(mode: .paragraph, caret: 2, in: text), NSRange(location: 0, length: 27))
    }
}
