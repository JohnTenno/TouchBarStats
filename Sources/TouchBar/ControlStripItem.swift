import AppKit

/// Control Strip button: the icon chosen in Settings (image, GIF or video; the app icon by default)
/// centered in its slot; tapping it opens the metrics.
/// The Control Strip slot is fixed (~58 pt), so the metrics live in the detail view.
final class ControlStripItem: NSObject, SettingsObserver {
    private static let iconSide: CGFloat = 26
    private static let defaultIcon = Bundle.main.url(forResource: "TouchBarIcon", withExtension: "png")

    let touchBarItem = NSCustomTouchBarItem(identifier: .init("com.tenno.TouchBarStats.strip"))
    var onTap: (() -> Void)?
    private let icon = MediaView(size: NSSize(width: iconSide, height: iconSide),
                                 cornerRadius: iconSide * 0.25)

    override init() {
        super.init()
        touchBarItem.view = makeView()
    }

    func settingsDidChange(_ settings: AppSettings) {
        let custom = settings.stripIcon.path.map { URL(fileURLWithPath: $0) }
        icon.display(custom ?? Self.defaultIcon, fit: custom == nil ? .fill : settings.stripIcon.fit)
    }

    private func makeView() -> NSView {
        let container = NSView()
        container.addSubview(icon)
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])

        let tap = NSClickGestureRecognizer(target: self, action: #selector(handleTap))
        tap.allowedTouchTypes = .direct
        container.addGestureRecognizer(tap)
        return container
    }

    @objc private func handleTap() {
        onTap?()
    }
}
