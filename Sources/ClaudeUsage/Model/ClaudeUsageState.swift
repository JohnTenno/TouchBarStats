import Foundation

/// Last known usage plus the most recent error, so data is not lost if a request fails.
struct ClaudeUsageState {
    var usage: ClaudeUsage?
    var errorMessage: String?
    var updatedAt: Date?

    func isStale(at now: Date = Date()) -> Bool {
        guard usage != nil else { return false }
        guard errorMessage == nil, let updatedAt else { return true }
        return now.timeIntervalSince(updatedAt) > 150
    }
}
