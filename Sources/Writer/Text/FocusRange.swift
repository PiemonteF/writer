import Foundation

enum FocusRange {
    static func range(mode: FocusMode, caret: Int, in text: NSString) -> NSRange? {
        guard caret >= 0, caret <= text.length else { return nil }
        let paragraph = text.paragraphRange(for: NSRange(location: caret, length: 0))
        switch mode {
        case .off:
            return nil
        case .paragraph:
            return paragraph
        case .sentence:
            var containing: NSRange?
            var preceding: NSRange?
            text.enumerateSubstrings(in: paragraph, options: [.bySentences, .substringNotRequired]) { _, sentence, _, stop in
                if NSLocationInRange(caret, sentence) {
                    containing = sentence
                    stop.pointee = true
                } else if NSMaxRange(sentence) == caret {
                    preceding = sentence
                }
            }
            return containing ?? preceding ?? paragraph
        }
    }
}
