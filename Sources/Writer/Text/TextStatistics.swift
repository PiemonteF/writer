import Foundation

struct TextStatistics: Equatable {
    let words: Int
    let characters: Int
    let sentences: Int
    let paragraphs: Int

    static let wordsPerMinute = 275.0

    var readingMinutes: Int {
        words == 0 ? 0 : max(1, Int((Double(words) / Self.wordsPerMinute).rounded(.up)))
    }

    static func compute(_ text: String) -> TextStatistics {
        let source = text as NSString
        let full = NSRange(location: 0, length: source.length)
        return TextStatistics(
            words: count(source, full, .byWords),
            characters: text.count,
            sentences: count(source, full, .bySentences),
            paragraphs: count(source, full, .byParagraphs))
    }

    private static func count(_ text: NSString, _ range: NSRange, _ unit: NSString.EnumerationOptions) -> Int {
        var total = 0
        text.enumerateSubstrings(in: range, options: [unit, .substringNotRequired]) { _, subrange, _, _ in
            if unit == .byWords || text.substring(with: subrange).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                total += 1
            }
        }
        return total
    }

    var summary: String {
        let formatted = NumberFormatter.localizedString(from: NSNumber(value: words), number: .decimal)
        return "\(formatted) \(words == 1 ? "word" : "words") · \(readingMinutes) min"
    }
}
