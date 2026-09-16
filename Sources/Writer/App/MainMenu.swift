import AppKit

enum MainMenu {
    static func build() -> NSMenu {
        let main = NSMenu()
        main.addItem(submenu("Writer", [
            item("About Writer", #selector(NSApplication.orderFrontStandardAboutPanel(_:))),
            .separator(),
            submenu("Settings", [
                item("Live Markdown Preview", #selector(AppDelegate.toggleLivePreview(_:)), "r", [.command, .option]),
                item("Heading Tree", #selector(AppDelegate.toggleOutline(_:)), "o", [.command, .option]),
            ]),
            .separator(),
            item("Hide Writer", #selector(NSApplication.hide(_:)), "h"),
            item("Hide Others", #selector(NSApplication.hideOtherApplications(_:)), "h", [.command, .option]),
            item("Show All", #selector(NSApplication.unhideAllApplications(_:))),
            .separator(),
            item("Quit Writer", #selector(NSApplication.terminate(_:)), "q"),
        ]))
        main.addItem(submenu("File", [
            item("New", #selector(NSDocumentController.newDocument(_:)), "n"),
            item("Open…", #selector(NSDocumentController.openDocument(_:)), "o"),
            openRecent(),
            .separator(),
            item("Choose Library Folder…", #selector(AppDelegate.chooseLibraryFolder(_:))),
            .separator(),
            item("Close", #selector(NSWindow.performClose(_:)), "w"),
            item("Save…", #selector(NSDocument.save(_:)), "s"),
            item("Duplicate", #selector(NSDocument.duplicate(_:)), "s", [.command, .shift]),
            item("Rename…", #selector(NSDocument.rename(_:))),
            item("Move To…", #selector(NSDocument.move(_:))),
            item("Revert To Saved", #selector(NSDocument.revertToSaved(_:))),
            .separator(),
            submenu("Export", [
                item("HTML…", #selector(EditorWindowController.exportHTML(_:))),
                item("PDF…", #selector(EditorWindowController.exportPDF(_:))),
            ]),
        ]))
        main.addItem(submenu("Edit", [
            item("Undo", Selector(("undo:")), "z"),
            item("Redo", Selector(("redo:")), "z", [.command, .shift]),
            .separator(),
            item("Cut", #selector(NSText.cut(_:)), "x"),
            item("Copy", #selector(NSText.copy(_:)), "c"),
            item("Paste", #selector(NSText.paste(_:)), "v"),
            item("Select All", #selector(NSText.selectAll(_:)), "a"),
            item("Copy HTML", #selector(EditorWindowController.copyHTML(_:)), "c", [.command, .option]),
            .separator(),
            submenu("Find", [
                item("Find…", #selector(NSTextView.performTextFinderAction(_:)), "f", tag: NSTextFinder.Action.showFindInterface.rawValue),
                item("Find Next", #selector(NSTextView.performTextFinderAction(_:)), "g", tag: NSTextFinder.Action.nextMatch.rawValue),
                item("Find Previous", #selector(NSTextView.performTextFinderAction(_:)), "g", [.command, .shift], tag: NSTextFinder.Action.previousMatch.rawValue),
                item("Use Selection for Find", #selector(NSTextView.performTextFinderAction(_:)), "e", tag: NSTextFinder.Action.setSearchString.rawValue),
            ]),
            submenu("Spelling", [
                item("Show Spelling and Grammar", #selector(NSText.showGuessPanel(_:)), ":"),
                item("Check Document Now", #selector(NSText.checkSpelling(_:)), ";"),
                .separator(),
                item("Check Spelling While Typing", #selector(NSTextView.toggleContinuousSpellChecking(_:))),
            ]),
        ]))
        main.addItem(submenu("Format", [
            item("Bold", #selector(EditorTextView.toggleBold(_:)), "b"),
            item("Italic", #selector(EditorTextView.toggleItalic(_:)), "i"),
            .separator(),
            item("Body", #selector(EditorTextView.setHeading(_:)), "0", [.command, .option], tag: 0),
            item("Heading 1", #selector(EditorTextView.setHeading(_:)), "1", [.command, .option], tag: 1),
            item("Heading 2", #selector(EditorTextView.setHeading(_:)), "2", [.command, .option], tag: 2),
            item("Heading 3", #selector(EditorTextView.setHeading(_:)), "3", [.command, .option], tag: 3),
        ]))
        main.addItem(submenu("Authors", [
            item("Show Authorship", #selector(AppDelegate.toggleAuthorship(_:)), "a", [.command, .shift]),
            .separator(),
            item("Paste as AI", #selector(EditorViewController.pasteAsAI(_:))),
            item("Paste as Mine", #selector(EditorViewController.pasteAsMine(_:))),
            item("Paste as Reference", #selector(EditorViewController.pasteAsReference(_:))),
            .separator(),
            item("Mark Selection as AI", #selector(EditorViewController.markAsAI(_:))),
            item("Mark Selection as Mine", #selector(EditorViewController.markAsMine(_:))),
            item("Mark Selection as Reference", #selector(EditorViewController.markAsReference(_:))),
        ]))
        main.addItem(submenu("View", [
            item("Commands…", #selector(AppDelegate.showCommands(_:)), "/"),
            .separator(),
            item("Focus Mode", #selector(AppDelegate.toggleFocusMode(_:)), "d"),
            submenu("Focus", [
                item("Sentence", #selector(AppDelegate.setFocusMode(_:)), represents: FocusMode.sentence),
                item("Paragraph", #selector(AppDelegate.setFocusMode(_:)), represents: FocusMode.paragraph),
            ]),
            item("Typewriter Mode", #selector(AppDelegate.toggleTypewriter(_:)), "t", [.command, .option]),
            .separator(),
            item("Preview", #selector(EditorWindowController.togglePreview(_:)), "r"),
            item("Library", #selector(EditorWindowController.toggleLibrary(_:)), "l", [.command, .option]),
            .separator(),
            item("Night Mode", #selector(AppDelegate.toggleNightMode(_:)), "n", [.command, .option]),
            submenu("Appearance", Appearance.allCases.map {
                item($0.title, #selector(AppDelegate.setAppearance(_:)), represents: $0)
            }),
            .separator(),
            submenu("Font", EditorFont.allCases.map {
                item($0.title, #selector(AppDelegate.setEditorFont(_:)), represents: $0)
            } + [.separator(), submenu("System fonts", NSFontManager.shared.availableFontFamilies.sorted {
                $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
            }.map { item($0, #selector(AppDelegate.setSystemFont(_:)), represents: $0) })]),
            item("Bigger", #selector(AppDelegate.biggerFont(_:)), "+"),
            item("Smaller", #selector(AppDelegate.smallerFont(_:)), "-"),
            .separator(),
            syntaxHighlight(),
            styleCheck(),
            item("Authorship", #selector(AppDelegate.toggleAuthorship(_:)), "a", [.command, .shift]),
            item("Word Count", #selector(AppDelegate.toggleStats(_:)), "c", [.command, .shift]),
            .separator(),
            item("Enter Full Screen", #selector(NSWindow.toggleFullScreen(_:)), "f", [.command, .control]),
        ]))
        let window = submenu("Window", [
            item("Minimize", #selector(NSWindow.performMiniaturize(_:)), "m"),
            item("Zoom", #selector(NSWindow.performZoom(_:))),
            .separator(),
            item("Bring All to Front", #selector(NSApplication.arrangeInFront(_:))),
        ])
        main.addItem(window)
        NSApplication.shared.windowsMenu = window.submenu
        main.addItem(submenu("Help", [
            item("Commands…", #selector(AppDelegate.showCommands(_:))),
        ]))
        return main
    }

    private static func item(
        _ title: String, _ action: Selector, _ key: String = "",
        _ modifiers: NSEvent.ModifierFlags = .command, tag: Int = 0, represents: Any? = nil
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.keyEquivalentModifierMask = key.isEmpty ? [] : modifiers
        item.tag = tag
        item.representedObject = represents
        return item
    }

    private static func submenu(_ title: String, _ items: [NSMenuItem]) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        let menu = NSMenu(title: title)
        items.forEach(menu.addItem)
        item.submenu = menu
        return item
    }

    private static func syntaxHighlight() -> NSMenuItem {
        let menuItem = submenu("Syntax Highlight", PartOfSpeech.allCases.map {
            item($0.title, #selector(AppDelegate.togglePartOfSpeech(_:)), represents: $0)
        } + [.separator(), item("Clear", #selector(AppDelegate.clearPartsOfSpeech(_:)))])
        menuItem.action = #selector(AppDelegate.toggleSyntaxHighlight(_:))
        menuItem.keyEquivalent = "d"
        menuItem.keyEquivalentModifierMask = [.command, .shift]
        return menuItem
    }

    private static func styleCheck() -> NSMenuItem {
        let menuItem = submenu("Style Check", StyleIssue.allCases.map {
            item($0.title, #selector(AppDelegate.toggleStyleIssue(_:)), represents: $0)
        } + [.separator(), item("Clear", #selector(AppDelegate.clearStyleCheck(_:)))])
        menuItem.action = #selector(AppDelegate.toggleStyleCheck(_:))
        menuItem.keyEquivalent = "d"
        menuItem.keyEquivalentModifierMask = [.command, .shift, .option]
        return menuItem
    }

    // NSDocumentController populates the submenu that contains a clearRecentDocuments: item.
    private static func openRecent() -> NSMenuItem {
        submenu("Open Recent", [
            item("Clear Menu", #selector(NSDocumentController.clearRecentDocuments(_:))),
        ])
    }
}
