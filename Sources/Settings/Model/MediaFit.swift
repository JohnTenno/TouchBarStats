/// How an image or video fits its space.
enum MediaFit: String, Codable, CaseIterable {
    /// Fully visible, with bars if the aspect ratio does not match.
    case fit
    /// Fills the whole space, cropping what overflows.
    case fill

    var title: String {
        switch self {
        case .fit: return "Fit"
        case .fill: return "Fill"
        }
    }
}
