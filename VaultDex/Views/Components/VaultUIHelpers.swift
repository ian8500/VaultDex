import SwiftUI

private struct BottomDockSpacingModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.bottom, 136)
    }
}

extension View {
    func bottomDockSpacing() -> some View {
        modifier(BottomDockSpacingModifier())
    }
}

struct VaultSectionHeader: View {
    let title: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.vdTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.84)
                .shadow(color: Color.vdGold.opacity(0.16), radius: 8, x: 0, y: 2)

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.vdTextSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct CompactInfoChip: View {
    let title: String
    let tint: Color
    var isProminent = false

    var body: some View {
        Text(title)
            .font(.caption2.weight(.bold))
            .lineLimit(1)
            .minimumScaleFactor(0.86)
            .foregroundStyle(isProminent ? Color.vdNavy : tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                (isProminent ? tint.opacity(0.92) : tint.opacity(0.13)),
                in: Capsule()
            )
            .overlay(Capsule().stroke(tint.opacity(isProminent ? 0.22 : 0.28), lineWidth: 1))
    }
}

struct CompactRarityChip: View {
    let rarity: CardRarity

    var body: some View {
        CompactInfoChip(title: rarity.displayName, tint: rarityTint, isProminent: rarity == .legendary || rarity == .mythic)
    }

    private var rarityTint: Color {
        switch rarity {
        case .common: Color(hex: 0x9BA6B8)
        case .uncommon: .vdLeaf
        case .rare: .vdSky
        case .epic: .vdViolet
        case .legendary: .vdGold
        case .mythic: .vdCoral
        }
    }
}

struct VaultCardThumbnail: View {
    let card: Card

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.vdPanelRaised.opacity(0.92))

            if let url = card.smallImageURL ?? card.largeImageURL {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .padding(4)
                } placeholder: {
                    placeholder
                }
            } else {
                placeholder
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(frameTint.opacity(0.30), lineWidth: 1)
        )
        .shadow(color: rarityGlow.opacity(0.12), radius: 10, x: 0, y: 4)
        .accessibilityHidden(true)
    }

    private var placeholder: some View {
        Image(systemName: "rectangle.portrait.fill")
            .font(.title2.weight(.bold))
            .foregroundStyle(Color.vdGold.opacity(0.84))
    }

    private var frameTint: Color {
        switch card.rarity {
        case .common: Color(hex: 0x9BA6B8)
        case .uncommon: .vdLeaf
        case .rare: .vdSky
        case .epic: .vdViolet
        case .legendary: .vdGold
        case .mythic: .vdCoral
        }
    }

    private var rarityGlow: Color {
        switch card.rarity {
        case .common: Color.clear
        case .uncommon: .vdLeaf
        case .rare: .vdSky
        case .epic: .vdViolet
        case .legendary: .vdGold
        case .mythic: .vdCoral
        }
    }
}

struct FeatureLinkCard<Destination: View>: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    private let destination: Destination

    init(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color,
        @ViewBuilder destination: () -> Destination
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.tint = tint
        self.destination = destination()
    }

    var body: some View {
        NavigationLink {
            destination
        } label: {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(tint)
                    .frame(width: 42, height: 42)
                    .background(
                        LinearGradient(colors: [tint.opacity(0.22), Color.vdPanelRaised.opacity(0.82)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 14)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.vdTextPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color.vdTextSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.vdTextSecondary)
            }
            .padding(15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.vdPanel.opacity(0.86), in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.vdGold.opacity(0.22), lineWidth: 1)
            )
            .shadow(color: Color.vdGold.opacity(0.08), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
}

struct MetricPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.headline)
                .foregroundStyle(Color.vdTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(title)
                .font(.caption)
                .foregroundStyle(Color.vdTextSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.vdPanelRaised.opacity(0.78), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.vdGold.opacity(0.16), lineWidth: 1)
        )
    }
}

struct StatusPill: View {
    let title: String
    let tint: Color

    var body: some View {
        Text(title)
            .font(.caption.weight(.bold))
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.16), in: Capsule())
            .overlay(Capsule().stroke(tint.opacity(0.45), lineWidth: 1))
    }
}
