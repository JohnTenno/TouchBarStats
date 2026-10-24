import Foundation

/// Reads the credentials Claude Code stores in the Keychain (or in ~/.claude/.credentials.json).
final class ClaudeCredentialStore {
    private let keychainService = "Claude Code-credentials"
    private let securityTool = URL(fileURLWithPath: "/usr/bin/security")

    private var credentialsFile: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".claude/.credentials.json")
    }

    func load() async throws -> ClaudeCredentials {
        if let data = try? Data(contentsOf: credentialsFile) {
            return try decode(data)
        }
        // Going through `security` reuses the Keychain permission Claude Code already has.
        let result = try await CommandRunner.run(
            securityTool, arguments: ["find-generic-password", "-s", keychainService, "-w"], timeout: 10)
        guard result.status == 0 else { throw ClaudeUsageError.notLoggedIn }
        return try decode(result.output)
    }

    private func decode(_ data: Data) throws -> ClaudeCredentials {
        guard
            let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let oauth = root["claudeAiOauth"] as? [String: Any],
            let token = oauth["accessToken"] as? String
        else { throw ClaudeUsageError.notLoggedIn }
        let expiresAt = (oauth["expiresAt"] as? Double).map { Date(timeIntervalSince1970: $0 / 1000) }
        return ClaudeCredentials(accessToken: token, expiresAt: expiresAt)
    }
}
