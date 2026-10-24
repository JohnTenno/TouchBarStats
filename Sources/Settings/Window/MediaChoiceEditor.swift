import SwiftUI

/// Preview + buttons to choose or remove a file (image, GIF or video) and how to fit it.
/// Used by the Control Strip icon and the animation item.
struct MediaChoiceEditor: View {
    @Binding var choice: MediaChoice
    let library: MediaLibrary
    let previewSize: CGSize
    let fallback: URL?
    let removeTitle: String
    var onChosen: () -> Void = {}

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            MediaPreview(url: choice.path.map { URL(fileURLWithPath: $0) } ?? fallback, fit: choice.fit, size: previewSize)
                .padding(6)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.black))
            VStack(alignment: .leading, spacing: 6) {
                Text(choice.path.map { URL(fileURLWithPath: $0).lastPathComponent } ?? "Default")
                    .font(.caption).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle)
                HStack {
                    Button("Choose file…", action: choose)
                    Button(removeTitle, action: remove).disabled(choice.path == nil)
                }
                Picker("Fit", selection: $choice.fit) {
                    ForEach(MediaFit.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .disabled(choice.path == nil)
            }
        }
        .padding(.vertical, 4)
    }

    private func choose() {
        guard let url = MediaFilePicker.choose() else { return }
        do {
            let path = try library.importFile(at: url)
            library.remove(choice.path)
            choice.path = path
            onChosen()
        } catch {
            MediaFilePicker.showError(error)
        }
    }

    private func remove() {
        library.remove(choice.path)
        choice.path = nil
    }
}
