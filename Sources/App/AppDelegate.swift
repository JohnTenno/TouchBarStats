import AppKit

/// Starts the monitors and the Touch Bar once the app finishes launching;
/// also applies the sampling interval from Settings and opens Settings when the app is reopened.
final class AppDelegate: NSObject, NSApplicationDelegate, SettingsObserver {
    private let monitor: SystemMonitor
    private let claudeMonitor: ClaudeUsageMonitor
    private let coordinator: TouchBarCoordinator
    private let settingsWindow: SettingsWindowController

    init(monitor: SystemMonitor, claudeMonitor: ClaudeUsageMonitor, coordinator: TouchBarCoordinator,
         settingsWindow: SettingsWindowController) {
        self.monitor = monitor
        self.claudeMonitor = claudeMonitor
        self.coordinator = coordinator
        self.settingsWindow = settingsWindow
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        coordinator.install()
        monitor.start()
        claudeMonitor.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor.stop()
        claudeMonitor.stop()
    }

    /// Opening the app while it is already running (Finder, Spotlight, `open`) shows Settings.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        settingsWindow.show()
        return false
    }

    func settingsDidChange(_ settings: AppSettings) {
        monitor.setInterval(settings.refreshInterval)
    }
}
