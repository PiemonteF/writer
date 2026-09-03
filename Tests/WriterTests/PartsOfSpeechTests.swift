import XCTest
@testable import Writer

final class PartsOfSpeechTests: XCTestCase {
    let text = "The quick brown fox jumps over the lazy dog and sleeps."

    private func words(_ part: PartOfSpeech, parts: Set<PartOfSpeech> = Set(PartOfSpeech.allCases)) -> Set<String> {
        Set(PartsOfSpeech.spans(in: text, parts: parts).filter { $0.part == part }.map { (text as NSString).substring(with: $0.range) })
    }

    func testTagging() {
        XCTAssertTrue(words(.noun).isSuperset(of: ["fox", "dog"]))
        XCTAssertTrue(words(.verb).contains("jumps"))
        XCTAssertTrue(words(.adjective).isSuperset(of: ["quick", "brown", "lazy"]))
        XCTAssertEqual(words(.conjunction), ["and"])
    }

    func testFiltering() {
        XCTAssertTrue(PartsOfSpeech.spans(in: text, parts: []).isEmpty)
        XCTAssertTrue(PartsOfSpeech.spans(in: text, parts: [.noun]).allSatisfy { $0.part == .noun })
        XCTAssertFalse(words(.noun, parts: [.noun]).isEmpty)
    }
}
