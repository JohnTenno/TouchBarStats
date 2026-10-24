import SwiftUI

/// GIF or video played as one more item of the detail bar, at the chosen width.
struct MediaSection: View {
    @Binding var settings: AppSettings
    let library: MediaLibrary

    var body: some View {
        Section {
            MediaChoiceEditor(choice: $settings.media, library: library,
                              previewSize: CGSize(width: min(settings.mediaWidth, 300), height: 30),
                              fallback: nil, removeTitle: "Remove",
                              onChosen: { settings.setVisible(.media, true) })
            LabeledContent("Ancho: \(Int(settings.mediaWidth)) pt") {
                Slider(value: $settings.mediaWidth, in: AppSettings.mediaWidthRange, step: 10)
            }
            .disabled(settings.media.path == nil)
        } header: {
            Text("Animation in the bar")
        } footer: {
            Text("Choosing a file enables \"Animation\" in the list above; move it with the arrows to place it next to the stats. The Touch Bar is about 30 pt tall.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
}
