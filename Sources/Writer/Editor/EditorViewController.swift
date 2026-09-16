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
    private var partsWork: DispatchWorkItem?
    private var partSpans: [PartOfSpeechSpan] = []
    private var partSpansText = ""
    private var styleWork: DispatchWorkItem?
    private var styleSpans: [StyleSpan] = []
    private var styleSpansText = ""
    private var prefs: Preferences { .shared }
    var authorship: Authorship
    var onTextChange: (() -> Void)?

    init(text: String, authorship loaded: Authorship? = nil) {
        let container = NSTextContainer(size: NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude))
        container.widthTracksTextView = false
        container.lineFragmentPadding = 0
        layoutManager.addTextContainer(container)
        storage.addLayoutManager(layoutManager)
        textView = EditorTextView(frame: .zero, textContainer: container)
        theme = Theme.make(.shared, dark: false)
        authorship = loaded ?? .selfTyped(length: (text as NSString).length)
        super.init(nibName: nil, bundle: nil)
        storage.delegate = self
        textView.delegate = self
        textView.allowsUndo = false
        textView.suppressAuthorship = true
        textView.string = text
        textView.suppressAuthorship = false
        textView.allowsUndo = true
        authorship = loaded ?? .selfTyped(length: storage.length)
        textView.setSelectedRange(NSRange(location: 0, length: 0))
        textView.copySlice = { [weak self] in
            guard let self else { return Authorship.selfTyped(length: 0) }
            let range = self.textView.selectedRange()
            guard range.length > 0, NSMaxRange(range) <= self.authorship.length else {
                return Authorship.selfTyped(length: 0)
            }
            return self.authorship.slice(range)
        }
        textView.styleRangeAt = { [weak self] location in
            self?.styleSpans.first { NSLocationInRange(location, $0.range) }?.range
        }
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
        root.frame = NSRect(x: 0, y: 0, width: 760, height: 720)
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

    func load(_ text: String, authorship loaded: Authorship? = nil) {
        textView.allowsUndo = false
        textView.suppressAuthorship = true
        textView.string = text
        textView.setSelectedRange(NSRange(location: 0, length: 0))
        textView.suppressAuthorship = false
        textView.allowsUndo = true
        authorship = loaded ?? .selfTyped(length: storage.length)
        rehighlightAll()
        scheduleParts()
        scheduleStyle()
        applyOverlay()
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
        updateContentInsets()
        rehighlightAll()
        scheduleParts()
        scheduleStyle()
        applyOverlay()
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

    private func updateContentInsets() {
        let insets = NSEdgeInsets(top: view.safeAreaInsets.top, left: 0, bottom: prefs.showStats ? StatsBar.height : 0, right: 0)
        if scrollView.contentInsets.top != insets.top || scrollView.contentInsets.bottom != insets.bottom {
            scrollView.contentInsets = insets
        }
    }

    private func updateInsets() {
        updateContentInsets()
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

    private func applyOverlay() {
        let full = NSRange(location: 0, length: storage.length)
        layoutManager.removeTemporaryAttribute(.foregroundColor, forCharacterRange: full)
        layoutManager.removeTemporaryAttribute(.strikethroughStyle, forCharacterRange: full)
        layoutManager.removeTemporaryAttribute(.strikethroughColor, forCharacterRange: full)
        let literal = spans.filter { [.code, .codeBlock, .url, .markup].contains($0.style) }.map(\.range)
        if prefs.showAuthorship {
            applyAuthorshipOverlay(in: full)
        } else if partSpansText == storage.string {
            for span in partSpans where NSMaxRange(span.range) <= full.length
                && !literal.contains(where: { NSIntersectionRange($0, span.range).length > 0 }) {
                layoutManager.addTemporaryAttribute(.foregroundColor, value: theme.partColors[span.part]!, forCharacterRange: span.range)
            }
        }
        if styleSpansText == storage.string {
            let strike = NSUnderlineStyle.single.rawValue
            for span in styleSpans where NSMaxRange(span.range) <= full.length
                && !literal.contains(where: { NSIntersectionRange($0, span.range).length > 0 }) {
                layoutManager.addTemporaryAttribute(.foregroundColor, value: theme.dimmedText, forCharacterRange: span.range)
                layoutManager.addTemporaryAttribute(.strikethroughStyle, value: strike, forCharacterRange: span.range)
                layoutManager.addTemporaryAttribute(.strikethroughColor, value: theme.dimmedText, forCharacterRange: span.range)
            }
        }
        guard let focus = FocusRange.range(mode: prefs.focusMode, caret: textView.selectedRange().location, in: storage.string as NSString)
        else { return }
        let before = NSRange(location: 0, length: focus.location)
        let after = NSRange(location: NSMaxRange(focus), length: full.length - NSMaxRange(focus))
        for range in [before, after] where range.length > 0 {
            layoutManager.addTemporaryAttribute(.foregroundColor, value: theme.dimmedText, forCharacterRange: range)
        }
    }

    private func applyAuthorshipOverlay(in full: NSRange) {
        let dark = isDark
        var aiWord = 0
        let source = storage.string as NSString
        for (range, author) in authorship.spans() where range.length > 0 && NSMaxRange(range) <= full.length {
            switch author {
            case .ai:
                let fallback = theme.authorshipColor(for: .ai, wordIndex: aiWord, dark: dark)
                layoutManager.addTemporaryAttribute(.foregroundColor, value: fallback, forCharacterRange: range)
                source.enumerateSubstrings(in: range, options: .byWords) { _, _, enclosing, _ in
                    let color = self.theme.authorshipColor(for: .ai, wordIndex: aiWord, dark: dark)
                    aiWord += 1
                    self.layoutManager.addTemporaryAttribute(.foregroundColor, value: color, forCharacterRange: enclosing)
                }
            default:
                let color = theme.authorshipColor(for: author, wordIndex: 0, dark: dark)
                layoutManager.addTemporaryAttribute(.foregroundColor, value: color, forCharacterRange: range)
            }
        }
    }

    private func centerCaret() {
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
        let clip = scrollView.contentView
        let midY = line.midY + textView.textContainerInset.height
        let target = max(0, min(midY - clip.bounds.height / 2, textView.frame.height - clip.bounds.height))
        clip.scroll(to: NSPoint(x: 0, y: target))
        scrollView.reflectScrolledClipView(clip)
    }

    private func scheduleParts() {
        partsWork?.cancel()
        let parts = prefs.highlightedParts
        let text = storage.string
        guard !parts.isEmpty else {
            partSpans = []
            partSpansText = ""
            return
        }
        let work = DispatchWorkItem { [weak self] in
            let spans = PartsOfSpeech.spans(in: text, parts: parts)
            DispatchQueue.main.async {
                guard let self, self.storage.string == text else { return }
                self.partSpans = spans
                self.partSpansText = text
                self.applyOverlay()
            }
        }
        partsWork = work
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.3, execute: work)
    }

    private func scheduleStyle() {
        styleWork?.cancel()
        let kinds = prefs.styleChecks
        let text = storage.string
        guard !kinds.isEmpty else {
            styleSpans = []
            styleSpansText = ""
            return
        }
        let work = DispatchWorkItem { [weak self] in
            let spans = StyleCheck.spans(in: text, kinds: kinds)
            DispatchQueue.main.async {
                guard let self, self.storage.string == text else { return }
                self.styleSpans = spans
                self.styleSpansText = text
                self.applyOverlay()
            }
        }
        styleWork = work
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.3, execute: work)
    }

    private func scheduleStats() {
        statsWork?.cancel()
        let text = storage.string
        let theme = theme
        let you: Int? = prefs.showAuthorship
            ? Int((authorship.ownedRatio(in: text as NSString) * 100).rounded())
            : nil
        let work = DispatchWorkItem { [weak self] in
            let stats = TextStatistics.compute(text)
            DispatchQueue.main.async { self?.statsBar.update(stats, theme: theme, youPercent: you) }
        }
        statsWork = work
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.2, execute: work)
    }

    @IBAction func pasteAsAI(_ sender: Any?) { paste(as: .ai) }
    @IBAction func pasteAsMine(_ sender: Any?) { paste(as: .selfTyped) }
    @IBAction func pasteAsReference(_ sender: Any?) { paste(as: .reference) }
    @IBAction func markAsAI(_ sender: Any?) { markSelection(as: .ai) }
    @IBAction func markAsMine(_ sender: Any?) { markSelection(as: .selfTyped) }
    @IBAction func markAsReference(_ sender: Any?) { markSelection(as: .reference) }

    private func paste(as author: Author) {
        textView.attributionLocked = true
        textView.inputAttribution = author
        textView.paste(nil)
    }

    private func markSelection(as author: Author) {
        let range = textView.selectedRange()
        guard range.length > 0, NSMaxRange(range) <= authorship.length else { return }
        registerAuthorshipUndo()
        authorship.mark(range, as: author)
        applyOverlay()
        scheduleStats()
    }

    private func registerAuthorshipUndo() {
        guard let undo = undoManager else { return }
        let previous = authorship
        undo.registerUndo(withTarget: self) { $0.restoreAuthorship(previous) }
    }

    private func restoreAuthorship(_ value: Authorship) {
        registerAuthorshipUndo()
        authorship = value
        applyOverlay()
        scheduleStats()
    }
}

