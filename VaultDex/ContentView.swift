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
    @State private var continueToProfileSetupAfterError = false
    @State private var selectedDestination: VaultDockDestination = .home
    @State private var saveStatusDismissTask: Task<Void, Never>?
    @AppStorage("hasCompletedVaultDexOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
            if authService.shouldShowLogin {
                NavigationStack {
                    AuthView()
                }
            } else if !hasResolvedAuthenticatedLaunch || store.isLoadingCloudData {
                AuthenticatedLoadingView()
            } else if shouldShowProfileLoadError && !continueToProfileSetupAfterError {
                ProfileLoadErrorView {
                    Task { await refreshDataMode() }
                } continueToSetup: {
                    continueToProfileSetupAfterError = true
                } signOut: {
                    Task {
                        try? await authService.signOut()
                        store.clearSignedOutState()
                    }
                }
            } else if needsProfileSetup || (continueToProfileSetupAfterError && shouldShowProfileLoadError) {
                NavigationStack {
                    ProfileSetupView()
                }
            } else if !hasCompletedOnboarding {
                OnboardingFlowView {
                    hasCompletedOnboarding = true
                }
            } else {
                mainTabs
            }
            }

            if let saveStatusMessage = store.saveStatusMessage {
                SaveStatusBanner(message: saveStatusMessage)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .tint(Color.vdGold)
        .background(AppBackground())
        .task {
            await refreshDataMode()
        }
        .onChange(of: authService.session) { _, _ in
            Task { await refreshDataMode() }
        }
        .onChange(of: authService.isDemoModeEnabled) { _, _ in
            Task { await refreshDataMode() }
        }
        .onChange(of: store.saveStatusMessage) { _, newValue in
            saveStatusDismissTask?.cancel()
            guard newValue == "Saved" || newValue == "Couldn’t save. Please try again." else { return }
            saveStatusDismissTask = Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                await MainActor.run {
                    store.clearSaveStatusMessage()
                }
            }
        }
    }

    private var mainTabs: some View {
        ZStack {
            ForEach(VaultDockDestination.allCases) { destination in
                NavigationStack {
                    destinationView(for: destination)
                }
                .opacity(selectedDestination == destination ? 1 : 0)
                .allowsHitTesting(selectedDestination == destination)
                .accessibilityHidden(selectedDestination != destination)
            }
        }
        .safeAreaInset(edge: .bottom) {
            PremiumNavigationDock(selectedDestination: $selectedDestination)
                .padding(.horizontal, 14)
                .padding(.top, 8)
                .padding(.bottom, 8)
        }
    }

    @ViewBuilder
    private func destinationView(for destination: VaultDockDestination) -> some View {
        switch destination {
        case .home:
            DashboardView()
        case .search:
            SearchView()
        case .vault:
            VaultView()
        case .wants:
            WishlistView()
        case .friends:
            FriendsView()
        case .trade:
            TradeView()
        case .scan:
            CardScannerView()
        case .profile:
            SocialProfileView()
        case .market:
            MarketPlaceholderView()
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
        continueToProfileSetupAfterError = false

        if authService.isDemoModeEnabled {
            store.useDemoMode()
        } else {
            await store.loadCloudDataIfPossible(session: authService.currentSession())
        }

        hasResolvedAuthenticatedLaunch = true
    }
}

private enum VaultDockDestination: String, CaseIterable, Identifiable {
    case home
    case search
    case vault
    case wants
    case friends
    case trade
    case scan
    case profile
    case market

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .search: "Search"
        case .vault: "Vault"
        case .wants: "Wants"
        case .friends: "Friends"
        case .trade: "Trade"
        case .scan: "Scan"
        case .profile: "Profile"
        case .market: "Market"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house.fill"
        case .search: "magnifyingglass"
        case .vault: "lock.shield.fill"
        case .wants: "star.fill"
        case .friends: "person.2.fill"
        case .trade: "arrow.left.arrow.right.circle.fill"
        case .scan: "camera.viewfinder"
        case .profile: "person.crop.circle.fill"
        case .market: "storefront.fill"
        }
    }

    var isProminent: Bool {
        self == .scan
    }
}

