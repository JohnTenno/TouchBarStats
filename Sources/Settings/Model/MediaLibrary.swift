import Foundation

/// Copies the files the user picks into the app's folder so they keep working
/// even if the original is moved or deleted, and cleans up copies no longer in use.
final class MediaLibrary {
    private let directory: URL
    private let fileManager = FileManager.default

    init(directory: URL) {
        self.directory = directory
    }

    /// Returns the path of the copy.
    func importFile(at source: URL) throws -> String {
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let name = UUID().uuidString + (source.pathExtension.isEmpty ? "" : ".\(source.pathExtension.lowercased())")
        let destination = directory.appendingPathComponent(name)
        try fileManager.copyItem(at: source, to: destination)
        return destination.path
    }

    /// Only deletes files inside the app's folder, never the user's originals.
    func remove(_ path: String?) {
        guard let path, owns(path) else { return }
        try? fileManager.removeItem(atPath: path)
    }

    func owns(_ path: String) -> Bool {
        URL(fileURLWithPath: path).deletingLastPathComponent().standardizedFileURL == directory.standardizedFileURL
    }
}
