import Foundation

/// Claude limits: the weekly one and the current session's (5 h).
struct ClaudeUsage {
    let weekly: UsageWindow?
    let session: UsageWindow?
}
