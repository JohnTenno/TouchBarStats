import AppKit

/// How loaded a value is according to its thresholds; decides the color it is drawn with.
enum LoadLevel {
    case normal
    case elevated
    case critical

    init(value: Double, elevatedAt: Double, criticalAt: Double) {
        if value >= criticalAt {
            self = .critical
        } else if value >= elevatedAt {
            self = .elevated
        } else {
            self = .normal
        }
    }

    var color: NSColor {
        switch self {
        case .normal: return .labelColor
        case .elevated: return .systemYellow
        case .critical: return .systemRed
        }
    }
}
