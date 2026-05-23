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
                        Label("Vault", systemImage: "lock.shield")
                    }

                    NavigationStack {
                        WishlistView()
                    }
                    .tabItem {
                        Label("Wants", systemImage: "star.fill")
                    }

                    NavigationStack {
                        TradeView()
                    }
                    .tabItem {
                        Label("Trade", systemImage: "arrow.left.arrow.right.circle.fill")
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
