import AppKit

final class Document: NSDocument {
    var text = ""

    override class var autosavesInPlace: Bool { true }

    override func makeWindowControllers() {
        addWindowController(EditorWindowController(document: self))
    }

    override func data(ofType typeName: String) throws -> Data {
        if let editor { text = editor.textView.string }
        return Data(text.utf8)
    }

    override func read(from data: Data, ofType typeName: String) throws {
        guard let decoded = String(data: data, encoding: .utf8) else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadInapplicableStringEncodingError)
        }
        text = decoded
        editor?.load(text)
    }

    private var editor: EditorViewController? {
        (windowControllers.first as? EditorWindowController)?.editor
    }
}
