import Darwin

/// Address of the Unix socket where the root fan helper listens.
enum FanHelperEndpoint {
    static let path = "/var/run/com.tenno.TouchBarStats.FanHelper.sock"

    static func address() -> sockaddr_un {
        var address = sockaddr_un()
        address.sun_family = sa_family_t(AF_UNIX)
        withUnsafeMutableBytes(of: &address.sun_path) { buffer in
            for (index, byte) in path.utf8.prefix(buffer.count - 1).enumerated() { buffer[index] = byte }
        }
        return address
    }

    /// Runs bind/connect with the address converted to the generic `sockaddr` type.
    static func withAddress(_ body: (UnsafePointer<sockaddr>, socklen_t) -> Int32) -> Int32 {
        var address = address()
        return withUnsafePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                body($0, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }
    }
}
