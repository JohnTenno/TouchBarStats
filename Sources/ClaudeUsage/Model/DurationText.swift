import Foundation

/// Short countdowns: "5 d 9 h", "3 h 12 min" or "12 min".
enum DurationText {
    static func until(_ date: Date?, now: Date = Date()) -> String {
        guard let date else { return "—" }
        let minutes = Int(max(0, date.timeIntervalSince(now)) / 60)
        let days = minutes / 1440
        let hours = (minutes % 1440) / 60
        let mins = minutes % 60
        if days > 0 { return "\(days) d \(hours) h" }
        if hours > 0 { return "\(hours) h \(mins) min" }
        return mins > 0 ? "\(mins) min" : "< 1 min"
    }
}
