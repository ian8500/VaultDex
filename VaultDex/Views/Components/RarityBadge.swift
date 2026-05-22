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
        .foregroundStyle(.vdTextPrimary)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(tint.opacity(0.16), in: Capsule())
        .overlay(
            Capsule()
                .stroke(tint.opacity(0.42), lineWidth: 1)
        )
    }

    private var tint: Color {
        switch rarity {
        case .common: .vdTextSecondary
        case .uncommon: .vdEmerald
        case .rare: Color(hex: 0x6FC8FF)
        case .epic: .vdViolet
        case .legendary: .vdGold
        case .mythic: .vdCoral
        }
    }
}

#Preview {
    HStack {
        ForEach(CardRarity.allCases) { rarity in
            RarityBadge(rarity: rarity)
        }
    }
    .padding()
    .background(AppBackground())
}
