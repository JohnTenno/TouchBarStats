import AppKit

/// Starts the monitors and the Touch Bar once the app finishes launching;
/// also applies the sampling interval from Settings and opens Settings when the app is reopened.
final class AppDelegate: NSObject, NSApplicationDelegate, SettingsObserver {
    private let monitor: SystemMonitor
    private let claudeMonitor: ClaudeUsageMonitor
    private let coordinator: TouchBarCoordinator
    private let settingsWindow: SettingsWindowController
    private var screenObservers: [NSObjectProtocol] = []

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
        let center = NSWorkspace.shared.notificationCenter
        screenObservers = [
            center.addObserver(forName: NSWorkspace.screensDidSleepNotification, object: nil, queue: .main) { [weak self] _ in
                self?.monitor.stop()
            },
            center.addObserver(forName: NSWorkspace.screensDidWakeNotification, object: nil, queue: .main) { [weak self] _ in
                self?.monitor.start()
            },
        ]
    }

    func applicationWillTerminate(_ notification: Notification) {
        screenObservers.forEach { NSWorkspace.shared.notificationCenter.removeObserver($0) }
        screenObservers.removeAll()
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
