import SwiftUI
import UIKit

struct DashboardView: View {
    @EnvironmentObject private var store: LocalVaultStore
    @State private var isLoading = true
    @State private var hasAnimated = false
    @State private var glowPulse = false

    private let statColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var pendingTrades: Int {
        store.tradeOffers.filter { $0.status == .pending }.count
    }

    private var friendOpportunities: [FriendTradeOpportunity] {
        store.tradeOpportunities()
    }

    private var friendsWithWantedCards: Int {
        friendOpportunities.filter { !$0.theyOwn.isEmpty }.count
    }

    private var fairTradeSuggestions: Int {
        friendOpportunities.filter { !$0.theyOwn.isEmpty && !$0.youOwn.isEmpty }.count
    }

    private var highlightedFairTradeSuggestions: Int {
        min(fairTradeSuggestions, 2)
    }

    private var rarestItem: CollectionItem? {
        store.collectionItems.sorted {
            if $0.card.rarity.dashboardRank == $1.card.rarity.dashboardRank {
                return $0.card.marketValue > $1.card.marketValue
            }
            return $0.card.rarity.dashboardRank > $1.card.rarity.dashboardRank
        }
        .first
    }

    private var highestValueItem: CollectionItem? {
        store.collectionItems.max { $0.card.marketValue < $1.card.marketValue }
    }

    private var recentlyAddedItem: CollectionItem? {
        store.recentlyAdded.first
    }

    private var isVaultEmpty: Bool {
        store.collectionItems.isEmpty
    }

