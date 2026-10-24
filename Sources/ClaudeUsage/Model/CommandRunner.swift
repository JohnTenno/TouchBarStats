import Foundation

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

        return try await withCheckedThrowingContinuation { continuation in
            process.terminationHandler = { finished in
                let data = stdout.fileHandleForReading.readDataToEndOfFile()
                continuation.resume(returning: Result(status: finished.terminationStatus, output: data))
            }
            do {
                try process.run()
            } catch {
                process.terminationHandler = nil
                continuation.resume(throwing: error)
                return
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
                if process.isRunning { process.terminate() }
            }
        }
    }
}
