import AppKit

/// Optional gear in the detail bar that opens the Settings window.
final class SettingsButtonItem: NSObject {
    let item = NSCustomTouchBarItem(identifier: .init("com.tenno.TouchBarStats.settings"))
    private let onTap: () -> Void

    init(onTap: @escaping () -> Void) {
        self.onTap = onTap
        super.init()
        let image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "Settings") ?? NSImage()
        item.view = NSButton(image: image, target: self, action: #selector(tapped))
    }

    @objc private func tapped() {
        onTap()
    }
}
