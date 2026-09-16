import AppKit

final class EditorTextView: NSTextView {
    private static let headingPrefix = try! NSRegularExpression(pattern: #"^[ \t]{0,3}#{1,6}[ \t]*"#)
    private static let authorshipType = NSPasteboard.PasteboardType("com.absonson.writer.authorship")

    private(set) var isSelectingWithMouse = false
    var didFinishMouseSelection: (() -> Void)?

    override func mouseDown(with event: NSEvent) {
        // Keep glyph geometry stable throughout AppKit's click/drag hit testing.
        isSelectingWithMouse = true
        super.mouseDown(with: event)
        isSelectingWithMouse = false
        didFinishMouseSelection?()
    }

    var renderedFences: [NSRange] = []
    var renderedRules: [NSRange] = []

    override func deleteBackward(_ sender: Any?) {
        if Preferences.shared.livePreview,
           let range = LiveMarkdown.ruleToDelete(in: string, selection: selectedRange(), rules: renderedRules + renderedFences) {
            insertText("", replacementRange: range)
        } else {
            super.deleteBackward(sender)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let layoutManager, let textContainer else { return }
        NSColor.separatorColor.setStroke()
        for range in renderedRules where NSMaxRange(range) <= (string as NSString).length {
            let glyph = layoutManager.glyphIndexForCharacter(at: range.location)
            let rect = layoutManager.lineFragmentRect(forGlyphAt: glyph, effectiveRange: nil)
                .offsetBy(dx: textContainerOrigin.x, dy: textContainerOrigin.y)
            guard rect.intersects(dirtyRect) else { continue }
            let path = NSBezierPath()
            path.move(to: NSPoint(x: rect.minX, y: rect.midY))
            path.line(to: NSPoint(x: rect.minX + textContainer.size.width, y: rect.midY))
            path.stroke()
        }
    }

    var inputAttribution: Author = .selfTyped
    var attributedSlice: Authorship?
    var attributionLocked = false
    var suppressAuthorship = false
    var copySlice: (() -> Authorship)?
    var styleRangeAt: ((Int) -> NSRange?)?

    @IBAction func toggleBold(_ sender: Any?) { toggleWrap("**") }

    @IBAction func toggleItalic(_ sender: Any?) { toggleWrap("_") }

    @IBAction func setHeading(_ sender: NSMenuItem) {
        let source = string as NSString
        let selection = selectedRange()
        let paragraphs = source.paragraphRange(for: selection)
        let prefix = sender.tag > 0 ? String(repeating: "#", count: sender.tag) + " " : ""
        var rewritten = ""
        source.enumerateSubstrings(in: paragraphs, options: .byParagraphs) { line, _, enclosing, _ in
            let stripped = Self.headingPrefix.stringByReplacingMatches(in: line ?? "", range: NSRange(location: 0, length: (line as NSString?)?.length ?? 0), withTemplate: "")
            rewritten += prefix + stripped + source.substring(with: NSRange(location: NSMaxRange(enclosing) - (enclosing.length - ((line as NSString?)?.length ?? 0)), length: enclosing.length - ((line as NSString?)?.length ?? 0)))
        }
        replace(paragraphs, with: rewritten)
        let shift = (rewritten as NSString).length - paragraphs.length
        setSelectedRange(NSRange(location: max(paragraphs.location, selection.location + shift), length: 0))
    }

    private func toggleWrap(_ delimiter: String) {
        let source = string as NSString
        let selection = selectedRange()
        let width = (delimiter as NSString).length
        let outer = NSRange(location: selection.location - width, length: selection.length + 2 * width)
        if outer.location >= 0, NSMaxRange(outer) <= source.length,
           source.substring(with: NSRange(location: outer.location, length: width)) == delimiter,
           source.substring(with: NSRange(location: NSMaxRange(selection), length: width)) == delimiter {
            replace(outer, with: source.substring(with: selection))
            setSelectedRange(NSRange(location: outer.location, length: selection.length))
            return
        }
        replace(selection, with: delimiter + source.substring(with: selection) + delimiter)
        setSelectedRange(NSRange(location: selection.location + width, length: selection.length))
    }

    override func selectionRange(forProposedRange proposedCharRange: NSRange, granularity: NSSelectionGranularity) -> NSRange {
        if granularity == .selectByWord, let range = styleRangeAt?(proposedCharRange.location) {
            return range
        }
        return super.selectionRange(forProposedRange: proposedCharRange, granularity: granularity)
    }

    private func replace(_ range: NSRange, with replacement: String) {
        guard shouldChangeText(in: range, replacementString: replacement) else { return }
        textStorage?.replaceCharacters(in: range, with: replacement)
        didChangeText()
    }

    override func readSelection(from pboard: NSPasteboard) -> Bool {
        if !attributionLocked {
            let text = pboard.string(forType: .string) ?? ""
            let utf16 = (text as NSString).length
            if let slice = decodeAuthorship(pboard.string(forType: Self.authorshipType), utf16Length: utf16) {
                attributedSlice = slice
            } else {
                inputAttribution = .ai
            }
        }
        let result = super.readSelection(from: pboard)
        inputAttribution = .selfTyped
        attributedSlice = nil
        attributionLocked = false
        return result
    }

    override func writeSelection(to pboard: NSPasteboard, types: [NSPasteboard.PasteboardType]) -> Bool {
        let result = super.writeSelection(to: pboard, types: types)
        if let slice = copySlice?(), slice.length > 0 {
            pboard.setString(encodeAuthorship(slice), forType: Self.authorshipType)
        }
        return result
    }

    private func encodeAuthorship(_ auth: Authorship) -> String {
        auth.runs.map { "\($0.author.annotationKey):\($0.length)" }.joined(separator: " ")
    }

    private func decodeAuthorship(_ payload: String?, utf16Length: Int) -> Authorship? {
        guard let payload, utf16Length > 0 else { return nil }
        var runs: [Authorship.Run] = []
        var total = 0
        for token in payload.split(separator: " ") {
            let parts = token.split(separator: ":", maxSplits: 1)
            guard parts.count == 2,
                  let author = Author.parse(key: String(parts[0])),
                  let length = Int(parts[1]), length > 0 else { return nil }
            runs.append(Authorship.Run(author: author, length: length))
            total += length
        }
        guard total == utf16Length else { return nil }
        return Authorship(length: total, runs: runs)
    }
}
