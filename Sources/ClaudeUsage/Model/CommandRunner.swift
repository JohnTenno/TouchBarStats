import Foundation
import Darwin
@preconcurrency import Dispatch

/// Runs a command without blocking the main thread. Deadlines and cancellation also
/// work when a child ignores SIGTERM or a descendant keeps its stdout pipe open.
enum CommandRunner {
    struct Result {
        let status: Int32
        let output: Data
    }

    enum Failure: Error { case timedOut }

    static func run(_ executable: URL, arguments: [String], directory: URL? = nil,
                    timeout: TimeInterval = 120) async throws -> Result {
        let execution = Execution(executable: executable, arguments: arguments, directory: directory)
        return try await withTaskCancellationHandler(operation: {
            try await withCheckedThrowingContinuation { execution.start(timeout: timeout, continuation: $0) }
        }, onCancel: { execution.cancel() })
    }

    /// All process, pipe and continuation state belongs to this serial queue.
    private final class Execution: @unchecked Sendable {
        private let queue = DispatchQueue(label: "com.tenno.TouchBarStats.command", qos: .utility)
        private let process = Process()
        private let pipe = Pipe()
        private var source: DispatchSourceRead?
        private var deadline: DispatchWorkItem?
        private var continuation: CheckedContinuation<Result, Error>?
        private var output = Data()
        private var cancelled = false
        private var finished = false

        init(executable: URL, arguments: [String], directory: URL?) {
            process.executableURL = executable
            process.arguments = arguments
            process.currentDirectoryURL = directory
            var environment = ProcessInfo.processInfo.environment
            let home = FileManager.default.homeDirectoryForCurrentUser.path
            environment["PATH"] = "\(home)/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
            process.environment = environment
            process.standardOutput = pipe
            process.standardError = FileHandle.nullDevice
            process.standardInput = FileHandle.nullDevice
        }

        func start(timeout: TimeInterval, continuation: CheckedContinuation<Result, Error>) {
            queue.async {
                self.continuation = continuation
                guard !self.cancelled else {
                    self.finish(.failure(CancellationError()))
                    return
                }
                let fd = self.pipe.fileHandleForReading.fileDescriptor
                let flags = fcntl(fd, F_GETFL)
                guard flags >= 0, fcntl(fd, F_SETFL, flags | O_NONBLOCK) == 0 else {
                    self.finish(.failure(POSIXError(.EIO)))
                    return
                }
                self.process.terminationHandler = { [self] process in
                    queue.async {
                        guard !self.finished else { return }
                        self.drain()
                        self.finish(.success(Result(status: process.terminationStatus, output: self.output)))
                    }
                }
                do { try self.process.run() } catch {
                    self.finish(.failure(error))
                    return
                }
                // The parent's copy must not hold the pipe open after the child exits.
                try? self.pipe.fileHandleForWriting.close()
                let reader = DispatchSource.makeReadSource(fileDescriptor: fd, queue: self.queue)
                reader.setEventHandler { [self] in drain() }
                self.source = reader
                reader.resume()
                let deadline = DispatchWorkItem { [self] in abort(Failure.timedOut) }
                self.deadline = deadline
                self.queue.asyncAfter(deadline: .now() + max(0, timeout), execute: deadline)
            }
        }

        func cancel() {
            queue.async {
                self.cancelled = true
                if self.continuation != nil { self.abort(CancellationError()) }
            }
        }

        private func drain() {
            guard !finished else { return }
            let fd = pipe.fileHandleForReading.fileDescriptor
            var buffer = [UInt8](repeating: 0, count: 65_536)
            // Yield periodically so an endlessly verbose child cannot starve the deadline.
            for _ in 0..<64 {
                let count = Darwin.read(fd, &buffer, buffer.count)
                if count > 0 { output.append(contentsOf: buffer.prefix(count)) }
                else if count < 0 && errno == EINTR { continue }
                else { break }
            }
        }

        private func abort(_ error: Error) {
            guard !finished else { return }
            if process.isRunning {
                process.terminate()
                let process = process
                queue.asyncAfter(deadline: .now() + 0.5) {
                    if process.isRunning { kill(process.processIdentifier, SIGKILL) }
                }
            }
            finish(.failure(error))
        }

        private func finish(_ result: Swift.Result<Result, Error>) {
            guard !finished else { return }
            finished = true
            deadline?.cancel()
            deadline = nil
            source?.setEventHandler {}
            source?.cancel()
            source = nil
            try? pipe.fileHandleForReading.close()
            try? pipe.fileHandleForWriting.close()
            process.terminationHandler = nil
            let continuation = continuation
            self.continuation = nil
            continuation?.resume(with: result)
        }
    }
}
