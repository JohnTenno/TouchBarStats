import Foundation

/// A limit window (weekly or 5 h session).
struct UsageWindow {
    let usedPercent: Double
    let resetsAt: Date?

    /// Percentage remaining. If the reset time has passed, the window counts as full.
    func remainingPercent(at now: Date = Date()) -> Double {
        if let resetsAt, resetsAt <= now { return 100 }
        return min(100, max(0, 100 - usedPercent))
    }
}
