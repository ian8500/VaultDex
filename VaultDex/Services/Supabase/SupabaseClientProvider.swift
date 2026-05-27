import Foundation

#if canImport(Supabase)
import Supabase
#endif

enum SupabaseHTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

enum SupabaseClientError: LocalizedError {
    case missingConfiguration
    case missingSupabasePackage
    case invalidResponse
    case requestFailed(Int, String)

    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            "Cloud services are not available right now."
        case .missingSupabasePackage:
            "Cloud services are not available right now."
        case .invalidResponse:
            "Unable to connect right now. Please try again."
        case .requestFailed:
            "Unable to connect right now. Please try again."
        }
    }
}

struct SupabaseSession: Equatable {
    let accessToken: String
    let refreshToken: String?
    let userID: UUID
    let email: String?
    let expiresAt: Date?

    func isExpired(leeway: TimeInterval = 60) -> Bool {
        guard let expiresAt else { return false }
        return expiresAt <= Date().addingTimeInterval(leeway)
    }
}

extension SupabaseSession: Codable {}

#if canImport(Supabase)
extension SupabaseSession {
    init(_ session: Session) {
        self.init(
            accessToken: session.accessToken,
            refreshToken: session.refreshToken,
            userID: session.user.id,
            email: session.user.email,
            expiresAt: Date(timeIntervalSince1970: session.expiresAt)
        )
    }
}
#endif

final class SupabaseClientProvider {
    static var isSupabaseSwiftPackageAvailable: Bool {
        #if canImport(Supabase)
        true
        #else
        false
        #endif
    }

    let config: SupabaseConfig
    private let urlSession: URLSession
    private var session: SupabaseSession?
    private var expiredStoredSession: SupabaseSession?
    private var demoModeEnabled: Bool

    init(config: SupabaseConfig = .current, urlSession: URLSession = SupabaseClientProvider.makeStableURLSession()) {
        self.config = SupabaseConfig.current
        self.urlSession = urlSession
        let storedSession = SupabaseSessionStore.load()
        if storedSession?.isExpired() == true {
            self.session = nil
            self.expiredStoredSession = storedSession
        } else {
            self.session = storedSession
            self.expiredStoredSession = nil
        }
        self.demoModeEnabled = SupabaseConfig.current.demoMode
    }

    static func makeStableURLSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = true
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil
        configuration.httpMaximumConnectionsPerHost = 4
        return URLSession(configuration: configuration)
    }

    var isRemoteEnabled: Bool {
        config.isConfigured && !demoModeEnabled
    }

    var canCreateClient: Bool {
        guard config.url != nil, !(config.publishableKey ?? "").isEmpty else { return false }
        #if canImport(Supabase)
        return sdkClient != nil
        #else
        return true
        #endif
    }

    #if canImport(Supabase)
    var sdkClient: SupabaseClient? {
        guard let url = config.url, let key = config.publishableKey else { return nil }
        let options = SupabaseClientOptions(
            auth: .init(emitLocalSessionAsInitialSession: true),
            global: .init(session: urlSession)
        )
        return SupabaseClient(supabaseURL: url, supabaseKey: key, options: options)
    }

    func requireSDKClient() throws -> SupabaseClient {
        guard let sdkClient else { throw SupabaseClientError.missingConfiguration }
        return sdkClient
    }
    #endif

    var currentSession: SupabaseSession? {
        guard session?.isExpired() != true else { return nil }
        return session
    }

    var hasExpiredStoredSession: Bool {
        expiredStoredSession != nil
    }

    func updateSession(_ session: SupabaseSession?) {
        self.session = session
        expiredStoredSession = nil
        SupabaseSessionStore.save(session)
    }

    func clearExpiredStoredSession() {
        expiredStoredSession = nil
        SupabaseSessionStore.save(nil)
    }

    func refreshExpiredStoredSession() async throws -> SupabaseSession? {
        guard let refreshToken = expiredStoredSession?.refreshToken, isRemoteEnabled else {
            clearExpiredStoredSession()
            return nil
        }

        #if canImport(Supabase)
        let client = try requireSDKClient()
        let refreshed = try await client.auth.refreshSession(refreshToken: refreshToken)
        let newSession = SupabaseSession(refreshed)
        updateSession(newSession)
        return newSession
        #else
        clearExpiredStoredSession()
        return nil
        #endif
    }

    func setDemoModeEnabled(_ isEnabled: Bool) {
        demoModeEnabled = isEnabled
    }

    func restRequest(
        table: String,
        method: SupabaseHTTPMethod = .get,
        queryItems: [URLQueryItem] = [],
        body: Data? = nil,
        prefer: String? = nil
    ) throws -> URLRequest {
        guard let baseURL = config.url, let anonKey = config.anonKey, isRemoteEnabled else {
            throw SupabaseClientError.missingConfiguration
        }

        var components = URLComponents(url: baseURL.appending(path: "rest/v1/\(table)"), resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components?.url else { throw SupabaseClientError.invalidResponse }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(session?.accessToken ?? anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let prefer {
            request.setValue(prefer, forHTTPHeaderField: "Prefer")
        }
        return request
    }

    func storageRequest(
        bucket: String,
        path: String,
        method: SupabaseHTTPMethod,
        contentType: String? = nil,
        body: Data? = nil,
        upsert: Bool = true
    ) throws -> URLRequest {
        guard let baseURL = config.url, let anonKey = config.anonKey, isRemoteEnabled else {
            throw SupabaseClientError.missingConfiguration
        }

        let cleanPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        var url = baseURL
        url.append(path: "storage/v1/object")
        url.append(path: bucket)
        cleanPath.split(separator: "/").forEach { component in
            url.append(path: String(component))
        }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(session?.accessToken ?? anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(contentType ?? "application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("3600", forHTTPHeaderField: "Cache-Control")
        if upsert {
            request.setValue("true", forHTTPHeaderField: "x-upsert")
        }
        return request
    }

    func publicStorageURL(bucket: String, path: String) throws -> URL {
        guard let baseURL = config.url else { throw SupabaseClientError.missingConfiguration }
        let cleanPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return baseURL.appending(path: "storage/v1/object/public/\(bucket)/\(cleanPath)")
    }

    func send<T: Decodable>(_ request: URLRequest, decode type: T.Type = T.self) async throws -> T {
        let (data, response) = try await urlSession.data(for: request)
        try Self.validate(response: response, data: data)
        return try JSONDecoder.supabase.decode(T.self, from: data)
    }

    func send(_ request: URLRequest) async throws {
        let (data, response) = try await urlSession.data(for: request)
        try Self.validate(response: response, data: data)
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await urlSession.data(for: request)
    }

    private static func validate(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseClientError.invalidResponse
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            throw SupabaseClientError.requestFailed(httpResponse.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
    }
}

enum SupabaseSessionStore {
    private static let key = "VaultDexSupabaseSession"

    static func load() -> SupabaseSession? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(SupabaseSession.self, from: data)
    }

    static func save(_ session: SupabaseSession?) {
        guard let session else {
            UserDefaults.standard.removeObject(forKey: key)
            return
        }

        if let data = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

extension JSONDecoder {
    static var supabase: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = ISO8601DateFormatter.supabase.date(from: string) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid Supabase date: \(string)")
        }
        return decoder
    }
}

extension JSONEncoder {
    static var supabase: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(ISO8601DateFormatter.supabase.string(from: date))
        }
        return encoder
    }
}

extension ISO8601DateFormatter {
    static let supabase: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
