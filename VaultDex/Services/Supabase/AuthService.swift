import Foundation

#if canImport(Supabase)
import Supabase
#endif

enum VaultAppStatus: Equatable {
    case demoMode
    case cloudReady
    case cloudSignedIn
    case supabaseConfigMissing
    case supabaseError(String)

    var title: String {
        switch self {
        case .demoMode: "Demo Mode"
        case .cloudReady: "Cloud Ready"
        case .cloudSignedIn: "Cloud Sync Active"
        case .supabaseConfigMissing: "Supabase Setup Needed"
        case .supabaseError: "Supabase Error"
        }
    }

    var message: String {
        switch self {
        case .demoMode:
            "Using local fallback mode. Supabase auth is safely bypassed."
        case .cloudReady:
            "sign in to sync"
        case .cloudSignedIn:
            "Signed in and syncing with Supabase."
        case .supabaseConfigMissing:
            "Supabase URL or publishable key is missing."
        case let .supabaseError(message):
            message
        }
    }

    var systemImage: String {
        switch self {
        case .demoMode: "iphone"
        case .cloudReady: "icloud"
        case .cloudSignedIn: "checkmark.icloud.fill"
        case .supabaseConfigMissing: "exclamationmark.icloud.fill"
        case .supabaseError: "exclamationmark.triangle.fill"
        }
    }
}

@MainActor
final class AuthService: ObservableObject {
    @Published private(set) var status: VaultAppStatus
    @Published private(set) var session: SupabaseSession?
    @Published private(set) var isLoading = false
    @Published private(set) var isDemoModeEnabled: Bool

    private let clientProvider: SupabaseClientProvider

    init(clientProvider: SupabaseClientProvider) {
        self.clientProvider = clientProvider
        let initialDemoMode = clientProvider.config.demoMode
        let initialSession = clientProvider.currentSession
        self.isDemoModeEnabled = initialDemoMode
        self.session = initialSession

        status = Self.status(
            demoMode: initialDemoMode,
            isConfigured: clientProvider.config.isConfigured,
            canCreateClient: clientProvider.canCreateClient,
            session: initialSession
        )
    }

    var shouldShowLogin: Bool {
        !isDemoModeEnabled && session == nil
    }

    var isSupabaseURLConfigured: Bool {
        clientProvider.config.url != nil
    }

    var isSupabaseKeyConfigured: Bool {
        !(clientProvider.config.publishableKey ?? "").isEmpty
    }

    var isSessionActive: Bool {
        session != nil
    }

    var debugDemoModeValue: String {
        "\(clientProvider.config.demoMode)"
    }

    var debugSupabaseURLValue: String {
        clientProvider.config.url == nil ? "missing" : "configured"
    }

    var debugPublishableKeyValue: String {
        (clientProvider.config.publishableKey ?? "").isEmpty ? "missing" : "configured"
    }

    var debugIsConfiguredValue: String {
        "\(clientProvider.config.isConfigured)"
    }

    var currentModeDescription: String {
        switch status {
        case .demoMode: "Demo"
        case .cloudReady: "Cloud Ready"
        case .cloudSignedIn: "Cloud Sync Active"
        case .supabaseConfigMissing: "Supabase Setup Needed"
        case .supabaseError: "Supabase Error"
        }
    }

    func setDemoModeEnabled(_ isEnabled: Bool) {
        UserDefaults.standard.set(isEnabled, forKey: "VaultDexDemoModeEnabled")
        clientProvider.setDemoModeEnabled(isEnabled)
        isDemoModeEnabled = isEnabled
        if isEnabled {
            status = .demoMode
        } else if session != nil {
            status = .cloudSignedIn
        } else if clientProvider.config.isConfigured && clientProvider.canCreateClient {
            status = .cloudReady
        } else {
            status = .supabaseConfigMissing
        }
    }

    func signUp(email: String, password: String) async throws {
        try await signUpWithSDK(email: email, password: password)
    }

    func signIn(email: String, password: String) async throws {
        try await signInWithSDK(email: email, password: password)
    }

