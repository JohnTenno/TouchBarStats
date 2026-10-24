/// Observer: receives every new Claude usage state (always on the main thread).
protocol ClaudeUsageObserver: AnyObject {
    func claudeUsageDidChange(_ state: ClaudeUsageState)
}
