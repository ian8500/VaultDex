import SwiftUI

struct VaultView: View {
    @EnvironmentObject private var store: LocalVaultStore
    @StateObject private var viewModel = VaultViewModel()

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    summary
                    collectionTools
                    favorites
                    collectionGrid
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("My Vault")
        .navigationBarTitleDisplayMode(.large)
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Collection Value")
                        .font(.subheadline)
                        .foregroundStyle(Color.vdTextSecondary)

                    Text(store.estimatedCollectionValue.vaultCurrency)
                        .font(.system(.largeTitle, design: .rounded, weight: .black))
                        .foregroundStyle(Color.vdTextPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                Spacer()

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(Color.vdGold)
                    .frame(width: 52, height: 52)
                    .background(Color.vdGold.opacity(0.16), in: RoundedRectangle(cornerRadius: 16))
            }

            HStack(spacing: 12) {
                MetricPill(title: "Cards", value: "\(store.totalCopiesOwned)")
                MetricPill(title: "Unique", value: "\(store.uniqueCardsOwned)")
                MetricPill(title: "Complete", value: viewModel.completionPercent(in: store).formatted(.percent.precision(.fractionLength(0))))
            }
        }
        .padding(18)
        .background(Color.vdPanel.opacity(0.82), in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.vdGold.opacity(0.26), lineWidth: 1)
        )
    }

    private var collectionTools: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Collection Tools", subtitle: "Track your collection value")

            FeatureLinkCard(
                title: "Import Collection",
                subtitle: "\(viewModel.binderFilledSlots(in: store))/\(viewModel.binderTotalSlots(in: store)) binder slots filled; scan demo cards next",
                systemImage: "square.and.arrow.down.on.square.fill",
                tint: .vdEmerald
            ) {
                ImportCollectionView()
            }

            FeatureLinkCard(
                title: "Wants",
                subtitle: "Find your next grail · \(store.wishlistItems.count) targets",
                systemImage: "star.fill",
                tint: .vdGold
            ) {
                WishlistView()
            }

            FeatureLinkCard(
                title: "My Binder",
                subtitle: "Build your dream binder",
                systemImage: "rectangle.grid.3x2.fill",
                tint: .vdViolet
            ) {
                BinderDesignerView()
            }

            FeatureLinkCard(
                title: "Completion Tracker",
                subtitle: "Track set-by-set demo completion",
                systemImage: "checklist.checked",
                tint: .vdCoral
            ) {
                CompletionTrackerView()
            }
        }
    }

    @ViewBuilder
    private var favorites: some View {
        let favoriteItems = viewModel.favoriteItems(in: store)

        if !favoriteItems.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                VaultSectionHeader(title: "Favorites", subtitle: "Pinned cards in your demo vault")

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(favoriteItems) { item in
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
    }

    private var collectionGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "My Vault", subtitle: "Offline inventory")

            if store.collectionItems.isEmpty {
                EmptyStateView(
                    systemImage: "rectangle.stack.badge.plus",
                    title: "My Vault is empty",
                    message: "Demo cards will appear here once added."
                )
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(viewModel.sortedItems(in: store)) { item in
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
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
