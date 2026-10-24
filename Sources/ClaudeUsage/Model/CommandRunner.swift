import Foundation
@preconcurrency import Dispatch

/// Runs a command-line tool without blocking the main thread and captures its output.
enum CommandRunner {
    struct Result {
        let status: Int32
        let output: Data
    }

    static func run(_ executable: URL, arguments: [String], directory: URL? = nil,
                    timeout: TimeInterval = 120) async throws -> Result {
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        if let directory { process.currentDirectoryURL = directory }
        var environment = ProcessInfo.processInfo.environment
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        environment["PATH"] = "\(home)/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
        process.environment = environment

        let stdout = Pipe()
        process.standardOutput = stdout
        process.standardError = FileHandle.nullDevice
        process.standardInput = FileHandle.nullDevice

        try process.run()
        let timeoutWork = DispatchWorkItem {
            if process.isRunning { process.terminate() }
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + timeout, execute: timeoutWork)
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                // Drain while the child runs: waiting for termination first deadlocks
                // when stdout fills the pipe (for example, verbose CLI output).
                let data = stdout.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()
                timeoutWork.cancel()
                continuation.resume(returning: Result(status: process.terminationStatus, output: data))
            }
        }
    }
}
