import AppKit

struct MarkdownHeading: Equatable {
    let title: String
    let level: Int
    let range: NSRange

    static func headings(in text: String, spans: [Span]) -> [MarkdownHeading] {
        let source = text as NSString
        return spans.compactMap { span in
            guard case .heading(let level) = span.style, level <= 3 else { return nil }
            let title = source.substring(with: span.range)
                .replacingOccurrences(of: #"^\s*#{1,3}\s*|\s+#+\s*$"#, with: "", options: .regularExpression)
            return MarkdownHeading(title: title.isEmpty ? "Untitled heading" : title, level: level, range: span.range)
        }
    }
}

final class HeadingTree: NSView {
    private let scrollView = NSScrollView()
    private let stack = FlippedHeadingStack()
    private var tracking: NSTrackingArea?
    private var buttons: [NSButton] = []
    var onSelect: ((Int) -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = 8
        layer?.borderWidth = 1
        updateContainerColors()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 3
        stack.edgeInsets = NSEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        scrollView.documentView = stack
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.widthAnchor.constraint(equalTo: scrollView.contentView.widthAnchor).isActive = true
        alphaValue = 0.25
        setAccessibilityLabel("Heading tree")
        scrollView.setAccessibilityLabel("Heading tree")
    }

    required init?(coder: NSCoder) { fatalError("not supported") }

    func update(_ headings: [MarkdownHeading]) {
        for button in buttons { stack.removeArrangedSubview(button); button.removeFromSuperview() }
        buttons = headings.enumerated().map { index, heading in
            let button = HeadingButton(title: String(repeating: "    ", count: heading.level - 1) + heading.title,
                                  target: self, action: #selector(selectHeading(_:)))
            button.tag = index
            button.isBordered = false
            button.alignment = .left
            button.font = .systemFont(ofSize: 11)
            button.lineBreakMode = .byTruncatingTail
            button.toolTip = heading.title
            button.setAccessibilityLabel("Heading \(heading.level): \(heading.title)")
            stack.addArrangedSubview(button)
            button.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -16).isActive = true
            return button
        }
    }

    func highlight(_ index: Int?) {
        for button in buttons {
            button.contentTintColor = button.tag == index ? .controlAccentColor : .secondaryLabelColor
            button.font = .systemFont(ofSize: 11, weight: button.tag == index ? .bold : .regular)
        }
    }

    @objc private func selectHeading(_ sender: NSButton) { onSelect?(sender.tag) }

    private func updateContainerColors() {
        effectiveAppearance.performAsCurrentDrawingAppearance {
            layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
            layer?.borderColor = NSColor.separatorColor.cgColor
        }
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateContainerColors()
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let tracking { removeTrackingArea(tracking) }
        let area = NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self)
        addTrackingArea(area)
        tracking = area
    }

    private func fade(to opacity: CGFloat) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? 0 : 0.18
            animator().alphaValue = opacity
        }
    }

    override func mouseEntered(with event: NSEvent) { fade(to: 1) }
    override func mouseExited(with event: NSEvent) { fade(to: 0.25) }
}

private final class FlippedHeadingStack: NSStackView {
    override var isFlipped: Bool { true }
}

private final class HeadingButton: NSButton {
    override func resetCursorRects() {
        super.resetCursorRects()
        addCursorRect(bounds, cursor: .pointingHand)
    }
}
