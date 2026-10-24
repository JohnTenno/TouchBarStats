import Foundation

/// Reads memory in use: apps + wired + compressed.
final class MemoryUsageReader {
    private let host = mach_host_self()
    private let totalBytes = ProcessInfo.processInfo.physicalMemory

    deinit { mach_port_deallocate(mach_task_self_, host) }

    func read() -> MemoryUsage? {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(host, HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return nil }

        let internalPages = UInt64(stats.internal_page_count)
        let purgeablePages = UInt64(stats.purgeable_count)
        let appPages = internalPages > purgeablePages ? internalPages - purgeablePages : 0
        let usedPages = appPages + UInt64(stats.wire_count) + UInt64(stats.compressor_page_count)
        return MemoryUsage(usedBytes: usedPages * UInt64(vm_kernel_page_size), totalBytes: totalBytes)
    }
}
