import SwiftUI

struct VaultView: View {
    @EnvironmentObject private var store: LocalVaultStore
    @StateObject private var viewModel = VaultViewModel()
    @State private var sortOption: VaultSortOption = .value

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
                    vaultActions
                    collectionGrid
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("Vault")
        .navigationBarTitleDisplayMode(.large)
    }

    private var vaultActions: some View {
        HStack(spacing: 12) {
            NavigationLink {
                SearchView()
            } label: {
                Label("Add card", systemImage: "plus.circle.fill")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.vdNavy)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.vdGold, in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)

            Menu {
                Picker("Sort", selection: $sortOption) {
                    ForEach(VaultSortOption.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.vdGold)
                    .frame(width: 54, height: 50)
                    .background(Color.vdPanelRaised.opacity(0.82), in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.vdGold.opacity(0.24), lineWidth: 1))
            }
            .menuStyle(.button)
            .accessibilityLabel("Sort and filter")
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Estimated Value")
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

    private var primaryActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Tools", subtitle: nil)

            FeatureLinkCard(
                title: "Import Collection",
                subtitle: "Upload CSV or JSON",
                systemImage: "square.and.arrow.down.on.square.fill",
                tint: .vdEmerald
            ) {
                ImportCollectionView()
            }

            FeatureLinkCard(
                title: "Wants",
                subtitle: "\(store.wishlistItems.count) cards",
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
                subtitle: "Track set-by-set completion",
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
            VaultSectionHeader(title: "Favorites", subtitle: nil)

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
            VaultSectionHeader(title: "Cards", subtitle: nil)

            if store.collectionItems.isEmpty {
                EmptyStateView(
                    systemImage: "rectangle.stack.badge.plus",
                    title: "Your vault is empty. Add your first card.",
                    message: "Search for a card or import your collection."
                )
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(sortedItems) { item in
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

    private var sortedItems: [CollectionItem] {
        switch sortOption {
        case .value:
            return viewModel.sortedItems(in: store)
        case .name:
            return store.collectionItems.sorted { $0.card.name.localizedCaseInsensitiveCompare($1.card.name) == .orderedAscending }
        case .newest:
            return store.collectionItems.sorted { $0.acquiredAt > $1.acquiredAt }
        }
    }
}

private enum VaultSortOption: String, CaseIterable, Identifiable {
    case value
    case name
    case newest

    var id: String { rawValue }

    var title: String {
        switch self {
        case .value: "Value"
        case .name: "Name"
        case .newest: "Newest"
        }
    }
}
