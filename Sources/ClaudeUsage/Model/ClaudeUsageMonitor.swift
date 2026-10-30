import AppKit

/// Polls once a minute. All state and observer delivery stay on the main thread;
/// every request has a deadline and an identity so late results cannot replace new data.
final class ClaudeUsageMonitor {
    private let fetchUsage: () async throws -> ClaudeUsage
    private let fetchInterval: TimeInterval
    private let requestTimeout: TimeInterval
    private var state = ClaudeUsageState()
    private var observers: [ClaudeUsageObserver] = []
    private var timers: [Timer] = []
    private var wakeObservers: [NSObjectProtocol] = []
    private var requestTask: Task<Void, Never>?
    private var requestID: UUID?
    private var requestStartedAt: Date?
    private var requestTimer: Timer?

    convenience init(client: ClaudeUsageClient, fetchInterval: TimeInterval = 60) {
        self.init(fetchInterval: fetchInterval, requestTimeout: 60, fetchUsage: { try await client.fetchUsage() })
    }

    init(fetchInterval: TimeInterval = 60, requestTimeout: TimeInterval = 60,
         fetchUsage: @escaping () async throws -> ClaudeUsage) {
        self.fetchInterval = fetchInterval
        self.requestTimeout = requestTimeout
        self.fetchUsage = fetchUsage
    }

    func add(_ observer: ClaudeUsageObserver) {
        observers.append(observer)
    }

    deinit { stop() }

    func start() {
        guard timers.isEmpty else { return }
        timers = [timer(every: fetchInterval) { $0.refresh() },
                  timer(every: 60) { $0.publish() }]
        let center = NSWorkspace.shared.notificationCenter
        wakeObservers = [NSWorkspace.didWakeNotification, NSWorkspace.screensDidWakeNotification].map { name in
            center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                guard let self else { return }
                // Mac wake and screen wake arrive together: keep a request just started
                // by the first notification, but replace one left over from sleep.
                let oldRequest = self.requestStartedAt.map { Date().timeIntervalSince($0) > 5 } ?? false
                self.refresh(replacingCurrent: oldRequest)
            }
        }
        refresh()
    }

    func stop() {
        timers.forEach { $0.invalidate() }
        timers = []
        let center = NSWorkspace.shared.notificationCenter
        wakeObservers.forEach { center.removeObserver($0) }
        wakeObservers = []
        cancelRequest()
    }

    /// Manual refresh and wake can replace a stalled request immediately.
    func refresh(replacingCurrent: Bool = false) {
        precondition(Thread.isMainThread)
        if requestID != nil {
            guard replacingCurrent else { return }
            cancelRequest()
        }
        let id = UUID()
        requestID = id
        requestStartedAt = Date()
        let deadline = Timer(timeInterval: requestTimeout, repeats: false) { [weak self] _ in
            guard let self, self.requestID == id else { return }
            self.cancelRequest()
            self.state.errorMessage = "Request timed out"
            self.publish()
        }
        requestTimer = deadline
        RunLoop.main.add(deadline, forMode: .common)
        let fetchUsage = fetchUsage
        requestTask = Task { @MainActor [weak self] in
            let result: Result<ClaudeUsage, Error>
            do { result = .success(try await fetchUsage()) }
            catch { result = .failure(error) }
            guard let self, self.requestID == id else { return }
            self.requestID = nil
            self.requestStartedAt = nil
            self.requestTask = nil
            self.requestTimer?.invalidate()
            self.requestTimer = nil
            switch result {
            case .success(let usage):
                self.state.usage = usage
                self.state.updatedAt = Date()
                self.state.errorMessage = nil
            case .failure(let error):
                self.state.errorMessage = ClaudeUsageError.describe(error)
            }
            self.publish()
        }
    }

    private func cancelRequest() {
        requestID = nil
        requestStartedAt = nil
        requestTimer?.invalidate()
        requestTimer = nil
        requestTask?.cancel()
        requestTask = nil
    }

    private func timer(every interval: TimeInterval, action: @escaping (ClaudeUsageMonitor) -> Void) -> Timer {
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            if let self { action(self) }
        }
        timer.tolerance = min(interval * 0.1, 5)
        RunLoop.main.add(timer, forMode: .common)
        return timer
    }

    private func publish() {
        precondition(Thread.isMainThread)
        observers.forEach { $0.claudeUsageDidChange(state) }
    }
}
