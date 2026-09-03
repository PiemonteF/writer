import AppKit

final class EditorWindowController: NSWindowController {
    let editor: EditorViewController

    init(document: Document) {
        editor = EditorViewController(text: document.text)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 820, height: 900),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false)
        window.titlebarAppearsTransparent = true
        window.contentViewController = editor
        window.minSize = NSSize(width: 400, height: 300)
        window.center()
        super.init(window: window)
        shouldCascadeWindows = true
        windowFrameAutosaveName = "EditorWindow"
    }

    required init?(coder: NSCoder) { fatalError("not supported") }
}
