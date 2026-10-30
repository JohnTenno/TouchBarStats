import AppKit

final class UsageObserver: ClaudeUsageObserver {
    var states: [ClaudeUsageState] = []
    func claudeUsageDidChange(_ state: ClaudeUsageState) {
        precondition(Thread.isMainThread)
        states.append(state)
    }
}

/// Intentionally ignores cancellation to verify that the monitor recovers anyway.
final class PendingFetches: @unchecked Sendable {
    private let lock = NSLock()
    private var pending: [CheckedContinuation<ClaudeUsage, Error>?] = []
    var count: Int { lock.withLock { pending.count } }
    func fetch() async throws -> ClaudeUsage {
        try await withCheckedThrowingContinuation { continuation in
            lock.withLock { pending.append(continuation) }
        }
    }
    func complete(_ index: Int, with result: Result<ClaudeUsage, Error>) {
        let continuation = lock.withLock {
            let value = pending[index]
            pending[index] = nil
            return value
        }
        continuation?.resume(with: result)
    }
}

func pump(until condition: () -> Bool, timeout: TimeInterval = 1) {
    let limit = Date().addingTimeInterval(timeout)
    while !condition() && Date() < limit {
        RunLoop.main.run(until: Date().addingTimeInterval(0.005))
    }
    precondition(condition(), "Timed out waiting for test condition")
}
func usage(_ percent: Double) -> ClaudeUsage {
    ClaudeUsage(weekly: UsageWindow(usedPercent: percent, resetsAt: nil), session: nil)
}

let t = TestRunner()
let pending = PendingFetches()
let observer = UsageObserver()
let monitor = ClaudeUsageMonitor(fetchInterval: 0.03, requestTimeout: 0.12, fetchUsage: pending.fetch)
monitor.add(observer)
monitor.start()
monitor.start()
pump(until: { pending.count == 1 })
monitor.refresh()
t.check(pending.count == 1, "ordinary refresh coalesces overlapping requests")
pending.complete(0, with: .success(usage(20)))
pump(until: { observer.states.last?.updatedAt != nil })
t.check(observer.states.last?.usage?.weekly?.usedPercent == 20, "publishes initial usage on main thread")
pump(until: { pending.count == 2 })
// Request 1 never finishes; its deadline must free the monitor for request 2.
pump(until: { observer.states.last?.errorMessage == "Request timed out" })
t.check(observer.states.last?.usage?.weekly?.usedPercent == 20, "retains last usage after timeout")
t.check(observer.states.last!.isStale(), "timeout marks retained data stale")
pump(until: { pending.count == 3 })
pending.complete(2, with: .success(usage(30)))
pump(until: { observer.states.last?.usage?.weekly?.usedPercent == 30 })
t.check(!observer.states.last!.isStale(), "next poll recovers without restarting the app")
pending.complete(1, with: .success(usage(99)))
RunLoop.main.run(until: Date().addingTimeInterval(0.01))
t.check(observer.states.last?.usage?.weekly?.usedPercent == 30, "late timed-out result cannot overwrite fresh data")
monitor.stop()
let stoppedCount = pending.count
RunLoop.main.run(until: Date().addingTimeInterval(0.07))
t.check(pending.count == stoppedCount, "repeated start does not leak polling timers")

monitor.refresh()
pump(until: { pending.count == stoppedCount + 1 })
monitor.refresh(replacingCurrent: true)
pump(until: { pending.count == stoppedCount + 2 })
pending.complete(stoppedCount + 1, with: .success(usage(40)))
pump(until: { observer.states.last?.usage?.weekly?.usedPercent == 40 })
pending.complete(stoppedCount, with: .success(usage(90)))
RunLoop.main.run(until: Date().addingTimeInterval(0.01))
t.check(observer.states.last?.usage?.weekly?.usedPercent == 40, "manual refresh replaces blocked request and ignores old result")

monitor.refresh()
pump(until: { pending.count == stoppedCount + 3 })
let publications = observer.states.count
monitor.stop()
pending.complete(stoppedCount + 2, with: .success(usage(80)))
RunLoop.main.run(until: Date().addingTimeInterval(0.02))
t.check(observer.states.count == publications, "stop cancels requests and suppresses late publication")

monitor.start()
pump(until: { pending.count == stoppedCount + 4 })
let center = NSWorkspace.shared.notificationCenter
center.post(name: NSWorkspace.didWakeNotification, object: nil)
center.post(name: NSWorkspace.screensDidWakeNotification, object: nil)
RunLoop.main.run(until: Date().addingTimeInterval(0.005))
t.check(pending.count == stoppedCount + 4, "paired wake notifications keep the request just started")
pending.complete(stoppedCount + 3, with: .success(usage(50)))
pump(until: { observer.states.last?.usage?.weekly?.usedPercent == 50 })
t.check(observer.states.last?.errorMessage == nil, "restart gets a fresh result")
monitor.stop()

let now = Date()
t.check(ClaudeUsageState(usage: usage(1), updatedAt: now.addingTimeInterval(-151)).isStale(at: now),
        "age marks cached data stale even without an error")
t.check(!ClaudeUsageState(usage: usage(1), updatedAt: now).isStale(at: now), "fresh data is current")
let config = ClaudeUsageClient.sessionConfiguration()
t.check(config.urlCache == nil && config.requestCachePolicy == .reloadIgnoringLocalCacheData,
        "usage requests bypass the URL cache")
t.check(config.timeoutIntervalForResource == 30, "network requests have a total resource deadline")

// The watchdog must also run while menus or touch tracking change the loop mode.
let trackingMode = RunLoop.Mode.eventTracking
CFRunLoopAddCommonMode(CFRunLoopGetMain(), CFRunLoopMode(rawValue: trackingMode.rawValue as CFString))
let trackingPending = PendingFetches()
let trackingObserver = UsageObserver()
let tracking = ClaudeUsageMonitor(fetchInterval: 1, requestTimeout: 0.04, fetchUsage: trackingPending.fetch)
tracking.add(trackingObserver)
tracking.start()
pump(until: { trackingPending.count == 1 })
let trackingLimit = Date().addingTimeInterval(0.2)
while trackingObserver.states.isEmpty && Date() < trackingLimit {
    _ = RunLoop.main.run(mode: trackingMode, before: Date().addingTimeInterval(0.005))
}
t.check(trackingObserver.states.last?.errorMessage == "Request timed out",
        "watchdog keeps running in tracking mode")
tracking.stop()
trackingPending.complete(0, with: .failure(CancellationError()))
RunLoop.main.run(until: Date().addingTimeInterval(0.01))
t.finish()
