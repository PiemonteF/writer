import AppKit
import UniformTypeIdentifiers

final class EditorWindowController: NSWindowController {
    let editor: EditorViewController
    private let preview = PreviewViewController()
    private let library = LibraryViewController()
    private let split = NSSplitViewController()
    private let previewItem: NSSplitViewItem
    private let libraryItem: NSSplitViewItem
    private var exporter: PreviewViewController?

    init(document: Document) {
        editor = EditorViewController(text: document.text, authorship: document.authorship)
        previewItem = NSSplitViewItem(viewController: preview)
        previewItem.minimumThickness = 320
        previewItem.canCollapse = true
        previewItem.isCollapsed = true
        libraryItem = NSSplitViewItem(sidebarWithViewController: library)
        libraryItem.minimumThickness = 180
        libraryItem.maximumThickness = 360
        libraryItem.isCollapsed = !Preferences.shared.showLibrary
        let editorItem = NSSplitViewItem(viewController: editor)
        editorItem.minimumThickness = 360
        split.addSplitViewItem(libraryItem)
        split.addSplitViewItem(editorItem)
        split.addSplitViewItem(previewItem)
        split.splitView.dividerStyle = .thin

        let visible = NSScreen.main?.visibleFrame.size ?? NSSize(width: 1440, height: 900)
        let size = NSSize(width: min(760, visible.width - 40), height: min(720, visible.height - 60))
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false)
        window.titlebarAppearsTransparent = true
        window.contentViewController = split
        window.setContentSize(size)
        window.minSize = NSSize(width: 400, height: 300)
        window.center()
        super.init(window: window)
        shouldCascadeWindows = true
        windowFrameAutosaveName = "EditorWindowFrame"
        editor.onTextChange = { [weak self] in self?.refreshPreview() }
    }

    required init?(coder: NSCoder) { fatalError("not supported") }

    private var documentTitle: String {
        document.flatMap { ($0 as? NSDocument)?.displayName } ?? "Untitled"
    }

    private func refreshPreview(immediately: Bool = false) {
        guard !previewItem.isCollapsed || immediately else { return }
        preview.render(editor.textView.string, title: documentTitle, immediately: immediately)
    }

    @IBAction func togglePreview(_ sender: Any?) {
        let showing = previewItem.isCollapsed
        if showing {
            let width = max(window?.frame.width ?? 0, 1240)
            window?.setContentSize(NSSize(width: width, height: window?.contentView?.frame.height ?? 720))
            refreshPreview(immediately: true)
        }
        previewItem.animator().isCollapsed = !showing
    }

    @IBAction func toggleLibrary(_ sender: Any?) {
        let showing = libraryItem.isCollapsed
        Preferences.shared.showLibrary = showing
        libraryItem.animator().isCollapsed = !showing
    }

    @IBAction func copyHTML(_ sender: Any?) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(MarkdownRenderer.body(from: editor.textView.string), forType: .string)
    }

    @IBAction func exportHTML(_ sender: Any?) {
        save(as: .html) { [self] url in
            let css = (try? String(contentsOf: Bundle.main.resourceURL!.appendingPathComponent("preview.css"), encoding: .utf8)) ?? ""
            let html = MarkdownRenderer.document(from: editor.textView.string, title: documentTitle, stylesheet: .inline(css))
            try html.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    @IBAction func exportPDF(_ sender: Any?) {
        save(as: .pdf) { [self] url in
            let exporter = PreviewViewController()
            exporter.view.frame = NSRect(x: 0, y: 0, width: 794, height: 1123)
            exporter.render(editor.textView.string, title: documentTitle, immediately: true)
            self.exporter = exporter
            exporter.pdf { [weak self] result in
                self?.exporter = nil
                switch result {
                case .success(let data): try? data.write(to: url)
                case .failure(let error): NSAlert(error: error).runModal()
                }
            }
        }
    }

    private func save(as type: UTType, _ write: @escaping (URL) throws -> Void) {
        guard let window else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [type]
        panel.nameFieldStringValue = (documentTitle as NSString).deletingPathExtension
        panel.beginSheetModal(for: window) { response in
            guard response == .OK, let url = panel.url else { return }
            do { try write(url) } catch { NSAlert(error: error).runModal() }
        }
    }
}

extension EditorWindowController: NSMenuItemValidation {
    func validateMenuItem(_ item: NSMenuItem) -> Bool {
        if item.action == #selector(togglePreview) {
            item.state = previewItem.isCollapsed ? .off : .on
        }
        if item.action == #selector(toggleLibrary) {
            item.state = libraryItem.isCollapsed ? .off : .on
        }
        return true
    }
}
