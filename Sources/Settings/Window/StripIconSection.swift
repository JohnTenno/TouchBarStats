import SwiftUI

/// Icon of the app's Control Strip button: the original or any image, GIF or video.
struct StripIconSection: View {
    @Binding var choice: MediaChoice
    let library: MediaLibrary

    var body: some View {
        Section {
            MediaChoiceEditor(choice: $choice, library: library, previewSize: CGSize(width: 26, height: 26),
                              fallback: Bundle.main.url(forResource: "TouchBarIcon", withExtension: "png"),
                              removeTitle: "Use original")
        } header: {
            Text("Control Strip icon")
        } footer: {
            Text("Shown at 26 × 26 pt; GIFs and videos loop without sound.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
}
