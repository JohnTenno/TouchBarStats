/// Whoever presents the bars: opens the Claude usage one.
protocol ClaudeUsageItemDelegate: AnyObject {
    func claudeUsageDidRequestOpen(_ item: ClaudeUsageItem)
}
