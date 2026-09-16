import AppKit

extension NSAttributedString.Key {
    static let markdownReplacement = NSAttributedString.Key("WriterMarkdownReplacement")
    static let hiddenMarkdown = NSAttributedString.Key("WriterHiddenMarkdown")
}

/// Presentation only: the text storage, clipboard and document keep the Markdown source.
enum LiveMarkdown {
    static func codeBlocks(in text: String, spans: [Span]) -> [NSRange] {
        var start: Int?
        var blocks: [NSRange] = []
        for span in spans where span.style == .codeFence {
            if let opening = start {
                blocks.append(NSRange(location: opening, length: NSMaxRange(span.range) - opening))
                start = nil
            } else {
                start = span.range.location
            }
        }
        if let start { blocks.append(NSRange(location: start, length: (text as NSString).length - start)) }
        return blocks
    }

    static func rules(in text: String, spans: [Span]) -> [NSRange] {
        let source = text as NSString
        return spans.compactMap { span in
            guard span.style == .markup else { return nil }
            let line = source.substring(with: span.range)
            let characters = line.filter { !$0.isWhitespace }
            guard characters.count >= 3, let first = characters.first,
                  "-*_".contains(first), characters.allSatisfy({ $0 == first }) else { return nil }
            return span.range
        }
    }

    static func ruleToDelete(in text: String, selection: NSRange, rules: [NSRange]) -> NSRange? {
        guard selection.length == 0, selection.location > 0 else { return nil }
        let source = text as NSString
        return rules.first { range in
            let end = NSMaxRange(range)
            if selection.location > range.location && selection.location <= end { return true }
            guard selection.location > end else { return false }
            let gap = source.substring(with: NSRange(location: end, length: selection.location - end))
            return gap == "\n" || gap == "\r\n" || gap == "\r"
        }.map { NSRange(location: $0.location, length: selection.location > NSMaxRange($0) ? selection.location - $0.location : $0.length) }
    }

    static func marker(in text: String, range: NSRange) -> String? {
        let source = text as NSString
        let paragraph = source.paragraphRange(for: range)
        let before = source.substring(with: NSRange(location: paragraph.location, length: range.location - paragraph.location))
        guard before.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        let token = source.substring(with: range).trimmingCharacters(in: .whitespaces)
        if ["-", "*", "+"].contains(token) { return "•" }
        if token.first?.isNumber == true { return token }
        return nil
    }

    static func apply(to storage: NSTextStorage, spans: [Span], selection: NSRange, theme: Theme) {
        let source = storage.string as NSString
        let active = source.paragraphRange(for: selection)
        let rules = rules(in: storage.string, spans: spans)
        for span in spans {
            switch span.style {
            case .quote:
                let paragraph = theme.paragraphStyle.mutableCopy() as! NSMutableParagraphStyle
                paragraph.firstLineHeadIndent = 16
                paragraph.headIndent = 16
                storage.addAttributes([.paragraphStyle: paragraph, .foregroundColor: NSColor.secondaryLabelColor],
                                      range: source.lineRange(for: span.range))
            case .heading(let level):
                storage.addAttribute(.font, value: NSFontManager.shared.convert(theme.boldFont,
                    toSize: theme.font.pointSize * (level == 1 ? 1.8 : level == 2 ? 1.45 : 1.2)), range: span.range)
            case .code:
                storage.addAttribute(.backgroundColor, value: theme.markup.withAlphaComponent(0.1), range: span.range)
            case .codeBlock:
                let paragraph = theme.paragraphStyle.mutableCopy() as! NSMutableParagraphStyle
                paragraph.firstLineHeadIndent = 12
                paragraph.headIndent = 12
                paragraph.tailIndent = -12
                storage.addAttribute(.paragraphStyle, value: paragraph, range: source.lineRange(for: span.range))
            case .codeFence:
                let line = source.lineRange(for: span.range)
                let editing = NSIntersectionRange(active, line).length > 0
                let paragraph = NSMutableParagraphStyle()
                paragraph.minimumLineHeight = editing ? 18 : 6
                paragraph.maximumLineHeight = editing ? 18 : 6
                paragraph.firstLineHeadIndent = 12
                paragraph.headIndent = 12
                storage.addAttributes([
                    .font: NSFontManager.shared.convert(theme.monoFont, toSize: editing ? 11 : 3),
                    .paragraphStyle: paragraph,
                ], range: line)
            case .markup:
                if marker(in: storage.string, range: span.range)?.first?.isNumber == true { continue }
                if rules.contains(span.range) || NSIntersectionRange(active, span.range).length == 0 {
                    storage.addAttribute(.hiddenMarkdown, value: true, range: span.range)
                    if let marker = marker(in: storage.string, range: span.range) {
                        let first = NSRange(location: span.range.location, length: 1)
                        storage.removeAttribute(.hiddenMarkdown, range: first)
                        storage.addAttribute(.markdownReplacement, value: marker, range: first)
                    }
                }
            default: break
            }
        }
        // Hide link destinations along with the closing syntax, while keeping labels editable.
        let links = try! NSRegularExpression(pattern: #"\[([^\]\n]+)\](\([^\)\n]*\))"#)
        for match in links.matches(in: storage.string, range: NSRange(location: 0, length: source.length))
            where NSIntersectionRange(active, match.range).length == 0
                && !spans.contains(where: { ($0.style == .code || $0.style == .codeBlock) && NSIntersectionRange($0.range, match.range).length > 0 }) {
            storage.addAttribute(.hiddenMarkdown, value: true, range: match.range(at: 2))
            storage.addAttribute(.foregroundColor, value: theme.accent, range: match.range(at: 1))
        }
    }
}

final class MarkdownLayoutManager: NSLayoutManager, NSLayoutManagerDelegate {
    var codeBlockRanges: [NSRange] = []
    var quoteRanges: [NSRange] = []

