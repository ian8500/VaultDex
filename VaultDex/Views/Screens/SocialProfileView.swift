import SwiftUI
import PhotosUI
import UIKit
import UniformTypeIdentifiers

struct SocialProfileView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var store: LocalVaultStore
    @State private var draft = ProfileDraft()
    @State private var hasLoadedDraft = false
    @State private var didSaveProfile = false
    @State private var selectedAvatarItem: PhotosPickerItem?
    @State private var profileMessage = ""
    @State private var usernameError = ""
    @State private var showLogoutConfirmation = false
    @State private var pendingAvatarImage: UIImage?
    @State private var showAvatarUploadError = false
    @State private var isProcessingAvatar = false
    @State private var avatarImageRefreshToken = 0
    @State private var showCameraPicker = false
    @State private var showCameraUnavailable = false

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    profileHeader
                    verificationStatus
                    profileEditor
                    logoutSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .bottomDockSpacing()
            }
        }
        .navigationTitle("Collector Profile")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            guard !hasLoadedDraft else { return }
            draft = ProfileDraft(profile: store.profile)
            hasLoadedDraft = true
            Task { await store.loadVerificationRequest() }
        }
        .onChange(of: selectedAvatarItem) { _, newItem in
            loadAvatar(from: newItem)
        }
        .alert("We couldn't save your profile picture.", isPresented: $showAvatarUploadError) {
            if pendingAvatarImage != nil {
                Button("Retry") {
                    Task { await savePendingAvatar() }
                }
            }
            Button("Take Profile Photo") {
                guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                    showCameraUnavailable = true
                    return
                }
                showCameraPicker = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Try taking a new profile photo instead.")
        }
        .confirmationDialog("Log out of VaultDex?", isPresented: $showLogoutConfirmation, titleVisibility: .visible) {
            Button("Log Out", role: .destructive) {
                Task {
                    try? await authService.signOut()
                    store.clearSignedOutState()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You can sign back in at any time.")
        }
        .alert("Camera isn't available", isPresented: $showCameraUnavailable) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Try choosing a photo from your library instead.")
        }
        .fullScreenCover(isPresented: $showCameraPicker) {
            ProfileCameraPicker { image in
                handleCameraImage(image)
            }
            .ignoresSafeArea()
        }
    }

    private var profileHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                profileAvatar

                VStack(alignment: .leading, spacing: 5) {
                    Text(store.profile.displayName)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.vdTextPrimary)
                        .lineLimit(1)

                    Text(store.profile.handle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.vdGold)

                    Text(profileSubtitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.vdTextSecondary)
                        .lineLimit(2)

                    Text(store.profile.bio)
                        .font(.subheadline)
                        .foregroundStyle(Color.vdTextSecondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            avatarPhotoActions

            if let message = store.imageUploadMessage {
                Label(message, systemImage: store.isUploadingAvatar ? "photo.badge.arrow.down.fill" : (message == "Profile picture saved." ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(message.hasPrefix("We couldn't") ? Color.vdCoral : (store.isUploadingAvatar ? Color.vdGold : Color.vdEmerald))
            }

            Label(store.profilePhotoUploadStatus, systemImage: "waveform.path.ecg")
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.vdTextSecondary)

            if didSaveProfile {
                Label(profileMessage.isEmpty ? "Changes saved" : profileMessage, systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.vdEmerald)
                    .transition(.opacity)
            }

            if !usernameError.isEmpty {
                Label(usernameError, systemImage: "exclamationmark.circle.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.vdCoral)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [Color.vdGold.opacity(0.16), Color.vdPanelRaised.opacity(0.92), Color.vdPanel.opacity(0.78)],
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

    private var verificationStatus: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: verificationDisplay.systemImage)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(verificationDisplay.tint)
                    .frame(width: 44, height: 44)
                    .background(verificationDisplay.tint.opacity(0.13), in: RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 4) {
                    Text("ID verification")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.vdTextPrimary)

                    Text(verificationDisplay.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.vdTextSecondary)
                }

                Spacer()
            }

            if store.verificationRequest?.status.lowercased() != "pending",
               store.verificationRequest?.status.lowercased() != "verified" {
                NavigationLink {
                    VerificationRequestView()
                } label: {
                    Label("Request verification", systemImage: "person.text.rectangle.fill")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.vdNavy)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.vdGold, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color.vdPanel.opacity(0.76), in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.vdGold.opacity(0.18), lineWidth: 1)
        )
    }

    private var verificationDisplay: VerificationStatusDisplay {
        guard let request = store.verificationRequest else {
            return VerificationStatusDisplay(title: "Not verified", systemImage: "checkmark.shield", tint: .vdTextSecondary)
        }

        switch request.status.lowercased() {
        case "pending":
            return VerificationStatusDisplay(title: "Pending review", systemImage: "clock.badge.checkmark.fill", tint: .vdGold)
        case "verified", "approved":
            return VerificationStatusDisplay(title: "Verified", systemImage: "checkmark.shield.fill", tint: .vdEmerald)
        case "rejected":
            return VerificationStatusDisplay(title: "Rejected", systemImage: "exclamationmark.shield.fill", tint: .vdCoral)
        default:
            return VerificationStatusDisplay(title: "Not verified", systemImage: "checkmark.shield", tint: .vdTextSecondary)
        }
    }

    private var avatarPhotoActions: some View {
        let isUploading = store.isUploadingAvatar || isProcessingAvatar

        return VStack(spacing: 10) {
            HStack(spacing: 10) {
                PhotosPicker(selection: $selectedAvatarItem, matching: .images) {
                    Label("Choose from Library", systemImage: "photo.on.rectangle.angled")
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(Color.vdGold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.vdPanelRaised.opacity(0.82), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.vdGold.opacity(0.28), lineWidth: 1)
                        )
                }
                .disabled(isUploading)

                Button {
                    guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                        showCameraUnavailable = true
                        return
                    }
                    showCameraPicker = true
                } label: {
                    Label("Take Profile Photo", systemImage: "camera.fill")
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(Color.vdNavy)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.vdGold, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .disabled(isUploading)
            }

            Button {
                Task { await removeAvatarPhoto() }
            } label: {
                Label("Remove Photo", systemImage: "trash")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.vdTextSecondary)
            }
            .buttonStyle(.plain)
            .disabled(isUploading || store.profile.avatarURL == nil)
        }
    }

    private var profileAvatar: some View {
        let avatarURL = displayAvatarURL
        let avatarSymbol = store.profile.avatarSymbol
        let initials = profileInitials
        let isUploading = store.isUploadingAvatar || isProcessingAvatar

        return Button {
            guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                showCameraUnavailable = true
                return
            }
            showCameraPicker = true
        } label: {
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: 0xFFF06A), Color.vdGold, Color.vdGoldDeep],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    if let avatarURL {
                        CachedAsyncImage(url: avatarURL) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            ProgressView()
                                .tint(Color.vdNavy)
                        }
                    } else {
                        avatarPlaceholder(symbol: avatarSymbol, initials: initials)
                    }

                    if isUploading {
                        Color.vdNavy.opacity(0.42)
                        ProgressView()
                            .tint(Color.vdGold)
                    }
                }
                .frame(width: 82, height: 82)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.48), lineWidth: 1))
                .shadow(color: Color.vdGold.opacity(0.32), radius: 16, x: 0, y: 8)

                Image(systemName: "camera.fill")
                    .font(.caption.weight(.black))
                    .foregroundStyle(Color.vdNavy)
                    .frame(width: 28, height: 28)
                    .background(Color.vdGold, in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 1))
            }
        }
        .buttonStyle(.plain)
        .disabled(isUploading)
        .accessibilityLabel("Take profile photo")
    }

    @ViewBuilder
    private func avatarPlaceholder(symbol: String, initials: String) -> some View {
        if initials.isEmpty {
            Image(systemName: symbol)
                .font(.system(size: 32, weight: .black))
                .foregroundStyle(Color.vdNavy)
        } else {
            Text(initials)
                .font(.title2.weight(.black))
                .foregroundStyle(Color.vdNavy)
        }
    }

    private var profileInitials: String {
        let source = store.profile.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let words = source.split(separator: " ")
        let initials = words.prefix(2).compactMap(\.first).map(String.init).joined()
        return initials.uppercased()
    }

    private var profileSubtitle: String {
        let location = store.profile.location.trimmingCharacters(in: .whitespacesAndNewlines)
        let collectorType = store.profile.collectorType.trimmingCharacters(in: .whitespacesAndNewlines)
        return location.isEmpty ? collectorType : "\(location) · \(collectorType)"
    }

    private var displayAvatarURL: URL? {
        guard avatarImageRefreshToken > 0,
              let avatarURL = store.profile.avatarURL,
              var components = URLComponents(url: avatarURL, resolvingAgainstBaseURL: false)
        else {
            return store.profile.avatarURL
        }
        components.queryItems = [URLQueryItem(name: "v", value: "\(avatarImageRefreshToken)")]
        return components.url ?? avatarURL
    }

    private var profileEditor: some View {
        VStack(alignment: .leading, spacing: 14) {
            VaultSectionHeader(title: "Edit profile", subtitle: nil)

            VStack(spacing: 12) {
                ProfileTextField(title: "Username", text: $draft.handle, systemImage: "at")
                ProfileTextField(title: "Display name", text: $draft.displayName, systemImage: "person.text.rectangle")
                ProfileTextField(title: "Location", text: $draft.location, systemImage: "location.fill")
                collectorTypePicker

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

            PrimaryButton(title: "Save Profile", systemImage: "checkmark.seal.fill") {
                Task { await saveProfile() }
            }
            .disabled(store.isSavingProfile)

            if store.isSavingProfile {
                Label("Saving profile...", systemImage: "icloud.and.arrow.up")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.vdGold)
            }
        }
    }

    private var collectorTypePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Collector type", systemImage: "crown.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.vdTextSecondary)

            Picker("Collector type", selection: $draft.collectorType) {
                ForEach(ProfileDraft.collectorTypes, id: \.self) { type in
                    Text(type.capitalized).tag(type)
                }
            }
            .pickerStyle(.menu)
            .tint(Color.vdGold)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color.vdPanelRaised.opacity(0.84), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.vdStroke.opacity(0.72), lineWidth: 1)
            )
        }
    }

    private func loadAvatar(from item: PhotosPickerItem?) {
        guard let item else { return }
        isProcessingAvatar = true
        store.updateProfilePhotoUploadStatus("Photo selected")
        Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else {
                    await MainActor.run {
                        store.reportImagePickerError("We couldn't use that image. Try taking a new profile photo instead.")
                        isProcessingAvatar = false
                        showAvatarUploadError = true
                        selectedAvatarItem = nil
                    }
                    return
                }
                await MainActor.run {
                    pendingAvatarImage = image
                    isProcessingAvatar = false
                    selectedAvatarItem = nil
                }
                await savePendingAvatar()
            } catch {
                await MainActor.run {
                    store.reportImagePickerError("We couldn't use that image. Try taking a new profile photo instead.")
                    isProcessingAvatar = false
                    showAvatarUploadError = true
                    selectedAvatarItem = nil
                }
            }
        }
    }

    private func handleCameraImage(_ image: UIImage?) {
        guard let image else { return }
        isProcessingAvatar = true
        store.updateProfilePhotoUploadStatus("Photo captured")
        Task {
            await MainActor.run {
                pendingAvatarImage = image
                isProcessingAvatar = false
            }
            await savePendingAvatar()
        }
    }

    private func removeAvatarPhoto() async {
        do {
            try await store.removeAvatarPhoto()
            pendingAvatarImage = nil
            avatarImageRefreshToken = Int(Date().timeIntervalSince1970)
        } catch {
            showAvatarUploadError = true
        }
    }

    private func savePendingAvatar() async {
        guard let pendingAvatarImage else { return }
        do {
            try await store.saveAvatar(image: pendingAvatarImage)
            self.pendingAvatarImage = nil
            avatarImageRefreshToken = Int(Date().timeIntervalSince1970)
            showAvatarUploadError = false
        } catch {
            showAvatarUploadError = true
        }
    }

    private var socialStats: some View {
        HStack(spacing: 12) {
            ProfileStatTile(title: "Reputation", value: "\(store.profile.reputationScore)", systemImage: "shield.checkered", tint: .vdGold)
            ProfileStatTile(title: "Trades", value: "\(store.profile.completedTrades)", systemImage: "arrow.left.arrow.right", tint: .vdEmerald)
            ProfileStatTile(title: "Mythics", value: "\(mythicCount)", systemImage: "sparkles", tint: .vdCoral)
        }
    }

    private var profileProgressSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Collector Progress", subtitle: "A calm view of your vault journey.")

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ProfileSummaryTile(
                    title: "Your Vault Value",
                    value: store.estimatedCollectionValue.compactVaultEstimatedCurrency,
                    systemImage: "chart.line.uptrend.xyaxis",
                    tint: .vdGold
                )

                ProfileSummaryTile(
                    title: "Added This Week",
                    value: "\(cardsAddedThisWeek)",
                    systemImage: "calendar.badge.plus",
                    tint: .vdSky
                )

                ProfileSummaryTile(
                    title: "Favourite Cards",
                    value: "\(favoriteCount)",
                    systemImage: "heart.fill",
                    tint: .vdCoral
                )

                ProfileSummaryTile(
                    title: "Grails",
                    value: "\(grailCount)",
                    systemImage: "sparkles",
                    tint: .vdGold
                )
            }
        }
    }

    private var achievementBadges: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Badges", subtitle: "Milestones earned through collecting and safe trading.")

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(achievementRows) { achievement in
                    AchievementBadge(achievement: achievement)
                }
            }
        }
    }

    private var logoutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Account", subtitle: "Manage your VaultDex access.")

            SecondaryButton(title: "Log Out", systemImage: "rectangle.portrait.and.arrow.right") {
                showLogoutConfirmation = true
            }
        }
    }

    private func saveProfile() async {
        usernameError = ""
        didSaveProfile = false

        guard let validatedDraft = draft.validated() else {
            usernameError = "Username must use lowercase letters, numbers or underscores."
            return
        }

        guard !validatedDraft.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            usernameError = "Display name cannot be empty."
            return
        }

        draft = validatedDraft
        do {
            try await store.updateProfile(validatedDraft.makeProfile(from: store.profile))
            profileMessage = "Profile saved"
            withAnimation(.easeInOut(duration: 0.2)) {
                didSaveProfile = true
            }
        } catch {
            usernameError = "Unable to save profile. Please try again."
        }
    }

    private var socialTools: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Social", subtitle: "Friends, invites and safety tools.")

            FeatureLinkCard(
                title: "Friends",
                subtitle: "\(store.friends.count) collectors connected",
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
                subtitle: "Share your invite message",
                systemImage: "paperplane.fill",
                tint: .vdViolet
            ) {
                InviteFriendsView()
            }

            FeatureLinkCard(
                title: "Settings",
                subtitle: "Privacy and trading preferences",
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
                subtitle: "Delete account data",
                systemImage: "person.crop.circle.badge.xmark",
                tint: .vdCoral
            ) {
                AccountDeletionView()
            }
        }
    }

    private var setProgress: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Set Progress", subtitle: "Completion by set.")

            if setProgressRows.isEmpty {
                EmptyStateView(
                    systemImage: "circle.dotted",
                    title: "No set progress yet",
                    message: "Add cards to see completion rings for each set."
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(setProgressRows.prefix(5)) { progress in
                        HStack(spacing: 14) {
                            ProfileSetProgressRing(fraction: progress.fraction)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(progress.cardSet.name)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(Color.vdTextPrimary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.82)

                                Text("\(progress.owned) of \(progress.total) cards")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.vdTextSecondary)
                            }

                            Spacer()

                            Text("\(Int((progress.fraction * 100).rounded()))%")
                                .font(.headline.weight(.black))
                                .foregroundStyle(Color.vdGold)
                                .lineLimit(1)
                        }
                        .padding(14)
                        .background(Color.vdPanel.opacity(0.78), in: RoundedRectangle(cornerRadius: 18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.vdStroke.opacity(0.45), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    private var showcase: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Top Cards", subtitle: "Favourites, grails and standout cards.")

            if store.collectionItems.isEmpty {
                EmptyStateView(
                    systemImage: "star",
                    title: "No top cards yet",
                    message: "Add cards to build a personal showcase."
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(topShowcaseItems) { item in
                            NavigationLink {
                                CardDetailView(card: item.card)
                            } label: {
                                VStack(alignment: .leading, spacing: 10) {
                                    CardTile(
                                        card: item.card,
                                        quantity: item.quantity,
                                        condition: item.condition,
                                        variant: item.variant,
                                        isAvailableForTrade: item.isAvailableForTrade,
                                        style: .compact
                                    )
                                    .frame(width: 220)

                                    HStack(spacing: 6) {
                                        if item.isFavorite {
                                            StatusPill(title: "Favourite", tint: .vdCoral)
                                        }
                                        if grailCardIDs.contains(item.card.id) {
                                            StatusPill(title: "Grail", tint: .vdGold)
                                        }
                                    }
                                }
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
        let ownedSets = Array(Set(store.collectionItems.map(\.card.set)))
        let candidateSets = store.sets.isEmpty ? ownedSets : Array(Set(store.sets + ownedSets))

        return candidateSets.map { set in
            let owned = Set(store.collectionItems.filter { $0.card.set.id == set.id }.map(\.card.id)).count
            let catalogueTotal = store.cards.filter { $0.set.id == set.id }.count
            let total = max(catalogueTotal, set.totalCards, owned, 1)
            return SetProgress(cardSet: set, owned: owned, total: max(total, 1))
        }
        .filter { $0.owned > 0 }
        .sorted {
            if $0.fraction == $1.fraction {
                return $0.owned > $1.owned
            }
            return $0.fraction > $1.fraction
        }
    }

    private var nextEvent: VaultEvent? {
        store.events.sorted { $0.date < $1.date }.first
    }

    private var cardsAddedThisWeek: Int {
        guard let startOfWeek = Calendar.current.date(byAdding: .day, value: -7, to: .now) else { return 0 }
        return store.collectionItems
            .filter { $0.acquiredAt >= startOfWeek }
            .reduce(0) { $0 + $1.quantity }
    }

    private var favoriteCount: Int {
        store.collectionItems.filter(\.isFavorite).count
    }

    private var grailCount: Int {
        store.wishlistItems.filter { $0.priority == .grail }.count
    }

    private var grailCardIDs: Set<Card.ID> {
        Set(store.wishlistItems.filter { $0.priority == .grail }.map(\.card.id))
    }

    private var topShowcaseItems: [CollectionItem] {
        store.collectionItems
            .sorted {
                let firstScore = showcaseScore(for: $0)
                let secondScore = showcaseScore(for: $1)
                if firstScore == secondScore {
                    return $0.card.marketValue > $1.card.marketValue
                }
                return firstScore > secondScore
            }
            .prefix(6)
            .map { $0 }
    }

    private func showcaseScore(for item: CollectionItem) -> Int {
        var score = item.card.rarity.profileRank
        if item.isFavorite { score += 20 }
        if grailCardIDs.contains(item.card.id) { score += 16 }
        if item.variant == .holo || item.variant == .reverseHolo { score += 2 }
        if item.variant == .fullArt || item.variant == .secretRare { score += 4 }
        return score
    }

    private var achievementRows: [ProfileAchievement] {
        [
            ProfileAchievement(title: "First Card", systemImage: "rectangle.stack.badge.plus", tint: .vdGold, isUnlocked: !store.collectionItems.isEmpty),
            ProfileAchievement(title: "First Grail", systemImage: "sparkles", tint: .vdGold, isUnlocked: grailCount > 0),
            ProfileAchievement(title: "First Trade", systemImage: "arrow.left.arrow.right.circle.fill", tint: .vdEmerald, isUnlocked: store.profile.completedTrades > 0 || store.tradeOffers.contains { $0.status == .completed }),
            ProfileAchievement(title: "Set Starter", systemImage: "circle.grid.3x3.fill", tint: .vdSky, isUnlocked: store.uniqueSetsOwned > 0),
            ProfileAchievement(title: "Trusted Collector", systemImage: "checkmark.shield.fill", tint: .vdLeaf, isUnlocked: store.profile.reputationScore >= 80 || !store.profile.trustBadges.isEmpty)
        ]
    }
}

private struct VerificationStatusDisplay {
    let title: String
    let systemImage: String
    let tint: Color
}

private struct ProfileCameraPicker: UIViewControllerRepresentable {
    let onImage: (UIImage?) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.mediaTypes = [UTType.image.identifier]
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let parent: ProfileCameraPicker

        init(parent: ProfileCameraPicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            parent.onImage(info[.originalImage] as? UIImage)
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onImage(nil)
            parent.dismiss()
        }
    }
}

struct VerificationRequestView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: LocalVaultStore
    @State private var fullName = ""
    @State private var includeDateOfBirth = false
    @State private var dateOfBirth = Date()
    @State private var note = ""
    @State private var message = ""

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Request verification", systemImage: "checkmark.shield.fill")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color.vdTextPrimary)

                        Text("Verification requests are reviewed by VaultDex admin.")
                            .font(.subheadline)
                            .foregroundStyle(Color.vdTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(18)
                    .background(Color.vdPanel.opacity(0.82), in: RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.vdGold.opacity(0.22), lineWidth: 1))

                    VStack(alignment: .leading, spacing: 14) {
                        ProfileTextField(title: "Full name", text: $fullName, systemImage: "person.text.rectangle")
                            .textContentType(.name)

                        Toggle(isOn: $includeDateOfBirth.animation(.easeInOut(duration: 0.2))) {
                            Text("Add date of birth")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Color.vdTextPrimary)
                        }
                        .tint(Color.vdGold)
                        .padding(14)
                        .background(Color.vdPanelRaised.opacity(0.84), in: RoundedRectangle(cornerRadius: 12))

                        if includeDateOfBirth {
                            DatePicker("Date of birth", selection: $dateOfBirth, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Color.vdTextPrimary)
                                .padding(14)
                                .background(Color.vdPanelRaised.opacity(0.84), in: RoundedRectangle(cornerRadius: 12))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Label("Short note", systemImage: "text.alignleft")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color.vdTextSecondary)

                            TextEditor(text: $note)
                                .frame(minHeight: 100)
                                .scrollContentBackground(.hidden)
                                .padding(10)
                                .foregroundStyle(Color.vdTextPrimary)
                                .background(Color.vdPanelRaised.opacity(0.84), in: RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.vdStroke.opacity(0.7), lineWidth: 1))
                        }

                        PrimaryButton(title: store.isSubmittingVerificationRequest ? "Sending..." : "Submit request", systemImage: "paperplane.fill") {
                            Task { await submit() }
                        }
                        .disabled(store.isSubmittingVerificationRequest || fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                        if !message.isEmpty {
                            Text(message)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(message == "Request sent" ? Color.vdEmerald : Color.vdCoral)
                        }
                    }
                }
                .padding(20)
                .bottomDockSpacing()
            }
        }
        .navigationTitle("Verification")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func submit() async {
        message = ""
        do {
            try await store.submitVerificationRequest(
                fullName: fullName,
                dateOfBirth: includeDateOfBirth ? Self.dateFormatter.string(from: dateOfBirth) : nil,
                note: note
            )
            message = "Request sent"
            dismiss()
        } catch {
            message = "Couldn’t send request. Please try again."
        }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_GB")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

struct ProfileSetupView: View {
    @EnvironmentObject private var store: LocalVaultStore
    @State private var draft = ProfileDraft()
    @State private var message = ""
    @State private var didLoadDraft = false

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        VaultDexLogo(size: 72)

                        Text("Set up your profile")
                            .font(.system(.largeTitle, design: .rounded, weight: .black))
                            .foregroundStyle(Color.vdTextPrimary)

                        Text("Choose how other collectors will see you.")
                            .font(.subheadline)
                            .foregroundStyle(Color.vdTextSecondary)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        ProfileTextField(title: "Username", text: $draft.handle, systemImage: "at")
                        ProfileTextField(title: "Display name", text: $draft.displayName, systemImage: "person.text.rectangle")
                        ProfileTextField(title: "Location", text: $draft.location, systemImage: "location.fill")

                        Picker("Collector type", selection: $draft.collectorType) {
                            ForEach(ProfileDraft.collectorTypes, id: \.self) { type in
                                Text(type.capitalized).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(Color.vdGold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color.vdPanelRaised.opacity(0.84), in: RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.vdStroke.opacity(0.72), lineWidth: 1))

                        VStack(alignment: .leading, spacing: 8) {
                            Label("Bio", systemImage: "text.alignleft")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color.vdTextSecondary)

                            TextEditor(text: $draft.bio)
                                .frame(minHeight: 90)
                                .scrollContentBackground(.hidden)
                                .padding(10)
                                .foregroundStyle(Color.vdTextPrimary)
                                .background(Color.vdPanelRaised.opacity(0.84), in: RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.vdStroke.opacity(0.72), lineWidth: 1))
                        }

                        PrimaryButton(title: "Save Profile", systemImage: "checkmark.seal.fill") {
                            Task { await saveProfile() }
                        }
                        .disabled(store.isSavingProfile)

                        if store.isSavingProfile {
                            Label("Saving profile...", systemImage: "icloud.and.arrow.up")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color.vdGold)
                        }

                        if !message.isEmpty {
                            Label(message, systemImage: "exclamationmark.circle.fill")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color.vdCoral)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(18)
                    .background(Color.vdPanel.opacity(0.9), in: RoundedRectangle(cornerRadius: 22))
                    .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.vdGold.opacity(0.24), lineWidth: 1))
                }
                .padding(20)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            guard !didLoadDraft else { return }
            draft = ProfileDraft(profile: store.profile)
            didLoadDraft = true
        }
    }

    private func saveProfile() async {
        guard let validatedDraft = draft.validated() else {
            message = "Username must use lowercase letters, numbers or underscores."
            return
        }

        guard !validatedDraft.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            message = "Display name cannot be empty."
            return
        }

        draft = validatedDraft
        message = ""
        do {
            try await store.updateProfile(validatedDraft.makeProfile(from: store.profile))
        } catch {
            message = "Unable to save profile. Please try again."
        }
    }
}

