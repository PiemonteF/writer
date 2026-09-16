import Foundation

enum CommandGuide {
    struct Item: Equatable {
        let group: String
        let title: String
        let shortcut: String
        let summary: String
    }

    enum Row: Equatable {
        case group(String)
        case command(Item)
    }

    static let items: [Item] = [
        Item(group: "Writer", title: "Live Markdown Preview", shortcut: "⌥⌘R",
             summary: "Render headings, lists, links, quotes and code in the editor. The file stays Markdown."),
        Item(group: "Writer", title: "Heading Tree", shortcut: "⌥⌘O",
             summary: "Floating outline of H1–H3. Click a heading to jump; the visible section is highlighted."),
        Item(group: "Writer", title: "Commands…", shortcut: "⌘/",
             summary: "Show every command, its shortcut, and what it does."),

        Item(group: "File", title: "New", shortcut: "⌘N",
             summary: "Open a new untitled document."),
        Item(group: "File", title: "Open…", shortcut: "⌘O",
             summary: "Open a Markdown or text file."),
        Item(group: "File", title: "Choose Library Folder…", shortcut: "",
             summary: "Pick the folder shown in the library sidebar. Default is Documents/Writer."),
        Item(group: "File", title: "Close", shortcut: "⌘W",
             summary: "Close the current window."),
        Item(group: "File", title: "Save…", shortcut: "⌘S",
             summary: "Save the document. Autosave is on."),
        Item(group: "File", title: "Duplicate", shortcut: "⇧⌘S",
             summary: "Create a copy of the current document."),
        Item(group: "File", title: "Rename…", shortcut: "",
             summary: "Rename the current file in place."),
        Item(group: "File", title: "Move To…", shortcut: "",
             summary: "Move the file to another folder."),
        Item(group: "File", title: "Revert To Saved", shortcut: "",
             summary: "Throw away unsaved edits and reload from disk."),
        Item(group: "File", title: "HTML…", shortcut: "",
             summary: "Export the document as an HTML file."),
        Item(group: "File", title: "PDF…", shortcut: "",
             summary: "Export the document as a PDF."),

        Item(group: "Edit", title: "Undo", shortcut: "⌘Z",
             summary: "Undo the last edit, including authorship."),
        Item(group: "Edit", title: "Redo", shortcut: "⇧⌘Z",
             summary: "Redo the last undone edit."),
        Item(group: "Edit", title: "Cut", shortcut: "⌘X",
             summary: "Cut the selection to the clipboard."),
        Item(group: "Edit", title: "Copy", shortcut: "⌘C",
             summary: "Copy the selection as plain Markdown."),
        Item(group: "Edit", title: "Paste", shortcut: "⌘V",
             summary: "Paste. Unattributed text is marked as AI until you rewrite it."),
        Item(group: "Edit", title: "Select All", shortcut: "⌘A",
             summary: "Select the whole document."),
        Item(group: "Edit", title: "Copy HTML", shortcut: "⌥⌘C",
             summary: "Copy the rendered HTML of the document."),
        Item(group: "Edit", title: "Find…", shortcut: "⌘F",
             summary: "Search in the current document."),
        Item(group: "Edit", title: "Find Next", shortcut: "⌘G",
             summary: "Jump to the next match."),
        Item(group: "Edit", title: "Find Previous", shortcut: "⇧⌘G",
             summary: "Jump to the previous match."),
        Item(group: "Edit", title: "Use Selection for Find", shortcut: "⌘E",
             summary: "Search for the selected text."),
        Item(group: "Edit", title: "Show Spelling and Grammar", shortcut: "⌘:",
             summary: "Open the spelling panel."),
        Item(group: "Edit", title: "Check Document Now", shortcut: "⌘;",
             summary: "Run a spelling check from the caret."),
        Item(group: "Edit", title: "Check Spelling While Typing", shortcut: "",
             summary: "Underline misspellings as you type."),

        Item(group: "Format", title: "Bold", shortcut: "⌘B",
             summary: "Wrap the selection in **bold** Markdown."),
        Item(group: "Format", title: "Italic", shortcut: "⌘I",
             summary: "Wrap the selection in _italic_ Markdown."),
        Item(group: "Format", title: "Body", shortcut: "⌥⌘0",
             summary: "Remove heading markers from the current lines."),
        Item(group: "Format", title: "Heading 1", shortcut: "⌥⌘1",
             summary: "Turn the current lines into an H1."),
        Item(group: "Format", title: "Heading 2", shortcut: "⌥⌘2",
             summary: "Turn the current lines into an H2."),
        Item(group: "Format", title: "Heading 3", shortcut: "⌥⌘3",
             summary: "Turn the current lines into an H3."),

        Item(group: "Authors", title: "Show Authorship", shortcut: "⇧⌘A",
             summary: "Your typing stays black. Pasted or generated text is in color. Rewrite it and it becomes yours."),
        Item(group: "Authors", title: "Paste as AI", shortcut: "",
             summary: "Paste and mark the insertion as generated."),
        Item(group: "Authors", title: "Paste as Mine", shortcut: "",
             summary: "Paste and mark the insertion as your own."),
        Item(group: "Authors", title: "Paste as Reference", shortcut: "",
             summary: "Paste as quoted reference text."),
        Item(group: "Authors", title: "Mark Selection as AI", shortcut: "",
             summary: "Tag the selection as generated."),
        Item(group: "Authors", title: "Mark Selection as Mine", shortcut: "",
             summary: "Tag the selection as your own."),
        Item(group: "Authors", title: "Mark Selection as Reference", shortcut: "",
             summary: "Tag the selection as reference."),

        Item(group: "View", title: "Focus Mode", shortcut: "⌘D",
             summary: "Keep the sentence at the caret; fade the rest."),
        Item(group: "View", title: "Sentence", shortcut: "",
             summary: "Focus on the current sentence."),
        Item(group: "View", title: "Paragraph", shortcut: "",
             summary: "Focus on the current paragraph."),
        Item(group: "View", title: "Typewriter Mode", shortcut: "⌥⌘T",
             summary: "Keep the caret line in the middle of the window."),
        Item(group: "View", title: "Preview", shortcut: "⌘R",
             summary: "Show rendered HTML beside the editor."),
        Item(group: "View", title: "Library", shortcut: "⌥⌘L",
             summary: "Show a sidebar of Markdown and text files."),
        Item(group: "View", title: "Night Mode", shortcut: "⌥⌘N",
             summary: "Switch between light and dark."),
        Item(group: "View", title: "System", shortcut: "",
             summary: "Follow the system appearance."),
        Item(group: "View", title: "Light", shortcut: "",
             summary: "Use the light theme."),
        Item(group: "View", title: "Dark", shortcut: "",
             summary: "Use the dark theme."),
        Item(group: "View", title: "Duo", shortcut: "",
             summary: "iA Writer Duo, the default proportional font."),
        Item(group: "View", title: "Quattro", shortcut: "",
             summary: "iA Writer Quattro, a four-axis proportional font."),
        Item(group: "View", title: "Mono", shortcut: "",
             summary: "iA Writer Mono."),
        Item(group: "View", title: "Bigger", shortcut: "⌘+",
             summary: "Increase the editor font size."),
        Item(group: "View", title: "Smaller", shortcut: "⌘-",
             summary: "Decrease the editor font size."),
        Item(group: "View", title: "Syntax Highlight", shortcut: "⇧⌘D",
             summary: "Color nouns, verbs, adjectives, adverbs and conjunctions."),
        Item(group: "View", title: "Nouns", shortcut: "",
             summary: "Color nouns red."),
        Item(group: "View", title: "Verbs", shortcut: "",
             summary: "Color verbs blue."),
        Item(group: "View", title: "Adjectives", shortcut: "",
             summary: "Color adjectives brown."),
        Item(group: "View", title: "Adverbs", shortcut: "",
             summary: "Color adverbs magenta."),
        Item(group: "View", title: "Conjunctions", shortcut: "",
             summary: "Color conjunctions green."),
        Item(group: "View", title: "Style Check", shortcut: "⌥⇧⌘D",
             summary: "Strike fillers, clichés and redundancies in the editor. Preview and export stay clean."),
        Item(group: "View", title: "Fillers", shortcut: "",
             summary: "Strike filler phrases such as “actually” and “pretty much”."),
        Item(group: "View", title: "Redundancies", shortcut: "",
             summary: "Strike redundant phrases such as “end result”."),
        Item(group: "View", title: "Clichés", shortcut: "",
             summary: "Strike clichés such as “think outside the box”."),
        Item(group: "View", title: "Authorship", shortcut: "⇧⌘A",
             summary: "Same as Show Authorship: color text by who wrote it."),
        Item(group: "View", title: "Word Count", shortcut: "⇧⌘C",
             summary: "Toggle the word count and reading time at the bottom of the window."),
        Item(group: "View", title: "Enter Full Screen", shortcut: "⌃⌘F",
             summary: "Expand the window to fill the screen."),
    ]

    static func matching(_ query: String) -> [Item] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return items }
        return items.filter { item in
            [item.group, item.title, item.shortcut, item.summary].contains {
                $0.localizedStandardContains(needle)
            }
        }
    }

    static func rows(matching query: String) -> [Row] {
        var rows: [Row] = []
        var current: String?
        for item in matching(query) {
            if item.group != current {
                rows.append(.group(item.group))
                current = item.group
            }
            rows.append(.command(item))
        }
        return rows
    }
}
