import Foundation
import UniformTypeIdentifiers

/// Factory: picks the source by file type (video or image, animated or not).
enum MediaSourceFactory {
    /// `targetSize` is the view size in pixels; images are pre-rendered to it.
    static func make(for url: URL, targetSize: CGSize, fit: MediaFit) -> MediaSource? {
        guard FileManager.default.fileExists(atPath: url.path),
              let type = UTType(filenameExtension: url.pathExtension) else { return nil }
        if type.conforms(to: .audiovisualContent) {
            return VideoSource(url: url)
        }
        if type.conforms(to: .image) {
            return ImageSequenceSource(url: url, targetSize: targetSize, fit: fit)
        }
        return nil
    }
}
