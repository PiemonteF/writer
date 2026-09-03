import AppKit

final class LibraryViewController: NSViewController {
    private let outline = NSOutlineView()
    private let search = NSSearchField()
    private var root = LibraryNode(url: Preferences.shared.libraryURL, isDirectory: true)
    private var visible: [LibraryNode] = []
    private var watcher: DispatchSourceFileSystemObject?
    private var reloadWork: DispatchWorkItem?

    override func loadView() {
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("name"))
        column.resizingMask = .autoresizingMask
        outline.addTableColumn(column)
        outline.outlineTableColumn = column
        outline.headerView = nil
        outline.style = .sourceList
        outline.rowSizeStyle = .default
        outline.floatsGroupRows = false
        outline.dataSource = self
        outline.delegate = self
        outline.target = self
        outline.action = #selector(rowClicked)
        outline.indentationPerLevel = 12

        let scroll = NSScrollView()
        scroll.documentView = outline
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        scroll.drawsBackground = false
        scroll.translatesAutoresizingMaskIntoConstraints = false

        search.placeholderString = "Search"
        search.controlSize = .small
        search.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        search.target = self
        search.action = #selector(searchChanged)
        search.translatesAutoresizingMaskIntoConstraints = false
        (search.cell as? NSSearchFieldCell)?.sendsSearchStringImmediately = true

        let container = NSView()
        container.addSubview(search)
        container.addSubview(scroll)
        NSLayoutConstraint.activate([
            search.topAnchor.constraint(equalTo: container.safeAreaLayoutGuide.topAnchor, constant: 8),
            search.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            search.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            scroll.topAnchor.constraint(equalTo: search.bottomAnchor, constant: 8),
            scroll.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            container.widthAnchor.constraint(greaterThanOrEqualToConstant: 180),
        ])
        view = container
        NotificationCenter.default.addObserver(self, selector: #selector(preferencesDidChange), name: .preferencesDidChange, object: nil)
        reload()
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        reload()
    }

    func reload() {
        let url = Preferences.shared.libraryURL
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        if root.url != url { root = LibraryNode(url: url, isDirectory: true) } else { root.reload() }
        watch(url)
        refreshVisible()
    }

    private func refreshVisible() {
        let query = search.stringValue.trimmingCharacters(in: .whitespaces)
        visible = query.isEmpty ? root.children : root.matching(query)
        outline.reloadData()
        if !query.isEmpty { outline.expandItem(nil, expandChildren: true) }
    }

    private func watch(_ url: URL) {
        watcher?.cancel()
        let descriptor = open(url.path, O_EVTONLY)
        guard descriptor >= 0 else { return }
        let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: descriptor, eventMask: [.write, .rename, .delete], queue: .main)
        source.setEventHandler { [weak self] in self?.scheduleReload() }
        source.setCancelHandler { close(descriptor) }
        source.resume()
        watcher = source
    }

    private func scheduleReload() {
        reloadWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.root.reload()
            self?.refreshVisible()
        }
        reloadWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
    }

    @objc private func preferencesDidChange() { reload() }

    @objc private func searchChanged() { refreshVisible() }

    @objc private func rowClicked() {
        guard let node = outline.item(atRow: outline.clickedRow) as? LibraryNode, node.isDirectory else { return }
        if outline.isItemExpanded(node) { outline.collapseItem(node) } else { outline.expandItem(node) }
    }

    func outlineViewSelectionDidChange(_ notification: Notification) {
        guard let node = outline.item(atRow: outline.selectedRow) as? LibraryNode, !node.isDirectory else { return }
        let current = view.window?.windowController?.document as? Document
        guard current?.fileURL != node.url else { return }
        NSDocumentController.shared.openDocument(withContentsOf: node.url, display: true) { _, _, _ in
            if let current, current.fileURL == nil, !current.isDocumentEdited {
                current.close()
            }
        }
    }
}

extension LibraryViewController: NSOutlineViewDataSource, NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        item == nil ? visible.count : ((item as? LibraryNode)?.children.count ?? 0)
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        item == nil ? visible[index] : (item as! LibraryNode).children[index]
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        (item as? LibraryNode)?.isDirectory ?? false
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let node = item as? LibraryNode else { return nil }
        let identifier = NSUserInterfaceItemIdentifier("cell")
        let cell = outlineView.makeView(withIdentifier: identifier, owner: nil) as? NSTableCellView ?? makeCell(identifier)
        cell.textField?.stringValue = node.name
        cell.imageView?.image = NSImage(systemSymbolName: node.isDirectory ? "folder" : "doc.text", accessibilityDescription: nil)
        return cell
    }

    private func makeCell(_ identifier: NSUserInterfaceItemIdentifier) -> NSTableCellView {
        let cell = NSTableCellView()
        cell.identifier = identifier
        let image = NSImageView()
        let text = NSTextField(labelWithString: "")
        text.lineBreakMode = .byTruncatingTail
        text.font = NSFont.systemFont(ofSize: 13)
        cell.imageView = image
        cell.textField = text
        cell.addSubview(image)
        cell.addSubview(text)
        image.translatesAutoresizingMaskIntoConstraints = false
        text.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            image.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 2),
            image.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
            image.widthAnchor.constraint(equalToConstant: 18),
            text.leadingAnchor.constraint(equalTo: image.trailingAnchor, constant: 6),
            text.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -4),
            text.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
        ])
        return cell
    }
}
