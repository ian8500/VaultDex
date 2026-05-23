import Foundation

struct SupabaseConfig: Equatable {
    // Development-only publishable Supabase config.
    // Move these values into secure build configuration before production.
    private static let developmentDemoMode = false
    private static let developmentURL = URL(string: "https://serqknmuacwbdgdrwkrp.supabase.co")!
    private static let developmentPublishableKey = "sb_publishable_3ZCT0O7LEOOsErhHTHu3wA_4TEA9DRS"

    let demoMode: Bool
    let url: URL?
    let publishableKey: String?

    var anonKey: String? {
        publishableKey
    }

    var isConfigured: Bool {
        true
    }

    var shouldUseRemote: Bool {
        !demoMode && isConfigured
    }

    static var current: SupabaseConfig {
        SupabaseConfig(
            demoMode: developmentDemoMode,
            url: developmentURL,
            publishableKey: developmentPublishableKey
        )
    }
}
