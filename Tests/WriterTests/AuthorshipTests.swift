import XCTest
@testable import Writer

final class AuthorshipTests: XCTestCase {
    func testSelfTypedEmpty() {
        let empty = Authorship.selfTyped(length: 0)
        XCTAssertEqual(empty.length, 0)
        XCTAssertTrue(empty.isTrivial)
        XCTAssertTrue(empty.spans().isEmpty)
    }

    func testInsertSplitsAndCoalesces() {
        var auth = Authorship.selfTyped(length: 10)
        auth.replace(location: 3, oldLength: 0, newLength: 4, with: .ai)
        XCTAssertEqual(auth.length, 14)
        XCTAssertEqual(authors(auth), [.selfTyped, .ai, .selfTyped])
        XCTAssertEqual(auth.runs.map(\.length), [3, 4, 7])
        auth.replace(location: 3, oldLength: 4, newLength: 2, with: .selfTyped)
        XCTAssertEqual(authors(auth), [.selfTyped])
        XCTAssertEqual(auth.runs.map(\.length), [12])
        XCTAssertTrue(auth.isTrivial)
    }

    func testDeleteAcrossRuns() {
        var auth = Authorship.selfTyped(length: 6)
        auth.mark(NSRange(location: 2, length: 2), as: .ai)
        auth.delete(1, 4)
        XCTAssertEqual(authors(auth), [.selfTyped])
        XCTAssertEqual(auth.runs.map(\.length), [2])
    }

    func testTypingOverAIMakesItYours() {
        var auth = Authorship.selfTyped(length: 0)
        auth.insert(0, 20, .ai)
        auth.replace(location: 5, oldLength: 3, newLength: 3, with: .selfTyped)
        XCTAssertEqual(authors(auth), [.ai, .selfTyped, .ai])
        XCTAssertEqual(auth.runs.map(\.length), [5, 3, 12])
    }

    func testMarkAndSlice() {
        var auth = Authorship.selfTyped(length: 9)
        auth.mark(NSRange(location: 3, length: 3), as: .reference)
        XCTAssertEqual(auth.slice(NSRange(location: 2, length: 5)).runs.map(\.author), [.selfTyped, .reference, .selfTyped])
        XCTAssertEqual(auth.slice(NSRange(location: 2, length: 5)).runs.map(\.length), [1, 3, 1])
    }

    func testSplicePreservesAuthors() {
        var host = Authorship.selfTyped(length: 4)
        var piece = Authorship.selfTyped(length: 0)
        piece.insert(0, 2, .ai)
        piece.insert(2, 1, .selfTyped)
        host.replace(location: 2, oldLength: 0, newLength: 0, with: .selfTyped)
        host.splice(piece, at: 2)
        XCTAssertEqual(authors(host), [.selfTyped, .ai, .selfTyped])
        XCTAssertEqual(host.runs.map(\.length), [2, 2, 3])
    }

    func testOwnedRatioIgnoresWhitespace() {
        var auth = Authorship.selfTyped(length: 5)
        let text = "ab cd" as NSString
        auth.mark(NSRange(location: 0, length: 2), as: .ai)
        XCTAssertEqual(auth.ownedRatio(in: text), 0.5)
        XCTAssertEqual(Authorship.selfTyped(length: 0).ownedRatio(in: "" as NSString), 1)
    }

    func testRoundTripASCII() {
        let body = "Hello world, this is mine."
        var auth = Authorship.selfTyped(length: (body as NSString).length)
        auth.mark(NSRange(location: 6, length: 5), as: .ai)
        auth.mark(NSRange(location: 21, length: 4), as: .reference)
        let file = AnnotationBlock.render(body: body, authorship: auth)
        let parsed = AnnotationBlock.parse(file)
        XCTAssertEqual(parsed.body, body)
        XCTAssertEqual(parsed.authorship, auth)
        XCTAssertTrue(file.contains("SHA-256"))
        XCTAssertTrue(file.hasSuffix("...\n"))
    }

    func testTrivialOmitsTrailer() {
        XCTAssertEqual(AnnotationBlock.render(body: "Just me.", authorship: .selfTyped(length: 8)), "Just me.")
    }

    func testRoundTripTrailingNewline() {
        let body = "Hello world.\n"
        var auth = Authorship.selfTyped(length: (body as NSString).length)
        auth.mark(NSRange(location: 6, length: 5), as: .ai)
        let parsed = AnnotationBlock.parse(AnnotationBlock.render(body: body, authorship: auth))
        XCTAssertEqual(parsed.body, body)
        XCTAssertEqual(parsed.authorship, auth)
    }

    func testHashMismatchDropsAuthorship() {
        let body = "Hello"
        var auth = Authorship.selfTyped(length: 5)
        auth.mark(NSRange(location: 0, length: 5), as: .ai)
        var file = AnnotationBlock.render(body: body, authorship: auth)
        file = file.replacingOccurrences(of: "Hello", with: "Helix")
        let parsed = AnnotationBlock.parse(file)
        XCTAssertEqual(parsed.body, "Helix")
        XCTAssertTrue(parsed.authorship.isTrivial)
    }

    func testGraphemeEmojiRoundTrip() {
        let body = "Hi 👋 there"
        var auth = Authorship.selfTyped(length: (body as NSString).length)
        let wave = (body as NSString).range(of: "👋")
        auth.mark(wave, as: .ai)
        let parsed = AnnotationBlock.parse(AnnotationBlock.render(body: body, authorship: auth))
        XCTAssertEqual(parsed.body, body)
        XCTAssertEqual(parsed.authorship, auth)
    }

    func testBodyContainingDashes() {
        let body = "Section\n---\nStill body"
        var auth = Authorship.selfTyped(length: (body as NSString).length)
        auth.mark(NSRange(location: 0, length: 7), as: .ai)
        let parsed = AnnotationBlock.parse(AnnotationBlock.render(body: body, authorship: auth))
        XCTAssertEqual(parsed.body, body)
        XCTAssertEqual(parsed.authorship, auth)
    }

    func testParsePlainFile() {
        let parsed = AnnotationBlock.parse("No trailer at all.")
        XCTAssertEqual(parsed.body, "No trailer at all.")
        XCTAssertTrue(parsed.authorship.isTrivial)
    }

    func testAuthorKeys() {
        XCTAssertEqual(Author.parse(key: "@Self"), .selfTyped)
        XCTAssertEqual(Author.parse(key: "@Jane"), .human("Jane"))
        XCTAssertEqual(Author.parse(key: "&Claude"), .ai)
        XCTAssertEqual(Author.parse(key: "*Reference"), .reference)
        XCTAssertEqual(Author.ai.annotationKey, "&AI")
    }

    private func authors(_ auth: Authorship) -> [Author] {
        auth.runs.map(\.author)
    }
}