    private var cardsAddedThisWeek: Int {
        guard let startOfWeek = Calendar.current.date(byAdding: .day, value: -7, to: .now) else { return 0 }
        return store.collectionItems
            .filter { $0.acquiredAt >= startOfWeek }
            .reduce(0) { $0 + $1.quantity }
    }

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    if isLoading {
                        loadingState
                    } else {
                        welcomeHeader
                        vaultSummary
                        primaryFindAction
                        quickActions
                        nextBestActionCard
                        if isVaultEmpty {
                            dashboardEmptyState
                        } else {
                            recentlyAddedSection
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .bottomDockSpacing()
                .opacity(isLoading || hasAnimated ? 1 : 0)
                .offset(y: isLoading || hasAnimated ? 0 : 12)
            }
        }
        .navigationTitle("Today")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard isLoading else { return }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
            try? await Task.sleep(nanoseconds: 320_000_000)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) {
                isLoading = false
                hasAnimated = true
            }
        }
    }

    private var loadingState: some View {
        VStack(spacing: 14) {
            ProgressView()
                .tint(Color.vdGold)

            Text("Preparing your vault")
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.vdTextPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(Color.vdPanel.opacity(0.88), in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.vdGold.opacity(0.24), lineWidth: 1))
        .padding(.top, 80)
    }

    private var welcomeHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            VaultDexLogo(size: 46)

            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome back")
                    .font(.callout.weight(.bold))
                    .foregroundStyle(Color.vdTextSecondary)

                Text(store.profile.displayName)
                    .font(.system(.title3, design: .rounded, weight: .black))
                    .foregroundStyle(Color.vdTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }

            Spacer()

            NavigationLink {
                SocialProfileView()
            } label: {
                profileAvatar
            }
            .buttonStyle(PressableScaleStyle())
        }
    }

    private var profileAvatar: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.vdGold)

            if let avatarURL = store.profile.avatarURL {
                AsyncImage(url: avatarURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        Image(systemName: store.profile.avatarSymbol)
                            .font(.system(size: 19, weight: .black))
                            .foregroundStyle(Color.vdNavy)
                    }
                }
            } else {
                Image(systemName: store.profile.avatarSymbol)
                    .font(.system(size: 19, weight: .black))
                    .foregroundStyle(Color.vdNavy)
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.36), lineWidth: 1)
        )
        .shadow(color: Color.vdGold.opacity(0.18), radius: 10, x: 0, y: 5)
        .accessibilityLabel("Open profile")
    }

    private var vaultSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("My Vault")
                        .font(.title3.weight(.black))
                        .foregroundStyle(Color.vdTextPrimary)

                    Text(store.totalCopiesOwned == 1 ? "1 card saved" : "\(store.totalCopiesOwned) cards saved")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.vdTextSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Spacer()

                Text(store.estimatedCollectionValue.compactVaultEstimatedCurrency)
                    .font(.system(.title2, design: .rounded, weight: .black))
                    .foregroundStyle(Color.vdGold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(
            LinearGradient(
                colors: [Color.vdPanelRaised.opacity(0.88), Color.vdPanel.opacity(0.70)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24)
        )
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.08), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.18), radius: 18, x: 0, y: 12)
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: store.profile.avatarSymbol)
                    .font(.system(size: 30, weight: .black))
                    .foregroundStyle(Color.vdNavy)
                    .frame(width: 70, height: 70)
                    .background(
                        LinearGradient(colors: [Color(hex: 0xFFF06A), Color.vdGold, Color.vdGoldDeep], startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 22)
                    )
                    .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.5), lineWidth: 1))
                    .shadow(color: Color.vdGold.opacity(0.36), radius: 20, x: 0, y: 8)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Welcome back")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.vdTextSecondary)

                    Text(store.profile.displayName)
                        .font(.system(.title2, design: .rounded, weight: .black))
                        .foregroundStyle(Color.vdTextPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    Label("Collector Level \(collectorLevel)", systemImage: "bolt.fill")
                        .font(.caption.weight(.black))
                        .foregroundStyle(Color.vdNavy)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.vdGold, in: Capsule())
                }

                Spacer()
            }

            HStack(spacing: 12) {
                HeroMetric(title: "Total Cards", value: "\(store.totalCopiesOwned)", icon: "rectangle.stack.fill")
                HeroMetric(title: "Estimated Value", value: store.estimatedCollectionValue.compactVaultEstimatedCurrency, icon: "chart.line.uptrend.xyaxis")
            }

        }
        .padding(20)
        .background {
            ZStack {
                LinearGradient(
                    colors: [Color.vdPanelRaised.opacity(0.96), Color.vdPanel.opacity(0.82), Color.vdNavy.opacity(0.92)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Circle()
                    .fill(Color.vdGold.opacity(glowPulse ? 0.34 : 0.20))
                    .blur(radius: glowPulse ? 52 : 38)
                    .frame(width: glowPulse ? 190 : 160, height: glowPulse ? 190 : 160)
                    .offset(x: 118, y: -72)

                LinearGradient(
                    colors: [Color.white.opacity(0.18), Color.clear, Color.vdGold.opacity(0.12), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .offset(x: glowPulse ? 24 : -18, y: glowPulse ? -10 : 10)
            }
            .clipShape(RoundedRectangle(cornerRadius: 26))
        }
        .overlay(RoundedRectangle(cornerRadius: 26).stroke(Color.vdGold.opacity(0.38), lineWidth: 1.2))
        .shadow(color: Color.vdGold.opacity(0.20), radius: 24, x: 0, y: 12)
        .scaleEffect(hasAnimated ? 1 : 0.98)
    }

    private var collectorLevel: Int {
        max(1, store.profile.collectorScore / 1000)
    }

    private var quickActions: some View {
        HStack(spacing: 12) {
            DashboardQuickAction(title: "Wants", subtitle: "Add to Wants", icon: "star.fill", tint: .vdLeaf) {
                WishlistView()
            }
            DashboardQuickAction(title: "Friends", subtitle: "View Friends", icon: "person.2.fill", tint: .vdSky) {
                FriendsView()
            }
            DashboardQuickAction(title: "Trade", subtitle: "Start Trade", icon: "arrow.left.arrow.right.circle.fill", tint: .vdGold) {
                TradeView()
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var primaryFindAction: some View {
        NavigationLink {
            SearchView()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.title3.weight(.black))
                Text("Find a card")
                    .font(.headline.weight(.black))
                Spacer()
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title3.weight(.black))
            }
            .foregroundStyle(Color.vdNavy)
            .padding(.horizontal, 18)
            .frame(minHeight: 66)
            .background(
                LinearGradient(
                    colors: [Color(hex: 0xFFF06A), Color.vdGold],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 22)
            )
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.42), lineWidth: 1))
            .shadow(color: Color.vdGold.opacity(0.26), radius: 18, x: 0, y: 10)
        }
        .simultaneousGesture(TapGesture().onEnded { lightHaptic() })
        .buttonStyle(PressableScaleStyle())
    }

    private var nextBestActionCard: some View {
        let action = nextBestAction
        return NavigationLink {
            action.destination
        } label: {
            HStack(spacing: 12) {
                Image(systemName: action.icon)
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(Color.vdNavy)
                    .frame(width: 42, height: 42)
                    .background(action.tint.opacity(0.94), in: RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Next step")
                        .font(.caption.weight(.black))
                        .foregroundStyle(Color.vdTextSecondary)
                    Text(action.title)
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(Color.vdTextPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                    Text(action.message)
                        .font(.caption)
                        .foregroundStyle(Color.vdTextSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.black))
                    .foregroundStyle(Color.vdTextSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(Color.vdPanel.opacity(0.64), in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.07), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 7)
        }
        .simultaneousGesture(TapGesture().onEnded { lightHaptic() })
        .buttonStyle(PressableScaleStyle())
    }

    private func lightHaptic() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private var nextBestAction: DashboardNextAction {
        if store.collectionItems.isEmpty {
            return DashboardNextAction(title: "Add your first card", message: "Search the card database and start your vault.", icon: "rectangle.stack.badge.plus", tint: .vdGold, destination: AnyView(SearchView()))
        }
        if store.wishlistItems.isEmpty {
            return DashboardNextAction(title: "Add cards you’re hunting", message: "Wants help friends spot fair trades.", icon: "star.fill", tint: .vdLeaf, destination: AnyView(WishlistView()))
        }
        if store.friends.isEmpty {
            return DashboardNextAction(title: "Invite a collector", message: "Collecting is better with trusted friends.", icon: "person.badge.plus", tint: .vdSky, destination: AnyView(InviteFriendsView()))
        }
        if pendingTrades > 0 {
            return DashboardNextAction(title: "Review trade offer", message: "Take a careful look before you accept.", icon: "tray.full.fill", tint: .vdCoral, destination: AnyView(TradeView()))
        }
        return DashboardNextAction(title: "Check trade matches", message: "Compare wants and vaults with friends.", icon: "scale.3d", tint: .vdGold, destination: AnyView(FriendsView()))
    }

    private var collectionStats: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Collection Stats", subtitle: "Live from local app state")

            LazyVGrid(columns: statColumns, spacing: 12) {
                DashboardStatCard(title: "Cards Owned", value: "\(store.totalCopiesOwned)", caption: "\(store.uniqueCardsOwned) unique cards", systemImage: "rectangle.stack.fill", tint: .vdGold)
                DashboardStatCard(title: "Unique Sets", value: "\(store.uniqueSetsOwned)", caption: "Sets represented", systemImage: "rectangle.3.group.fill", tint: .vdSky)
                DashboardStatCard(title: "Wishlist Matches", value: "\(friendOpportunities.reduce(0) { $0 + $1.theyOwn.count })", caption: "Friends own cards you want", systemImage: "star.bubble.fill", tint: .vdLeaf)
                DashboardStatCard(title: "Pending Trades", value: "\(pendingTrades)", caption: "Offers awaiting action", systemImage: "clock.badge.fill", tint: .vdCoral)
            }
        }
    }

    private var dashboardEmptyState: some View {
        EmptyStateView(
            systemImage: "rectangle.stack.badge.plus",
            title: "Start building your vault",
            message: "Find your first card and add it to My Vault."
        )
    }

    private var recentlyAddedSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("Recently Added")
                    .font(.title3.weight(.black))
                    .foregroundStyle(Color.vdTextPrimary)
                    .lineLimit(1)

                Spacer()

                NavigationLink {
                    VaultView()
                } label: {
                    Text("View all")
                        .font(.caption.weight(.black))
                        .foregroundStyle(Color.vdGold)
                        .lineLimit(1)
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: 10) {
                ForEach(store.recentlyAdded.prefix(3)) { item in
                    FeaturedDashboardCard(item: item)
                }
            }
        }
    }

    private var featuredCards: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Recently Added", subtitle: nil)

            if store.collectionItems.isEmpty {
                EmptyStateView(systemImage: "sparkles.rectangle.stack", title: "Your vault is empty", message: "Add your first card.")
            } else {
                VStack(spacing: 12) {
                    ForEach(store.recentlyAdded.prefix(3)) { item in
                        FeaturedDashboardCard(item: item)
                    }
                }
            }
        }
    }

    private var friendOpportunitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Trade Opportunities", subtitle: nil)

            if store.friends.isEmpty {
                EmptyStateView(systemImage: "person.2.badge.plus", title: "No trade matches yet", message: "Add friends to start trading.")
            } else {
                LazyVGrid(columns: statColumns, spacing: 12) {
                    OpportunityCard(
                        title: "\(friendsWithWantedCards) friends have cards you want",
                        subtitle: firstWantedMatchText,
                        icon: "person.2.fill",
                        tint: .vdGold
                    )

                    OpportunityCard(
                        title: "\(highlightedFairTradeSuggestions) fair trades suggested",
                        subtitle: "\(fairTradeSuggestions) total matches from both wants lists",
                        icon: "scale.3d",
                        tint: .vdLeaf
                    )
                }
            }
        }
    }

    private var firstWantedMatchText: String {
        guard let opportunity = friendOpportunities.first(where: { !$0.theyOwn.isEmpty }),
              let card = opportunity.theyOwn.first?.card else {
            return "Add wants to unlock matches"
        }
        return "\(opportunity.friend.displayName) has \(card.name)"
    }

    private var safetyPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(Color.vdNavy)
                    .frame(width: 54, height: 54)
                    .background(Color.vdGold, in: RoundedRectangle(cornerRadius: 18))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Trade safely")
                        .font(.title3.weight(.black))
                        .foregroundStyle(Color.vdTextPrimary)

                    Text("Review condition, value and trust before trading.")
                        .font(.caption)
                        .foregroundStyle(Color.vdTextSecondary)
                }
            }
        }
        .padding(18)
        .background(
            LinearGradient(colors: [Color.vdGold.opacity(0.16), Color.vdPanel.opacity(0.9), Color.vdPanelRaised.opacity(0.86)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 22)
        )
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.vdGold.opacity(0.28), lineWidth: 1))
        .shadow(color: Color.vdGold.opacity(0.10), radius: 16, x: 0, y: 8)
    }
}

