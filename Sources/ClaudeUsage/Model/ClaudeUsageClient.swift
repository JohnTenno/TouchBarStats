import Foundation

/// Fetches Claude limits with the CLI's OAuth token. If the token is about to expire or the API
/// rejects it, lets the CLI renew it (it never renews or writes it by itself).
final class ClaudeUsageClient {
    private let endpoint = URL(string: "https://api.anthropic.com/api/oauth/usage")!
    private let renewalMargin: TimeInterval = 15 * 60
    private let session: URLSession

    static func sessionConfiguration() -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 30
        return configuration
    }
    private let store: ClaudeCredentialStore
    private let renewer: ClaudeTokenRenewer

    init(store: ClaudeCredentialStore = ClaudeCredentialStore(), renewer: ClaudeTokenRenewer = ClaudeTokenRenewer()) {
        self.session = URLSession(configuration: Self.sessionConfiguration())
        self.store = store
        self.renewer = renewer
    }

    deinit { session.invalidateAndCancel() }

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
        try Task.checkCancellation()
        var request = URLRequest(url: endpoint, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
        request.setValue("Bearer \(credentials.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")

        let (data, response) = try await session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        if status == 401 || status == 403 { throw ClaudeUsageError.unauthorized }
        guard status == 200 else { throw ClaudeUsageError.http(status) }
        guard let body = try? JSONDecoder().decode(ClaudeUsageResponse.self, from: data) else {
            throw ClaudeUsageError.malformedResponse
        }
        return ClaudeUsage(weekly: body.sevenDay?.usageWindow, session: body.fiveHour?.usageWindow)
    }
}
