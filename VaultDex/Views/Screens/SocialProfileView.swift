import SwiftUI

struct SocialProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    profileHeader
                    socialStats
                    setProgress
                    showcase
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
    }

    private var profileHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: viewModel.profile.avatarSymbol)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Color.vdGold)
                    .frame(width: 72, height: 72)
                    .background(
                        LinearGradient(
                            colors: [Color.vdPanelRaised, Color(hex: 0x241E30)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 8)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.vdGold.opacity(0.35), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 5) {
                    Text(viewModel.profile.displayName)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.vdTextPrimary)
                        .lineLimit(1)

                    Text(viewModel.profile.handle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.vdGold)

                    Text(viewModel.profile.bio)
                        .font(.subheadline)
                        .foregroundStyle(Color.vdTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            PrimaryButton(title: "Share Demo Profile", systemImage: "square.and.arrow.up") {}
        }
        .padding(18)
        .background(Color.vdPanel.opacity(0.84), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.78), lineWidth: 1)
        )
    }

    private var socialStats: some View {
        HStack(spacing: 12) {
            ProfileStatTile(title: "Score", value: "\(viewModel.profile.collectorScore)", systemImage: "crown.fill", tint: .vdGold)
            ProfileStatTile(title: "Followers", value: "\(viewModel.profile.followers)", systemImage: "person.2.fill", tint: .vdEmerald)
            ProfileStatTile(title: "Mythics", value: "\(viewModel.mythicCount)", systemImage: "sparkles", tint: .vdCoral)
        }
    }

    private var setProgress: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Set Progress", subtitle: "Local collection coverage")

            VStack(spacing: 10) {
                ForEach(viewModel.setProgress) { progress in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(progress.cardSet.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color.vdTextPrimary)

                                Text(progress.cardSet.code + " · " + "\(progress.cardSet.releaseYear)")
                                    .font(.caption)
                                    .foregroundStyle(Color.vdTextSecondary)
                            }

                            Spacer()

                            Text("\(progress.owned)/\(progress.total)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color.vdGold)
                        }

                        ProgressView(value: progress.fraction)
                            .tint(Color.vdGold)
                            .background(Color.vdStroke.opacity(0.6), in: Capsule())
                    }
                    .padding(14)
                    .background(Color.vdPanel.opacity(0.78), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.vdStroke.opacity(0.68), lineWidth: 1)
                    )
                }
            }
        }
    }

    private var showcase: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Showcase", subtitle: "Favorite vault pieces")

            if viewModel.collectionItems.isEmpty {
                EmptyStateView(
                    systemImage: "star",
                    title: "No showcase yet",
                    message: "Favorites from the vault appear here."
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(viewModel.collectionItems.filter(\.isFavorite)) { item in
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

private struct ProfileStatTile: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.13), in: RoundedRectangle(cornerRadius: 8))

            Text(value)
                .font(.headline)
                .foregroundStyle(Color.vdTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(title)
                .font(.caption)
                .foregroundStyle(Color.vdTextSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.vdPanel.opacity(0.82), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.72), lineWidth: 1)
        )
    }
}