private struct ProfileDraft {
    static let collectorTypes = [
        "casual collector",
        "parent account",
        "serious collector",
        "trader"
    ]

    var displayName = ""
    var handle = ""
    var location = ""
    var bio = ""
    var collectorType = Self.collectorTypes[0]
    var avatarSymbol = "person.crop.circle.fill"

    init() {}

    init(profile: UserProfile) {
        displayName = profile.displayName
        handle = profile.handle
        location = profile.location
        bio = profile.bio
        collectorType = Self.collectorTypes.contains(profile.collectorType) ? profile.collectorType : Self.collectorTypes[0]
        avatarSymbol = profile.avatarSymbol
    }

    func validated() -> ProfileDraft? {
        var copy = self
        let username = copy.handle
            .replacingOccurrences(of: "@", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !username.isEmpty, username.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "_" }) else {
            return nil
        }

        copy.handle = "@\(username)"
        copy.displayName = copy.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        copy.location = copy.location.trimmingCharacters(in: .whitespacesAndNewlines)
        copy.bio = copy.bio.trimmingCharacters(in: .whitespacesAndNewlines)
        copy.avatarSymbol = copy.avatarSymbol.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "person.crop.circle.fill" : copy.avatarSymbol
        copy.collectorType = Self.collectorTypes.contains(copy.collectorType) ? copy.collectorType : Self.collectorTypes[0]
        return copy
    }

    func makeProfile(from profile: UserProfile) -> UserProfile {
        UserProfile(
            id: profile.id,
            displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? profile.displayName : displayName.trimmingCharacters(in: .whitespacesAndNewlines),
            handle: handle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? profile.handle : handle.trimmingCharacters(in: .whitespacesAndNewlines),
            location: location.trimmingCharacters(in: .whitespacesAndNewlines),
            bio: bio.trimmingCharacters(in: .whitespacesAndNewlines),
            collectorType: Self.collectorTypes.contains(collectorType) ? collectorType : profile.collectorType,
            avatarSymbol: avatarSymbol.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? profile.avatarSymbol : avatarSymbol,
            avatarURL: profile.avatarURL,
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
    @EnvironmentObject private var store: LocalVaultStore
    @State private var profileVisibility = BinderVisibility.friends
    @State private var collectionVisibility = BinderVisibility.friends
    @State private var wantsVisibility = BinderVisibility.friends
    @State private var allowFriendTradeRequests = true
    @State private var showWishlistBadges = true
    @State private var requireSafeTradeForHighValue = true
    @State private var parentManagedAccount = false
    @State private var showDeveloperAdmin = false

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    settingsHeader
                    privacyControls
                    tradeControls
                    legalLinks
                    developerAdminArea
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .bottomDockSpacing()
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }

    private var settingsHeader: some View {
        HStack(spacing: 14) {
            VaultDexLogo(size: 48)

            VStack(alignment: .leading, spacing: 5) {
                Text("Collector Profile")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.vdTextPrimary)

                Text("Privacy, safety and profile preferences.")
                    .font(.subheadline)
                    .foregroundStyle(Color.vdTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
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
            VaultSectionHeader(title: "Privacy Controls", subtitle: "Choose what other collectors can see.")

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

            Picker("Wants visibility", selection: $wantsVisibility) {
                ForEach(BinderVisibility.allCases) { visibility in
                    Label(visibility.displayName, systemImage: visibility.systemImage).tag(visibility)
                }
            }
            .pickerStyle(.segmented)

            SafetyInfoRow(
                systemImage: "eye.slash.fill",
                title: "Your choice",
                message: "Use Private, Friends or Public controls for profile details, your vault and wants."
            )
        }
    }

    private var tradeControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Trading Preferences", subtitle: "Set your comfort level for trades.")

            SafetyToggleRow(title: "Allow friend trade requests", subtitle: "Friends can send trade offers.", isOn: $allowFriendTradeRequests)
            SafetyToggleRow(title: "Show wants badges", subtitle: "Card screens can show when friends want a card.", isOn: $showWishlistBadges)
            SafetyToggleRow(title: "Safe trade for high value", subtitle: "Prefer an intermediary flow for expensive cards.", isOn: $requireSafeTradeForHighValue)
            SafetyToggleRow(title: "Parent-managed account", subtitle: "Guardian approval and trade review controls.", isOn: $parentManagedAccount)
            SafetyInfoRow(systemImage: "message.badge.slash.fill", title: "No open random chat", message: "VaultDex keeps trading focused on friend-based offers, not public chat rooms.")
            SafetyInfoRow(systemImage: "person.crop.circle.badge.questionmark", title: "No anonymous messaging", message: "Trade messages stay tied to collector profiles so reports and blocks can be reviewed.")
        }
    }

    private var legalLinks: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Legal", subtitle: "Terms, privacy and app information.")

            PlaceholderLinkRow(title: "Terms", systemImage: "doc.text.fill")
            PlaceholderLinkRow(title: "Privacy policy", systemImage: "hand.raised.fill")
        }
    }

    private var developerAdminArea: some View {
        DisclosureGroup(isExpanded: $showDeveloperAdmin) {
            Button {
                Task { await store.testAvatarUpload() }
            } label: {
                Label("Test Avatar Upload", systemImage: "photo.badge.checkmark.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.vdTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color.vdPanel.opacity(0.74), in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .padding(.top, 10)

            if let status = store.avatarTestUploadStatus {
                Label(status, systemImage: status.contains("succeeded") ? "checkmark.circle.fill" : (status.contains("started") ? "arrow.triangle.2.circlepath" : "exclamationmark.triangle.fill"))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(status.contains("failed") ? Color.vdCoral : (status.contains("succeeded") ? Color.vdEmerald : Color.vdGold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 4)
            }

            VStack(spacing: 10) {
                developerButton("Import sample cards", systemImage: "square.and.arrow.down.fill") {
                    Task { await store.importSampleCards() }
                }

                developerButton("Refresh popular cards", systemImage: "arrow.clockwise.circle.fill") {
                    Task { await store.refreshPopularCards() }
                }

                developerButton("Show card cache count", systemImage: "number.circle.fill") {
                    Task { await store.loadCardCacheCount() }
                }

                developerButton("Clear card cache", systemImage: "trash.fill") {
                    Task { await store.clearCardCache() }
                }

                if let status = store.cardCacheAdminStatus {
                    Text(status)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(status.contains("Couldn’t") ? Color.vdCoral : Color.vdTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.top, 8)

            NavigationLink {
                VerificationAdminPlaceholderView()
            } label: {
                Label("Verification requests", systemImage: "checkmark.shield.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.vdTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color.vdPanel.opacity(0.74), in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        } label: {
            Label("Developer / Admin", systemImage: "wrench.and.screwdriver.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.vdTextSecondary)
        }
        .tint(Color.vdGold)
        .padding(14)
        .background(Color.vdPanel.opacity(0.52), in: RoundedRectangle(cornerRadius: 16))
    }

    private func developerButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.vdTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color.vdPanel.opacity(0.62), in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

struct VerificationAdminPlaceholderView: View {
    @EnvironmentObject private var store: LocalVaultStore

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    VaultSectionHeader(title: "Pending verification", subtitle: "Admin review placeholder.")

                    if store.pendingVerificationRequests.isEmpty {
                        EmptyStateView(
                            systemImage: "checkmark.shield",
                            title: "No pending requests",
                            message: "New ID verification requests will appear here for admin review."
                        )
                    } else {
                        VStack(spacing: 12) {
                            ForEach(store.pendingVerificationRequests) { request in
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(request.fullName)
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(Color.vdTextPrimary)

                                    Text("Submitted for review")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Color.vdTextSecondary)

                                    HStack(spacing: 10) {
                                        SecondaryButton(title: "Approve", systemImage: "checkmark.circle.fill") {}
                                        SecondaryButton(title: "Reject", systemImage: "xmark.circle.fill") {}
                                    }
                                }
                                .padding(16)
                                .background(Color.vdPanel.opacity(0.78), in: RoundedRectangle(cornerRadius: 18))
                            }
                        }
                    }
                }
                .padding(20)
                .bottomDockSpacing()
            }
        }
        .navigationTitle("Admin")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await store.loadPendingVerificationRequests()
        }
    }
}

struct SafetyCentreView: View {
    @State private var reportText = ""
    @State private var listingReportText = ""
    @State private var blockText = ""
    @State private var actionMessage: String?

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    safetyHeader
                    communicationSection
                    familyGuidance
                    tradeSafetyTips
                    marketplaceTips
                    reportBlockTools
                    privacyAndLegal
                    disclaimer
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .bottomDockSpacing()
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

            Text("Simple guidance for trading safely with friends and family.")
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

    private var communicationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Communication", subtitle: "Designed for safer collector interactions.")

            SafetyInfoRow(systemImage: "person.2.fill", title: "Friends first", message: "Trading is built around collectors you add, not open random chat.")
            SafetyInfoRow(systemImage: "person.crop.circle.badge.checkmark", title: "Known profiles", message: "Messages are linked to signed-in profiles. Anonymous messaging is not part of VaultDex.")
            SafetyInfoRow(systemImage: "bubble.left.and.exclamationmark.bubble.right.fill", title: "Keep it trade related", message: "Offer messages should stay about cards, condition, value and delivery arrangements.")
        }
    }

    private var familyGuidance: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Parent/Child Trading", subtitle: "Helpful checks before younger collectors trade.")

            SafetyInfoRow(systemImage: "figure.and.child.holdinghands", title: "Parent-managed account", message: "A guardian approval flow is planned for younger collectors and high-value trades.")
            SafetyInfoRow(systemImage: "person.2.fill", title: "Use supervised accounts", message: "Children should trade only with parent or guardian awareness, especially for high-value cards.")
            SafetyInfoRow(systemImage: "lock.shield.fill", title: "Keep personal details private", message: "Do not share home addresses, school details, phone numbers, or payment information in trade messages.")
            SafetyInfoRow(systemImage: "checkmark.seal.fill", title: "Confirm every trade", message: "Review condition, variant, value balance, and wants before accepting an offer.")
        }
    }

    private var tradeSafetyTips: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Trade Safety Tips", subtitle: "Simple checks before you accept.")

            SafetyInfoRow(systemImage: "scale.3d", title: "Check value balance", message: "Use estimated values as a guide only. Condition, grading and personal preference can change a fair trade.")
            SafetyInfoRow(systemImage: "rectangle.stack.badge.person.crop.fill", title: "Confirm the exact card", message: "Compare set, number, variant, language and photos before sending cards.")
            SafetyInfoRow(systemImage: "hand.raised.fill", title: "Pause if unsure", message: "Reject any offer that feels rushed, unclear or uncomfortable.")
        }
    }

    private var marketplaceTips: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Marketplace Safety Tips", subtitle: "Keep trades clear, fair and comfortable.")

            SafetyInfoRow(systemImage: "star.leadinghalf.filled", title: "Check reputation", message: "Prefer traders with strong reputation scores, completed trades, and trust badges.")
            SafetyInfoRow(systemImage: "camera.macro", title: "Ask for clear photos", message: "For physical cards, verify card condition, language, variant, and authenticity before meeting or shipping.")
            SafetyInfoRow(systemImage: "arrow.triangle.2.circlepath", title: "Use safe trade options", message: "For expensive trades, use an intermediary or trusted in-person venue once supported.")
        }
    }

    private var reportBlockTools: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Report & Block", subtitle: "Moderation actions")

            ProfileTextField(title: "Report user", text: $reportText, systemImage: "flag.fill")
            ProfileTextField(title: "Report listing", text: $listingReportText, systemImage: "flag.checkered")
            ProfileTextField(title: "Block user", text: $blockText, systemImage: "nosign")

            HStack(spacing: 10) {
                PrimaryButton(title: "Report", systemImage: "flag.fill") {
                    actionMessage = "Thanks. Reporting tools will be available soon."
                }
                PrimaryButton(title: "Block", systemImage: "nosign") {
                    actionMessage = "Thanks. Blocking tools will be available soon."
                }
            }

            if let actionMessage {
                Text(actionMessage)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.vdTextSecondary)
                    .padding(.top, 2)
            }
        }
    }

    private var privacyAndLegal: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Privacy & Policies", subtitle: "Control your data and review app policies.")

            PlaceholderLinkRow(title: "Privacy controls", systemImage: "hand.raised.fill")
            SafetyInfoRow(systemImage: "lock.fill", title: "Private", message: "Only you can see it.")
            SafetyInfoRow(systemImage: "person.2.fill", title: "Friends", message: "Only accepted friends can see it.")
            SafetyInfoRow(systemImage: "globe.europe.africa.fill", title: "Public", message: "Visible to collectors when public features are enabled.")
            PlaceholderLinkRow(title: "Terms", systemImage: "doc.text.fill")
            PlaceholderLinkRow(title: "Privacy policy", systemImage: "lock.doc.fill")
        }
    }

    private var disclaimer: some View {
        Text("VaultDex is independent and not affiliated with The Pokémon Company, Nintendo, Creatures Inc. or GAME FREAK.")
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

            Text("Draft")
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
        .background(Color.vdPanel.opacity(0.82), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(tint.opacity(0.32), lineWidth: 1)
        )
        .shadow(color: tint.opacity(0.10), radius: 10, x: 0, y: 5)
    }
}