private struct HeroMetric: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.vdTextSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            Text(value)
                .font(.system(.title3, design: .rounded, weight: .black))
                .foregroundStyle(Color.vdTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(13)
        .background(Color.vdNavy.opacity(0.28), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.vdGold.opacity(0.18), lineWidth: 1))
    }
}

private struct DashboardNextAction {
    let title: String
    let message: String
    let icon: String
    let tint: Color
    let destination: AnyView
}

private struct DashboardQuickAction<Destination: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    let destination: Destination

    init(title: String, subtitle: String, icon: String, tint: Color, @ViewBuilder destination: () -> Destination) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.tint = tint
        self.destination = destination()
    }

    var body: some View {
        NavigationLink {
            destination
        } label: {
            VStack(spacing: 9) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(Color.vdNavy)
                    .frame(width: 50, height: 50)
                    .background(
                        LinearGradient(
                            colors: [tint.opacity(0.98), tint.opacity(0.78)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 17)
                    )
                    .overlay(RoundedRectangle(cornerRadius: 17).stroke(Color.white.opacity(0.24), lineWidth: 1))
                    .shadow(color: tint.opacity(0.16), radius: 10, x: 0, y: 5)

                Text(title)
                    .font(.caption.weight(.black))
                    .foregroundStyle(Color.vdTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .allowsTightening(true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(Color.vdPanel.opacity(0.56), in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.07), lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 20))
            .accessibilityLabel(subtitle)
        }
        .simultaneousGesture(TapGesture().onEnded {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        })
        .buttonStyle(PressableScaleStyle())
    }
}

