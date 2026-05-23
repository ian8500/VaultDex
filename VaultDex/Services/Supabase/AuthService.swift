import Foundation

enum VaultAppStatus: Equatable {
    case demoMode
    case supabaseConnected
    case supabaseMissingPackage
    case supabaseError(String)

    var title: String {
        switch self {
        case .demoMode: "Demo Mode"
        case .supabaseConnected: "Supabase Connected"
        case .supabaseMissingPackage: "Supabase Missing Package"
        case .supabaseError: "Supabase Error"
        }
    }

    var message: String {
        switch self {
        case .demoMode:
            "Using local demo data. Supabase auth is safely bypassed."
        case .supabaseConnected:
            "Auth session is active and ready for profile data."
        case .supabaseMissingPackage:
            "The Swift package is not installed. REST auth fallback is available for this proof step."
        case let .supabaseError(message):
            message
        }
    }

    var systemImage: String {
        switch self {
        case .demoMode: "iphone"
        case .supabaseConnected: "checkmark.seal.fill"
        case .supabaseMissingPackage: "shippingbox.fill"
        case .supabaseError: "exclamationmark.triangle.fill"
        }
    }
}

@MainActor
final class AuthService: ObservableObject {
    @Published private(set) var status: VaultAppStatus
    @Published private(set) var session: SupabaseSession?
    @Published private(set) var isLoading = false

    private let clientProvider: SupabaseClientProvider

    init(clientProvider: SupabaseClientProvider) {
        self.clientProvider = clientProvider
        session = clientProvider.currentSession

        if clientProvider.config.demoMode || !clientProvider.config.isConfigured {
            status = .demoMode
        } else if SupabaseClientProvider.isSupabaseSwiftPackageAvailable {
            status = .demoMode
        } else {
            status = .supabaseMissingPackage
        }
    }

    func signUp(email: String, password: String) async throws {
        try await authenticate(path: "signup", email: email, password: password, grantType: nil)
    }

    func signIn(email: String, password: String) async throws {
        try await authenticate(path: "token", email: email, password: password, grantType: "password")
    }

    func signOut() async throws {
        guard clientProvider.config.shouldUseRemote else {
            session = nil
            clientProvider.updateSession(nil)
            status = .demoMode
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let request = try clientProvider.authRequest(path: "logout")
            try await clientProvider.send(request)
            session = nil
            clientProvider.updateSession(nil)
            status = SupabaseClientProvider.isSupabaseSwiftPackageAvailable ? .demoMode : .supabaseMissingPackage
        } catch {
            status = .supabaseError(error.localizedDescription)
            throw error
        }
    }

    func currentSession() -> SupabaseSession? {
        session
    }

    private func authenticate(path: String, email: String, password: String, grantType: String?) async throws {
        guard clientProvider.config.shouldUseRemote else {
            status = .demoMode
            throw SupabaseClientError.missingConfiguration
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let payload = AuthPayload(email: email, password: password)
            let queryItems = grantType.map { [URLQueryItem(name: "grant_type", value: $0)] } ?? []
            let request = try clientProvider.authRequest(path: path, body: JSONEncoder.supabase.encode(payload), queryItems: queryItems)
            let response = try await clientProvider.send(request, decode: AuthResponse.self)
            let newSession = try response.session()
            session = newSession
            clientProvider.updateSession(newSession)
            try await upsertProfile(for: newSession)
            status = .supabaseConnected
        } catch {
            session = nil
            clientProvider.updateSession(nil)
            status = .supabaseError(error.localizedDescription)
            throw error
        }
    }

    private func upsertProfile(for session: SupabaseSession) async throws {
        let fallbackUsername = session.email?
            .components(separatedBy: "@")
            .first?
            .lowercased()
            .filter { $0.isLetter || $0.isNumber || $0 == "_" }
        let username = fallbackUsername?.isEmpty == false
            ? fallbackUsername ?? "collector_\(session.userID.uuidString.prefix(8))"
            : "collector_\(session.userID.uuidString.prefix(8))"
        let profile = ProfilePayload(
            id: session.userID,
            username: username,
            displayName: session.email ?? "VaultDex Collector"
        )
        let request = try clientProvider.restRequest(
            table: "profiles",
            method: .post,
            body: JSONEncoder.supabase.encode(profile),
            prefer: "resolution=merge-duplicates"
        )
        try await clientProvider.send(request)
    }

    private struct AuthPayload: Codable {
        let email: String
        let password: String
    }

    private struct AuthResponse: Codable {
        let accessToken: String?
        let refreshToken: String?
        let expiresIn: Int?
        let user: AuthUser?

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case expiresIn = "expires_in"
            case user
        }

        func session() throws -> SupabaseSession {
            guard let accessToken, let userID = user?.id else {
                throw SupabaseClientError.invalidResponse
            }
            return SupabaseSession(
                accessToken: accessToken,
                refreshToken: refreshToken,
                userID: userID,
                email: user?.email,
                expiresAt: expiresIn.map { Date().addingTimeInterval(TimeInterval($0)) }
            )
        }
    }

    private struct AuthUser: Codable {
        let id: UUID
        let email: String?
    }

    private struct ProfilePayload: Codable {
        let id: UUID
        let username: String
        let displayName: String

        enum CodingKeys: String, CodingKey {
            case id
            case username
            case displayName = "display_name"
        }
    }
}
