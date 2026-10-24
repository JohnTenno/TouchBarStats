import SwiftUI

/// Root of the Settings window: each section edits part of AppSettings and the store saves and applies instantly.
struct SettingsView: View {
    @ObservedObject var store: SettingsStore
    let library: MediaLibrary

    var body: some View {
        Form {
            BarItemsSection(settings: $store.settings)
            StripIconSection(choice: $store.settings.stripIcon, library: library)
            MediaSection(settings: $store.settings, library: library)
            GeneralSection(settings: $store.settings, onReset: store.resetToDefaults)
        }
        .formStyle(.grouped)
        .frame(width: 520, height: 600)
    }
}
