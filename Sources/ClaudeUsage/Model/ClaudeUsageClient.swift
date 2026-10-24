import Foundation

/// Fetches Claude limits with the CLI's OAuth token. If the token is about to expire or the API
/// rejects it, lets the CLI renew it (it never renews or writes it by itself).
final class ClaudeUsageClient {
    private let endpoint = URL(string: "https://api.anthropic.com/api/oauth/usage")!
    private let renewalMargin: TimeInterval = 15 * 60
    private let store: ClaudeCredentialStore
    private let renewer: ClaudeTokenRenewer

    init(store: ClaudeCredentialStore = ClaudeCredentialStore(), renewer: ClaudeTokenRenewer = ClaudeTokenRenewer()) {
        self.store = store
        self.renewer = renewer
    }

    func fetchUsage() async throws -> ClaudeUsage {
        var credentials = try await store.load()
        if credentials.expires(within: renewalMargin), await renewer.renewIfAllowed() {
            credentials = try await store.load()
        }
        do {
            return try await request(with: credentials)
        } catch ClaudeUsageError.unauthorized {
            guard await renewer.renewIfAllowed() else { throw ClaudeUsageError.unauthorized }
            return try await request(with: try await store.load())
        }
    }

    private func request(with credentials: ClaudeCredentials) async throws -> ClaudeUsage {
        var request = URLRequest(url: endpoint, timeoutInterval: 20)
        request.setValue("Bearer \(credentials.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        if status == 401 || status == 403 { throw ClaudeUsageError.unauthorized }
        guard status == 200 else { throw ClaudeUsageError.http(status) }
        guard let body = try? JSONDecoder().decode(ClaudeUsageResponse.self, from: data) else {
            throw ClaudeUsageError.malformedResponse
        }
        return ClaudeUsage(weekly: body.sevenDay?.usageWindow, session: body.fiveHour?.usageWindow)
    }
}
