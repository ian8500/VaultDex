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
    @State private var hasResolvedAuthenticatedLaunch = false

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
            } else if !hasResolvedAuthenticatedLaunch || store.isLoadingCloudData {
                AuthenticatedLoadingView()
            } else if shouldShowProfileLoadError {
                ProfileLoadErrorView {
                    Task { await refreshDataMode() }
                }
            } else if needsProfileSetup {
                NavigationStack {
                    ProfileSetupView()
                }
            } else {
                mainTabs
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

    private var mainTabs: some View {
        TabView {
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .accessibilityLabel("Home")

            NavigationStack {
                SearchView()
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            .accessibilityLabel("Search")

            NavigationStack {
                VaultView()
            }
            .tabItem {
                Label("Vault", systemImage: "lock.shield")
            }
            .accessibilityLabel("Vault")

            NavigationStack {
                FriendsView()
            }
            .tabItem {
                Label("Friends", systemImage: "person.2.fill")
            }
            .accessibilityLabel("Friends")

            NavigationStack {
                TradeView()
            }
            .tabItem {
                Label("Trade", systemImage: "arrow.left.arrow.right.circle.fill")
            }
            .accessibilityLabel("Trade")
        }
    }

    private var needsProfileSetup: Bool {
        let username = store.profile.handle
            .replacingOccurrences(of: "@", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let displayName = store.profile.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return username.isEmpty || displayName.isEmpty
    }

    private var shouldShowProfileLoadError: Bool {
        guard store.lastSyncError != nil, !authService.isDemoModeEnabled else { return false }
        return store.profile.handle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && store.profile.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func refreshDataMode() async {
        guard authService.currentSession() != nil else {
            hasResolvedAuthenticatedLaunch = false
            store.clearSignedOutState()
            return
        }

        hasResolvedAuthenticatedLaunch = false

        if authService.isDemoModeEnabled {
            store.useDemoMode()
        } else {
            await store.loadCloudDataIfPossible(session: authService.currentSession())
        }

        hasResolvedAuthenticatedLaunch = true
    }
}

private struct AuthenticatedLoadingView: View {
    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 16) {
                VaultDexLogo(size: 70)

                ProgressView()
                    .tint(Color.vdGold)

                Text("Loading profile...")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.vdTextPrimary)
            }
            .padding(28)
            .background(Color.vdPanel.opacity(0.9), in: RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.vdGold.opacity(0.24), lineWidth: 1))
        }
    }
}

private struct ProfileLoadErrorView: View {
    let retry: () -> Void

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 16) {
                VaultDexLogo(size: 70)

                Image(systemName: "exclamationmark.icloud.fill")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(Color.vdGold)

                Text("Unable to load profile")
                    .font(.title3.weight(.black))
                    .foregroundStyle(Color.vdTextPrimary)

                Text("Please check your connection and try again.")
                    .font(.subheadline)
                    .foregroundStyle(Color.vdTextSecondary)
                    .multilineTextAlignment(.center)

                PrimaryButton(title: "Retry", systemImage: "arrow.clockwise") {
                    retry()
                }
            }
            .padding(24)
            .background(Color.vdPanel.opacity(0.9), in: RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.vdGold.opacity(0.24), lineWidth: 1))
            .padding(20)
        }
    }
}
