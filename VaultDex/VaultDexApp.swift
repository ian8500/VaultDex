//
//  VaultDexApp.swift
//  VaultDex
//
//  Created by Ian Dickson on 22/05/2026.
//

import SwiftUI

@main
struct VaultDexApp: App {
    @StateObject private var store = LocalVaultStore(
        repositories: .live(config: .current),
        localRepositories: .demo()
    )

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
