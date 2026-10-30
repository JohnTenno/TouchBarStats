import Foundation

@main struct CommandRunnerTests {
    static func main() async throws {
        let start = Date()
        let result = try await CommandRunner.run(URL(fileURLWithPath: "/usr/bin/head"),
            arguments: ["-c", "1048576", "/dev/zero"], timeout: 10)
        precondition(result.status == 0 && result.output.count == 1_048_576)
        precondition(Date().timeIntervalSince(start) < 10)
        do {
            _ = try await CommandRunner.run(URL(fileURLWithPath: "/bin/sleep"),
                arguments: ["10"], timeout: 0.1)
            fatalError("Expected timeout")
        } catch CommandRunner.Failure.timedOut { }
        do {
            _ = try await CommandRunner.run(URL(fileURLWithPath: "/nonexistent-command"), arguments: [])
            fatalError("Expected launch error")
        } catch { }

        let ignoredStart = Date()
        do {
            _ = try await CommandRunner.run(URL(fileURLWithPath: "/bin/sh"),
                arguments: ["-c", "trap '' TERM; /bin/sleep 2"], timeout: 0.1)
            fatalError("Expected timeout even when SIGTERM is ignored")
        } catch CommandRunner.Failure.timedOut { }
        precondition(Date().timeIntervalSince(ignoredStart) < 1)

        let inheritedStart = Date()
        let inherited = try await CommandRunner.run(URL(fileURLWithPath: "/bin/sh"),
            arguments: ["-c", "/bin/sleep 2 & echo done; exit 0"], timeout: 0.5)
        precondition(inherited.status == 0 && String(data: inherited.output, encoding: .utf8) == "done\n")
        precondition(Date().timeIntervalSince(inheritedStart) < 1)

        let cancellationStart = Date()
        let task = Task {
            try await CommandRunner.run(URL(fileURLWithPath: "/bin/sleep"), arguments: ["10"])
        }
        try await Task.sleep(nanoseconds: 50_000_000)
        task.cancel()
        do {
            _ = try await task.value
            fatalError("Expected cancellation")
        } catch is CancellationError { }
        precondition(Date().timeIntervalSince(cancellationStart) < 1)

        let recovery = try await CommandRunner.run(URL(fileURLWithPath: "/bin/echo"), arguments: ["ok"])
        precondition(recovery.status == 0 && String(data: recovery.output, encoding: .utf8) == "ok\n")
        print("OK: 7 command runner checks (output, timeout, launch, ignored SIGTERM, inherited pipe, cancellation, recovery)")
    }
}
