import SwiftUI

/// The same Touch Bar MediaView inside SwiftUI, to see the GIF or video exactly as it will look.
struct MediaPreview: NSViewRepresentable {
    let url: URL?
    let fit: MediaFit
    let size: CGSize

    func makeNSView(context: Context) -> MediaView {
        MediaView(size: size, cornerRadius: min(size.width, size.height) * 0.2)
    }

    func updateNSView(_ view: MediaView, context: Context) {
        view.width = size.width
        view.display(url, fit: fit)
    }
}
