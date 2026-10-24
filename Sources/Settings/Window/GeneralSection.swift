import AppKit
import SwiftUI

/// Sampling interval, menu bar icon, reset and quit.
struct GeneralSection: View {
    @Binding var settings: AppSettings
    let onReset: () -> Void

    var body: some View {
        Section {
            Picker("Refresh metrics every", selection: $settings.refreshInterval) {
                ForEach(AppSettings.refreshIntervals, id: \.self) { Text("\(Int($0)) s").tag($0) }
            }
            Toggle("Show menu bar icon", isOn: $settings.showsMenuBarIcon)
            HStack {
                Button("Restore defaults", action: onReset)
                Spacer()
                Button("Quit TouchBarStats") { NSApp.terminate(nil) }
            }
        } header: {
            Text("General")
        } footer: {
            Text("Without the menu bar icon, get back here by opening TouchBarStats again from Applications, or with the Settings button on the Touch Bar.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
}
