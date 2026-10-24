/// Observer: receives every new sample from the monitor.
protocol SnapshotObserver: AnyObject {
    func monitorDidCapture(_ snapshot: SystemSnapshot)
}
