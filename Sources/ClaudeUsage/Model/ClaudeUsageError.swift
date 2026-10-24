import Foundation

/// Failures fetching usage; `message` is shown on the Touch Bar.
enum ClaudeUsageError: Error {
    case notLoggedIn
    case unauthorized
    case http(Int)
    case malformedResponse

    var message: String {
        switch self {
        case .notLoggedIn: return "Not logged in to Claude"
        case .unauthorized: return "Session expired"
        case .http(let code): return "Error HTTP \(code)"
        case .malformedResponse: return "Unexpected response"
        }
    }

    static func describe(_ error: Error) -> String {
        (error as? ClaudeUsageError)?.message ?? "Offline"
    }
}
