import Foundation

enum SupabaseDevConfig {
    // Development-only publishable Supabase config.
    // Move these values into secure build configuration before production.
    static let demoMode = false
    static let url = URL(string: "https://serqknmuacwbdgdrwkrp.supabase.co")!
    static let publishableKey = "sb_publishable_3ZCT0O7LEOOsErhHTHu3wA_4TEA9DRS"
}
