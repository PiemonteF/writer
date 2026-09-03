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
    let lineHeightMultiple: CGFloat = 1.5
    let maxLineWidth: CGFloat

    static func make(_ prefs: Preferences, dark: Bool) -> Theme {
        let size = prefs.fontSize
        let family = prefs.font.familyName
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
            maxLineWidth: averageAdvance * CGFloat(prefs.lineLength)
        )
    }

    private static func face(_ family: String, size: CGFloat, traits: NSFontTraitMask) -> NSFont {
        NSFontManager.shared.font(withFamily: family, traits: traits, weight: 5, size: size)
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
