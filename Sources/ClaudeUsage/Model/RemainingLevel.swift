import AppKit

/// Traffic-light color by how much of the limit remains.
enum RemainingLevel {
    case plenty   // more than 40 %
    case low      // 15 % a 40 %
    case critical // less than 15 %

    init(remainingPercent: Double) {
        if remainingPercent > 40 {
            self = .plenty
        } else if remainingPercent >= 15 {
            self = .low
        } else {
            self = .critical
        }
    }

    var color: NSColor {
        switch self {
        case .plenty: return .systemGreen
        case .low: return .systemYellow
        case .critical: return .systemRed
        }
    }
}