private struct PressableScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.24, dampingFraction: 0.82), value: configuration.isPressed)
    }
}

private struct DashboardVaultChip: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.black))
                .foregroundStyle(Color.vdGold)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.vdTextSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)

                Text(value)
                    .font(.caption.weight(.black))
                    .foregroundStyle(Color.vdTextPrimary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(Color.vdNavy.opacity(0.34), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }
}

private struct FeaturedDashboardCard: View {
    @EnvironmentObject private var store: LocalVaultStore
    let item: CollectionItem

    private var valueLabel: String {
        if item.card.marketValue > 0 {
            return item.card.marketValue.vaultEstimatedCurrency
        }
        return store.isCheckingValue(for: item.card) ? "Checking value…" : "Value unavailable"
    }

    var body: some View {
        NavigationLink {
            CardDetailView(card: item.card)
        } label: {
            HStack(alignment: .center, spacing: 14) {
                cardThumbnail

                VStack(alignment: .leading, spacing: 10) {
                    Text(item.card.name)
                        .font(.system(.headline, design: .rounded, weight: .black))
                        .foregroundStyle(Color.vdTextPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.86)
                        .multilineTextAlignment(.leading)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 7) {
                            DashboardInfoChip(text: "\(item.card.set.code) #\(item.card.number)", icon: "rectangle.3.group.fill", tint: .vdSky)
                            DashboardInfoChip(text: item.card.rarity.displayName, icon: "sparkles", tint: rarityTint)
                            DashboardInfoChip(text: valueLabel, icon: "seal.fill", tint: .vdGold, isFilled: true)
                        }
                    }
                    .scrollDisabled(false)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.black))
                    .foregroundStyle(Color.vdTextSecondary.opacity(0.85))
            }
            .padding(12)
            .background(
                LinearGradient(
                    colors: [Color.vdPanelRaised.opacity(0.82), Color.vdPanel.opacity(0.58)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 22)
            )
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.07), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.14), radius: 14, x: 0, y: 8)
        }
        .buttonStyle(PressableScaleStyle())
    }

    private var cardThumbnail: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [Color.vdGold.opacity(0.18), Color.vdPanelRaised.opacity(0.92)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if let imageURL = item.card.smallImageURL ?? item.card.largeImageURL {
                CachedAsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image(systemName: "rectangle.stack.fill")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.vdGold)
                }
            } else {
                Image(systemName: "rectangle.stack.fill")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.vdGold)
            }
        }
        .frame(width: 72, height: 98)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(rarityTint.opacity(0.32), lineWidth: 1))
        .shadow(color: rarityTint.opacity(0.14), radius: 10, x: 0, y: 5)
    }

    private var rarityTint: Color {
        switch item.card.rarity {
        case .common: .vdTextSecondary
        case .uncommon: .vdLeaf
        case .rare: .vdSky
        case .epic: .vdViolet
        case .legendary, .mythic: .vdGold
        }
    }
}

