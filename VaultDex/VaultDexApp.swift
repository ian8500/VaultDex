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
        URLCache.shared = URLCache(
            memoryCapacity: 64 * 1024 * 1024,
            diskCapacity: 256 * 1024 * 1024,
            diskPath: "VaultDexImageCache"
        )

        let config = SupabaseConfig.current
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
