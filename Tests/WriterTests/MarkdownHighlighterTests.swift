import XCTest
@testable import Writer

final class MarkdownHighlighterTests: XCTestCase {
    private func spans(_ text: String) -> Set<Span> { Set(MarkdownHighlighter.spans(in: text)) }

    func testHeading() {
        let result = spans("## Title")
        XCTAssertTrue(result.contains(Span(range: NSRange(location: 0, length: 8), style: .heading(level: 2))))
        XCTAssertTrue(result.contains(Span(range: NSRange(location: 0, length: 2), style: .markup)))
    }

    func testStrong() {
        let result = spans("a **bold** b")
        XCTAssertTrue(result.contains(Span(range: NSRange(location: 4, length: 4), style: .strong)))
        XCTAssertTrue(result.contains(Span(range: NSRange(location: 2, length: 2), style: .markup)))
        XCTAssertTrue(result.contains(Span(range: NSRange(location: 8, length: 2), style: .markup)))
        XCTAssertFalse(result.contains { $0.style == .emphasis })
    }

    func testEmphasis() {
        let result = spans("_em_ and *it*")
        XCTAssertTrue(result.contains(Span(range: NSRange(location: 1, length: 2), style: .emphasis)))
        XCTAssertTrue(result.contains(Span(range: NSRange(location: 10, length: 2), style: .emphasis)))
        XCTAssertFalse(spans("snake_case_name").contains { $0.style == .emphasis })
    }

    func testInlineCode() {
        let result = spans("use `x` here")
        XCTAssertTrue(result.contains(Span(range: NSRange(location: 5, length: 1), style: .code)))
        XCTAssertTrue(result.contains(Span(range: NSRange(location: 4, length: 1), style: .markup)))
    }

    func testFencedCode() {
        let result = spans("```\n**not bold**\n```\n**bold**")
        XCTAssertTrue(result.contains(Span(range: NSRange(location: 4, length: 12), style: .codeBlock)))
        XCTAssertTrue(result.contains(Span(range: NSRange(location: 0, length: 3), style: .markup)))
        XCTAssertFalse(result.contains(Span(range: NSRange(location: 6, length: 8), style: .strong)))
        XCTAssertTrue(result.contains(Span(range: NSRange(location: 23, length: 4), style: .strong)))
    }

    func testLink() {
        let result = spans("[iA](https://ia.net)")
        XCTAssertTrue(result.contains(Span(range: NSRange(location: 5, length: 14), style: .url)))
        XCTAssertTrue(result.contains(Span(range: NSRange(location: 0, length: 1), style: .markup)))
        XCTAssertTrue(result.contains(Span(range: NSRange(location: 3, length: 2), style: .markup)))
        XCTAssertTrue(result.contains(Span(range: NSRange(location: 19, length: 1), style: .markup)))
    }

    func testListAndQuoteMarkers() {
        XCTAssertTrue(spans("- item").contains(Span(range: NSRange(location: 0, length: 1), style: .markup)))
        XCTAssertTrue(spans("12. item").contains(Span(range: NSRange(location: 0, length: 3), style: .markup)))
        XCTAssertTrue(spans("> quote").contains(Span(range: NSRange(location: 0, length: 2), style: .markup)))
    }

    func testHorizontalRule() {
        XCTAssertTrue(spans("---").contains(Span(range: NSRange(location: 0, length: 3), style: .markup)))
        XCTAssertFalse(spans("---").contains { $0.style == .emphasis })
    }

    func testInlineInsideHeading() {
        XCTAssertTrue(spans("# A **b**").contains(Span(range: NSRange(location: 6, length: 1), style: .strong)))
    }
}
