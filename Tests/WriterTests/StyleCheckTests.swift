import XCTest
@testable import Writer

final class StyleCheckTests: XCTestCase {
    func testFillers() {
        let spans = StyleCheck.spans(in: "This is actually like a basically good idea.", kinds: [.filler])
        let words = set(spans, in: "This is actually like a basically good idea.")
        XCTAssertEqual(words, ["actually", "like", "basically"])
    }

    func testRedundancyPhrase() {
        let text = "The end result was an unexpected surprise."
        let words = set(StyleCheck.spans(in: text, kinds: [.redundancy]), in: text)
        XCTAssertEqual(words, ["end result", "unexpected surprise"])
    }

    func testCliche() {
        let text = "Think outside the box at the end of the day."
        let words = set(StyleCheck.spans(in: text, kinds: [.cliche]), in: text)
        XCTAssertEqual(words, ["Think outside the box", "at the end of the day"])
    }

    func testLongestMatchWins() {
        let text = "It was pretty much over."
        let words = set(StyleCheck.spans(in: text, kinds: [.filler]), in: text)
        XCTAssertEqual(words, ["pretty much"])
        XCTAssertFalse(words.contains("pretty"))
    }

    func testWordBoundaries() {
        let text = "Every very note."
        let words = set(StyleCheck.spans(in: text, kinds: [.filler]), in: text)
        XCTAssertEqual(words, ["very"])
        XCTAssertFalse(words.contains("Every"))
    }

    func testFiltering() {
        let text = "basically the end result, think outside the box"
        XCTAssertTrue(StyleCheck.spans(in: text, kinds: []).isEmpty)
        XCTAssertEqual(StyleCheck.spans(in: text, kinds: [.filler]).count, 1)
        XCTAssertEqual(StyleCheck.spans(in: text, kinds: [.redundancy]).count, 1)
        XCTAssertEqual(StyleCheck.spans(in: text, kinds: [.cliche]).count, 1)
    }

    func testCaseInsensitiveAndCurlyApostrophe() {
        let text = "To Be Honest, it\u{2019}s fine."
        let words = set(StyleCheck.spans(in: text, kinds: [.filler]), in: text)
        XCTAssertTrue(words.contains { $0.lowercased() == "to be honest" })
    }

    private func set(_ spans: [StyleSpan], in text: String) -> Set<String> {
        Set(spans.map { (text as NSString).substring(with: $0.range) })
    }
}
