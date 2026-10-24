import AppKit
import UniformTypeIdentifiers

/// AppKit dialogs to choose the file and report when it could not be copied.
enum MediaFilePicker {
    static func choose() -> URL? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image, .audiovisualContent]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "Choose an image, GIF or video"
        return panel.runModal() == .OK ? panel.url : nil
    }

    static func showError(_ error: Error) {
        let alert = NSAlert(error: error)
        alert.messageText = "Could not use that file"
        alert.runModal()
    }
}
