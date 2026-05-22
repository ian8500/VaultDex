import SwiftUI

struct SocialProfileView: View {
    @EnvironmentObject private var store: LocalVaultStore
    @State private var draft = ProfileDraft()
    @State private var hasLoadedDraft = false
    @State private var didSaveProfile = false

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    profileHeader
                    profileEditor
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
        .onAppear {
            guard !hasLoadedDraft else { return }
            draft = ProfileDraft(profile: store.profile)
            hasLoadedDraft = true
        }
    }

    private var profileHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: store.profile.avatarSymbol)
                    .font(.system(size: 32, weight: .black))
                    .foregroundStyle(Color.vdNavy)
                    .frame(width: 78, height: 78)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: 0xFFF06A), Color.vdGold, Color.vdGoldDeep],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 22)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color.white.opacity(0.48), lineWidth: 1)
                    )
                    .shadow(color: Color.vdGold.opacity(0.32), radius: 16, x: 0, y: 8)

                VStack(alignment: .leading, spacing: 5) {
                    Text(store.profile.displayName)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.vdTextPrimary)
                        .lineLimit(1)

                    Text(store.profile.handle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.vdGold)

                    Text(store.profile.location + " · " + store.profile.collectorType)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.vdTextSecondary)

                    Text(store.profile.bio)
                        .font(.subheadline)
                        .foregroundStyle(Color.vdTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 8) {
                ForEach(store.profile.trustBadges.prefix(3), id: \.self) { badge in
                    StatusPill(title: badge, tint: .vdEmerald)
                }
            }

            PrimaryButton(title: "Save Profile Changes", systemImage: "checkmark.seal.fill") {
                store.updateProfile(draft.makeProfile(from: store.profile))
                didSaveProfile = true
            }

            if didSaveProfile {
                Label("Changes saved locally", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.vdEmerald)
                    .transition(.opacity)
            }
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [Color.vdPanelRaised.opacity(0.94), Color.vdPanel.opacity(0.78)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.vdGold.opacity(0.28), lineWidth: 1)
        )
        .shadow(color: Color.vdGold.opacity(0.10), radius: 18, x: 0, y: 8)
    }

    private var profileEditor: some View {
        VStack(alignment: .leading, spacing: 14) {
            VaultSectionHeader(title: "My Profile", subtitle: "Edit the local profile fields that will sync later")

            VStack(spacing: 12) {
                ProfileTextField(title: "Avatar symbol", text: $draft.avatarSymbol, systemImage: "photo.badge.plus")
                ProfileTextField(title: "Username", text: $draft.handle, systemImage: "at")
                ProfileTextField(title: "Display name", text: $draft.displayName, systemImage: "person.text.rectangle")
                ProfileTextField(title: "Location", text: $draft.location, systemImage: "location.fill")
                ProfileTextField(title: "Collector type", text: $draft.collectorType, systemImage: "crown.fill")

                VStack(alignment: .leading, spacing: 8) {
                    Label("Bio", systemImage: "text.alignleft")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.vdTextSecondary)

                    TextEditor(text: $draft.bio)
                        .frame(minHeight: 94)
                        .scrollContentBackground(.hidden)
                        .padding(10)
                        .foregroundStyle(Color.vdTextPrimary)
                        .background(Color.vdPanelRaised.opacity(0.84), in: RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.vdStroke.opacity(0.72), lineWidth: 1)
                        )
                }
            }

            Text("Avatar upload is represented by the symbol field for now. A photo picker can attach to this same profile field when storage is added.")
                .font(.caption)
                .foregroundStyle(Color.vdTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var socialStats: some View {
        HStack(spacing: 12) {
            ProfileStatTile(title: "Reputation", value: "\(store.profile.reputationScore)", systemImage: "shield.checkered", tint: .vdGold)
            ProfileStatTile(title: "Trades", value: "\(store.profile.completedTrades)", systemImage: "arrow.left.arrow.right", tint: .vdEmerald)
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
                title: "Settings",
                subtitle: "Privacy controls and local demo preferences",
                systemImage: "gearshape.fill",
                tint: .vdGold
            ) {
                SettingsView()
            }

            FeatureLinkCard(
                title: "Safety Centre",
                subtitle: "Trading guidance, privacy, reporting, and disclaimers",
                systemImage: "shield.lefthalf.filled",
                tint: .vdEmerald
            ) {
                SafetyCentreView()
            }

            FeatureLinkCard(
                title: "Danger Zone",
                subtitle: "Delete account and reset local demo user state",
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

private struct ProfileDraft {
    var displayName = ""
    var handle = ""
    var location = ""
    var bio = ""
    var collectorType = ""
    var avatarSymbol = "person.crop.circle.fill"

    init() {}

    init(profile: UserProfile) {
        displayName = profile.displayName
        handle = profile.handle
        location = profile.location
        bio = profile.bio
        collectorType = profile.collectorType
        avatarSymbol = profile.avatarSymbol
    }

    func makeProfile(from profile: UserProfile) -> UserProfile {
        UserProfile(
            id: profile.id,
            displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? profile.displayName : displayName,
            handle: handle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? profile.handle : handle,
            location: location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? profile.location : location,
            bio: bio.trimmingCharacters(in: .whitespacesAndNewlines),
            collectorType: collectorType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? profile.collectorType : collectorType,
            avatarSymbol: avatarSymbol.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? profile.avatarSymbol : avatarSymbol,
            reputationScore: profile.reputationScore,
            trustBadges: profile.trustBadges,
            completedTrades: profile.completedTrades,
            collectorScore: profile.collectorScore,
            favoriteSet: profile.favoriteSet,
            joinedDate: profile.joinedDate,
            followers: profile.followers,
            following: profile.following
        )
    }
}

private struct ProfileTextField: View {
    let title: String
    @Binding var text: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.vdGold)
                .frame(width: 34, height: 34)
                .background(Color.vdGold.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            TextField(title, text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.vdTextPrimary)
        }
        .padding(12)
        .background(Color.vdPanelRaised.opacity(0.84), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.72), lineWidth: 1)
        )
    }
}

