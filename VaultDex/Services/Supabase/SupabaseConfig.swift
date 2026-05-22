import Foundation

struct SupabaseConfig: Equatable {
    let demoMode: Bool
    let url: URL?
    let anonKey: String?

    var isConfigured: Bool {
        url != nil && !(anonKey ?? "").isEmpty
    }

    var shouldUseRemote: Bool {
        !demoMode && isConfigured
    }

    static var current: SupabaseConfig {
        SupabaseConfig(
            demoMode: Self.boolValue(named: "DEMO_MODE", defaultValue: true),
            url: Self.urlValue(named: "SUPABASE_URL"),
            anonKey: Self.stringValue(named: "SUPABASE_ANON_KEY")
        )
    }

    private static func stringValue(named key: String) -> String? {
        if let environmentValue = ProcessInfo.processInfo.environment[key],
           !environmentValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return environmentValue.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let bundleValue = Bundle.main.object(forInfoDictionaryKey: key) as? String,
           !bundleValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return bundleValue.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return nil
    }

    private static func boolValue(named key: String, defaultValue: Bool) -> Bool {
        guard let rawValue = stringValue(named: key)?.lowercased() else { return defaultValue }
        switch rawValue {
        case "1", "true", "yes", "y": return true
        case "0", "false", "no", "n": return false
        default: return defaultValue
        }
    }

    private static func urlValue(named key: String) -> URL? {
        guard let rawValue = stringValue(named: key) else { return nil }
        return URL(string: rawValue)
    }
}

