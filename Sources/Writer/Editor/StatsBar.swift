import AppKit

final class StatsBar: NSView {
    static let height: CGFloat = 28

    private let label = NSTextField(labelWithString: "")

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        label.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        label.alignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            heightAnchor.constraint(equalToConstant: Self.height),
        ])
    }

    required init?(coder: NSCoder) { fatalError("not supported") }

    func update(_ stats: TextStatistics, theme: Theme) {
        label.stringValue = stats.summary
        label.textColor = theme.dimmedText
    }
}
