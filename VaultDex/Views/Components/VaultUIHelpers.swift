import SwiftUI

private struct BottomDockSpacingModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.bottom, 132)
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
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.16), in: Capsule())
            .overlay(Capsule().stroke(tint.opacity(0.45), lineWidth: 1))
    }
}
