/// A file chosen by the user (image, GIF or video) and how to fit it; with no file the default is used.
struct MediaChoice: Codable, Equatable {
    var path: String?
    var fit: MediaFit

    init(path: String? = nil, fit: MediaFit) {
        self.path = path
        self.fit = fit
    }
}