struct SettingsView: View {
    @State private var profileVisibility = BinderVisibility.friends
    @State private var collectionVisibility = BinderVisibility.friends
    @State private var allowFriendTradeRequests = true
    @State private var showWishlistBadges = true
    @State private var requireSafeTradeForHighValue = true

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    settingsHeader
                    privacyControls
                    tradeControls
                    legalLinks
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }

    private var settingsHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Profile Settings", systemImage: "gearshape.fill")
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.vdTextPrimary)

            Text("Local controls for privacy, visibility, and future marketplace behaviour.")
                .font(.subheadline)
                .foregroundStyle(Color.vdTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(Color.vdPanel.opacity(0.84), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.78), lineWidth: 1)
        )
    }

    private var privacyControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Privacy Controls", subtitle: "Visibility defaults for your profile and collection")

            Picker("Profile visibility", selection: $profileVisibility) {
                ForEach(BinderVisibility.allCases) { visibility in
                    Label(visibility.displayName, systemImage: visibility.systemImage).tag(visibility)
                }
            }
            .pickerStyle(.segmented)

            Picker("Collection visibility", selection: $collectionVisibility) {
                ForEach(BinderVisibility.allCases) { visibility in
                    Label(visibility.displayName, systemImage: visibility.systemImage).tag(visibility)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var tradeControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Trading Preferences", subtitle: "Prototype toggles for future safety rules")

            SafetyToggleRow(title: "Allow friend trade requests", subtitle: "Friends can send local demo trade offers.", isOn: $allowFriendTradeRequests)
            SafetyToggleRow(title: "Show wishlist badges", subtitle: "Card screens can show when friends want a card.", isOn: $showWishlistBadges)
            SafetyToggleRow(title: "Safe trade for high value", subtitle: "Prefer intermediary flow placeholders for expensive cards.", isOn: $requireSafeTradeForHighValue)
        }
    }

    private var legalLinks: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Legal", subtitle: "Placeholders until production policies are connected")

            PlaceholderLinkRow(title: "Terms placeholder", systemImage: "doc.text.fill")
            PlaceholderLinkRow(title: "Privacy policy placeholder", systemImage: "hand.raised.fill")
        }
    }
}