extension EditorViewController: NSTextStorageDelegate {
    func textStorage(_ storage: NSTextStorage, didProcessEditing editedMask: NSTextStorageEditActions, range editedRange: NSRange, changeInLength delta: Int) {
        guard editedMask.contains(.editedCharacters) else { return }
        applyAttribution(editedRange: editedRange, delta: delta)
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

    private func applyAttribution(editedRange: NSRange, delta: Int) {
        guard !textView.suppressAuthorship else { return }
        guard undoManager?.isUndoing != true, undoManager?.isRedoing != true else { return }
        registerAuthorshipUndo()
        let newLength = editedRange.length
        let oldLength = newLength - delta
        if authorship.length != storage.length - delta {
            authorship = .selfTyped(length: max(0, storage.length - delta))
        }
        if let slice = textView.attributedSlice, slice.length == newLength {
            authorship.delete(editedRange.location, oldLength)
            authorship.splice(slice, at: editedRange.location)
        } else {
            authorship.replace(
                location: editedRange.location,
                oldLength: oldLength,
                newLength: newLength,
                with: textView.inputAttribution)
        }
        if authorship.length != storage.length {
            authorship = .selfTyped(length: storage.length)
        }
    }
}

extension EditorViewController: NSTextViewDelegate {
    func undoManager(for view: NSTextView) -> UndoManager? {
        (self.view.window?.windowController?.document as? NSDocument)?.undoManager
    }

