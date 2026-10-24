import Darwin

/// Fan helper client. Keeps the connection open: if the app quits or crashes,
/// the helper notices the close and returns the fans to automatic.
final class FanControlClient {
    private var socket: Int32 = -1

    deinit {
        disconnect()
    }

    /// Sends the command; retries once after reconnecting in case the helper restarted.
    func send(_ command: FanCommand) -> Bool {
        for _ in 0..<2 {
            if socket < 0 && !connect() { return false }
            if write(command.line + "\n") { return true }
            disconnect()
        }
        return false
    }

    private func connect() -> Bool {
        let descriptor = Darwin.socket(AF_UNIX, SOCK_STREAM, 0)
        guard descriptor >= 0 else { return false }
        var noSignal: Int32 = 1
        setsockopt(descriptor, SOL_SOCKET, SO_NOSIGPIPE, &noSignal, socklen_t(MemoryLayout<Int32>.size))
        guard FanHelperEndpoint.withAddress({ Darwin.connect(descriptor, $0, $1) }) == 0 else {
            close(descriptor)
            return false
        }
        socket = descriptor
        return true
    }

    private func write(_ text: String) -> Bool {
        let bytes = Array(text.utf8)
        return bytes.withUnsafeBytes { Darwin.write(socket, $0.baseAddress, $0.count) } == bytes.count
    }

    private func disconnect() {
        guard socket >= 0 else { return }
        close(socket)
        socket = -1
    }
}
