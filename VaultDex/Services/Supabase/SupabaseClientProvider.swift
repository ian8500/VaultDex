import Foundation

#if canImport(Supabase)
import Supabase
#endif

enum SupabaseHTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case delete = "DELETE"
}

enum SupabaseClientError: LocalizedError {
    case missingConfiguration
    case invalidResponse
    case requestFailed(Int, String)

    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            "Supabase is not configured. Set DEMO_MODE=false, SUPABASE_URL, and SUPABASE_PUBLISHABLE_KEY."
        case .invalidResponse:
            "Supabase returned an invalid response."
        case let .requestFailed(statusCode, body):
            "Supabase request failed with status \(statusCode): \(body)"
        }
    }
}

struct SupabaseSession: Equatable {
    let accessToken: String
    let refreshToken: String?
    let userID: UUID
    let email: String?
    let expiresAt: Date?
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

    init(config: SupabaseConfig = .current, urlSession: URLSession = .shared) {
        self.config = config
        self.urlSession = urlSession
        self.session = SupabaseSessionStore.load()
    }

    var isRemoteEnabled: Bool {
        config.isConfigured && !UserDefaults.standard.bool(forKey: "VaultDexDemoModeEnabled")
    }

    var canCreateClient: Bool {
        guard config.isConfigured else { return false }
        #if canImport(Supabase)
        return sdkClient != nil
        #else
        return true
        #endif
    }

    #if canImport(Supabase)
    var sdkClient: SupabaseClient? {
        guard let url = config.url, let key = config.publishableKey else { return nil }
        return SupabaseClient(supabaseURL: url, supabaseKey: key)
    }

    func requireSDKClient() throws -> SupabaseClient {
        guard let sdkClient else { throw SupabaseClientError.missingConfiguration }
        return sdkClient
    }
    #endif

    var currentSession: SupabaseSession? {
        session
    }

    func updateSession(_ session: SupabaseSession?) {
        self.session = session
        SupabaseSessionStore.save(session)
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

    func storageRequest(bucket: String, path: String, method: SupabaseHTTPMethod, contentType: String? = nil, body: Data? = nil) throws -> URLRequest {
        guard let baseURL = config.url, let anonKey = config.anonKey, isRemoteEnabled else {
            throw SupabaseClientError.missingConfiguration
        }

        let cleanPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let url = baseURL.appending(path: "storage/v1/object/\(bucket)/\(cleanPath)")
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(session?.accessToken ?? anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(contentType ?? "application/octet-stream", forHTTPHeaderField: "Content-Type")
        return request
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
