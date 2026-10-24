import Foundation

@main struct CommandRunnerTests {
    static func main() async throws {
        // Much larger than a pipe buffer: must finish without waiting for the timeout.
        let start = Date()
        let result = try await CommandRunner.run(URL(fileURLWithPath: "/usr/bin/head"),
            arguments: ["-c", "1048576", "/dev/zero"], timeout: 10)
        precondition(result.status == 0 && result.output.count == 1_048_576)
        precondition(Date().timeIntervalSince(start) < 10)
        let timeout = try await CommandRunner.run(URL(fileURLWithPath: "/bin/sleep"),
            arguments: ["10"], timeout: 0.1)
        precondition(timeout.status != 0)
        do {
            _ = try await CommandRunner.run(URL(fileURLWithPath: "/nonexistent-command"), arguments: [])
            fatalError("Expected launch error")
        } catch { }
        print("OK: 3 command runner checks (large output, timeout, launch failure)")
    }
}
