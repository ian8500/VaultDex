import SwiftUI

enum CardTileStyle {
    case compact
    case standard
}

struct CardTile: View {
    let card: Card
    var quantity: Int?
    var condition: CardCondition?
    var variant: CardVariant?
    var isAvailableForTrade = false
    var style: CardTileStyle = .standard

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            art

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(card.name)
                            .font(style == .compact ? .subheadline.weight(.black) : .headline.weight(.black))
                            .foregroundStyle(Color.vdTextPrimary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.86)

                        Text(card.set.code + " #" + card.number + " · " + card.cardType.displayName + " · " + card.typeLine)
                            .font(.caption)
                            .foregroundStyle(Color.vdTextSecondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)

                    if let quantity {
                        Text("x\(quantity)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.vdGold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.vdGold.opacity(0.9), in: Capsule())
                            .foregroundStyle(Color.vdNavy)
                    }
                }

                HStack {
                    RarityBadge(rarity: card.rarity)

                    Spacer()

                    Text(card.marketValue.vaultCurrency)
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(Color.vdTextPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                if variant != nil || isAvailableForTrade {
                    HStack(spacing: 6) {
                        if let variant {
                            StatusPill(title: variant.displayName, tint: .vdViolet)
                        }

                        if isAvailableForTrade {
                            StatusPill(title: "For Trade", tint: .vdEmerald)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(
            LinearGradient(
                colors: [Color.vdPanelRaised.opacity(0.98), Color.vdPanel.opacity(0.94)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(card.rarity.cardFrameTint.opacity(0.68), lineWidth: 1.25)
        )
        .overlay(cardShine.clipShape(RoundedRectangle(cornerRadius: 18)))
        .shadow(color: card.rarity.rarityGlow.opacity(0.34), radius: card.rarity.glowRadius, x: 0, y: 0)
        .shadow(color: Color.vdNavy.opacity(0.18), radius: 16, x: 0, y: 8)
    }

    private var art: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(
                colors: card.accent.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.vdGold.opacity(0.72), lineWidth: 2)
                .padding(7)

            LinearGradient(
                colors: [Color.white.opacity(0.0), Color.white.opacity(0.32), Color.white.opacity(0.0)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .rotationEffect(.degrees(-10))

            if isFoil {
                foilShimmer
            }

            if let imageURL = card.smallImageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFit()
                            .padding(8)
                            .transition(.opacity)
                    default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            VStack(alignment: .leading) {
                Spacer()

                if card.smallImageURL == nil {
                    Image(systemName: card.accent.symbolName)
                        .font(.system(size: style == .compact ? 30 : 42, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.86))
                        .shadow(color: .black.opacity(0.22), radius: 6, x: 0, y: 4)
                }

                Text((condition ?? card.condition).displayName)
                    .font(.caption2.weight(.bold))
                    .textCase(.uppercase)
                    .foregroundStyle(.white.opacity(0.78))
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)

            Text("\(card.power)")
                .font(.system(.callout, design: .rounded, weight: .black))
                .foregroundStyle(Color(hex: 0x111318))
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(Color.vdGold.opacity(0.92), in: Capsule())
                .padding(10)

            Text(card.cardType.displayName)
                .font(.caption2.weight(.black))
                .textCase(.uppercase)
                .foregroundStyle(.white.opacity(0.86))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(.black.opacity(0.26), in: Capsule())
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(10)
        }
        .frame(height: style == .compact ? 112 : 152)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(.white.opacity(0.26), lineWidth: 1)
        )
    }

    private var isFoil: Bool {
        switch variant {
        case .holo, .reverseHolo, .fullArt, .secretRare, .promo:
            true
        case .normal, .none:
            false
        }
    }

    private var cardShine: some View {
        LinearGradient(
            colors: [Color.white.opacity(0.16), Color.clear, Color.vdGold.opacity(0.08), Color.clear],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .allowsHitTesting(false)
    }

    private var foilShimmer: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.white.opacity(0.0),
                    Color.white.opacity(0.34),
                    Color.vdSky.opacity(0.26),
                    Color.vdGold.opacity(0.30),
                    Color.white.opacity(0.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .rotationEffect(.degrees(12))
            .blendMode(.screen)

            Image(systemName: "sparkles")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.28))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(14)
        }
        .allowsHitTesting(false)
    }
}

private extension CardAccent {
    var gradientColors: [Color] {
        switch self {
        case .aurora:
            [Color.vdMidnight, Color.vdSky, Color.vdGold]
        case .ember:
            [Color.vdNavy, Color.vdCoral, Color.vdGold]
        case .frost:
            [Color.vdMidnight, Color.vdSky, Color(hex: 0xEAF7FF)]
        case .solar:
            [Color(hex: 0x8E6100), Color.vdGold, Color.vdCoral]
        case .venom:
            [Color.vdNavy, Color.vdLeaf, Color.vdGold]
        case .void:
            [Color.vdMidnight, Color.vdViolet, Color.vdGold]
        }
    }

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

private extension CardRarity {
    var cardFrameTint: Color {
        switch self {
        case .common: Color(hex: 0x9BA6B8)
        case .uncommon: .vdLeaf
        case .rare: .vdSky
        case .epic: .vdViolet
        case .legendary: .vdGold
        case .mythic: .vdCoral
        }
    }

    var rarityGlow: Color {
        switch self {
        case .common: Color.clear
        case .uncommon: .vdLeaf
        case .rare: .vdSky
        case .epic: .vdViolet
        case .legendary: .vdGold
        case .mythic: .vdCoral
        }
    }

    var glowRadius: CGFloat {
        switch self {
        case .common: 0
        case .uncommon: 6
        case .rare: 10
        case .epic: 14
        case .legendary, .mythic: 18
        }
    }
}
