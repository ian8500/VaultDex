import SwiftUI

struct RarityBadge: View {
    let rarity: CardRarity

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(tint)
                .frame(width: 7, height: 7)

            Text(rarity.displayName)
                .font(.caption2.weight(.bold))
                .textCase(.uppercase)
                .tracking(0.4)
        }
        .foregroundStyle(textColor)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(
            LinearGradient(colors: [tint.opacity(0.95), tint.opacity(0.52)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: Capsule()
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.32), lineWidth: 1)
        )
        .shadow(color: tint.opacity(0.24), radius: 8, x: 0, y: 3)
    }

    private var tint: Color {
        switch rarity {
        case .common: Color(hex: 0x9BA6B8)
        case .uncommon: .vdLeaf
        case .rare: .vdSky
        case .epic: .vdViolet
        case .legendary: .vdGold
        case .mythic: .vdCoral
        }
    }

    private var textColor: Color {
        switch rarity {
        case .legendary: .vdNavy
        default: .white
        }
    }
}
