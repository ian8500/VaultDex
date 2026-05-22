//
//  VaultDexApp.swift
//  VaultDex
//
//  Created by Ian Dickson on 22/05/2026.
//

import SwiftUI

@main
struct VaultDexApp: App {
    @StateObject private var store = LocalVaultStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
