import AppKit

struct Theme {
    let font: NSFont
    let boldFont: NSFont
    let italicFont: NSFont
    let boldItalicFont: NSFont
    let monoFont: NSFont
    let background: NSColor
    let text: NSColor
    let dimmedText: NSColor
    let markup: NSColor
    let accent: NSColor
    let partColors: [PartOfSpeech: NSColor]
    let lineHeightMultiple: CGFloat = 1.5
    let maxLineWidth: CGFloat

    static func make(_ prefs: Preferences, dark: Bool) -> Theme {
        let size = prefs.fontSize
        let family = prefs.systemFont ?? prefs.font.familyName
        let regular = face(family, size: size, traits: [])
        let sample = "abcdefghijklmnopqrstuvwxyz" as NSString
        let averageAdvance = sample.size(withAttributes: [.font: regular]).width / CGFloat(sample.length)
        return Theme(
            font: regular,
            boldFont: face(family, size: size, traits: .boldFontMask),
            italicFont: face(family, size: size, traits: .italicFontMask),
            boldItalicFont: face(family, size: size, traits: [.boldFontMask, .italicFontMask]),
            monoFont: face(EditorFont.mono.familyName, size: size, traits: []),
            background: dark ? NSColor(hex: 0x1E1E1E) : NSColor(hex: 0xFCFCFC),
            text: dark ? NSColor(hex: 0xE6E6E6) : NSColor(hex: 0x1A1A1A),
            dimmedText: dark ? NSColor(hex: 0x575757) : NSColor(hex: 0xBFBFBF),
            markup: dark ? NSColor(hex: 0x6C7885) : NSColor(hex: 0x8E9AA8),
            accent: dark ? NSColor(hex: 0x4A90FF) : NSColor(hex: 0x2F7CF6),
            partColors: dark
                ? [.noun: NSColor(hex: 0xFF6B66), .verb: NSColor(hex: 0x5B9BFF), .adjective: NSColor(hex: 0xD8A62B), .adverb: NSColor(hex: 0xE090B0), .conjunction: NSColor(hex: 0x5FC27A)]
                : [.noun: NSColor(hex: 0xC44C4C), .verb: NSColor(hex: 0x2F7CF6), .adjective: NSColor(hex: 0xB8860B), .adverb: NSColor(hex: 0xC45A9A), .conjunction: NSColor(hex: 0x3F9F57)],
            maxLineWidth: averageAdvance * CGFloat(prefs.lineLength)
        )
    }

    private static func face(_ family: String, size: CGFloat, traits: NSFontTraitMask) -> NSFont {
        NSFontManager.shared.font(withFamily: family, traits: traits, weight: 5, size: size)
            ?? NSFontManager.shared.font(withFamily: family, traits: [], weight: 5, size: size)
            ?? NSFont.monospacedSystemFont(ofSize: size, weight: traits.contains(.boldFontMask) ? .bold : .regular)
    }

    var paragraphStyle: NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineHeightMultiple = lineHeightMultiple
        return style
    }

    var baseAttributes: [NSAttributedString.Key: Any] {
        [.font: font, .foregroundColor: text, .paragraphStyle: paragraphStyle]
    }

    func authorshipColor(for author: Author, wordIndex: Int, dark: Bool) -> NSColor {
        switch author {
        case .selfTyped:
            return text
        case .reference:
            return dimmedText
        case .ai:
            let palette = dark ? Self.aiDark : Self.aiLight
            return palette[wordIndex % palette.count]
        case .human(let name):
            let palette = dark ? Self.humanDark : Self.humanLight
            var hash = 0
            for scalar in name.unicodeScalars { hash = hash &* 31 &+ Int(scalar.value) }
            return palette[abs(hash) % palette.count]
        }
    }

    private static let aiLight: [NSColor] = [
        NSColor(hex: 0xC46A38), NSColor(hex: 0x6B5CA8), NSColor(hex: 0xC45A7A),
        NSColor(hex: 0x2E8F78), NSColor(hex: 0xB8860B), NSColor(hex: 0x3A6FA0),
    ]
    private static let aiDark: [NSColor] = [
        NSColor(hex: 0xE08A5C), NSColor(hex: 0xB5A3E0), NSColor(hex: 0xE090B0),
        NSColor(hex: 0x7EC8B8), NSColor(hex: 0xE0C56A), NSColor(hex: 0x7EB0E0),
    ]
    private static let humanLight: [NSColor] = [
        NSColor(hex: 0x6A7B8A), NSColor(hex: 0x7A6B5A), NSColor(hex: 0x5A7A6A), NSColor(hex: 0x7A5A6A),
    ]
    private static let humanDark: [NSColor] = [
        NSColor(hex: 0x8A9BAA), NSColor(hex: 0xAA9B8A), NSColor(hex: 0x8AAAA0), NSColor(hex: 0xAA8A9A),
    ]
}

extension NSColor {
    convenience init(hex: Int) {
        self.init(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1)
    }
}
