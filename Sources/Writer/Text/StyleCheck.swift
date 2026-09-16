import Foundation

enum StyleIssue: String, CaseIterable {
    case filler, redundancy, cliche

    var title: String {
        switch self {
        case .filler: return "Fillers"
        case .redundancy: return "Redundancies"
        case .cliche: return "Clichés"
        }
    }
}

struct StyleSpan: Hashable {
    let range: NSRange
    let kind: StyleIssue
}

enum StyleCheck {
    static func spans(in text: String, kinds: Set<StyleIssue>) -> [StyleSpan] {
        guard !kinds.isEmpty, !text.isEmpty else { return [] }
        let haystack = text.replacingOccurrences(of: "\u{2019}", with: "'") as NSString
        let full = NSRange(location: 0, length: haystack.length)
        var occupied = IndexSet()
        var result: [StyleSpan] = []
        for (kind, regex) in compiled where kinds.contains(kind) {
            for match in regex.matches(in: haystack as String, range: full) {
                let range = match.range
                guard range.length > 0 else { continue }
                let indices = IndexSet(integersIn: range.location..<NSMaxRange(range))
                if occupied.intersection(indices).isEmpty {
                    occupied.formUnion(indices)
                    result.append(StyleSpan(range: range, kind: kind))
                }
            }
        }
        return result
    }

    private static let compiled: [(StyleIssue, NSRegularExpression)] = {
        let pairs = StyleIssue.allCases.flatMap { kind -> [(StyleIssue, NSRegularExpression)] in
            patterns[kind]!.compactMap { phrase in
                let escaped = phrase.split(separator: " ")
                    .map { NSRegularExpression.escapedPattern(for: String($0)) }
                    .joined(separator: #"\s+"#)
                guard let regex = try? NSRegularExpression(pattern: #"\b\#(escaped)\b"#, options: [.caseInsensitive]) else {
                    return nil
                }
                return (kind, regex)
            }
        }
        return pairs.sorted { $0.1.pattern.count > $1.1.pattern.count }
    }()

    private static let patterns: [StyleIssue: [String]] = [
        .filler: [
            "needless to say", "to be honest", "to be fair", "for what it's worth",
            "in my opinion", "in my view", "as a matter of fact", "the fact that",
            "due to the fact that", "in order to", "it seems", "it appears",
            "i think", "i believe", "i feel", "i mean", "you know",
            "kind of", "kinda", "sort of", "pretty much", "a little bit",
            "a bit", "a little", "as it were", "so to speak", "if you will",
            "per se", "as such", "in fact", "of course", "at all",
            "actually", "really", "very", "just", "perhaps", "maybe",
            "quite", "rather", "somewhat", "basically", "literally",
            "honestly", "frankly", "simply", "clearly", "obviously",
            "definitely", "certainly", "absolutely", "totally", "completely",
            "extremely", "incredibly", "truly", "surely", "probably",
            "possibly", "apparently", "essentially", "generally", "usually",
            "typically", "anyway", "anyhow", "somehow", "fairly",
            "almost", "slightly", "relatively", "virtually", "practically",
            "nearly", "hardly", "scarcely", "like",
        ],
        .redundancy: [
            "each and every", "first and foremost", "null and void",
            "cease and desist", "safe and sound", "over and done with",
            "basic fundamentals", "basic essentials", "added bonus",
            "advance forward", "advance planning", "already exist",
            "blend together", "brief moment", "close proximity",
            "combine together", "completely finish", "completely unique",
            "consensus of opinion", "current status", "descend down",
            "each individual", "empty void", "end result", "enter in",
            "exact same", "fall down", "final outcome", "final result",
            "free gift", "frozen ice", "future plans", "gather together",
            "green in color", "honest truth", "inner feelings",
            "join together", "kneel down", "lift up", "major breakthrough",
            "meet together", "merge together", "mix together",
            "mutual cooperation", "new beginning", "new innovation",
            "old adage", "past history", "past memories", "personal opinion",
            "plan ahead", "postpone until later", "proceed forward",
            "raise up", "reason why", "reason is because", "repeat again",
            "return back", "revert back", "rise up", "round in shape",
            "small in size", "still remains", "sum total", "surrounded on all sides",
            "true fact", "unexpected surprise", "usual custom",
            "visible to the eye", "warn in advance", "whether or not",
            "absolutely essential", "absolutely necessary", "completely destroyed",
            "estimated roughly", "foreign imports", "pair of twins",
            "PIN number", "ATM machine", "HIV virus", "LCD display",
        ],
        .cliche: [
            "at the end of the day", "in this day and age", "when all is said and done",
            "for all intents and purposes", "the fact of the matter",
            "the name of the game", "tip of the iceberg", "elephant in the room",
            "think outside the box", "low-hanging fruit", "move the needle",
            "hit the nail on the head", "back to the drawing board",
            "beat around the bush", "best thing since sliced bread",
            "bite the bullet", "by leaps and bounds", "cut to the chase",
            "every cloud has a silver lining", "few and far between",
            "food for thought", "go the extra mile", "in a nutshell",
            "in the nick of time", "last but not least", "nipping it in the bud",
            "on the same page", "only time will tell", "paradigm shift",
            "pushing the envelope", "read between the lines", "time will tell",
            "touch base", "win-win situation", "against all odds",
            "at the drop of a hat", "brass tacks", "crystal clear",
            "it is what it is", "long and short of it", "in the same boat",
            "plenty of fish in the sea", "the whole nine yards",
            "avoid it like the plague", "calm before the storm",
            "better late than never", "easier said than done",
            "at face value", "in hot water", "out of the blue",
            "the bottom line", "a blessing in disguise",
        ],
    ]
}
