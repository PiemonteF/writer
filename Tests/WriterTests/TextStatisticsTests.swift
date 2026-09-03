import XCTest
@testable import Writer

final class TextStatisticsTests: XCTestCase {
    func testCounts() {
        let stats = TextStatistics.compute("Hello world. Second one here.\n\nNext paragraph.")
        XCTAssertEqual(stats.words, 7)
        XCTAssertEqual(stats.sentences, 3)
        XCTAssertEqual(stats.paragraphs, 2)
        XCTAssertEqual(stats.readingMinutes, 1)
    }

    func testEmpty() {
        let stats = TextStatistics.compute("")
        XCTAssertEqual(stats, TextStatistics(words: 0, characters: 0, sentences: 0, paragraphs: 0))
        XCTAssertEqual(stats.readingMinutes, 0)
        XCTAssertEqual(stats.summary, "0 words · 0 min")
    }

    func testReadingTimeRoundsUp() {
        let words = Array(repeating: "word", count: 276).joined(separator: " ")
        XCTAssertEqual(TextStatistics.compute(words).readingMinutes, 2)
    }
}
