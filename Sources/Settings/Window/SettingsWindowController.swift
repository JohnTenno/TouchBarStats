import AppKit
import SwiftUI

/// Settings window. The app has no Dock icon, so it is activated by hand to bring the window to the front.
final class SettingsWindowController: NSWindowController {
    convenience init(store: SettingsStore, library: MediaLibrary) {
        let window = NSWindow(contentViewController: NSHostingController(rootView: SettingsView(store: store, library: library)))
        window.title = "TouchBarStats Settings"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.center()
        self.init(window: window)
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }
}
