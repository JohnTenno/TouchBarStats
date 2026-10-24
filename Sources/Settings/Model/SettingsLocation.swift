import Foundation

/// Where the user's configuration lives: the settings JSON and the copies of their images and videos.
struct SettingsLocation {
    let directory: URL

    /// ~/Library/Application Support/TouchBarStats
    static let standard = SettingsLocation(directory: FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("TouchBarStats", isDirectory: true))

    var settingsFile: URL {
        directory.appendingPathComponent("settings.json")
    }

    var mediaDirectory: URL {
        directory.appendingPathComponent("Media", isDirectory: true)
    }
}
