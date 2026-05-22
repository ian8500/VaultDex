import SwiftUI

struct TradeView: View {
    @EnvironmentObject private var store: LocalVaultStore
    @StateObject private var viewModel = TradeViewModel()

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    tradeBinderSection
                    listingsSection
                    activeSection
                    completedSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("Trade Zone")
        .navigationBarTitleDisplayMode(.large)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Trade Desk")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.vdTextPrimary)

                    Text("Offline listings and offers with demo counterparties")
                        .font(.subheadline)
                        .foregroundStyle(Color.vdTextSecondary)
                }

                Spacer()

                Image(systemName: "arrow.left.arrow.right.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(Color.vdGold)
            }

            PrimaryButton(title: "\(store.tradeableCollectionItems.count) Cards Marked For Trade", systemImage: "checkmark.seal.fill") {}
        }
        .padding(18)
        .background(Color.vdPanel.opacity(0.82), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.78), lineWidth: 1)
        )
    }

    private var tradeBinderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Your Trade Binder", subtitle: "Cards you marked available from detail")

            if store.tradeableCollectionItems.isEmpty {
                EmptyStateView(
                    systemImage: "arrow.left.arrow.right",
                    title: "No trade cards yet",
                    message: "Open a card detail and mark it available for trade."
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(store.tradeableCollectionItems) { item in
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

    private var listingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Trade Listings", subtitle: "\(viewModel.listings.count) cards available")

            VStack(spacing: 12) {
                ForEach(viewModel.listings) { listing in
                    TradeListingRow(listing: listing)
                }
            }
        }
    }

    private var activeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Active Offers", subtitle: "\(viewModel.activeOffers.count) open")

            if viewModel.activeOffers.isEmpty {
                EmptyStateView(
                    systemImage: "arrow.left.arrow.right",
                    title: "No active trades",
                    message: "Accepted and declined offers stay in history."
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.activeOffers) { offer in
                        TradeOfferRow(offer: offer)
                    }
                }
            }
        }
    }

    private var completedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "History", subtitle: "Completed demo activity")

            VStack(spacing: 12) {
                ForEach(viewModel.completedOffers) { offer in
                    TradeOfferRow(offer: offer)
                }
            }
        }
    }
}

private struct TradeListingRow: View {
    let listing: TradeListing

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            CardTile(card: listing.card, style: .compact)
                .frame(width: 150)

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(listing.ownerName)
                            .font(.headline)
                            .foregroundStyle(Color.vdTextPrimary)

                        Text(listing.ownerHandle + " · " + listing.locationLabel)
                            .font(.caption)
                            .foregroundStyle(Color.vdTextSecondary)
                    }

                    Spacer()

                    if listing.isFeatured {
                        StatusPill(title: "Featured", tint: .vdGold)
                    }
                }

                Text(listing.askingFor)
                    .font(.subheadline)
                    .foregroundStyle(Color.vdTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Label(listing.listedAt.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.vdTextSecondary)
            }
        }
        .padding(12)
        .background(Color.vdPanel.opacity(0.86), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.72), lineWidth: 1)
        )
    }
}

private struct TradeOfferRow: View {
    let offer: TradeOffer

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(offer.partnerName)
                        .font(.headline)
                        .foregroundStyle(Color.vdTextPrimary)

                    Text(offer.partnerHandle)
                        .font(.caption)
                        .foregroundStyle(Color.vdTextSecondary)
                }

                Spacer()

                statusBadge
            }

            Text(offer.note)
                .font(.subheadline)
                .foregroundStyle(Color.vdTextSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .top, spacing: 12) {
                cardStack(title: "Offering", cards: offer.offeredCards)
                Image(systemName: "arrow.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.vdGold)
                    .padding(.top, 28)
                cardStack(title: "Requesting", cards: offer.requestedCards)
            }

            HStack {
                Label("\(offer.expiresInDays) days", systemImage: "clock")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.vdTextSecondary)

                Spacer()

                Text(offer.createdAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(Color.vdTextSecondary)
            }
        }
        .padding(16)
        .background(Color.vdPanel.opacity(0.86), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.72), lineWidth: 1)
        )
    }

    private var statusBadge: some View {
        Text(offer.status.displayName)
            .font(.caption.weight(.bold))
            .foregroundStyle(statusTint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(statusTint.opacity(0.14), in: Capsule())
            .overlay(Capsule().stroke(statusTint.opacity(0.35), lineWidth: 1))
    }

    private var statusTint: Color {
        switch offer.status {
        case .pending: .vdGold
        case .accepted: .vdEmerald
        case .countered: .vdViolet
        case .declined: .vdCoral
        }
    }

    private func cardStack(title: String, cards: [Card]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.vdTextSecondary)

            VStack(spacing: 6) {
                ForEach(cards.prefix(3)) { card in
                    HStack(spacing: 8) {
                        Image(systemName: card.accent.symbolName)
                            .font(.caption)
                            .foregroundStyle(Color.vdGold)
                            .frame(width: 24, height: 24)
                            .background(Color.vdGold.opacity(0.11), in: RoundedRectangle(cornerRadius: 6))

                        Text(card.name)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.vdTextPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(Color.vdPanelRaised.opacity(0.72), in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension CardAccent {
    var symbolName: String {
        switch self {
        case .aurora: "sparkles"
        case .ember: "flame.fill"
        case .frost: "snowflake"
        case .solar: "sun.max.fill"
        case .venom: "leaf.fill"
        case .void: "moon.stars.fill"
        }
    }
}
