import Foundation

/// What is needed from Claude Code's OAuth credentials. Read-only.
struct ClaudeCredentials {
    let accessToken: String
    let expiresAt: Date?

    /// True if the token expires within `margin` seconds.
    func expires(within margin: TimeInterval, now: Date = Date()) -> Bool {
        guard let expiresAt else { return false }
        return expiresAt.timeIntervalSince(now) < margin
    }
}
