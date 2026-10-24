import AppKit

/// Claude logo + weekly %, without a button background so it takes the same space as a metric.
/// Tappable like a button thanks to a gesture recognizer.
final class ClaudeBadgeView: NSStackView {
    private let label = NSTextField(labelWithString: "--")
    private let onTap: () -> Void

    init(fontSize: CGFloat, onTap: @escaping () -> Void) {
        self.onTap = onTap
        super.init(frame: .zero)
        orientation = .horizontal
        spacing = 3
        let logo = NSImageView(image: ClaudeLogo.image(side: 64) ?? NSImage())
        logo.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            logo.widthAnchor.constraint(equalToConstant: fontSize + 2),
            logo.heightAnchor.constraint(equalToConstant: fontSize + 2),
        ])
        label.font = .monospacedDigitSystemFont(ofSize: fontSize, weight: .medium)
        addArrangedSubview(logo)
        addArrangedSubview(label)

        let tap = NSClickGestureRecognizer(target: self, action: #selector(handleTap))
        tap.allowedTouchTypes = .direct
        addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) {
        fatalError("ClaudeBadgeView is not used from Interface Builder")
    }

    func show(_ text: String, color: NSColor) {
        label.stringValue = text
        label.textColor = color
    }

    @objc private func handleTap() {
        onTap()
    }
}