    func signOut() async throws {
        guard session != nil else {
            clientProvider.updateSession(nil)
            status = isDemoModeEnabled ? .demoMode : .cloudReady
            return
        }

        guard clientProvider.isRemoteEnabled else {
            session = nil
            clientProvider.updateSession(nil)
            status = isDemoModeEnabled ? .demoMode : .cloudReady
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            #if canImport(Supabase)
            let client = try clientProvider.requireSDKClient()
            try await client.auth.signOut()
            #endif
            session = nil
            clientProvider.updateSession(nil)
            status = isDemoModeEnabled ? .demoMode : .cloudReady
        } catch {
            logSupabaseError(error)
            status = .supabaseError(Self.displayMessage(for: error))
            throw error
        }
    }

    func currentSession() -> SupabaseSession? {
        session
    }

    private func signUpWithSDK(email: String, password: String) async throws {
        guard clientProvider.config.isConfigured, clientProvider.canCreateClient else {
            status = .cloudReady
            throw SupabaseClientError.missingConfiguration
        }
        clientProvider.setDemoModeEnabled(false)
        isDemoModeEnabled = false

        isLoading = true
        defer { isLoading = false }

        do {
            #if canImport(Supabase)
            let client = try clientProvider.requireSDKClient()
            let response = try await client.auth.signUp(email: email, password: password)
            guard let sdkSession = response.session else {
                status = .cloudReady
                throw SupabaseAuthFlowError.emailConfirmationRequired
            }
            try await finishAuthentication(with: sdkSession, client: client)
            #else
            status = .cloudReady
            throw SupabaseClientError.missingSupabasePackage
            #endif
        } catch {
            session = nil
            clientProvider.updateSession(nil)
            logSupabaseError(error)
            if case SupabaseClientError.missingConfiguration = error {
                status = .cloudReady
            } else {
                status = .supabaseError(Self.displayMessage(for: error))
            }
            throw error
        }
    }

    private func signInWithSDK(email: String, password: String) async throws {
        guard clientProvider.config.isConfigured, clientProvider.canCreateClient else {
            status = .cloudReady
            throw SupabaseClientError.missingConfiguration
        }
        clientProvider.setDemoModeEnabled(false)
        isDemoModeEnabled = false

        isLoading = true
        defer { isLoading = false }

        do {
            #if canImport(Supabase)
            let client = try clientProvider.requireSDKClient()
            let sdkSession = try await client.auth.signIn(email: email, password: password)
            try await finishAuthentication(with: sdkSession, client: client)
            #else
            status = .cloudReady
            throw SupabaseClientError.missingSupabasePackage
            #endif
        } catch {
            session = nil
            clientProvider.updateSession(nil)
            logSupabaseError(error)
            if case SupabaseClientError.missingConfiguration = error {
                status = .cloudReady
            } else {
                status = .supabaseError(Self.displayMessage(for: error))
            }
            throw error
        }
    }

    #if canImport(Supabase)
    private func finishAuthentication(with sdkSession: Session, client: SupabaseClient) async throws {
        let newSession = SupabaseSession(sdkSession)
        session = newSession
        clientProvider.updateSession(newSession)
        try await upsertProfile(for: newSession, client: client)
        status = .cloudSignedIn
    }
    #endif

    #if canImport(Supabase)
    private func upsertProfile(for session: SupabaseSession, client: SupabaseClient) async throws {
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
        try await client
            .from("profiles")
            .upsert(profile, onConflict: "id")
            .execute()
    }
    #endif

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

    private static func status(
        demoMode: Bool,
        isConfigured: Bool,
        canCreateClient: Bool,
        session: SupabaseSession?
    ) -> VaultAppStatus {
        if demoMode { return .demoMode }
        guard isConfigured else { return .supabaseConfigMissing }
        return session == nil ? .cloudReady : .cloudSignedIn
    }

    private func logSupabaseError(_ error: Error) {
        print("VaultDex Supabase auth error: \(String(reflecting: error))")
    }

    private static func displayMessage(for error: Error) -> String {
        if case SupabaseClientError.missingConfiguration = error {
            return "Cloud Ready — sign in to sync"
        }
        if let localizedError = error as? LocalizedError,
           let description = localizedError.errorDescription {
            return description
        }
        return error.localizedDescription
    }
}

enum SupabaseAuthFlowError: LocalizedError {
    case emailConfirmationRequired

    var errorDescription: String? {
        switch self {
        case .emailConfirmationRequired:
            "Sign up succeeded. Check your email to confirm your account, then sign in."
        }
    }
}