private struct DashboardInfoChip: View {
    let text: String
    let icon: String
    let tint: Color
    var isFilled = false

    var body: some View {
        Label(text, systemImage: icon)
            .font(.caption2.weight(.black))
            .foregroundStyle(isFilled ? Color.vdNavy : tint)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(isFilled ? tint : tint.opacity(0.13), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(isFilled ? Color.white.opacity(0.24) : tint.opacity(0.24), lineWidth: 1)
            )
    }
}

private struct OpportunityCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(tint)
                .frame(width: 40, height: 40)
                .background(tint.opacity(0.16), in: RoundedRectangle(cornerRadius: 14))

            Text(title)
                .font(.subheadline.weight(.black))
                .foregroundStyle(Color.vdTextPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(Color.vdTextSecondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.vdPanel.opacity(0.86), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(tint.opacity(0.26), lineWidth: 1))
    }
}

private struct SafetyReminderRow: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(Color.vdGold)
                .frame(width: 30, height: 30)
                .background(Color.vdGold.opacity(0.14), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.vdTextPrimary)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(Color.vdTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.vdPanelRaised.opacity(0.58), in: RoundedRectangle(cornerRadius: 14))
    }
}

private extension CardRarity {
    var dashboardRank: Int {
        switch self {
        case .common: 0
        case .uncommon: 1
        case .rare: 2
        case .epic: 3
        case .legendary: 4
        case .mythic: 5
        }
    }
}
