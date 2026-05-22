import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var store: LocalVaultStore
    @StateObject private var viewModel = DashboardViewModel()

    private let statColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private let featureColumns = [
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    statsGrid
                    featureGrid
                    recentlyAdded
                    friendsWantSection
                    featuredCards
                    activityFeed
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Text("Demo")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.vdGold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.vdGold.opacity(0.14), in: Capsule())
            }
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: store.profile.avatarSymbol)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Color.vdGold)
                .frame(width: 56, height: 56)
                .background(Color.vdPanelRaised, in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.vdStroke, lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome back")
                    .font(.subheadline)
                    .foregroundStyle(Color.vdTextSecondary)

                Text(store.profile.displayName)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.vdTextPrimary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.vdPanel.opacity(0.72), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.7), lineWidth: 1)
        )
    }

    private var statsGrid: some View {
        LazyVGrid(columns: statColumns, spacing: 12) {
            DashboardStatCard(
                title: "Cards Owned",
                value: "\(store.totalCopiesOwned)",
                caption: "\(store.uniqueCardsOwned) unique",
                systemImage: "rectangle.stack.fill",
                tint: .vdEmerald
            )

            DashboardStatCard(
                title: "Estimated Value",
                value: store.estimatedCollectionValue.compactVaultCurrency,
                caption: "Local market estimate",
                systemImage: "chart.line.uptrend.xyaxis",
                tint: .vdGold
            )

            DashboardStatCard(
                title: "Wishlist",
                value: "\(store.wishlistItems.count)",
                caption: "Cards being watched",
                systemImage: "star.fill",
                tint: .vdViolet
            )

            DashboardStatCard(
                title: "Unique Sets",
                value: "\(store.uniqueSetsOwned)",
                caption: "Represented in vault",
                systemImage: "rectangle.stack.badge.person.crop",
                tint: .vdCoral
            )

            DashboardStatCard(
                title: "Demo Dex",
                value: viewModel.completionPercent(in: store).formatted(.percent.precision(.fractionLength(0))),
                caption: "\(store.cards.count) catalog cards",
                systemImage: "checklist.checked",
                tint: .vdEmerald
            )

            DashboardStatCard(
                title: "Friends Online",
                value: "\(store.friends.filter(\.isOnline).count)",
                caption: "\(store.friendWants.count) friend wants",
                systemImage: "person.2.fill",
                tint: .vdViolet
            )
        }
    }

    private var featureGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "VaultDex Hub", subtitle: "Native demo flows ready for offline use")

            LazyVGrid(columns: featureColumns, spacing: 10) {
                FeatureLinkCard(
                    title: "Import Collection",
                    subtitle: "Review camera, CSV, and manual demo imports",
                    systemImage: "square.and.arrow.down.on.square.fill",
                    tint: .vdEmerald
                ) {
                    ImportCollectionView()
                }

                FeatureLinkCard(
                    title: "Wishlist",
                    subtitle: "Track chase cards and target prices",
                    systemImage: "star.fill",
                    tint: .vdGold
                ) {
                    WishlistView()
                }

                FeatureLinkCard(
                    title: "Binder Designer",
                    subtitle: "Arrange showcase pages and empty slots",
                    systemImage: "rectangle.grid.3x2.fill",
                    tint: .vdViolet
                ) {
                    BinderDesignerView()
                }

                FeatureLinkCard(
                    title: "Pokedex Tracker",
                    subtitle: "See demo catalog completion by set",
                    systemImage: "checklist.checked",
                    tint: .vdCoral
                ) {
                    CompletionTrackerView()
                }
            }
        }
    }

    private var featuredCards: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Featured Vault", subtitle: "Highest value demo cards")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(viewModel.highlightCards(in: store)) { card in
                        NavigationLink {
                            CardDetailView(card: card)
                        } label: {
                            let item = store.collectionItem(for: card)
                            CardTile(
                                card: card,
                                quantity: item?.quantity,
                                condition: item?.condition,
                                variant: item?.variant,
                                isAvailableForTrade: item?.isAvailableForTrade ?? false,
                                style: .compact
                            )
                            .frame(width: 220)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
        }
    }

    private var activityFeed: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Recent Activity", subtitle: "Local collection and social updates")

            VStack(spacing: 10) {
                ForEach(viewModel.recentActivity(in: store)) { activity in
                    HStack(spacing: 12) {
                        Image(systemName: activity.systemImage)
                            .foregroundStyle(Color.vdGold)
                            .frame(width: 34, height: 34)
                            .background(Color.vdGold.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

                        VStack(alignment: .leading, spacing: 3) {
                            Text(activity.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.vdTextPrimary)

                            Text(activity.subtitle)
                                .font(.caption)
                                .foregroundStyle(Color.vdTextSecondary)
                        }

                        Spacer()
                    }
                    .padding(12)
                    .background(Color.vdPanel.opacity(0.78), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.vdStroke.opacity(0.65), lineWidth: 1)
                    )
                }
            }
        }
    }

    private var recentlyAdded: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Recently Added", subtitle: "Newest cards in your local collection")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(store.recentlyAdded.prefix(5)) { item in
                        NavigationLink {
                            CardDetailView(card: item.card)
                        } label: {
                            CardTile(
                                card: item.card,
                                quantity: item.quantity,
                                condition: item.condition,
                                variant: item.variant,
                                isAvailableForTrade: item.isAvailableForTrade,
                                style: .compact
                            )
                            .frame(width: 220)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
        }
    }

    private var friendsWantSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Friends Want", subtitle: "Trade ideas from your local social graph")

            VStack(spacing: 10) {
                ForEach(store.friendWants) { want in
                    NavigationLink {
                        CardDetailView(card: want.card)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: want.friend.avatarSymbol)
                                .foregroundStyle(Color.vdGold)
                                .frame(width: 34, height: 34)
                                .background(Color.vdGold.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

                            VStack(alignment: .leading, spacing: 3) {
                                Text(want.friend.displayName + " wants " + want.card.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color.vdTextPrimary)
                                    .lineLimit(1)

                                Text(want.note)
                                    .font(.caption)
                                    .foregroundStyle(Color.vdTextSecondary)
                                    .lineLimit(2)
                            }

                            Spacer()

                            StatusPill(title: want.priority.displayName, tint: want.priority == .grail ? .vdCoral : .vdGold)
                        }
                        .padding(12)
                        .background(Color.vdPanel.opacity(0.78), in: RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.vdStroke.opacity(0.65), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
