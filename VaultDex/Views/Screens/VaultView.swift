import SwiftUI

struct VaultView: View {
    @EnvironmentObject private var store: LocalVaultStore
    @StateObject private var viewModel = VaultViewModel()
    @State private var sortOption: VaultSortOption = .value
    @State private var displayMode: VaultDisplayMode = .grid
    @State private var selectedType: CardType?
    @State private var selectedRarity: CardRarity?
    @State private var tradeOnly = false
    @State private var creditsOnly = false

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
                    collectionSection
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
        VStack(spacing: 12) {
            Picker("View", selection: $displayMode) {
                ForEach(VaultDisplayMode.allCases) { mode in
                    Label(mode.title, systemImage: mode.systemImage).tag(mode)
                }
            }
            .pickerStyle(.segmented)

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

                NavigationLink {
                    CardScannerView()
                } label: {
                    Image(systemName: "camera.viewfinder")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.vdNavy)
                        .frame(width: 54, height: 50)
                        .background(Color.vdGold.opacity(0.92), in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Scan card")

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
    }

    private var filterMenu: some View {
        Menu {
            Picker("Type", selection: $selectedType) {
                Text("All Types").tag(CardType?.none)
                ForEach(CardType.allCases) { type in
                    Text(type.displayName).tag(CardType?.some(type))
                }
            }

            Picker("Rarity", selection: $selectedRarity) {
                Text("All Rarities").tag(CardRarity?.none)
                ForEach(CardRarity.allCases) { rarity in
                    Text(rarity.displayName).tag(CardRarity?.some(rarity))
                }
            }

            Toggle("Available for trade", isOn: $tradeOnly)
            Toggle("Available for credits", isOn: $creditsOnly)

            if hasActiveFilters {
                Button("Clear filters", role: .destructive) {
                    selectedType = nil
                    selectedRarity = nil
                    tradeOnly = false
                    creditsOnly = false
                }
            }
        } label: {
            Label(hasActiveFilters ? "Filters on" : "Filter", systemImage: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.vdGold)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(Color.vdGold.opacity(0.12), in: Capsule())
                .overlay(Capsule().stroke(Color.vdGold.opacity(0.28), lineWidth: 1))
        }
        .buttonStyle(.plain)
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

            if hasActiveFilters {
                HStack(spacing: 8) {
                    Image(systemName: "line.3.horizontal.decrease.circle.fill")
                        .foregroundStyle(Color.vdGold)
                    Text("\(filteredItems.count) shown · \(filteredValue.vaultCurrency)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.vdTextSecondary)
                }
                .padding(.top, 2)
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

    private var collectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VaultSectionHeader(title: "Cards", subtitle: nil)
                Spacer()
                filterMenu
            }

            if store.collectionItems.isEmpty {
                EmptyStateView(
                    systemImage: "rectangle.stack.badge.plus",
                    title: "Your vault is empty. Add your first card.",
                    message: "Search for a card or import your collection."
                )
            } else if filteredItems.isEmpty {
                EmptyStateView(
                    systemImage: "line.3.horizontal.decrease.circle",
                    title: "No cards match these filters.",
                    message: "Clear filters or try a different type or rarity."
                )
            } else if displayMode == .grid {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(filteredItems) { item in
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
            } else {
                VStack(spacing: 10) {
                    ForEach(filteredItems) { item in
                        NavigationLink {
                            CardDetailView(card: item.card)
                        } label: {
                            VaultListRow(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var filteredItems: [CollectionItem] {
        sortedItems.filter { item in
            let matchesType = selectedType == nil || item.card.cardType == selectedType
            let matchesRarity = selectedRarity == nil || item.card.rarity == selectedRarity
            let matchesTrade = !tradeOnly || item.isAvailableForTrade
            let matchesCredits = !creditsOnly || item.isAvailableForCredits
            return matchesType && matchesRarity && matchesTrade && matchesCredits
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

    private var filteredValue: Double {
        filteredItems.reduce(0) { $0 + ($1.card.marketValue * Double($1.quantity)) }
    }

    private var hasActiveFilters: Bool {
        selectedType != nil || selectedRarity != nil || tradeOnly || creditsOnly
    }
}

private struct VaultListRow: View {
    let item: CollectionItem

    var body: some View {
        HStack(spacing: 12) {
            CardArtworkThumbnail(card: item.card)
                .frame(width: 58, height: 80)

            VStack(alignment: .leading, spacing: 5) {
                Text(item.card.name)
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(Color.vdTextPrimary)
                    .lineLimit(1)

                Text(item.card.set.name + " #" + item.card.number)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.vdTextSecondary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    RarityBadge(rarity: item.card.rarity)
                    StatusPill(title: item.condition.displayName, tint: .vdSky)
                    if item.isAvailableForTrade {
                        StatusPill(title: "Trade", tint: .vdEmerald)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 5) {
                Text("x\(item.quantity)")
                    .font(.headline.weight(.black))
                    .foregroundStyle(Color.vdGold)
                Text((item.card.marketValue * Double(item.quantity)).vaultCurrency)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.vdTextSecondary)
            }
        }
        .padding(12)
        .background(Color.vdPanel.opacity(0.84), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.vdStroke.opacity(0.58), lineWidth: 1))
    }
}

private struct CardArtworkThumbnail: View {
    let card: Card

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.vdPanelRaised.opacity(0.9))

            if let url = card.smallImageURL ?? card.largeImageURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFit()
                    default:
                        Image(systemName: "rectangle.portrait.fill")
                            .foregroundStyle(Color.vdGold)
                    }
                }
                .padding(4)
            } else {
                Image(systemName: "rectangle.portrait.fill")
                    .foregroundStyle(Color.vdGold)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private enum VaultDisplayMode: String, CaseIterable, Identifiable {
    case grid
    case list

    var id: String { rawValue }

    var title: String {
        switch self {
        case .grid: "Grid"
        case .list: "List"
        }
    }

    var systemImage: String {
        switch self {
        case .grid: "square.grid.2x2.fill"
        case .list: "list.bullet"
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
