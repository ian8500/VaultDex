import SwiftUI

struct SearchView: View {
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
                    VaultSectionHeader(title: "Find Cards", subtitle: "Search the offline demo catalog")
                    searchField
                    rarityFilters
                    setFilters

                    if viewModel.filteredCards.isEmpty {
                        EmptyStateView(
                            systemImage: "magnifyingglass",
                            title: "No cards found",
                            message: "Try a different name, set, type, or rarity."
                        )
                        .padding(.top, 32)
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(viewModel.filteredCards) { card in
                                VStack(alignment: .leading, spacing: 8) {
                                    CardTile(card: card, quantity: viewModel.quantityOwned(for: card), style: .compact)

                                    if viewModel.isWishlisted(card) {
                                        StatusPill(title: "Wishlisted", tint: .vdGold)
                                    } else if viewModel.quantityOwned(for: card) != nil {
                                        StatusPill(title: "In Vault", tint: .vdEmerald)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.large)
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
        .background(Color.vdPanel.opacity(0.9), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.8), lineWidth: 1)
        )
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

    private var setFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(title: "All Sets", isSelected: viewModel.selectedSet == nil) {
                    viewModel.selectedSet = nil
                }

                ForEach(viewModel.allSets) { set in
                    filterChip(title: set.code, isSelected: viewModel.selectedSet == set) {
                        viewModel.selectedSet = set
                    }
                }
            }
        }
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
}
