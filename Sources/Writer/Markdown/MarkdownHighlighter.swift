import AppKit

enum MarkdownStyle: Hashable {
    case heading(level: Int)
    case strong
    case emphasis
    case code
    case codeBlock
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

    private static let fence = regex(#"^\s{0,3}(```|~~~)"#)

    private static let lineRules: [LineRule] = [
        LineRule(pattern: regex(#"^\s{0,3}(#{1,6})[ \t]+\S.*$"#), line: nil, markupGroups: [1], headingGroup: 1),
        LineRule(pattern: regex(#"^\s{0,3}(#{1,6})[ \t]*$"#), line: nil, markupGroups: [1], headingGroup: 1),
        LineRule(pattern: regex(#"^\s{0,3}([-*_])(?:[ \t]*\1){2,}[ \t]*$"#), line: .markup, markupGroups: [], headingGroup: nil),
        LineRule(pattern: regex(#"^\s*((?:>[ \t]?)+)"#), line: nil, markupGroups: [1], headingGroup: nil),
        LineRule(pattern: regex(#"^\s*(?:>[ \t]?)*\s*([-*+]|\d{1,9}[.)])[ \t]+"#), line: nil, markupGroups: [1], headingGroup: nil),
    ]

    private static let inlineRules: [InlineRule] = [
        InlineRule(pattern: regex(#"(?<![*\w])(\*|_)(?=\S)(.+?)(?<=\S)(\1)(?![*\w])"#), content: (2, .emphasis), markupGroups: [1, 3]),
        InlineRule(pattern: regex(#"(\*\*|__)(?=\S)(.+?)(?<=\S)(\1)"#), content: (2, .strong), markupGroups: [1, 3]),
        InlineRule(pattern: regex(#"(\[)([^\]]*)(\]\()([^)]*)(\))"#), content: (4, .url), markupGroups: [1, 3, 5]),
        InlineRule(pattern: regex(#"(`+)(.+?)(\1)"#), content: (2, .code), markupGroups: [1, 3]),
    ]

    static func spans(in text: String) -> [Span] {
        let source = text as NSString
        var result: [Span] = []
        var inFence = false
        source.enumerateSubstrings(in: NSRange(location: 0, length: source.length), options: [.byLines, .substringNotRequired]) { _, lineRange, _, _ in
            if fence.firstMatch(in: text, range: lineRange) != nil {
                inFence.toggle()
                result.append(Span(range: lineRange, style: .markup))
                return
            }
            if inFence {
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
                inlineOnly = false
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
        for rule in inlineRules {
            for match in rule.pattern.matches(in: text, range: lineRange) {
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
            case .heading: addTrait(.boldFontMask, to: storage, range: clipped)
            case .strong: addTrait(.boldFontMask, to: storage, range: clipped)
            case .emphasis: addTrait(.italicFontMask, to: storage, range: clipped)
            case .code, .codeBlock: storage.addAttribute(.font, value: theme.monoFont, range: clipped)
            case .url, .markup: storage.addAttribute(.foregroundColor, value: theme.markup, range: clipped)
            }
        }
    }

    private static func addTrait(_ trait: NSFontTraitMask, to storage: NSTextStorage, range: NSRange) {
        storage.enumerateAttribute(.font, in: range) { value, subrange, _ in
            guard let font = value as? NSFont else { return }
            storage.addAttribute(.font, value: NSFontManager.shared.convert(font, toHaveTrait: trait), range: subrange)
        }
    }

    private static func regex(_ pattern: String) -> NSRegularExpression {
        try! NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])
    }
}
