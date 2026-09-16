import AppKit

final class CommandGuideController: NSWindowController, NSWindowDelegate {
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 640),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false)
        window.title = "Commands"
        window.minSize = NSSize(width: 420, height: 320)
        window.maxSize = NSSize(width: 640, height: 10_000)
        window.setFrameAutosaveName("CommandGuide")
        window.isReleasedWhenClosed = false
        self.init(window: window)
        window.delegate = self
        window.contentViewController = CommandGuideViewController()
        window.center()
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(sender)
        NSApp.activate(ignoringOtherApps: true)
        (window?.contentViewController as? CommandGuideViewController)?.focusSearch()
    }

    override func cancelOperation(_ sender: Any?) {
        close()
    }
}

final class CommandGuideViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, NSSearchFieldDelegate {
    private let search = NSSearchField()
    private let table = NSTableView()
    private let scroll = NSScrollView()
    private let empty = NSTextField(labelWithString: "No matching commands")
    private var rows: [CommandGuide.Row] = CommandGuide.rows(matching: "")
    private var theme = Theme.make(.shared, dark: false)

    override func loadView() {
        let root = AppearanceObservingGuideView()
        root.wantsLayer = true
        root.onAppearanceChange = { [weak self] in self?.applyTheme() }

        search.placeholderString = "Filter commands"
        search.delegate = self
        search.sendsSearchStringImmediately = true
        search.translatesAutoresizingMaskIntoConstraints = false
        search.setAccessibilityLabel("Filter commands")

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("command"))
        table.addTableColumn(column)
        table.headerView = nil
        table.delegate = self
        table.dataSource = self
        table.style = .plain
        table.rowSizeStyle = .custom
        table.allowsEmptySelection = true
        table.allowsMultipleSelection = false
        table.floatsGroupRows = false
        table.usesAlternatingRowBackgroundColors = false
        table.intercellSpacing = NSSize(width: 0, height: 2)
        table.setAccessibilityLabel("Commands")

        scroll.documentView = table
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        scroll.borderType = .noBorder
        scroll.drawsBackground = false
        scroll.translatesAutoresizingMaskIntoConstraints = false

        empty.alignment = .center
        empty.isHidden = true
        empty.translatesAutoresizingMaskIntoConstraints = false

        root.addSubview(search)
        root.addSubview(scroll)
        root.addSubview(empty)
        NSLayoutConstraint.activate([
            search.topAnchor.constraint(equalTo: root.safeAreaLayoutGuide.topAnchor, constant: 12),
            search.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 16),
            search.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -16),
            scroll.topAnchor.constraint(equalTo: search.bottomAnchor, constant: 10),
            scroll.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: root.bottomAnchor),
            empty.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            empty.centerYAnchor.constraint(equalTo: scroll.centerYAnchor),
        ])
        view = root
        NotificationCenter.default.addObserver(
            self, selector: #selector(applyTheme), name: .preferencesDidChange, object: nil)
        applyTheme()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        focusSearch()
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        if let column = table.tableColumns.first {
            column.width = max(200, table.bounds.width - 4)
        }
    }

    func focusSearch() {
        view.window?.makeFirstResponder(search)
    }

    @objc private func applyTheme() {
        let dark = view.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        theme = Theme.make(.shared, dark: dark)
        view.layer?.backgroundColor = theme.background.cgColor
        view.window?.backgroundColor = theme.background
        table.backgroundColor = theme.background
        empty.textColor = theme.dimmedText
        empty.font = .systemFont(ofSize: 13)
        table.reloadData()
    }

    func controlTextDidChange(_ obj: Notification) {
        rows = CommandGuide.rows(matching: search.stringValue)
        empty.isHidden = !rows.isEmpty
        table.reloadData()
        if !rows.isEmpty { table.scrollRowToVisible(0) }
    }

    func numberOfRows(in tableView: NSTableView) -> Int { rows.count }

    func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool {
        if case .group = rows[row] { return true }
        return false
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        switch rows[row] {
        case .group: return 28
        case .command: return 62
        }
    }

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        if case .command = rows[row] { return true }
        return false
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        switch rows[row] {
        case .group(let name):
            let wrap = NSView()
            let label = NSTextField(labelWithString: name)
            label.font = .systemFont(ofSize: 11, weight: .semibold)
            label.textColor = theme.dimmedText
            label.translatesAutoresizingMaskIntoConstraints = false
            wrap.addSubview(label)
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: 18),
                label.bottomAnchor.constraint(equalTo: wrap.bottomAnchor, constant: -4),
            ])
            return wrap
        case .command(let item):
            let cell = CommandRow()
            cell.apply(item, theme: theme)
            return cell
        }
    }
}

private final class CommandRow: NSView {
    private let title = NSTextField(labelWithString: "")
    private let shortcut = NSTextField(labelWithString: "")
    private let summary = NSTextField(labelWithString: "")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        title.lineBreakMode = .byTruncatingTail
        shortcut.alignment = .right
        summary.maximumNumberOfLines = 2
        summary.lineBreakMode = .byWordWrapping
        summary.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        for label in [title, shortcut, summary] {
            label.translatesAutoresizingMaskIntoConstraints = false
            addSubview(label)
        }
        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            title.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            shortcut.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            shortcut.centerYAnchor.constraint(equalTo: title.centerYAnchor),
            shortcut.leadingAnchor.constraint(greaterThanOrEqualTo: title.trailingAnchor, constant: 12),
            shortcut.widthAnchor.constraint(greaterThanOrEqualToConstant: 56),
            summary.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            summary.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            summary.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 2),
            summary.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -6),
        ])
    }

    required init?(coder: NSCoder) { fatalError("not supported") }

    func apply(_ item: CommandGuide.Item, theme: Theme) {
        title.stringValue = item.title
        title.font = .systemFont(ofSize: 13, weight: .medium)
        title.textColor = theme.text
        shortcut.stringValue = item.shortcut
        shortcut.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        shortcut.textColor = theme.markup
        shortcut.isHidden = item.shortcut.isEmpty
        summary.stringValue = item.summary
        summary.font = .systemFont(ofSize: 11)
        summary.textColor = theme.dimmedText
    }
}

private final class AppearanceObservingGuideView: NSView {
    var onAppearanceChange: (() -> Void)?

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        onAppearanceChange?()
    }
}
