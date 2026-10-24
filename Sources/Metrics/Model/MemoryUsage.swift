/// Memory in use, computed like Activity Monitor's "Memory Used".
struct MemoryUsage {
    let usedBytes: UInt64
    let totalBytes: UInt64

    var fraction: Double {
        totalBytes == 0 ? 0 : Double(usedBytes) / Double(totalBytes)
    }
}
