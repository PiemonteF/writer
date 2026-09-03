import AppKit

final class EditorViewController: NSViewController {
    let textView: EditorTextView
    private let scrollView = NSScrollView()
    private let statsBar = StatsBar()
    private let storage = NSTextStorage()
    private let layoutManager = NSLayoutManager()
    private var theme: Theme
    private var spans: [Span] = []
    private var statsWork: DispatchWorkItem?
    private var prefs: Preferences { .shared }

    init(text: String) {
        let container = NSTextContainer(size: NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude))
        container.widthTracksTextView = false
        container.lineFragmentPadding = 0
        layoutManager.addTextContainer(container)
        storage.addLayoutManager(layoutManager)
        textView = EditorTextView(frame: .zero, textContainer: container)
        theme = Theme.make(.shared, dark: false)
        super.init(nibName: nil, bundle: nil)
        storage.delegate = self
        textView.delegate = self
        textView.string = text
        textView.setSelectedRange(NSRange(location: 0, length: 0))
        preferredContentSize = NSSize(width: 820, height: 900)
    }

    required init?(coder: NSCoder) { fatalError("not supported") }

    override func loadView() {
        textView.isRichText = false
        textView.allowsUndo = true
        textView.usesFontPanel = false
        textView.usesFindBar = true
        textView.isIncrementalSearchingEnabled = true
        textView.isContinuousSpellCheckingEnabled = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.drawsBackground = false

        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.scrollerStyle = .overlay
        scrollView.drawsBackground = false
        scrollView.automaticallyAdjustsContentInsets = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        statsBar.translatesAutoresizingMaskIntoConstraints = false

        let root = AppearanceObservingView()
        root.wantsLayer = true
        root.onAppearanceChange = { [weak self] in self?.applyTheme() }
        root.addSubview(scrollView)
        root.addSubview(statsBar)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: root.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: root.bottomAnchor),
            statsBar.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            statsBar.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            statsBar.bottomAnchor.constraint(equalTo: root.bottomAnchor),
        ])
        root.frame = NSRect(origin: .zero, size: preferredContentSize)
        view = root
        NotificationCenter.default.addObserver(
            self, selector: #selector(preferencesDidChange), name: .preferencesDidChange, object: nil)
        applyTheme()
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        view.window?.makeFirstResponder(textView)
        applyTheme()
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        updateInsets()
    }

    func load(_ text: String) {
        textView.string = text
        textView.setSelectedRange(NSRange(location: 0, length: 0))
        rehighlightAll()
        applyFocus()
        scheduleStats()
    }

    @objc private func preferencesDidChange() {
        applyTheme()
    }

    private var isDark: Bool {
        view.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }

    private func applyTheme() {
        theme = Theme.make(prefs, dark: isDark)
        view.layer?.backgroundColor = theme.background.cgColor
        view.window?.backgroundColor = theme.background
        textView.insertionPointColor = theme.accent
        textView.selectedTextAttributes = [.backgroundColor: theme.accent.withAlphaComponent(0.25)]
        textView.typingAttributes = theme.baseAttributes
        statsBar.isHidden = !prefs.showStats
        statsBar.layer?.backgroundColor = theme.background.cgColor
        scrollView.contentInsets = NSEdgeInsets(top: 0, left: 0, bottom: prefs.showStats ? StatsBar.height : 0, right: 0)
        rehighlightAll()
        applyFocus()
        scheduleStats()
        view.needsLayout = true
        if prefs.typewriter { centerCaret() }
    }

    private func rehighlightAll() {
        spans = MarkdownHighlighter.spans(in: storage.string)
        storage.beginEditing()
        MarkdownHighlighter.apply(spans, to: storage, theme: theme, in: NSRange(location: 0, length: storage.length))
        storage.endEditing()
    }

    private func updateInsets() {
        let width = scrollView.contentView.bounds.width
        let visibleHeight = scrollView.contentView.bounds.height
        guard width > 0 else { return }
        let column = min(width - 48, theme.maxLineWidth)
        let horizontal = max(24, ((width - column) / 2).rounded(.down))
        let vertical = prefs.typewriter ? (visibleHeight / 2).rounded(.down) : 48
        let inset = NSSize(width: horizontal, height: vertical)
        if textView.textContainerInset != inset {
            textView.textContainerInset = inset
        }
        let containerWidth = width - 2 * horizontal
        if textView.textContainer?.size.width != containerWidth {
            textView.textContainer?.size = NSSize(width: containerWidth, height: CGFloat.greatestFiniteMagnitude)
        }
    }

    private func applyFocus() {
        let full = NSRange(location: 0, length: storage.length)
        layoutManager.removeTemporaryAttribute(.foregroundColor, forCharacterRange: full)
        guard let focus = FocusRange.range(mode: prefs.focusMode, caret: textView.selectedRange().location, in: storage.string as NSString)
        else { return }
        let before = NSRange(location: 0, length: focus.location)
        let after = NSRange(location: NSMaxRange(focus), length: full.length - NSMaxRange(focus))
        for range in [before, after] where range.length > 0 {
            layoutManager.addTemporaryAttribute(.foregroundColor, value: theme.dimmedText, forCharacterRange: range)
        }
    }

    private func centerCaret() {
        guard let container = textView.textContainer else { return }
        let caret = textView.selectedRange().location
        let glyphCount = layoutManager.numberOfGlyphs
        var line: NSRect
        if glyphCount == 0 {
            line = NSRect(x: 0, y: 0, width: 0, height: theme.font.pointSize * theme.lineHeightMultiple)
        } else if caret < storage.length {
            line = layoutManager.lineFragmentRect(forGlyphAt: layoutManager.glyphIndexForCharacter(at: caret), effectiveRange: nil)
        } else if !layoutManager.extraLineFragmentRect.isEmpty {
            line = layoutManager.extraLineFragmentRect
        } else {
            line = layoutManager.lineFragmentRect(forGlyphAt: glyphCount - 1, effectiveRange: nil)
        }
        _ = container
        let clip = scrollView.contentView
        let midY = line.midY + textView.textContainerInset.height
        let target = max(0, min(midY - clip.bounds.height / 2, textView.frame.height - clip.bounds.height))
        clip.scroll(to: NSPoint(x: 0, y: target))
        scrollView.reflectScrolledClipView(clip)
    }

    private func scheduleStats() {
        statsWork?.cancel()
        let text = storage.string
        let theme = theme
        let work = DispatchWorkItem { [weak self] in
            let stats = TextStatistics.compute(text)
            DispatchQueue.main.async { self?.statsBar.update(stats, theme: theme) }
        }
        statsWork = work
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.2, execute: work)
    }
}

