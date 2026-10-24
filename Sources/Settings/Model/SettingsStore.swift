import Combine
import Foundation

/// Observer pattern subject for settings: loads them from JSON, saves them on every change
/// and notifies the Touch Bar so it updates instantly. Also feeds the SwiftUI window.
final class SettingsStore: ObservableObject {
    @Published var settings: AppSettings {
        didSet {
            guard settings != oldValue else { return }
            save()
            observers.forEach { $0.settingsDidChange(settings) }
        }
    }

    private let file: URL
    private var observers: [SettingsObserver] = []

    init(file: URL) {
        self.file = file
        settings = Self.load(from: file)
    }

    /// Adds the observer and immediately sends it the current settings.
    func add(_ observer: SettingsObserver) {
        observers.append(observer)
        observer.settingsDidChange(settings)
    }

    func resetToDefaults() {
        settings = .defaults
    }

    private func save() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
            try encoder.encode(settings).write(to: file, options: .atomic)
        } catch {
            NSLog("TouchBarStats: could not save settings: \(error)")
        }
    }

    private static func load(from file: URL) -> AppSettings {
        guard let data = try? Data(contentsOf: file) else { return .defaults }
        return (try? JSONDecoder().decode(AppSettings.self, from: data)) ?? .defaults
    }
}
