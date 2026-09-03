import Foundation
import NaturalLanguage

enum PartOfSpeech: String, CaseIterable {
    case noun, verb, adjective, adverb, conjunction

    var title: String {
        switch self {
        case .noun: return "Nouns"
        case .verb: return "Verbs"
        case .adjective: return "Adjectives"
        case .adverb: return "Adverbs"
        case .conjunction: return "Conjunctions"
        }
    }

    fileprivate static let byTag: [NLTag: PartOfSpeech] = [
        .noun: .noun, .pronoun: .noun, .verb: .verb, .adjective: .adjective, .adverb: .adverb, .conjunction: .conjunction,
    ]
}

struct PartOfSpeechSpan: Hashable {
    let range: NSRange
    let part: PartOfSpeech
}

enum PartsOfSpeech {
    static func spans(in text: String, parts: Set<PartOfSpeech>) -> [PartOfSpeechSpan] {
        guard !parts.isEmpty, !text.isEmpty else { return [] }
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        var result: [PartOfSpeechSpan] = []
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: [.omitPunctuation, .omitWhitespace, .omitOther]) { tag, range in
            if let tag, let part = PartOfSpeech.byTag[tag], parts.contains(part) {
                result.append(PartOfSpeechSpan(range: NSRange(range, in: text), part: part))
            }
            return true
        }
        return result
    }
}
