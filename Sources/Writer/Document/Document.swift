import AppKit

final class Document: NSDocument {
    var text = ""
    var authorship = Authorship.selfTyped(length: 0)

    override class var autosavesInPlace: Bool { true }

    override func makeWindowControllers() {
        addWindowController(EditorWindowController(document: self))
    }

    override func data(ofType typeName: String) throws -> Data {
        if let editor {
            text = editor.textView.string
            authorship = editor.authorship
        }
        return Data(AnnotationBlock.render(body: text, authorship: authorship).utf8)
    }

    override func read(from data: Data, ofType typeName: String) throws {
        guard let decoded = String(data: data, encoding: .utf8) else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadInapplicableStringEncodingError)
        }
        let parsed = AnnotationBlock.parse(decoded)
        text = parsed.body
        authorship = parsed.authorship
        editor?.load(text, authorship: authorship)
    }

    private var editor: EditorViewController? {
        (windowControllers.first as? EditorWindowController)?.editor
    }
}
