import Darwin

/// Serves one client at a time over the Unix socket and applies its commands to the SMC.
/// When the client disconnects (the app quit or crashed) it returns to automatic.
final class FanHelperServer {
    private static let backlog: Int32 = 4
    private static let socketPermissions: mode_t = 0o666
    private static let newline = UInt8(ascii: "\n")

    private let controller: FanController

    init(controller: FanController) {
        self.controller = controller
    }

    func run() -> Never {
        let listener = makeListener()
        log("Listening on \(FanHelperEndpoint.path)")
        while true {
            let client = accept(listener, nil, nil)
            guard client >= 0 else { continue }
            serve(client)
            close(client)
            log(controller.restoreAutomatic() ? "Client disconnected: automatic" : "Could not return to automatic")
        }
    }

    private func makeListener() -> Int32 {
        let listener = socket(AF_UNIX, SOCK_STREAM, 0)
        unlink(FanHelperEndpoint.path)
        guard listener >= 0,
              FanHelperEndpoint.withAddress({ bind(listener, $0, $1) }) == 0,
              chmod(FanHelperEndpoint.path, Self.socketPermissions) == 0,
              listen(listener, Self.backlog) == 0
        else {
            log("Could not open the socket: \(String(cString: strerror(errno)))")
            exit(1)
        }
        return listener
    }

    private func serve(_ client: Int32) {
        var pending: [UInt8] = []
        var chunk = [UInt8](repeating: 0, count: 256)
        while true {
            let count = chunk.withUnsafeMutableBytes { read(client, $0.baseAddress, $0.count) }
            guard count > 0 else { return }
            pending += chunk.prefix(count)
            while let end = pending.firstIndex(of: Self.newline) {
                execute(String(decoding: pending[..<end], as: UTF8.self))
                pending.removeSubrange(...end)
            }
        }
    }

    private func execute(_ line: String) {
        switch FanCommand(line: line) {
        case .automatic:
            if !controller.restoreAutomatic() { log("The SMC rejected automatic mode") }
        case .manual(let fraction):
            if !controller.setManual(fraction: fraction) { log("The SMC rejected manual mode") }
        case nil:
            log("Orden desconocida: \(line)")
        }
    }

    private func log(_ message: String) {
        fputs("FanHelper: \(message)\n", stderr)
    }
}
