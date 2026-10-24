import Foundation

/// Lets the Claude CLI renew its own token with a minimal prompt.
/// Never refreshes OAuth by itself; it only runs the CLI, at most once every 10 minutes.
final class ClaudeTokenRenewer {
    private let minimumInterval: TimeInterval = 600
    private var lastAttempt: Date?

    private let arguments = [
        "-p", "ok",
        "--model", "haiku",
        "--strict-mcp-config",
        "--mcp-config", #"{"mcpServers":{}}"#,
    ]

    /// Returns true if the CLI actually ran, so the credentials are read again.
    func renewIfAllowed(now: Date = Date()) async -> Bool {
        if let lastAttempt, now.timeIntervalSince(lastAttempt) < minimumInterval { return false }
        guard let cli = locateCLI() else { return false }
        lastAttempt = now
        let result = try? await CommandRunner.run(cli, arguments: arguments,
                                                  directory: FileManager.default.temporaryDirectory)
        return result != nil
    }

    private func locateCLI() -> URL? {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let candidates = [
            "\(home)/.local/bin/claude",
            "\(home)/.claude/local/claude",
            "/opt/homebrew/bin/claude",
            "/usr/local/bin/claude",
        ]
        return candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
            .map { URL(fileURLWithPath: $0) }
    }
}