private struct ProfileSummaryTile: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 11))

            Text(value)
                .font(.system(.title3, design: .rounded, weight: .black))
                .foregroundStyle(Color.vdTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.vdTextSecondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.vdPanel.opacity(0.78), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.07), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.10), radius: 10, x: 0, y: 6)
    }
}

private struct ProfileAchievement: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String
    let tint: Color
    let isUnlocked: Bool
}

private struct AchievementBadge: View {
    let achievement: ProfileAchievement

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: achievement.isUnlocked ? achievement.systemImage : "lock.fill")
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(achievement.isUnlocked ? Color.vdNavy : Color.vdTextSecondary)
                .frame(width: 34, height: 34)
                .background(
                    (achievement.isUnlocked ? achievement.tint : Color.vdPanelRaised)
                        .opacity(achievement.isUnlocked ? 0.95 : 0.75),
                    in: RoundedRectangle(cornerRadius: 12)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.title)
                    .font(.caption.weight(.black))
                    .foregroundStyle(Color.vdTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Text(achievement.isUnlocked ? "Earned" : "In progress")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(achievement.isUnlocked ? achievement.tint : Color.vdTextSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.vdPanel.opacity(achievement.isUnlocked ? 0.82 : 0.52), in: RoundedRectangle(cornerRadius: 17))
        .overlay(
            RoundedRectangle(cornerRadius: 17)
                .stroke((achievement.isUnlocked ? achievement.tint : Color.vdStroke).opacity(0.34), lineWidth: 1)
        )
    }
}

private struct ProfileSetProgressRing: View {
    let fraction: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.vdStroke.opacity(0.48), lineWidth: 6)

            Circle()
                .trim(from: 0, to: min(max(fraction, 0), 1))
                .stroke(
                    LinearGradient(colors: [Color.vdGold, Color(hex: 0xFFF06A)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Text("\(Int((fraction * 100).rounded()))")
                .font(.caption2.weight(.black))
                .foregroundStyle(Color.vdGold)
                .minimumScaleFactor(0.75)
        }
        .frame(width: 48, height: 48)
        .accessibilityLabel("Set completion \(Int((fraction * 100).rounded())) percent")
    }
}

private extension CardRarity {
    var profileRank: Int {
        switch self {
        case .common: 0
        case .uncommon: 1
        case .rare: 2
        case .epic: 3
        case .legendary: 4
        case .mythic: 5
        }
    }
}
