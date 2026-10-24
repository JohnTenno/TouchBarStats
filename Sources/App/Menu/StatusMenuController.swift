import AppKit

/// Menu bar icon with "Settings…" and "Quit"; shown or hidden according to Settings.
final class StatusMenuController: NSObject, SettingsObserver {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let onOpenSettings: () -> Void

    init(onOpenSettings: @escaping () -> Void) {
        self.onOpenSettings = onOpenSettings
        super.init()
        statusItem.button?.image = NSImage(systemSymbolName: "gauge.with.dots.needle.33percent",
                                           accessibilityDescription: "TouchBarStats")
        statusItem.menu = makeMenu()
    }

    func settingsDidChange(_ settings: AppSettings) {
        statusItem.isVisible = settings.showsMenuBarIcon
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        let settings = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit TouchBarStats", action: #selector(NSApplication.terminate(_:)),
                                keyEquivalent: "q"))
        return menu
    }

    @objc private func openSettings() {
        onOpenSettings()
    }
}
