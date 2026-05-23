import Foundation

struct SupabaseConfig: Equatable {
    // Development-only publishable Supabase config.
    // Move these values into secure build configuration before production.
    static let developmentDemoMode = false
    static let developmentURL = URL(string: "https://serqknmuacwbdgdrwkrp.supabase.co")!
    static let developmentPublishableKey = "sb_publishable_3ZCT0O7LEOOsErhHTHu3wA_4TEA9DRS"

    let demoMode: Bool
    let url: URL?
    let publishableKey: String?

    var anonKey: String? {
        publishableKey
    }

    var isConfigured: Bool {
        url != nil && !(publishableKey ?? "").isEmpty
    }

    var shouldUseRemote: Bool {
        !demoMode && isConfigured
    }

    static var current: SupabaseConfig {
        SupabaseConfig(
            demoMode: Self.boolValue(named: "DEMO_MODE", defaultValue: developmentDemoMode),
            url: Self.urlValue(named: "SUPABASE_URL") ?? developmentURL,
            publishableKey: Self.stringValue(named: "SUPABASE_PUBLISHABLE_KEY")
                ?? Self.stringValue(named: "SUPABASE_ANON_KEY")
                ?? developmentPublishableKey
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
