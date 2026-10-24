import Foundation

/// Last known usage plus the most recent error, so data is not lost if a request fails.
struct ClaudeUsageState {
    var usage: ClaudeUsage?
    var errorMessage: String?
}
