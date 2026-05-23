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
            && store.wishlistItems.isEmpty
            && store.tradeOffers.isEmpty
            && store.tradeListings.isEmpty
            && store.friends.isEmpty
    }

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    if isLoading {
                        loadingState
                    } else {
                        heroCard
                        quickActions
                        if isVaultEmpty {
                            dashboardEmptyState
                        }
                        collectionStats
                        featuredCards
                        friendOpportunitiesSection
                        safetyPanel
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 28)
                .opacity(isLoading || hasAnimated ? 1 : 0)
                .offset(y: isLoading || hasAnimated ? 0 : 12)
            }
        }
        .navigationTitle("Today")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Text(store.runtimeMode.displayName)
                    .font(.caption.weight(.black))
                    .foregroundStyle(Color.vdNavy)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.vdGold.opacity(0.94), in: Capsule())
            }
        }
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

            Text("Checking cards, wants, trade offers, and safe-trade reminders.")
                .font(.subheadline)
                .foregroundStyle(Color.vdTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(Color.vdPanel.opacity(0.88), in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.vdGold.opacity(0.24), lineWidth: 1))
        .padding(.top, 80)
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

            Text("Track your collection value")
                .font(.caption.weight(.black))
                .foregroundStyle(Color.vdGold)
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
            VaultSectionHeader(title: "Quick Actions", subtitle: "Jump straight into the collection flow")

            LazyVGrid(columns: statColumns, spacing: 12) {
                DashboardQuickAction(title: "Add Card", subtitle: "Grow My Vault", icon: "plus.circle.fill", tint: .vdGold) {
                    SearchView()
                }
                DashboardQuickAction(title: "Search", subtitle: "Find cards", icon: "magnifyingglass", tint: .vdSky) {
                    SearchView()
                }
                DashboardQuickAction(title: "Import", subtitle: "Paste CSV", icon: "square.and.arrow.down.on.square.fill", tint: .vdLeaf) {
                    ImportCollectionView()
                }
                DashboardQuickAction(title: "Trade", subtitle: "Trade Hub", icon: "arrow.left.arrow.right", tint: .vdCoral) {
                    TradeView()
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
            message: "Search for real cards, import a CSV, or add wants to turn this dashboard into your collector command centre."
        )
    }

    private var featuredCards: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Featured Cards", subtitle: "Rarest, highest value, and newest pulls")

            if store.collectionItems.isEmpty {
                EmptyStateView(systemImage: "sparkles.rectangle.stack", title: "Start building your vault", message: "Add your first card to reveal rarest, highest value, and recently added highlights.")
            } else {
                VStack(spacing: 12) {
                    if let rarestItem {
                        FeaturedDashboardCard(label: "Rarest Card", item: rarestItem, accent: .vdGold)
                    }
                    if let highestValueItem {
                        FeaturedDashboardCard(label: "Highest Value Card", item: highestValueItem, accent: .vdLeaf)
                    }
                    if let recentlyAddedItem {
                        FeaturedDashboardCard(label: "Recently Added", item: recentlyAddedItem, accent: .vdSky)
                    }
                }
            }
        }
    }

    private var friendOpportunitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Friend Opportunities", subtitle: "Match with collectors")

            if store.friends.isEmpty {
                EmptyStateView(systemImage: "person.2.badge.plus", title: "Add collectors to trade safely", message: "Connect with trusted collectors to compare wants, collections, and fair trade ideas.")
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

                    Text("Friendly reminders before real accounts and moderation arrive.")
                        .font(.caption)
                        .foregroundStyle(Color.vdTextSecondary)
                }
            }

            VStack(spacing: 10) {
                SafetyReminderRow(icon: "person.crop.circle.badge.checkmark", title: "Parent approval", message: "Require a trusted grown-up review before young collectors trade.")
                SafetyReminderRow(icon: "hand.raised.fill", title: "Report/block reminders", message: "Keep report and block controls visible on listings and profiles.")
                SafetyReminderRow(icon: "checkmark.seal.fill", title: "Value and condition check", message: "Review condition, variant, credits, and fairness before accepting.")
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
