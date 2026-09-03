import Foundation
import Ink

enum MarkdownRenderer {
    static func body(from markdown: String) -> String {
        MarkdownParser().html(from: markdown)
    }

    static func document(from markdown: String, title: String, stylesheet: Stylesheet) -> String {
        let head: String
        switch stylesheet {
        case .linked(let href): head = "<link rel=\"stylesheet\" href=\"\(href)\">"
        case .inline(let css): head = "<style>\(css)</style>"
        }
        return """
        <!doctype html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>\(escape(title))</title>
        \(head)
        </head>
        <body><article>
        \(body(from: markdown))
        </article></body>
        </html>
        """
    }

    enum Stylesheet {
        case linked(String)
        case inline(String)
    }

    static func escape(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}