    override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: NSPoint) {
        if let textContainer = textContainers.first {
            for range in codeBlockRanges {
                let glyphs = glyphRange(forCharacterRange: range, actualCharacterRange: nil)
                guard NSIntersectionRange(glyphs, glyphsToShow).length > 0 else { continue }
                var block = NSRect.null
                enumerateLineFragments(forGlyphRange: glyphs) { rect, _, _, _, _ in
                    block = block.union(rect)
                }
                guard !block.isNull else { continue }
                block.origin.x = 0
                block.size.width = textContainer.size.width
                let path = NSBezierPath(roundedRect: block.offsetBy(dx: origin.x, dy: origin.y).insetBy(dx: 0.5, dy: 0.5),
                                        xRadius: 7, yRadius: 7)
                NSColor.quaternaryLabelColor.withAlphaComponent(0.06).setFill()
                path.fill()
                NSColor.separatorColor.setStroke()
                path.stroke()
            }
        }
        for range in quoteRanges {
            let glyphs = glyphRange(forCharacterRange: range, actualCharacterRange: nil)
            guard NSIntersectionRange(glyphs, glyphsToShow).length > 0 else { continue }
            var block = NSRect.null
            enumerateLineFragments(forGlyphRange: glyphs) { rect, _, _, _, _ in block = block.union(rect) }
            guard !block.isNull else { continue }
            let bar = NSRect(x: origin.x, y: origin.y + block.minY + 2, width: 3, height: max(0, block.height - 4))
            NSColor.tertiaryLabelColor.setFill()
            NSBezierPath(roundedRect: bar, xRadius: 1.5, yRadius: 1.5).fill()
        }
        super.drawBackground(forGlyphRange: glyphsToShow, at: origin)
    }

    override init() {
        super.init()
        delegate = self
    }

    required init?(coder: NSCoder) { fatalError("not supported") }

    func layoutManager(_ layoutManager: NSLayoutManager, shouldUse action: NSLayoutManager.ControlCharacterAction,
                       forControlCharacterAt charIndex: Int) -> NSLayoutManager.ControlCharacterAction {
        if textStorage?.attribute(.hiddenMarkdown, at: charIndex, effectiveRange: nil) as? Bool == true {
            return .zeroAdvancement
        }
        return action
    }

    func layoutManager(_ layoutManager: NSLayoutManager, shouldGenerateGlyphs glyphs: UnsafePointer<CGGlyph>,
                       properties props: UnsafePointer<NSLayoutManager.GlyphProperty>,
                       characterIndexes: UnsafePointer<Int>, font: NSFont, forGlyphRange glyphRange: NSRange) -> Int {
        guard let textStorage else { return 0 }
        var replacementGlyphs = Array(UnsafeBufferPointer(start: glyphs, count: glyphRange.length))
        var properties = Array(UnsafeBufferPointer(start: props, count: glyphRange.length))
        for index in properties.indices {
            if let marker = textStorage.attribute(.markdownReplacement, at: characterIndexes[index], effectiveRange: nil) as? String,
               var character = marker.utf16.first {
                CTFontGetGlyphsForCharacters(font as CTFont, &character, &replacementGlyphs[index], 1)
            }
            if textStorage.attribute(.hiddenMarkdown, at: characterIndexes[index], effectiveRange: nil) as? Bool == true {
                // Null glyphs lose their line association; zero-width controls retain hit testing.
                properties[index] = .controlCharacter
            }
        }
        replacementGlyphs.withUnsafeBufferPointer { buffer in
            properties.withUnsafeBufferPointer {
                setGlyphs(buffer.baseAddress!, properties: $0.baseAddress!, characterIndexes: characterIndexes,
                          font: font, forGlyphRange: glyphRange)
            }
        }
        return glyphRange.length
    }
}