extension EditorViewController: NSTextStorageDelegate {
    func textStorage(_ storage: NSTextStorage, willProcessEditing editedMask: NSTextStorageEditActions, range editedRange: NSRange, changeInLength delta: Int) {
        guard editedMask.contains(.editedCharacters) else { return }
        let text = storage.string as NSString
        let fresh = MarkdownHighlighter.spans(in: storage.string)
        let oldEditedEnd = NSMaxRange(editedRange) - delta
        var shifted = Set<Span>()
        for span in spans {
            if NSMaxRange(span.range) <= editedRange.location {
                shifted.insert(span)
            } else if span.range.location >= oldEditedEnd {
                shifted.insert(Span(range: NSRange(location: span.range.location + delta, length: span.range.length), style: span.style))
            }
        }
        var dirty = text.paragraphRange(for: editedRange)
        for span in shifted.symmetricDifference(fresh) where NSMaxRange(span.range) <= text.length {
            dirty = NSUnionRange(dirty, text.paragraphRange(for: span.range))
        }
        spans = fresh
        MarkdownHighlighter.apply(fresh, to: storage, theme: theme, in: dirty)
    }
}

extension EditorViewController: NSTextViewDelegate {
    func undoManager(for view: NSTextView) -> UndoManager? {
        (self.view.window?.windowController?.document as? NSDocument)?.undoManager
    }

    func textDidChange(_ notification: Notification) {
        applyFocus()
        scheduleStats()
        if prefs.typewriter { centerCaret() }
    }

    func textViewDidChangeSelection(_ notification: Notification) {
        applyFocus()
        if prefs.typewriter { centerCaret() }
    }
}

private final class AppearanceObservingView: NSView {
    var onAppearanceChange: (() -> Void)?

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        onAppearanceChange?()
    }
}
