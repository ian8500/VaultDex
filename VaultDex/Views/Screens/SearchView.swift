import SwiftUI
import UIKit

struct SearchView: View {
    @EnvironmentObject private var store: LocalVaultStore
    @StateObject private var viewModel = SearchViewModel()
    @State private var showFilters = false
    @State private var successMessage: String?
    @State private var searchTask: Task<Void, Never>?

    private let popularFilters = ["Pikachu", "Charizard", "Eevee", "Mew", "Snorlax", "Holo", "Full Art"]

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    searchField
                    popularQuickFilters
                    filterButton

                    if showFilters {
                        VStack(alignment: .leading, spacing: 12) {
                            typeFilters
                            rarityFilters
                            setFilters
                            sortControls
                        }
                        .padding(14)
                        .background(Color.vdPanel.opacity(0.74), in: RoundedRectangle(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.vdGold.opacity(0.18), lineWidth: 1))
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    if viewModel.isLoading && viewModel.filteredCards(in: store).isEmpty {
                        loadingState
                    } else if viewModel.errorMessage != nil && viewModel.filteredCards(in: store).isEmpty {
                        errorState
                    } else if viewModel.filteredCards(in: store).isEmpty {
                        emptyState
                    } else {
                        VStack(spacing: 12) {
                            ForEach(viewModel.filteredCards(in: store)) { card in
                                let item = store.collectionItem(for: card)
                                SearchResultRow(
                                    card: card,
                                    collectionItem: item,
                                    isWanted: store.isWishlisted(card),
                                    onAddToVault: {
                                        if item == nil {
                                            store.addCard(card)
                                            showSuccess("Added to My Vault")
                                        }
                                    },
                                    onToggleWant: {
                                        if store.isWishlisted(card) {
                                            store.removeFromWishlist(card)
                                        } else {
                                            store.addToWishlist(card, priority: .medium, budget: card.marketValue)
                                            showSuccess("Added to Wants")
                                        }
                                    },
                                    onMarkTrade: {
                                        if store.collectionItem(for: card) == nil {
                                            store.addCard(card)
                                        }
                                        store.updateTradeAvailability(for: card, isAvailable: true)
                                        showSuccess("Marked for Trade")
                                    }
                                )
                            }
                        }

                        loadMoreButton
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .bottomDockSpacing()
            }

            if let successMessage {
                VStack {
                    Spacer()
                    SuccessToast(message: successMessage)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 18)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
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
        .onDisappear {
            searchTask?.cancel()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Search")
                .font(.system(.largeTitle, design: .rounded, weight: .black))
                .foregroundStyle(Color.vdTextPrimary)
            Text("Live card data from the Pokémon TCG database")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.vdTextSecondary)
                .lineLimit(2)
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
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.vdTextSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(Color.vdPanel.opacity(0.82), in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var popularQuickFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(popularFilters, id: \.self) { filter in
                    Button {
                        viewModel.query = filter
                    } label: {
                        Text(filter)
                            .font(.caption.weight(.black))
                            .foregroundStyle(Color.vdNavy)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(Color.vdGold.opacity(0.92), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var filterButton: some View {
        HStack {
            Button {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.88)) {
                    showFilters.toggle()
                }
            } label: {
                Label(showFilters ? "Hide filters" : "Filter", systemImage: "line.3.horizontal.decrease.circle")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.vdGold)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 10)
                    .background(Color.vdGold.opacity(0.12), in: Capsule())
                    .overlay(Capsule().stroke(Color.vdGold.opacity(0.26), lineWidth: 1))
            }
            .buttonStyle(.plain)

            Spacer()

            Text(summaryText)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.vdTextSecondary)
        }
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
            return "\(count) of \(total)"
        }
        return "\(count) cards"
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                ProgressView()
                    .tint(Color.vdGold)

                Text("Loading cards…")
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(Color.vdTextSecondary)

                Spacer()
            }
            .padding(.horizontal, 4)

            ForEach(0..<5, id: \.self) { _ in
                SearchSkeletonRow()
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var errorState: some View {
        VStack(spacing: 16) {
            EmptyStateView(
                systemImage: "wifi.exclamationmark",
                title: viewModel.errorMessage ?? "Cards are taking longer than expected.",
                message: "Try again, or tap a quick search above."
            )

            PrimaryButton(title: "Try again", systemImage: "arrow.clockwise") {
                runSearch()
            }
        }
        .padding(.top, 24)
    }

    private var emptyState: some View {
        EmptyStateView(
            systemImage: "magnifyingglass",
            title: viewModel.query.isEmpty ? "Find a card" : "No cards found",
            message: viewModel.query.isEmpty ? "Search by name or tap a quick chip." : "Try a name, set, number, rarity or type."
        )
        .padding(.top, 32)
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
                    showSuccess("Added to My Vault")
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
                    showSuccess("Added to Wants")
                }
            }

