import Foundation

/// ISO-8601 dates that tolerate microsecond fractions ("2026-10-10T05:00:00.332258+00:00").
enum DateParsing {
    private static let formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static func iso8601(_ text: String?) -> Date? {
        guard let text else { return nil }
        let trimmed = text.replacingOccurrences(of: #"\.\d+"#, with: "", options: .regularExpression)
        return formatter.date(from: trimmed)
    }
}
