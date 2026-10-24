/// Cumulative CPU counters; the difference between two samples gives the usage percentage.
struct CPUTicks {
    let busy: UInt64
    let total: UInt64

    func usage(since previous: CPUTicks) -> Double {
        guard total > previous.total, busy >= previous.busy else { return 0 }
        return Double(busy - previous.busy) / Double(total - previous.total)
    }
}