            quickActionButton(
                title: "Trade",
                systemImage: item?.isAvailableForTrade == true ? "arrow.left.arrow.right.circle.fill" : "arrow.left.arrow.right.circle",
                tint: .vdSky
            ) {
                if store.collectionItem(for: card) == nil {
                    store.addCard(card)
                    showSuccess("Added to My Vault")
                }
                store.updateTradeAvailability(for: card, isAvailable: true)
            }
        }
    }

    private func showSuccess(_ message: String) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
            successMessage = message
        }
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    if successMessage == message {
                        successMessage = nil
                    }
                }
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
        searchTask?.cancel()
        searchTask = Task {
            if debounce {
                try? await Task.sleep(for: .milliseconds(400))
            }
            guard !Task.isCancelled else { return }
            await viewModel.search(store: store)
        }
    }
}

private struct SearchResultRow: View {
    let card: Card
    let collectionItem: CollectionItem?
    let isWanted: Bool
    let onAddToVault: () -> Void
    let onToggleWant: () -> Void
    let onMarkTrade: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            NavigationLink {
                CardDetailView(card: card)
            } label: {
                HStack(alignment: .center, spacing: 13) {
                    thumbnail

                    VStack(alignment: .leading, spacing: 9) {
                        Text(card.name)
                            .font(.system(.headline, design: .rounded, weight: .black))
                            .foregroundStyle(Color.vdTextPrimary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.86)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 7) {
                                SearchInfoChip(text: "\(card.set.code) #\(card.number)", systemImage: "rectangle.3.group.fill", tint: .vdSky)
                                SearchInfoChip(text: card.rarity.displayName, systemImage: "sparkles", tint: rarityTint)
                                SearchInfoChip(text: card.marketValue.vaultCurrency, systemImage: "seal.fill", tint: .vdGold, isFilled: true)
                            }
                        }

                        HStack(spacing: 7) {
                            if collectionItem != nil {
                                StatusPill(title: "In My Vault", tint: .vdEmerald)
                            }
                            if isWanted {
                                StatusPill(title: "Wanted", tint: .vdGold)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.black))
                        .foregroundStyle(Color.vdTextSecondary)
                }
            }
            .buttonStyle(.plain)

            HStack(spacing: 8) {
                rowAction(
                    title: collectionItem == nil ? "Vault" : "Saved",
                    systemImage: collectionItem == nil ? "plus.circle.fill" : "checkmark.circle.fill",
                    tint: .vdEmerald,
                    action: onAddToVault
                )
                rowAction(
                    title: isWanted ? "Wanted" : "Wants",
                    systemImage: isWanted ? "star.fill" : "star",
                    tint: .vdGold,
                    isFilled: true,
                    action: onToggleWant
                )
                rowAction(
                    title: "Trade",
                    systemImage: collectionItem?.isAvailableForTrade == true ? "arrow.left.arrow.right.circle.fill" : "arrow.left.arrow.right.circle",
                    tint: .vdSky,
                    action: onMarkTrade
                )
            }
        }
        .padding(12)
        .background(Color.vdPanel.opacity(0.72), in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.07), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 7)
    }

    private var thumbnail: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 13)
                .fill(Color.vdPanelRaised.opacity(0.84))

            if let imageURL = card.smallImageURL ?? card.largeImageURL {
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
        .frame(width: 70, height: 96)
        .clipShape(RoundedRectangle(cornerRadius: 13))
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(rarityTint.opacity(0.28), lineWidth: 1))
    }

    private func rowAction(title: String, systemImage: String, tint: Color, isFilled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.black))
                .foregroundStyle(isFilled ? Color.vdNavy : tint)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(isFilled ? tint : tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 13))
                .overlay(RoundedRectangle(cornerRadius: 13).stroke(tint.opacity(0.26), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var rarityTint: Color {
        switch card.rarity {
        case .common: .vdTextSecondary
        case .uncommon: .vdLeaf
        case .rare: .vdSky
        case .epic: .vdViolet
        case .legendary, .mythic: .vdGold
        }
    }
}

private struct SearchInfoChip: View {
    let text: String
    let systemImage: String
    let tint: Color
    var isFilled = false

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption2.weight(.black))
            .foregroundStyle(isFilled ? Color.vdNavy : tint)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(isFilled ? tint : tint.opacity(0.13), in: Capsule())
            .overlay(Capsule().stroke(isFilled ? Color.white.opacity(0.24) : tint.opacity(0.24), lineWidth: 1))
    }
}

private struct SearchSkeletonRow: View {
    var body: some View {
        HStack(spacing: 13) {
            RoundedRectangle(cornerRadius: 13)
                .fill(Color.vdPanelRaised.opacity(0.72))
                .frame(width: 70, height: 96)

            VStack(alignment: .leading, spacing: 10) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.vdPanelRaised.opacity(0.72))
                    .frame(height: 18)

                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.vdPanelRaised.opacity(0.56))
                    .frame(width: 170, height: 14)

                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.vdPanelRaised.opacity(0.46))
                    .frame(width: 120, height: 14)
            }

            Spacer()
        }
        .padding(12)
        .background(Color.vdPanel.opacity(0.58), in: RoundedRectangle(cornerRadius: 20))
    }
}

struct SuccessToast: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "checkmark.circle.fill")
            .font(.headline.weight(.black))
            .foregroundStyle(Color.vdNavy)
            .frame(maxWidth: .infinity)
            .padding(15)
            .background(Color.vdGold, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.45), lineWidth: 1))
            .shadow(color: Color.vdGold.opacity(0.28), radius: 18, x: 0, y: 8)
    }
}
