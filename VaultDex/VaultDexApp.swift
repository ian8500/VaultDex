//
//  VaultDexApp.swift
//  VaultDex
//
//  Created by Ian Dickson on 22/05/2026.
//

import SwiftUI

@main
struct VaultDexApp: App {
    @StateObject private var store: LocalVaultStore
    @StateObject private var authService: AuthService

    init() {
        let config = SupabaseConfig.current
        print("Supabase config URL present: \(config.url != nil)")
        print("Supabase config key present: \(!(config.publishableKey ?? "").isEmpty)")
        print("Supabase isConfigured: \(config.isConfigured)")
        print("Supabase demoMode: \(config.demoMode)")

        let repositories = VaultRepositoryContainer.live(config: config)
        _store = StateObject(
            wrappedValue: LocalVaultStore(
                repositories: repositories,
                localRepositories: .demo()
            )
        )
        _authService = StateObject(wrappedValue: AuthService(clientProvider: repositories.clientProvider))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(authService)
        }
    }
}
