import AppKit

final class EditorTextView: NSTextView {
    private static let headingPrefix = try! NSRegularExpression(pattern: #"^[ \t]{0,3}#{1,6}[ \t]*"#)

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

    private func replace(_ range: NSRange, with replacement: String) {
        guard shouldChangeText(in: range, replacementString: replacement) else { return }
        textStorage?.replaceCharacters(in: range, with: replacement)
        didChangeText()
    }
}
