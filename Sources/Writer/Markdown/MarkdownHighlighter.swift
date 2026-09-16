import AppKit

enum MarkdownStyle: Hashable {
    case heading(level: Int)
    case strong
    case emphasis
    case code
    case codeBlock
    case codeFence
    case quote
    case url
    case markup
}

struct Span: Hashable {
    let range: NSRange
    let style: MarkdownStyle
}

enum MarkdownHighlighter {
    private struct LineRule {
        let pattern: NSRegularExpression
        let line: MarkdownStyle?
        let markupGroups: [Int]
        let headingGroup: Int?
    }

    private struct InlineRule {
        let pattern: NSRegularExpression
        let content: (group: Int, style: MarkdownStyle)?
        let markupGroups: [Int]
    }

    private static let fence = regex(#"^[ \t]{0,3}(`{3,}|~{3,})(.*)$"#)

    private static let lineRules: [LineRule] = [
        LineRule(pattern: regex(#"^\s{0,3}(#{1,6})[ \t]+\S.*$"#), line: nil, markupGroups: [1], headingGroup: 1),
        LineRule(pattern: regex(#"^\s{0,3}(#{1,6})[ \t]*$"#), line: nil, markupGroups: [1], headingGroup: 1),
        LineRule(pattern: regex(#"^\s{0,3}([-*_])(?:[ \t]*\1){2,}[ \t]*$"#), line: .markup, markupGroups: [], headingGroup: nil),
        LineRule(pattern: regex(#"^\s*((?:>[ \t]?)+)"#), line: .quote, markupGroups: [1], headingGroup: nil),
        LineRule(pattern: regex(#"^\s*(?:>[ \t]?)*\s*([-*+]|\d{1,9}[.)])[ \t]+"#), line: nil, markupGroups: [1], headingGroup: nil),
    ]

    private static let inlineRules: [InlineRule] = [
        InlineRule(pattern: regex(#"(?<![*\w])(\*|_)(?=[^\s*_])(.+?)(?<=[^\s*_])(\1)(?![*\w])"#), content: (2, .emphasis), markupGroups: [1, 3]),
        InlineRule(pattern: regex(#"(\*\*|__)(?=\S)(.+?)(?<=\S)(\1)"#), content: (2, .strong), markupGroups: [1, 3]),
        InlineRule(pattern: regex(#"(\[)([^\]]*)(\]\()([^)]*)(\))"#), content: (4, .url), markupGroups: [1, 3, 5]),
        InlineRule(pattern: regex(#"(`+)(.+?)(\1)"#), content: (2, .code), markupGroups: [1, 3]),
    ]

    static func spans(in text: String) -> [Span] {
        let source = text as NSString
        var result: [Span] = []
        var openFence: (marker: Character, length: Int)?
        source.enumerateSubstrings(in: NSRange(location: 0, length: source.length), options: [.byLines, .substringNotRequired]) { _, lineRange, _, _ in
            if let match = fence.firstMatch(in: text, range: lineRange) {
                let marker = source.substring(with: match.range(at: 1))
                let suffix = source.substring(with: match.range(at: 2))
                if let opened = openFence {
                    if marker.first == opened.marker, marker.count >= opened.length,
                       suffix.trimmingCharacters(in: .whitespaces).isEmpty {
                        openFence = nil
                        result.append(Span(range: lineRange, style: .markup))
                        result.append(Span(range: lineRange, style: .codeFence))
                    } else {
                        result.append(Span(range: lineRange, style: .codeBlock))
                    }
                    return
                } else if marker.first != "`" || !suffix.contains("`") {
                    openFence = (marker.first!, marker.count)
                    result.append(Span(range: lineRange, style: .markup))
                    result.append(Span(range: lineRange, style: .codeFence))
                    return
                }
            }
            if openFence != nil {
                result.append(Span(range: lineRange, style: .codeBlock))
                return
            }
            result += lineSpans(in: text, range: lineRange)
        }
        return result
    }

    private static func lineSpans(in text: String, range lineRange: NSRange) -> [Span] {
        var result: [Span] = []
        var inlineOnly = true
        for rule in lineRules {
            guard let match = rule.pattern.firstMatch(in: text, range: lineRange) else { continue }
            if let style = rule.line {
                result.append(Span(range: lineRange, style: style))
                if style != .quote { inlineOnly = false }
            }
            if let group = rule.headingGroup {
                result.append(Span(range: lineRange, style: .heading(level: match.range(at: group).length)))
            }
            for group in rule.markupGroups {
                let markupRange = match.range(at: group)
                if markupRange.length > 0 { result.append(Span(range: markupRange, style: .markup)) }
            }
        }
        guard inlineOnly else { return result }
        // Code content is literal, including Markdown-looking delimiters inside it.
        var codeRanges: [NSRange] = []
        for rule in [inlineRules.last!] + inlineRules.dropLast() {
            for match in rule.pattern.matches(in: text, range: lineRange) {
                guard !codeRanges.contains(where: { NSIntersectionRange($0, match.range).length > 0 }) else { continue }
                if rule.content?.style == .code { codeRanges.append(match.range) }
                if let content = rule.content {
                    let contentRange = match.range(at: content.group)
                    if contentRange.length > 0 { result.append(Span(range: contentRange, style: content.style)) }
                }
                for group in rule.markupGroups {
                    let markupRange = match.range(at: group)
                    if markupRange.length > 0 { result.append(Span(range: markupRange, style: .markup)) }
                }
            }
        }
        return result
    }

    static func apply(_ spans: [Span], to storage: NSTextStorage, theme: Theme, in range: NSRange) {
        storage.setAttributes(theme.baseAttributes, range: range)
        for span in spans {
            let clipped = NSIntersectionRange(span.range, range)
            guard clipped.length > 0 else { continue }
            switch span.style {
            case .quote: break
            case .heading, .strong: embolden(storage, range: clipped, theme: theme)
            case .emphasis: italicize(storage, range: clipped, theme: theme)
            case .code, .codeBlock: storage.addAttribute(.font, value: theme.monoFont, range: clipped)
            case .url, .markup, .codeFence: storage.addAttribute(.foregroundColor, value: theme.markup, range: clipped)
            }
        }
    }

    private static func embolden(_ storage: NSTextStorage, range: NSRange, theme: Theme) {
        storage.enumerateAttribute(.font, in: range) { value, subrange, _ in
            let current = value as? NSFont
            let italic = current?.fontName == theme.italicFont.fontName || current?.fontName == theme.boldItalicFont.fontName
            storage.addAttribute(.font, value: italic ? theme.boldItalicFont : theme.boldFont, range: subrange)
        }
    }

    private static func italicize(_ storage: NSTextStorage, range: NSRange, theme: Theme) {
        storage.enumerateAttribute(.font, in: range) { value, subrange, _ in
            let current = value as? NSFont
            let bold = current?.fontName == theme.boldFont.fontName || current?.fontName == theme.boldItalicFont.fontName
            storage.addAttribute(.font, value: bold ? theme.boldItalicFont : theme.italicFont, range: subrange)
        }
    }

    private static func regex(_ pattern: String) -> NSRegularExpression {
        try! NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])
    }
}