    func textDidChange(_ notification: Notification) {
        applyOverlay()
        scheduleParts()
        scheduleStyle()
        scheduleStats()
        onTextChange?()
        if prefs.typewriter { centerCaret() }
    }

    func textViewDidChangeSelection(_ notification: Notification) {
        applyOverlay()
        if prefs.typewriter { centerCaret() }
    }

    func textView(_ view: NSTextView, menu: NSMenu, for event: NSEvent, at charIndex: Int) -> NSMenu? {
        menu.addItem(.separator())
        let authors = NSMenu(title: "Authors")
        for (title, selector) in [
            ("Paste as AI", #selector(pasteAsAI)),
            ("Paste as Mine", #selector(pasteAsMine)),
            ("Paste as Reference", #selector(pasteAsReference)),
        ] as [(String, Selector)] {
            let item = NSMenuItem(title: title, action: selector, keyEquivalent: "")
            item.target = self
            authors.addItem(item)
        }
        authors.addItem(.separator())
        for (title, selector) in [
            ("Mark Selection as AI", #selector(markAsAI)),
            ("Mark Selection as Mine", #selector(markAsMine)),
            ("Mark Selection as Reference", #selector(markAsReference)),
        ] as [(String, Selector)] {
            let item = NSMenuItem(title: title, action: selector, keyEquivalent: "")
            item.target = self
            authors.addItem(item)
        }
        let wrap = NSMenuItem(title: "Authors", action: nil, keyEquivalent: "")
        wrap.submenu = authors
        menu.addItem(wrap)
        return menu
    }
}

extension EditorViewController: NSMenuItemValidation {
    func validateMenuItem(_ item: NSMenuItem) -> Bool {
        switch item.action {
        case #selector(pasteAsAI), #selector(pasteAsMine), #selector(pasteAsReference):
            return NSPasteboard.general.string(forType: .string) != nil
        case #selector(markAsAI), #selector(markAsMine), #selector(markAsReference):
            return textView.selectedRange().length > 0
        default:
            return true
        }
    }
}

private final class AppearanceObservingView: NSView {
    var onAppearanceChange: (() -> Void)?

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        onAppearanceChange?()
    }
}
