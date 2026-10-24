/// Observer: notified every time the user changes something in Settings.
protocol SettingsObserver: AnyObject {
    func settingsDidChange(_ settings: AppSettings)
}
