import SwiftUI

struct VaultView: View {
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
                    favorites
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

    private var summary: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Collection Value")
                        .font(.subheadline)
                        .foregroundStyle(Color.vdTextSecondary)

                    Text(viewModel.totalValue.vaultCurrency)
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
                    .background(Color.vdGold.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))
            }

            HStack(spacing: 12) {
                metric(title: "Cards", value: "\(viewModel.totalCopies)")
                metric(title: "Unique", value: "\(viewModel.collectionItems.count)")
                metric(title: "Favorites", value: "\(viewModel.favoriteItems.count)")
            }
        }
        .padding(18)
        .background(Color.vdPanel.opacity(0.82), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.78), lineWidth: 1)
        )
    }

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.headline)
                .foregroundStyle(Color.vdTextPrimary)

            Text(title)
                .font(.caption)
                .foregroundStyle(Color.vdTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.vdPanelRaised.opacity(0.72), in: RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var favorites: some View {
        if !viewModel.favoriteItems.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader(title: "Favorites", subtitle: "Pinned cards in your demo vault")

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(viewModel.favoriteItems) { item in
                            CardTile(card: item.card, quantity: item.quantity, style: .compact)
                                .frame(width: 220)
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
            sectionHeader(title: "Collection", subtitle: "Offline inventory")

            if viewModel.collectionItems.isEmpty {
                EmptyStateView(
                    systemImage: "rectangle.stack.badge.plus",
                    title: "Vault is empty",
                    message: "Demo cards will appear here once added."
                )
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(viewModel.sortedItems) { item in
                        CardTile(card: item.card, quantity: item.quantity, style: .compact)
                    }
                }
            }
        }
    }

    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.vdTextPrimary)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(Color.vdTextSecondary)
        }
    }
}
