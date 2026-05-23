//
//  ContentView.swift
//  VaultDex
//
//  Created by Ian Dickson on 22/05/2026.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var store: LocalVaultStore

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor { traits in
            traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.05, green: 0.10, blue: 0.18, alpha: 0.97)
            : UIColor(red: 1.00, green: 0.96, blue: 0.80, alpha: 0.97)
        }
        appearance.shadowColor = UIColor(red: 1.00, green: 0.85, blue: 0.30, alpha: 0.26)

        let selectedColor = UIColor(red: 1.00, green: 0.78, blue: 0.12, alpha: 1)
        let normalColor = UIColor.secondaryLabel
        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]
        appearance.stackedLayoutAppearance.normal.iconColor = normalColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: normalColor]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        VStack(spacing: 0) {
            AppStatusBanner(status: authService.status, runtimeMode: store.runtimeMode, syncError: store.lastSyncError)

            if authService.shouldShowLogin {
                NavigationStack {
                    AuthView()
                }
            } else {
                TabView {
                    NavigationStack {
                        DashboardView()
                    }
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }

                    NavigationStack {
                        SearchView()
                    }
                    .tabItem {
                        Label("Search", systemImage: "magnifyingglass")
                    }

                    NavigationStack {
                        VaultView()
                    }
                    .tabItem {
                        Label("My Vault", systemImage: "lock.shield")
                    }

                    NavigationStack {
                        TradeView()
                    }
                    .tabItem {
                        Label("Trade Hub", systemImage: "arrow.left.arrow.right")
                    }

                    NavigationStack {
                        AuthView()
                    }
                    .tabItem {
                        Label("Account", systemImage: "person.crop.circle")
                    }
                }
            }
        }
        .tint(Color.vdGold)
        .background(AppBackground())
        .toolbarBackground(Color.vdPanel.opacity(0.95), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .task {
            await refreshDataMode()
        }
        .onChange(of: authService.session) { _, _ in
            Task { await refreshDataMode() }
        }
        .onChange(of: authService.isDemoModeEnabled) { _, _ in
            Task { await refreshDataMode() }
        }
    }

    private func refreshDataMode() async {
        if authService.isDemoModeEnabled {
            store.useDemoMode()
        } else {
            await store.loadCloudDataIfPossible(session: authService.currentSession())
        }
    }
}

private struct AppStatusBanner: View {
    let status: VaultAppStatus
    let runtimeMode: VaultRuntimeMode
    let syncError: String?

    private var tint: Color {
        switch status {
        case .demoMode: .vdSky
        case .cloudMode: .vdLeaf
        case .offlineMode: .vdGold
        case .supabaseMissingPackage: .vdGold
        case .supabaseError: .vdCoral
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: status.systemImage)
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(Color.vdNavy)
                .frame(width: 28, height: 28)
                .background(tint, in: Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text(status.title + " · " + runtimeMode.displayName)
                    .font(.caption.weight(.black))
                    .foregroundStyle(Color.vdTextPrimary)
                Text(syncError ?? status.message)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.vdTextSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.vdPanel.opacity(0.96))
        .overlay(Rectangle().fill(tint.opacity(0.32)).frame(height: 1), alignment: .bottom)
    }
}
