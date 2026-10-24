import Foundation

/// Part of the response of GET https://api.anthropic.com/api/oauth/usage.
struct ClaudeUsageResponse: Decodable {
    struct Window: Decodable {
        let utilization: Double?
        let resetsAt: String?

        enum CodingKeys: String, CodingKey {
            case utilization
            case resetsAt = "resets_at"
        }

        var usageWindow: UsageWindow {
            UsageWindow(usedPercent: utilization ?? 0, resetsAt: DateParsing.iso8601(resetsAt))
        }
    }

    let fiveHour: Window?
    let sevenDay: Window?

    enum CodingKeys: String, CodingKey {
        case fiveHour = "five_hour"
        case sevenDay = "seven_day"
    }
}
