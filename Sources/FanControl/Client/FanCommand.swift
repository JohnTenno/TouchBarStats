/// Command the app sends to the fan helper; it travels as one line of text over the socket.
enum FanCommand: Equatable {
    case automatic
    case manual(fraction: Double)

    private static let automaticWord = "auto"
    private static let manualWord = "manual"

    /// Parses a line ("auto" or "manual 0.42"); the fraction is clamped to 0...1.
    init?(line: String) {
        let parts = line.split(separator: " ")
        switch (parts.first.map(String.init), parts.count) {
        case (Self.automaticWord, 1):
            self = .automatic
        case (Self.manualWord, 2):
            guard let fraction = Double(parts[1]), fraction.isFinite else { return nil }
            self = .manual(fraction: min(max(fraction, 0), 1))
        default:
            return nil
        }
    }

    var line: String {
        switch self {
        case .automatic: return Self.automaticWord
        case .manual(let fraction): return "\(Self.manualWord) \(fraction)"
        }
    }
}
