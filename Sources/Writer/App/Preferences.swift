import AppKit

enum FocusMode: String, CaseIterable {
    case off, sentence, paragraph
}

enum EditorFont: String, CaseIterable {
    case duo, quattro, mono

    var familyName: String {
        switch self {
        case .duo: return "iA Writer Duo S"
        case .quattro: return "iA Writer Quattro S"
        case .mono: return "iA Writer Mono S"
        }
    }

    var title: String {
        switch self {
        case .duo: return "Duo"
        case .quattro: return "Quattro"
        case .mono: return "Mono"
        }
    }
}

enum Appearance: String, CaseIterable {
    case system, light, dark

    var title: String { rawValue.capitalized }
}

extension Notification.Name {
    static let preferencesDidChange = Notification.Name("WriterPreferencesDidChange")
}

final class Preferences {
    static let shared = Preferences()

    private let defaults = UserDefaults.standard

    var font: EditorFont {
        get { enumValue("font", default: .duo) }
        set { store(newValue.rawValue, "font") }
    }

    var fontSize: CGFloat {
        get { defaults.object(forKey: "fontSize") as? CGFloat ?? 17 }
        set { store(newValue, "fontSize") }
    }

    var appearance: Appearance {
        get { enumValue("appearance", default: .system) }
        set { store(newValue.rawValue, "appearance") }
    }

    var focusMode: FocusMode {
        get { enumValue("focusMode", default: .off) }
        set { store(newValue.rawValue, "focusMode") }
    }

    var typewriter: Bool {
        get { defaults.bool(forKey: "typewriter") }
        set { store(newValue, "typewriter") }
    }

    var showStats: Bool {
        get { defaults.object(forKey: "showStats") as? Bool ?? true }
        set { store(newValue, "showStats") }
    }

    var showAuthorship: Bool {
        get { defaults.bool(forKey: "showAuthorship") }
        set { store(newValue, "showAuthorship") }
    }

    var highlightedParts: Set<PartOfSpeech> {
        get { Set((defaults.stringArray(forKey: "highlightedParts") ?? []).compactMap(PartOfSpeech.init(rawValue:))) }
        set { store(newValue.map(\.rawValue).sorted(), "highlightedParts") }
    }

    var styleChecks: Set<StyleIssue> {
        get { Set((defaults.stringArray(forKey: "styleChecks") ?? []).compactMap(StyleIssue.init(rawValue:))) }
        set { store(newValue.map(\.rawValue).sorted(), "styleChecks") }
    }

    var libraryURL: URL {
        get {
            defaults.string(forKey: "libraryPath").map { URL(fileURLWithPath: $0) }
                ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents/Writer")
        }
        set { store(newValue.path, "libraryPath") }
    }

    var showLibrary: Bool {
        get { defaults.bool(forKey: "showLibrary") }
        set { store(newValue, "showLibrary") }
    }

    var lineLength: Int {
        get { defaults.object(forKey: "lineLength") as? Int ?? 66 }
        set { store(newValue, "lineLength") }
    }

    private func enumValue<T: RawRepresentable>(_ key: String, default fallback: T) -> T where T.RawValue == String {
        defaults.string(forKey: key).flatMap(T.init(rawValue:)) ?? fallback
    }

    private func store(_ value: Any, _ key: String) {
        defaults.set(value, forKey: key)
        NotificationCenter.default.post(name: .preferencesDidChange, object: self)
    }
}
