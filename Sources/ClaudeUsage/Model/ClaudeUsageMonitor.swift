import AppKit

/// Polls usage every 5 minutes and when the Mac wakes; also ticks every minute
/// so countdowns stay current between polls.
final class ClaudeUsageMonitor {
    private let client: ClaudeUsageClient
    private let fetchInterval: TimeInterval
    private var state = ClaudeUsageState()
    private var observers: [ClaudeUsageObserver] = []
    private var timers: [Timer] = []
    private var loading = false
    private var wakeObserver: NSObjectProtocol?

    init(client: ClaudeUsageClient, fetchInterval: TimeInterval = 300) {
        self.client = client
        self.fetchInterval = fetchInterval
    }

    func add(_ observer: ClaudeUsageObserver) {
        observers.append(observer)
    }

    deinit { stop() }

    func start() {
        guard timers.isEmpty else { return }
        refresh()
        timers = [
            Timer.scheduledTimer(withTimeInterval: fetchInterval, repeats: true) { [weak self] _ in self?.refresh() },
            Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in self?.publish() },
        ]
        timers.forEach { $0.tolerance = min($0.timeInterval * 0.1, 10) }
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { [weak self] _ in self?.refresh() }
    }

    func stop() {
        timers.forEach { $0.invalidate() }
        timers = []
        if let wakeObserver { NSWorkspace.shared.notificationCenter.removeObserver(wakeObserver) }
        wakeObserver = nil
    }

    func refresh() {
        guard !loading else { return }
        loading = true
        Task {
            var next = state
            do {
                next.usage = try await client.fetchUsage()
                next.errorMessage = nil
            } catch {
                next.errorMessage = ClaudeUsageError.describe(error)
            }
            DispatchQueue.main.async {
                self.state = next
                self.loading = false
                self.publish()
            }
        }
    }

    private func publish() {
        observers.forEach { $0.claudeUsageDidChange(state) }
    }
}