private struct PremiumNavigationDock: View {
    @Binding var selectedDestination: VaultDockDestination

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(VaultDockDestination.allCases) { destination in
                        DockButton(
                            destination: destination,
                            isSelected: selectedDestination == destination
                        ) {
                            guard selectedDestination != destination else { return }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.spring(response: 0.34, dampingFraction: 0.84)) {
                                selectedDestination = destination
                            }
                        }
                        .id(destination.id)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(.ultraThinMaterial)

                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.vdNavy.opacity(0.88), Color.vdPanel.opacity(0.76)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(Color.vdGold.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.28), radius: 22, x: 0, y: 10)
            .shadow(color: Color.vdGold.opacity(0.10), radius: 18, x: 0, y: 4)
            .onAppear {
                proxy.scrollTo(selectedDestination.id, anchor: .center)
            }
            .onChange(of: selectedDestination) { _, newValue in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                    proxy.scrollTo(newValue.id, anchor: .center)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Main navigation")
        }
    }
}

private struct DockButton: View {
    let destination: VaultDockDestination
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: destination.systemImage)
                    .font(.system(size: destination.isProminent ? 18 : 16, weight: .black))
                    .symbolRenderingMode(.hierarchical)

                Text(destination.title)
                    .font(.caption.weight(.black))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .allowsTightening(true)
            }
            .foregroundStyle(isSelected ? Color.vdNavy : Color.vdTextPrimary)
            .frame(minWidth: destination.isProminent ? 96 : 82)
            .frame(height: 52)
            .padding(.horizontal, isSelected ? 8 : 4)
            .background {
                buttonBackground
                    .clipShape(Capsule())
            }
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.white.opacity(0.44) : Color.white.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: isSelected ? Color.vdGold.opacity(0.30) : Color.clear, radius: 14, x: 0, y: 6)
            .scaleEffect(isSelected ? 1.05 : 1)
            .contentShape(Capsule())
            .animation(.spring(response: 0.28, dampingFraction: 0.82), value: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(destination.title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    @ViewBuilder
    private var buttonBackground: some View {
        if isSelected {
            LinearGradient(
                colors: [Color(hex: 0xFFF06A), Color.vdGold],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if destination.isProminent {
            LinearGradient(
                colors: [Color.vdGold.opacity(0.22), Color.vdGold.opacity(0.10)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            Color.white.opacity(0.06)
        }
    }
}

private struct MarketPlaceholderView: View {
    var body: some View {
        ZStack {
            AppBackground()

            VStack(alignment: .leading, spacing: 18) {
                VaultDexLogo(size: 54)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Card Market")
                        .font(.system(.largeTitle, design: .rounded, weight: .black))
                        .foregroundStyle(Color.vdTextPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    Text("Browse active listings from trusted collectors.")
                        .font(.headline)
                        .foregroundStyle(Color.vdTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                EmptyStateView(
                    systemImage: "storefront.fill",
                    title: "No listings found",
                    message: "Live listings will appear here when collectors list cards."
                )

                NavigationLink {
                    TradeView()
                } label: {
                    Label("Open Trade", systemImage: "arrow.left.arrow.right.circle.fill")
                        .font(.headline.weight(.black))
                        .foregroundStyle(Color.vdNavy)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.vdGold, in: RoundedRectangle(cornerRadius: 18))
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(22)
        }
        .navigationTitle("Market")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct OnboardingFlowView: View {
    let onFinish: () -> Void
    @State private var stepIndex = 0

    private let steps: [OnboardingStep] = [
        OnboardingStep(title: "Welcome to VaultDex", message: "A calm place to find, save and trade cards with care.", systemImage: "sparkles"),
        OnboardingStep(title: "Find your first card", message: "Search live card data and spot the card you love.", systemImage: "magnifyingglass"),
        OnboardingStep(title: "Add it to My Vault", message: "Keep your collection organised with value estimates.", systemImage: "lock.shield.fill"),
        OnboardingStep(title: "Add a card to Wants", message: "Track the cards you are hunting for next.", systemImage: "star.fill"),
        OnboardingStep(title: "Invite a friend", message: "Compare collections with collectors you trust.", systemImage: "person.2.fill"),
        OnboardingStep(title: "Start trading safely", message: "Use wants, values and safety reminders before trading.", systemImage: "arrow.left.arrow.right.circle.fill")
    ]

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 24) {
                Spacer()
                VaultDexLogo(size: 86)

                VStack(spacing: 14) {
                    Image(systemName: steps[stepIndex].systemImage)
                        .font(.system(size: 34, weight: .black))
                        .foregroundStyle(Color.vdNavy)
                        .frame(width: 76, height: 76)
                        .background(Color.vdGold, in: Circle())

                    Text(steps[stepIndex].title)
                        .font(.system(.largeTitle, design: .rounded, weight: .black))
                        .foregroundStyle(Color.vdTextPrimary)
                        .multilineTextAlignment(.center)

                    Text(steps[stepIndex].message)
                        .font(.headline)
                        .foregroundStyle(Color.vdTextSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(24)
                .background(Color.vdPanel.opacity(0.9), in: RoundedRectangle(cornerRadius: 26))
                .overlay(RoundedRectangle(cornerRadius: 26).stroke(Color.vdGold.opacity(0.25), lineWidth: 1))

                HStack(spacing: 7) {
                    ForEach(steps.indices, id: \.self) { index in
                        Capsule()
                            .fill(index == stepIndex ? Color.vdGold : Color.vdStroke.opacity(0.7))
                            .frame(width: index == stepIndex ? 28 : 8, height: 8)
                            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: stepIndex)
                    }
                }

                PrimaryButton(title: stepIndex == steps.count - 1 ? "Start Collecting" : "Next", systemImage: "arrow.right.circle.fill") {
                    if stepIndex == steps.count - 1 {
                        onFinish()
                    } else {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.88)) {
                            stepIndex += 1
                        }
                    }
                }

                Button("Skip") {
                    onFinish()
                }
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.vdTextSecondary)

                Spacer()
            }
            .padding(22)
        }
    }
}

private struct OnboardingStep {
    let title: String
    let message: String
    let systemImage: String
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

private struct SaveStatusBanner: View {
    let message: String

    private var systemImage: String {
        switch message {
        case "Saving...": "arrow.triangle.2.circlepath"
        case "Saved": "checkmark.circle.fill"
        default: "exclamationmark.triangle.fill"
        }
    }

    private var tint: Color {
        switch message {
        case "Saved": .vdLeaf
        case "Saving...": .vdGold
        default: .vdCoral
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.callout.weight(.black))
                .foregroundStyle(tint)

            Text(message)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.vdTextPrimary)
                .lineLimit(1)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(tint.opacity(0.28), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.18), radius: 16, y: 8)
        .accessibilityElement(children: .combine)
    }
}

private struct ProfileLoadErrorView: View {
    let retry: () -> Void
    let continueToSetup: () -> Void
    let signOut: () -> Void

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 16) {
                VaultDexLogo(size: 70)

                Image(systemName: "exclamationmark.icloud.fill")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(Color.vdGold)

                Text("We couldn’t load your profile")
                    .font(.title3.weight(.black))
                    .foregroundStyle(Color.vdTextPrimary)

                Text("Try again, finish setup, or sign out.")
                    .font(.subheadline)
                    .foregroundStyle(Color.vdTextSecondary)
                    .multilineTextAlignment(.center)

                PrimaryButton(title: "Retry", systemImage: "arrow.clockwise") {
                    retry()
                }

                SecondaryButton(title: "Finish Profile Setup", systemImage: "person.crop.circle.badge.plus") {
                    continueToSetup()
                }

                Button(role: .destructive) {
                    signOut()
                } label: {
                    Text("Sign Out")
                        .font(.subheadline.weight(.bold))
                }
            }
            .padding(24)
            .background(Color.vdPanel.opacity(0.9), in: RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.vdGold.opacity(0.24), lineWidth: 1))
            .padding(20)
        }
    }
}
