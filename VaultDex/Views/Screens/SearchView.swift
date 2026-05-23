import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var store: LocalVaultStore
    @StateObject private var viewModel = SearchViewModel()

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    VaultSectionHeader(title: "Find Cards", subtitle: "Search live Pokémon TCG cards")
                    searchField
                    apiStatus
                    typeFilters
                    rarityFilters
                    setFilters
                    sortControls
                    resultsSummary

                    if viewModel.isLoading && viewModel.filteredCards(in: store).isEmpty {
                        loadingState
                    } else if viewModel.filteredCards(in: store).isEmpty {
                        EmptyStateView(
                            systemImage: "magnifyingglass",
                            title: "No cards found",
                            message: viewModel.errorMessage ?? "Try a different name, set, type, or rarity."
                        )
                        .padding(.top, 32)
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(viewModel.filteredCards(in: store)) { card in
                                let item = store.collectionItem(for: card)

                                VStack(alignment: .leading, spacing: 8) {
                                    NavigationLink {
                                        CardDetailView(card: card)
                                    } label: {
                                        VStack(alignment: .leading, spacing: 8) {
                                            CardTile(
                                                card: card,
                                                quantity: item?.quantity,
                                                condition: item?.condition,
                                                variant: item?.variant,
                                                isAvailableForTrade: item?.isAvailableForTrade ?? false,
                                                style: .compact
                                            )

                                            if store.isWishlisted(card) {
                                                StatusPill(title: "Wanted", tint: .vdGold)
                                            } else if item != nil {
                                                StatusPill(title: "In My Vault", tint: .vdEmerald)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)

                                    quickActions(for: card, item: item)
                                }
                            }
                        }

                        loadMoreButton
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadInitialResults(store: store)
        }
        .onChange(of: viewModel.query) { _, _ in
            runSearch(debounce: true)
        }
        .onChange(of: viewModel.selectedRarity) { _, _ in
            runSearch()
        }
        .onChange(of: viewModel.selectedType) { _, _ in
            runSearch()
        }
        .onChange(of: viewModel.selectedSet) { _, _ in
            runSearch()
        }
        .onChange(of: viewModel.sortOption) { _, _ in
            runSearch()
        }
    }

    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.vdTextSecondary)

            TextField("Search cards, sets, or types", text: $viewModel.query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundStyle(Color.vdTextPrimary)

            if !viewModel.query.isEmpty {
                Button {
                    viewModel.query = ""
                    runSearch()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.vdTextSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(Color.vdPanel.opacity(0.9), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.8), lineWidth: 1)
        )
    }

    private var sortControls: some View {
        HStack(spacing: 10) {
            Label("Sort", systemImage: "arrow.up.arrow.down")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.vdTextSecondary)

            Picker("Sort", selection: $viewModel.sortOption) {
                ForEach(SearchSortOption.allCases) { option in
                    Text(option.displayName).tag(option)
                }
            }
            .pickerStyle(.menu)
            .tint(Color.vdGold)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.vdPanel.opacity(0.72), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.64), lineWidth: 1)
        )
    }

    private var resultsSummary: some View {
        HStack(spacing: 8) {
            Image(systemName: "square.grid.2x2.fill")
                .foregroundStyle(Color.vdGold)

            Text(summaryText)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.vdTextSecondary)

            Spacer()
        }
    }

    private var summaryText: String {
        let count = viewModel.filteredCards(in: store).count
        if let total = viewModel.totalResults, !viewModel.isShowingFallback {
            return "\(count) of \(total) live cards"
        }
        return "\(count) cards"
    }

    private var apiStatus: some View {
        Group {
            if viewModel.isLoading {
                Label("Loading live card data", systemImage: "arrow.clockwise")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.vdGold)
            } else if viewModel.isShowingFallback {
                Label("Live API unavailable. Showing local fallback cards.", systemImage: "wifi.slash")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.vdCoral)
            } else if viewModel.didLoadAPI {
                Label("Live Pokémon TCG results", systemImage: "checkmark.icloud.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.vdLeaf)
            }
        }
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(Color.vdGold)
            Text("Searching the card archive...")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.vdTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .background(Color.vdPanel.opacity(0.72), in: RoundedRectangle(cornerRadius: 8))
    }

    private var rarityFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(title: "All", isSelected: viewModel.selectedRarity == nil) {
                    viewModel.selectedRarity = nil
                }

                ForEach(CardRarity.allCases) { rarity in
                    filterChip(title: rarity.displayName, isSelected: viewModel.selectedRarity == rarity) {
                        viewModel.selectedRarity = rarity
                    }
                }
            }
        }
    }

    private var typeFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(title: "All Types", isSelected: viewModel.selectedType == nil) {
                    viewModel.selectedType = nil
                }

                ForEach(CardType.allCases) { type in
                    filterChip(title: type.displayName, isSelected: viewModel.selectedType == type) {
                        viewModel.selectedType = type
                    }
                }
            }
        }
    }

    private var setFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(title: "All Sets", isSelected: viewModel.selectedSet == nil) {
                    viewModel.selectedSet = nil
                }

                ForEach(viewModel.availableSets(in: store)) { set in
                    filterChip(title: set.code, isSelected: viewModel.selectedSet == set) {
                        viewModel.selectedSet = set
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var loadMoreButton: some View {
        if viewModel.canLoadMore {
            Button {
                Task { await viewModel.loadMore(store: store) }
            } label: {
                HStack(spacing: 10) {
                    if viewModel.isLoadingMore {
                        ProgressView()
                            .tint(Color(hex: 0x111318))
                    } else {
                        Image(systemName: "plus.circle.fill")
                    }

                    Text(viewModel.isLoadingMore ? "Loading more cards" : "Load more cards")
                        .font(.headline.weight(.bold))
                }
                .foregroundStyle(Color(hex: 0x111318))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.vdGold, in: RoundedRectangle(cornerRadius: 8))
                .shadow(color: Color.vdGold.opacity(0.22), radius: 16, x: 0, y: 8)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoadingMore)
            .padding(.top, 4)
        }
    }

    private func quickActions(for card: Card, item: CollectionItem?) -> some View {
        HStack(spacing: 6) {
            quickActionButton(
                title: "Vault",
                systemImage: item == nil ? "plus.circle.fill" : "checkmark.circle.fill",
                tint: .vdEmerald
            ) {
                if item == nil {
                    store.addCard(card)
                }
            }

            quickActionButton(
                title: "Wants",
                systemImage: store.isWishlisted(card) ? "star.fill" : "star",
                tint: .vdGold
            ) {
                if store.isWishlisted(card) {
                    store.removeFromWishlist(card)
                } else {
                    store.addToWishlist(card, priority: .medium, budget: card.marketValue)
                }
            }

            quickActionButton(
                title: "Trade",
                systemImage: item?.isAvailableForTrade == true ? "arrow.left.arrow.right.circle.fill" : "arrow.left.arrow.right.circle",
                tint: .vdSky
            ) {
                if store.collectionItem(for: card) == nil {
                    store.addCard(card)
                }
                store.updateTradeAvailability(for: card, isAvailable: true)
            }
        }
    }

    private func quickActionButton(
        title: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.bold))
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(tint.opacity(0.28), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(isSelected ? Color(hex: 0x111318) : .vdTextPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.vdGold : Color.vdPanelRaised, in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.vdGold.opacity(0.3) : Color.vdStroke, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func runSearch(debounce: Bool = false) {
        Task {
            if debounce {
                try? await Task.sleep(for: .milliseconds(350))
            }
            await viewModel.search(store: store)
        }
    }
}
