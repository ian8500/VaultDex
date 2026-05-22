import SwiftUI

struct SocialProfileView: View {
    @EnvironmentObject private var store: LocalVaultStore

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    profileHeader
                    socialStats
                    socialTools
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
                Image(systemName: store.profile.avatarSymbol)
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
                    Text(store.profile.displayName)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.vdTextPrimary)
                        .lineLimit(1)

                    Text(store.profile.handle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.vdGold)

                    Text(store.profile.bio)
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
            ProfileStatTile(title: "Score", value: "\(store.profile.collectorScore)", systemImage: "crown.fill", tint: .vdGold)
            ProfileStatTile(title: "Online", value: "\(onlineFriends)", systemImage: "person.2.fill", tint: .vdEmerald)
            ProfileStatTile(title: "Mythics", value: "\(mythicCount)", systemImage: "sparkles", tint: .vdCoral)
        }
    }

    private var socialTools: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Social", subtitle: "Friends, invites, events, and account controls")

            FeatureLinkCard(
                title: "Friends",
                subtitle: "\(store.friends.count) demo collectors connected",
                systemImage: "person.2.fill",
                tint: .vdEmerald
            ) {
                FriendsView()
            }

            FeatureLinkCard(
                title: "Events",
                subtitle: nextEvent?.title ?? "Upcoming local events",
                systemImage: "calendar",
                tint: .vdGold
            ) {
                EventsView()
            }

            FeatureLinkCard(
                title: "Invite Friends",
                subtitle: "Share a local demo invite code",
                systemImage: "paperplane.fill",
                tint: .vdViolet
            ) {
                InviteFriendsView()
            }

            FeatureLinkCard(
                title: "Account Deletion",
                subtitle: "Offline dry-run for the future privacy flow",
                systemImage: "person.crop.circle.badge.xmark",
                tint: .vdCoral
            ) {
                AccountDeletionView()
            }
        }
    }

    private var setProgress: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Set Progress", subtitle: "Local collection coverage")

            VStack(spacing: 10) {
                ForEach(setProgressRows) { progress in
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
            VaultSectionHeader(title: "Showcase", subtitle: "Favorite vault pieces")

            if store.collectionItems.isEmpty {
                EmptyStateView(
                    systemImage: "star",
                    title: "No showcase yet",
                    message: "Favorites from the vault appear here."
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(store.collectionItems.filter(\.isFavorite)) { item in
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

    private var onlineFriends: Int {
        store.friends.filter(\.isOnline).count
    }

    private var mythicCount: Int {
        store.collectionItems
            .filter { $0.card.rarity == .mythic }
            .reduce(0) { $0 + $1.quantity }
    }

    private var setProgressRows: [SetProgress] {
        store.sets.map { set in
            let owned = Set(store.collectionItems.filter { $0.card.set == set }.map(\.card.id)).count
            let total = store.cards.filter { $0.set == set }.count
            return SetProgress(cardSet: set, owned: owned, total: max(total, 1))
        }
    }

    private var nextEvent: VaultEvent? {
        store.events.sorted { $0.date < $1.date }.first
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
