import XCTest
@testable import Writer

final class MarkdownRendererTests: XCTestCase {
    func testBody() {
        XCTAssertEqual(MarkdownRenderer.body(from: "# Hi\n\nSome **bold**."), "<h1>Hi</h1><p>Some <strong>bold</strong>.</p>")
    }

    func testDocumentEscapesTitleAndInlinesStylesheet() {
        let html = MarkdownRenderer.document(from: "x", title: "A <b> & C", stylesheet: .inline("body{}"))
        XCTAssertTrue(html.contains("<title>A &lt;b&gt; &amp; C</title>"))
        XCTAssertTrue(html.contains("<style>body{}</style>"))
        XCTAssertTrue(html.contains("<article>\n<p>x</p>\n</article>"))
    }
}
