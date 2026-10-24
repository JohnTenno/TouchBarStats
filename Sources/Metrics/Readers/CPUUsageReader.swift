import Darwin

/// Total CPU usage (all cores) between one reading and the next.
final class CPUUsageReader {
    private let host = mach_host_self()
    private var previous: CPUTicks?

    init() {
        previous = currentTicks()
    }

    deinit { mach_port_deallocate(mach_task_self_, host) }

    func read() -> Double? {
        guard let current = currentTicks() else { return nil }
        defer { previous = current }
        return previous.map { current.usage(since: $0) }
    }

    private func currentTicks() -> CPUTicks? {
        var info = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(host, HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return nil }

        let user = UInt64(info.cpu_ticks.0)
        let system = UInt64(info.cpu_ticks.1)
        let idle = UInt64(info.cpu_ticks.2)
        let nice = UInt64(info.cpu_ticks.3)
        return CPUTicks(busy: user + system + nice, total: user + system + idle + nice)
    }
}
