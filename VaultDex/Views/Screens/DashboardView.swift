import SwiftUI

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

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    if isLoading {
                        loadingState
                    } else {
                        welcomeHeader
                        vaultSummary
                        quickActions
                        if isVaultEmpty {
                            dashboardEmptyState
                        } else {
                            recentlyAddedSection
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 28)
                .opacity(isLoading || hasAnimated ? 1 : 0)
                .offset(y: isLoading || hasAnimated ? 0 : 12)
            }
        }
        .navigationTitle("Home")
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
        HStack(alignment: .center, spacing: 14) {
            VaultDexLogo(size: 58)

            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome back")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.vdTextSecondary)

                Text(store.profile.displayName)
                    .font(.system(.title2, design: .rounded, weight: .black))
                    .foregroundStyle(Color.vdTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }

            Spacer()

            NavigationLink {
                SocialProfileView()
            } label: {
                Image(systemName: store.profile.avatarSymbol)
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(Color.vdNavy)
                    .frame(width: 44, height: 44)
                    .background(Color.vdGold, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.4), lineWidth: 1)
                    )
                    .shadow(color: Color.vdGold.opacity(0.24), radius: 12, x: 0, y: 6)
                    .accessibilityLabel("Open profile")
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 4)
    }

    private var vaultSummary: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 7) {
                Text("My Vault")
                    .font(.title3.weight(.black))
                    .foregroundStyle(Color.vdTextPrimary)

                Text(store.totalCopiesOwned == 1 ? "1 card saved" : "\(store.totalCopiesOwned) cards saved")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.vdTextSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 5) {
                Text("Estimated Value")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.vdTextSecondary)
                Text(store.estimatedCollectionValue.compactVaultCurrency)
                    .font(.system(.title3, design: .rounded, weight: .black))
                    .foregroundStyle(Color.vdGold)
            }
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [Color.vdPanelRaised.opacity(0.94), Color.vdPanel.opacity(0.82)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22)
        )
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.vdGold.opacity(0.24), lineWidth: 1))
        .shadow(color: Color.vdGold.opacity(0.10), radius: 16, x: 0, y: 8)
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
                HeroMetric(title: "Estimated Value", value: store.estimatedCollectionValue.compactVaultCurrency, icon: "chart.line.uptrend.xyaxis")
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
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Quick Actions", subtitle: nil)

            LazyVGrid(columns: statColumns, spacing: 12) {
                DashboardQuickAction(title: "Search Cards", subtitle: "Find cards", icon: "magnifyingglass", tint: .vdSky) {
                    SearchView()
                }
                DashboardQuickAction(title: "Wants", subtitle: "Cards to hunt", icon: "star.fill", tint: .vdLeaf) {
                    WishlistView()
                }
            }
        }
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
            message: "Search for a card and add it to My Vault."
        )
    }

    private var recentlyAddedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Recently Added", subtitle: nil)

            VStack(spacing: 12) {
                ForEach(store.recentlyAdded.prefix(3)) { item in
                    FeaturedDashboardCard(label: "Added", item: item, accent: .vdSky)
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
                        FeaturedDashboardCard(label: "Added", item: item, accent: .vdSky)
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
            HStack(spacing: 11) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .black))
                    .foregroundStyle(Color.vdNavy)
                    .frame(width: 42, height: 42)
                    .background(tint.opacity(0.9), in: RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(Color.vdTextPrimary)
                    Text(subtitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.vdTextSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .padding(13)
            .background(Color.vdPanel.opacity(0.86), in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(tint.opacity(0.28), lineWidth: 1))
            .shadow(color: tint.opacity(0.10), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }
}

private struct FeaturedDashboardCard: View {
    let label: String
    let item: CollectionItem
    let accent: Color

    var body: some View {
        NavigationLink {
            CardDetailView(card: item.card)
        } label: {
            HStack(spacing: 12) {
                CardTile(card: item.card, quantity: item.quantity, condition: item.condition, variant: item.variant, isAvailableForTrade: item.isAvailableForTrade, style: .compact)
                    .frame(width: 112)

                VStack(alignment: .leading, spacing: 8) {
                    StatusPill(title: label, tint: accent)

                    Text(item.card.name)
                        .font(.headline.weight(.black))
                        .foregroundStyle(Color.vdTextPrimary)
                        .lineLimit(2)

                    Text("\(item.card.set.code) #\(item.card.number) · \(item.card.rarity.displayName)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.vdTextSecondary)
                        .lineLimit(1)

                    Label(item.card.marketValue.vaultCurrency, systemImage: "seal.fill")
                        .font(.caption.weight(.black))
                        .foregroundStyle(Color.vdNavy)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(Color.vdGold, in: Capsule())
                }

                Spacer(minLength: 0)
            }
            .padding(12)
            .background(
                LinearGradient(colors: [Color.vdPanelRaised.opacity(0.94), Color.vdPanel.opacity(0.82)], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 20)
            )
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(accent.opacity(0.28), lineWidth: 1))
            .shadow(color: accent.opacity(0.10), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
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
