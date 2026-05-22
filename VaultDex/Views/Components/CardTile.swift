import SwiftUI

enum CardTileStyle {
    case compact
    case standard
}

struct CardTile: View {
    let card: Card
    var quantity: Int?
    var style: CardTileStyle = .standard

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            art

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(card.name)
                            .font(style == .compact ? .subheadline.weight(.bold) : .headline)
                            .foregroundStyle(Color.vdTextPrimary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.86)

                        Text(card.set.code + " · " + card.typeLine)
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
                            .background(Color.vdGold.opacity(0.14), in: Capsule())
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
            }
        }
        .padding(12)
        .background(Color.vdPanel.opacity(0.92), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.78), lineWidth: 1)
        )
    }

    private var art: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(
                colors: card.accent.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading) {
                Spacer()

                Image(systemName: card.accent.symbolName)
                    .font(.system(size: style == .compact ? 30 : 42, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.86))

                Text(card.condition.displayName)
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
                .background(.white.opacity(0.82), in: Capsule())
                .padding(10)
        }
        .frame(height: style == .compact ? 112 : 152)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.14), lineWidth: 1)
        )
    }
}

private extension CardAccent {
    var gradientColors: [Color] {
        switch self {
        case .aurora:
            [Color(hex: 0x2C7A7B), Color(hex: 0x5E5CE6), Color(hex: 0xEAC76A)]
        case .ember:
            [Color(hex: 0x411E28), Color(hex: 0xC44D42), Color(hex: 0xEAC76A)]
        case .frost:
            [Color(hex: 0x153748), Color(hex: 0x7EC8E3), Color(hex: 0xEAF7FF)]
        case .solar:
            [Color(hex: 0x47320E), Color(hex: 0xE8A84E), Color(hex: 0xF47F72)]
        case .venom:
            [Color(hex: 0x10251D), Color(hex: 0x3D9D72), Color(hex: 0xC7F464)]
        case .void:
            [Color(hex: 0x10131A), Color(hex: 0x4D315F), Color(hex: 0x9A85FF)]
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