struct SafetyCentreView: View {
    @State private var reportText = ""
    @State private var blockText = ""

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    safetyHeader
                    guidanceSection
                    marketplaceTips
                    reportBlockTools
                    privacyAndLegal
                    disclaimer
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("Safety Centre")
        .navigationBarTitleDisplayMode(.large)
    }

    private var safetyHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Trade Carefully", systemImage: "shield.lefthalf.filled")
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.vdTextPrimary)

            Text("VaultDex is currently local/offline. These safety flows are placeholders for future moderation, reporting, and privacy systems.")
                .font(.subheadline)
                .foregroundStyle(Color.vdTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(Color.vdPanel.opacity(0.84), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdEmerald.opacity(0.34), lineWidth: 1)
        )
    }

    private var guidanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Parent/Child Trading", subtitle: "Guidance before real accounts are added")

            SafetyInfoRow(systemImage: "person.2.fill", title: "Use supervised accounts", message: "Children should trade only with parent or guardian awareness, especially for high-value cards.")
            SafetyInfoRow(systemImage: "lock.shield.fill", title: "Keep personal details private", message: "Do not share home addresses, school details, phone numbers, or payment information in trade messages.")
            SafetyInfoRow(systemImage: "checkmark.seal.fill", title: "Confirm every trade", message: "Review condition, variant, value balance, and wishlist intent before accepting an offer.")
        }
    }

    private var marketplaceTips: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Marketplace Safety Tips", subtitle: "Prototype marketplace rules for safer trading")

            SafetyInfoRow(systemImage: "star.leadinghalf.filled", title: "Check reputation", message: "Prefer traders with strong reputation scores, completed trades, and trust badges.")
            SafetyInfoRow(systemImage: "camera.macro", title: "Ask for clear photos", message: "For physical cards, verify card condition, language, variant, and authenticity before meeting or shipping.")
            SafetyInfoRow(systemImage: "arrow.triangle.2.circlepath", title: "Use safe trade options", message: "For expensive trades, use an intermediary or in-person venue placeholder once supported.")
        }
    }

    private var reportBlockTools: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Report & Block", subtitle: "Offline placeholders for moderation")

            ProfileTextField(title: "Report user placeholder", text: $reportText, systemImage: "flag.fill")
            ProfileTextField(title: "Block user placeholder", text: $blockText, systemImage: "nosign")

            HStack(spacing: 10) {
                PrimaryButton(title: "Report", systemImage: "flag.fill") {}
                PrimaryButton(title: "Block", systemImage: "nosign") {}
            }
        }
    }

    private var privacyAndLegal: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Privacy & Policies", subtitle: "Production copy will live here later")

            PlaceholderLinkRow(title: "Privacy controls", systemImage: "hand.raised.fill")
            PlaceholderLinkRow(title: "Terms placeholder", systemImage: "doc.text.fill")
            PlaceholderLinkRow(title: "Privacy policy placeholder", systemImage: "lock.doc.fill")
        }
    }

    private var disclaimer: some View {
        Text("VaultDex is an independent collection and trading companion app and is not affiliated with, endorsed by, or sponsored by The Pokémon Company, Nintendo, Creatures Inc. or GAME FREAK.")
            .font(.caption)
            .foregroundStyle(Color.vdTextSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(16)
            .background(Color.vdPanel.opacity(0.82), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.vdStroke.opacity(0.72), lineWidth: 1)
            )
    }
}

private struct SafetyToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.vdTextPrimary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.vdTextSecondary)
            }
        }
        .tint(Color.vdGold)
        .padding(14)
        .background(Color.vdPanel.opacity(0.84), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.72), lineWidth: 1)
        )
    }
}

private struct SafetyInfoRow: View {
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color.vdEmerald)
                .frame(width: 38, height: 38)
                .background(Color.vdEmerald.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.vdTextPrimary)

                Text(message)
                    .font(.caption)
                    .foregroundStyle(Color.vdTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(Color.vdPanel.opacity(0.84), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.72), lineWidth: 1)
        )
    }
}

private struct PlaceholderLinkRow: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.vdGold)
                .frame(width: 38, height: 38)
                .background(Color.vdGold.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.vdTextPrimary)

            Spacer()

            Text("Coming soon")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.vdTextSecondary)
        }
        .padding(14)
        .background(Color.vdPanel.opacity(0.84), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.72), lineWidth: 1)
        )
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
