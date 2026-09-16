import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var commandGuide: CommandGuideController?

    func applicationWillFinishLaunching(_ notification: Notification) {
        registerBundledFonts()
        _ = NSDocumentController.shared
        NSApp.mainMenu = MainMenu.build()
        applyAppearance()
        NotificationCenter.default.addObserver(
            self, selector: #selector(preferencesDidChange), name: .preferencesDidChange, object: nil)
    }

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool { true }

    @objc private func preferencesDidChange() { applyAppearance() }

    private func applyAppearance() {
        switch Preferences.shared.appearance {
        case .system: NSApp.appearance = nil
        case .light: NSApp.appearance = NSAppearance(named: .aqua)
        case .dark: NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }

    private func registerBundledFonts() {
        guard let fontsURL = Bundle.main.resourceURL?.appendingPathComponent("Fonts"),
              let files = try? FileManager.default.contentsOfDirectory(at: fontsURL, includingPropertiesForKeys: nil)
        else { return }
        for file in files where file.pathExtension == "ttf" {
            CTFontManagerRegisterFontsForURL(file as CFURL, .process, nil)
        }
    }

    @IBAction func chooseLibraryFolder(_ sender: Any?) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.directoryURL = Preferences.shared.libraryURL
        panel.prompt = "Use Folder"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        Preferences.shared.libraryURL = url
    }

    @IBAction func toggleFocusMode(_ sender: Any?) {
        let prefs = Preferences.shared
        prefs.focusMode = prefs.focusMode == .off ? .sentence : .off
    }

    @IBAction func setFocusMode(_ sender: NSMenuItem) {
        guard let mode = sender.representedObject as? FocusMode else { return }
        Preferences.shared.focusMode = mode
    }

    @IBAction func toggleTypewriter(_ sender: Any?) {
        Preferences.shared.typewriter.toggle()
    }

    @IBAction func toggleNightMode(_ sender: Any?) {
        let prefs = Preferences.shared
        prefs.appearance = prefs.appearance == .dark ? .light : .dark
    }

    @IBAction func setAppearance(_ sender: NSMenuItem) {
        guard let appearance = sender.representedObject as? Appearance else { return }
        Preferences.shared.appearance = appearance
    }

    @IBAction func toggleStats(_ sender: Any?) {
        Preferences.shared.showStats.toggle()
    }

    @IBAction func toggleAuthorship(_ sender: Any?) {
        Preferences.shared.showAuthorship.toggle()
    }

    @IBAction func setEditorFont(_ sender: NSMenuItem) {
        guard let font = sender.representedObject as? EditorFont else { return }
        Preferences.shared.systemFont = nil
        Preferences.shared.font = font
    }

    @IBAction func setSystemFont(_ sender: NSMenuItem) {
        guard let family = sender.representedObject as? String else { return }
        Preferences.shared.systemFont = family
    }

    @IBAction func toggleLivePreview(_ sender: Any?) { Preferences.shared.livePreview.toggle() }
    @IBAction func toggleOutline(_ sender: Any?) { Preferences.shared.showOutline.toggle() }

    @IBAction func showCommands(_ sender: Any?) {
        if commandGuide == nil {
            commandGuide = CommandGuideController()
        }
        commandGuide?.showWindow(sender)
    }

    @IBAction func toggleSyntaxHighlight(_ sender: Any?) {
        let prefs = Preferences.shared
        prefs.highlightedParts = prefs.highlightedParts.isEmpty ? Set(PartOfSpeech.allCases) : []
    }

    @IBAction func togglePartOfSpeech(_ sender: NSMenuItem) {
        guard let part = sender.representedObject as? PartOfSpeech else { return }
        let prefs = Preferences.shared
        prefs.highlightedParts = prefs.highlightedParts.symmetricDifference([part])
    }

    @IBAction func clearPartsOfSpeech(_ sender: Any?) {
        Preferences.shared.highlightedParts = []
    }

    @IBAction func toggleStyleCheck(_ sender: Any?) {
        let prefs = Preferences.shared
        prefs.styleChecks = prefs.styleChecks.isEmpty ? Set(StyleIssue.allCases) : []
    }

    @IBAction func toggleStyleIssue(_ sender: NSMenuItem) {
        guard let kind = sender.representedObject as? StyleIssue else { return }
        let prefs = Preferences.shared
        prefs.styleChecks = prefs.styleChecks.symmetricDifference([kind])
    }

    @IBAction func clearStyleCheck(_ sender: Any?) {
        Preferences.shared.styleChecks = []
    }

    @IBAction func biggerFont(_ sender: Any?) {
        let prefs = Preferences.shared
        prefs.fontSize = min(prefs.fontSize + 1, 40)
    }

    @IBAction func smallerFont(_ sender: Any?) {
        let prefs = Preferences.shared
        prefs.fontSize = max(prefs.fontSize - 1, 9)
    }
}

extension AppDelegate: NSMenuItemValidation {
    func validateMenuItem(_ item: NSMenuItem) -> Bool {
        let prefs = Preferences.shared
        switch item.action {
        case #selector(toggleFocusMode): item.state = prefs.focusMode != .off ? .on : .off
        case #selector(setFocusMode): item.state = item.representedObject as? FocusMode == prefs.focusMode ? .on : .off
        case #selector(toggleTypewriter): item.state = prefs.typewriter ? .on : .off
        case #selector(toggleNightMode): item.state = prefs.appearance == .dark ? .on : .off
        case #selector(setAppearance): item.state = item.representedObject as? Appearance == prefs.appearance ? .on : .off
        case #selector(toggleStats): item.state = prefs.showStats ? .on : .off
        case #selector(toggleAuthorship): item.state = prefs.showAuthorship ? .on : .off
        case #selector(toggleSyntaxHighlight): item.state = prefs.highlightedParts.isEmpty ? .off : .on
        case #selector(togglePartOfSpeech): item.state = (item.representedObject as? PartOfSpeech).map(prefs.highlightedParts.contains) == true ? .on : .off
        case #selector(toggleStyleCheck): item.state = prefs.styleChecks.isEmpty ? .off : .on
        case #selector(toggleStyleIssue): item.state = (item.representedObject as? StyleIssue).map(prefs.styleChecks.contains) == true ? .on : .off
        case #selector(setEditorFont): item.state = prefs.systemFont == nil && item.representedObject as? EditorFont == prefs.font ? .on : .off
        case #selector(setSystemFont): item.state = item.representedObject as? String == prefs.systemFont ? .on : .off
        case #selector(toggleLivePreview): item.state = prefs.livePreview ? .on : .off
        case #selector(toggleOutline): item.state = prefs.showOutline ? .on : .off
        default: break
        }
        return true
    }
}
