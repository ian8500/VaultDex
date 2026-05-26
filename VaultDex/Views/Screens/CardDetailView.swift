import SwiftUI
import PhotosUI
import UIKit

struct CardDetailView: View {
    @EnvironmentObject private var store: LocalVaultStore

    let card: Card

    @State private var ownedQuantity = 1
    @State private var selectedCondition: CardCondition
    @State private var selectedVariant = CardVariant.normal
    @State private var isAvailableForTrade = false
    @State private var collectionLanguage = "English"
    @State private var gradedCompany = ""
    @State private var gradedScore = ""
    @State private var collectionNotes = ""
    @State private var collectionVisibility = CollectionVisibility.private
    @State private var isAvailableForCredits = false
    @State private var askingCredits = 0
    @State private var wishlistPriority = WishlistPriority.medium
    @State private var wishlistPreferredCondition = CardCondition.nearMint
    @State private var wishlistBudget: Double
    @State private var wishlistNotes = ""
    @State private var selectedFrontPhotoItem: PhotosPickerItem?
    @State private var selectedBackPhotoItem: PhotosPickerItem?
    @State private var liveCard: Card?
    @State private var isLoadingLiveCard = false
    @State private var detailErrorMessage: String?
    @State private var successMessage: String?

    private let apiService = CardAPIService()

    init(card: Card) {
        self.card = card
        _selectedCondition = State(initialValue: card.condition)
        _wishlistBudget = State(initialValue: card.marketValue)
    }

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    hero
                    if isLoadingLiveCard {
                        loadingLiveCardState
                    }
                    if let detailErrorMessage {
                        detailErrorState(detailErrorMessage)
                    }
                    quickActions
                    priceDisclaimer
                    friendWishlistBadges
                    collectionEditor
                    wishlistEditor
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }

            if let successMessage {
                VStack {
                    Spacer()
                    SuccessToast(message: successMessage)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 18)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationTitle(detailCard.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            syncState()
            store.cacheViewedCard(detailCard)
        }
        .task {
            await loadLiveDetailIfPossible()
        }
    }

    private var detailCard: Card {
        liveCard ?? card
    }

    private var ownedItem: CollectionItem? {
        store.collectionItem(for: detailCard)
    }

    private var savedWishlistItem: WishlistItem? {
        store.wishlistItem(for: detailCard)
    }

    private var friendsWantingCard: [Friend] {
        store.friendsWanting(detailCard)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 14) {
            realArtwork
                .padding(.bottom, 4)

            HStack(spacing: 10) {
                StatusPill(title: detailCard.cardType.displayName, tint: .vdEmerald)
                RarityBadge(rarity: detailCard.rarity)
                StatusPill(title: detailCard.marketValue.vaultCurrency, tint: .vdGold)
            }

            Text(detailCard.set.name + " · " + detailCard.typeLine)
                .font(.subheadline)
                .foregroundStyle(Color.vdTextSecondary)
                .fixedSize(horizontal: false, vertical: true)

            metadataGrid
        }
    }

    private var realArtwork: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [Color.vdGold.opacity(0.16), Color.vdPanel.opacity(0.92), Color.vdSky.opacity(0.10)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if let imageURL = detailCard.largeImageURL ?? detailCard.smallImageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFit()
                            .padding(18)
                            .transition(.opacity)
                    case .failure:
                        CardTile(
                            card: detailCard,
                            quantity: ownedItem?.quantity,
                            condition: ownedItem?.condition,
                            variant: ownedItem?.variant,
                            isAvailableForTrade: ownedItem?.isAvailableForTrade ?? false
                        )
                        .padding(12)
                    default:
                        ProgressView()
                            .tint(Color.vdGold)
                    }
                }
            } else {
                CardTile(
                    card: detailCard,
                    quantity: ownedItem?.quantity,
                    condition: ownedItem?.condition,
                    variant: ownedItem?.variant,
                    isAvailableForTrade: ownedItem?.isAvailableForTrade ?? false
                )
                .padding(12)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 430)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.vdGold.opacity(detailCard.rarity == .legendary || detailCard.rarity == .mythic ? 0.58 : 0.24), lineWidth: 1.2)
        )
        .shadow(color: Color.vdGold.opacity(detailCard.rarity == .legendary || detailCard.rarity == .mythic ? 0.22 : 0.10), radius: 22, x: 0, y: 10)
    }

    private var metadataGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            detailMetric("Set", detailCard.set.name)
            detailMetric("Number", detailCard.number)
            detailMetric("Rarity", detailCard.rarity.displayName)
            detailMetric("Value", detailCard.marketValue.vaultCurrency)
        }
    }

    private func detailMetric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.black))
                .foregroundStyle(Color.vdTextSecondary)
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.vdTextPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.vdPanelRaised.opacity(0.72), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.58), lineWidth: 1)
        )
    }

    private var quickActions: some View {
        HStack(spacing: 10) {
            detailAction(
                title: ownedItem == nil ? "Add to My Vault" : "In My Vault",
                systemImage: ownedItem == nil ? "plus.circle.fill" : "checkmark.circle.fill",
                tint: .vdEmerald
            ) {
                if ownedItem == nil {
                    store.addCard(detailCard, quantity: ownedQuantity, condition: selectedCondition, variant: selectedVariant)
                    showSuccess("Added to My Vault")
                    syncState()
                }
            }

            detailAction(
                title: savedWishlistItem == nil ? "Add to Wants" : "Already in Wants",
                systemImage: savedWishlistItem == nil ? "star.fill" : "star.circle.fill",
                tint: .vdGold
            ) {
                if savedWishlistItem == nil {
                    store.addToWishlist(detailCard, priority: wishlistPriority, preferredCondition: wishlistPreferredCondition, budget: wishlistBudget, notes: wishlistNotes)
                    showSuccess("Added to Wants")
                    syncState()
                }
            }

            detailAction(
                title: ownedItem?.isAvailableForTrade == true ? "Marked for Trade" : "Mark for Trade",
                systemImage: "arrow.left.arrow.right.circle.fill",
                tint: .vdSky
            ) {
                if ownedItem == nil {
                    store.addCard(detailCard, quantity: ownedQuantity, condition: selectedCondition, variant: selectedVariant)
                }
                store.updateTradeAvailability(for: detailCard, isAvailable: true)
                showSuccess("Marked for Trade")
                syncState()
            }
        }
    }

    private func showSuccess(_ message: String) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
            successMessage = message
        }
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    if successMessage == message {
                        successMessage = nil
                    }
                }
            }
        }
    }

    private var loadingLiveCardState: some View {
        Label("Refreshing card details...", systemImage: "arrow.triangle.2.circlepath")
            .font(.caption.weight(.bold))
            .foregroundStyle(Color.vdTextSecondary)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.vdPanel.opacity(0.72), in: RoundedRectangle(cornerRadius: 8))
    }

    private func detailErrorState(_ message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark")
                .foregroundStyle(Color.vdGold)

            Text(message)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.vdTextSecondary)

            Spacer()

            Button("Retry") {
                Task { await loadLiveDetailIfPossible(force: true) }
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(Color.vdGold)
        }
        .padding(12)
        .background(Color.vdPanel.opacity(0.72), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.vdGold.opacity(0.18), lineWidth: 1))
    }

    private func detailAction(title: String, systemImage: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 7) {
                Image(systemName: systemImage)
                    .font(.headline.weight(.bold))
                Text(title)
                    .font(.caption.weight(.bold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
            }
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .frame(height: 78)
            .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(tint.opacity(0.34), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var priceDisclaimer: some View {
        Label(
            "Values are estimates based on available market data.",
            systemImage: "info.circle.fill"
        )
        .font(.caption.weight(.semibold))
        .foregroundStyle(Color.vdTextSecondary)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.vdGold.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdGold.opacity(0.22), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var friendWishlistBadges: some View {
        if !friendsWantingCard.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                VaultSectionHeader(title: "Friend Wants", subtitle: "Friends who want this card")

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(friendsWantingCard) { friend in
                            HStack(spacing: 8) {
                                Image(systemName: friend.avatarSymbol)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Color.vdGold)

                                Text(friend.displayName)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Color.vdTextPrimary)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(Color.vdGold.opacity(0.12), in: Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.vdGold.opacity(0.28), lineWidth: 1)
                            )
                        }
                    }
                }
            }
            .padding(16)
            .background(Color.vdPanel.opacity(0.84), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.vdStroke.opacity(0.72), lineWidth: 1)
            )
        }
    }

    private var collectionEditor: some View {
        VStack(alignment: .leading, spacing: 16) {
            VaultSectionHeader(
                title: "My Vault",
                subtitle: ownedItem == nil ? "Add this card to your vault." : "Edit quantity, condition, variant and trade status."
            )

            Stepper(value: $ownedQuantity, in: 1...99) {
                editorLabel(title: "Quantity", value: "\(ownedQuantity)")
            }

            Picker("Condition", selection: $selectedCondition) {
                ForEach(CardCondition.allCases) { condition in
                    Text(condition.displayName).tag(condition)
                }
            }
            .pickerStyle(.menu)

            Picker("Variant", selection: $selectedVariant) {
                ForEach(CardVariant.allCases) { variant in
                    Text(variant.displayName).tag(variant)
                }
            }
            .pickerStyle(.menu)

            Toggle("Available for trade", isOn: $isAvailableForTrade)
                .tint(Color.vdEmerald)

            Toggle("Available for credits", isOn: $isAvailableForCredits)
                .tint(Color.vdGold)

            if isAvailableForCredits {
                Stepper(value: $askingCredits, in: 0...999_999, step: 25) {
                    editorLabel(title: "Asking Credits", value: "\(askingCredits)")
                }
            }

            Picker("Visibility", selection: $collectionVisibility) {
                ForEach(CollectionVisibility.allCases) { visibility in
                    Text(visibility.displayName).tag(visibility)
                }
            }
            .pickerStyle(.segmented)

            editableTextField(title: "Language", text: $collectionLanguage, prompt: "English")
            editableTextField(title: "Grading Company", text: $gradedCompany, prompt: "Optional")
            editableTextField(title: "Graded Score", text: $gradedScore, prompt: "Optional")
            editableTextEditor(title: "Notes", text: $collectionNotes, prompt: "Storage, trade notes, provenance")
            cardPhotoUploader

            if let error = store.lastSyncError, error.contains("Collection") {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.vdCoral)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if ownedItem == nil {
                PrimaryButton(title: "Add to My Vault", systemImage: "plus.circle.fill") {
                    store.addCard(detailCard, quantity: ownedQuantity, condition: selectedCondition, variant: selectedVariant)
                    store.updateTradeAvailability(for: detailCard, isAvailable: isAvailableForTrade)
                    saveCollectionDetails()
                    syncState()
                }
            } else {
                PrimaryButton(title: "Save Collection Changes", systemImage: "checkmark.circle.fill") {
                    store.updateQuantity(for: detailCard, quantity: ownedQuantity)
                    store.updateCondition(for: detailCard, condition: selectedCondition)
                    store.updateVariant(for: detailCard, variant: selectedVariant)
                    store.updateTradeAvailability(for: detailCard, isAvailable: isAvailableForTrade)
                    saveCollectionDetails()
                    syncState()
                }

                secondaryButton(title: "Remove from Collection", systemImage: "minus.circle.fill", tint: .vdCoral) {
                    store.removeCard(detailCard)
                    syncState()
                }
            }
        }
        .padding(18)
        .background(Color.vdPanel.opacity(0.84), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.78), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var cardPhotoUploader: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(
                title: "Owned Card Photos",
                subtitle: "Add private front and back photos."
            )

            if let ownedItem {
                HStack(spacing: 12) {
                    cardPhotoPicker(
                        title: "Front",
                        side: .front,
                        url: ownedItem.frontPhotoURL,
                        selection: $selectedFrontPhotoItem
                    )
                    cardPhotoPicker(
                        title: "Back",
                        side: .back,
                        url: ownedItem.backPhotoURL,
                        selection: $selectedBackPhotoItem
                    )
                }

                if let message = store.imageUploadMessage, store.uploadingCardPhotoSide != nil || message.contains("photo") {
                    Label(message, systemImage: store.uploadingCardPhotoSide == nil ? "checkmark.circle.fill" : "photo.badge.arrow.down.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(store.uploadingCardPhotoSide == nil ? Color.vdEmerald : Color.vdGold)
                }
            } else {
                Label("Add this card to My Vault before uploading front or back photos.", systemImage: "lock.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.vdTextSecondary)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.vdPanelRaised.opacity(0.74), in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private func cardPhotoPicker(
        title: String,
        side: CardPhotoSide,
        url: URL?,
        selection: Binding<PhotosPickerItem?>
    ) -> some View {
        let activeUploadSide = store.uploadingCardPhotoSide
        let isUploading = activeUploadSide == side

        return PhotosPicker(selection: selection, matching: .images) {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.vdPanelRaised.opacity(0.82))

                    if let url {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case let .success(image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure:
                                Image(systemName: "photo.fill")
                                    .foregroundStyle(Color.vdTextSecondary)
                            default:
                                ProgressView()
                                    .tint(Color.vdGold)
                            }
                        }
                    } else {
                        Image(systemName: side == .front ? "rectangle.portrait.fill" : "rectangle.portrait.rotate.fill")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color.vdGold)
                    }
                }
                .frame(height: 128)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.vdGold.opacity(url == nil ? 0.24 : 0.46), lineWidth: 1)
                )

                HStack(spacing: 6) {
                    if isUploading {
                        ProgressView()
                            .tint(Color.vdGold)
                    } else {
                        Image(systemName: "photo.badge.plus")
                    }
                    Text(title)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .font(.caption.weight(.black))
                .foregroundStyle(Color.vdTextPrimary)
            }
        }
        .disabled(activeUploadSide != nil)
        .onChange(of: selection.wrappedValue) { _, newItem in
            loadCardPhoto(from: newItem, side: side)
        }
        .frame(maxWidth: .infinity)
    }

    private func loadCardPhoto(from item: PhotosPickerItem?, side: CardPhotoSide) {
        guard let item, let ownedItem else { return }
        Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    await MainActor.run {
                        store.reportImagePickerError("\(side.displayName) photo upload failed: VaultDex could not read the selected photo.")
                        resetPhotoSelection(for: side)
                    }
                    return
                }
                await MainActor.run {
                    store.uploadCardPhotoImageData(data, for: ownedItem, side: side)
                    resetPhotoSelection(for: side)
                }
            } catch {
                await MainActor.run {
                    store.reportImagePickerError("\(side.displayName) photo upload failed. Please try again.")
                    resetPhotoSelection(for: side)
                }
            }
        }
    }

    private func resetPhotoSelection(for side: CardPhotoSide) {
        switch side {
        case .front:
            selectedFrontPhotoItem = nil
        case .back:
            selectedBackPhotoItem = nil
        }
    }

    private var wishlistEditor: some View {
        VStack(alignment: .leading, spacing: 16) {
            VaultSectionHeader(
                title: "Wants",
                subtitle: savedWishlistItem == nil ? "Find your next grail with budget, priority, and notes" : "Edit this want"
            )

            Picker("Priority", selection: $wishlistPriority) {
                ForEach(WishlistPriority.allCases) { priority in
                    Text(priority.displayName).tag(priority)
                }
            }
            .pickerStyle(.segmented)

            Picker("Preferred Condition", selection: $wishlistPreferredCondition) {
                ForEach(CardCondition.allCases) { condition in
                    Text(condition.displayName).tag(condition)
                }
            }
            .pickerStyle(.menu)
            .foregroundStyle(Color.vdTextPrimary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Max Trade Estimate")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.vdTextSecondary)

                TextField("Max trade estimate", value: $wishlistBudget, format: .number.precision(.fractionLength(0...2)))
                    .keyboardType(.decimalPad)
                    .foregroundStyle(Color.vdTextPrimary)
                    .padding(14)
                    .background(Color.vdPanelRaised.opacity(0.82), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.vdStroke.opacity(0.8), lineWidth: 1)
                    )
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Notes")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.vdTextSecondary)

                TextField("Want notes", text: $wishlistNotes, axis: .vertical)
                    .lineLimit(3...5)
                    .foregroundStyle(Color.vdTextPrimary)
                    .padding(14)
                    .background(Color.vdPanelRaised.opacity(0.82), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.vdStroke.opacity(0.8), lineWidth: 1)
                    )
            }

            VStack(alignment: .leading, spacing: 10) {
                Label(savedWishlistItem == nil ? "Not in Wants yet" : "Already in Wants", systemImage: savedWishlistItem == nil ? "star" : "star.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(savedWishlistItem == nil ? Color.vdTextSecondary : Color.vdGold)

                Text("Friends and market matches appear when real shared wants or listings are available.")
                    .font(.caption)
                    .foregroundStyle(Color.vdTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if store.lastSyncError?.contains("Wants") == true, let error = store.lastSyncError {
                Text(error)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.vdCoral)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if savedWishlistItem == nil {
                PrimaryButton(title: "Add to Wants", systemImage: "star.fill") {
                    store.addToWishlist(detailCard, priority: wishlistPriority, preferredCondition: wishlistPreferredCondition, budget: wishlistBudget, notes: wishlistNotes)
                    syncState()
                }
            } else {
                PrimaryButton(title: "Save Want", systemImage: "checkmark.circle.fill") {
                    store.updateWishlist(for: detailCard, priority: wishlistPriority, preferredCondition: wishlistPreferredCondition, budget: wishlistBudget, notes: wishlistNotes)
                    syncState()
                }

                secondaryButton(title: "Remove from Wants", systemImage: "star.slash.fill", tint: .vdCoral) {
                    store.removeFromWishlist(detailCard)
                    syncState()
                }
            }
        }
        .padding(18)
        .background(Color.vdPanel.opacity(0.84), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.78), lineWidth: 1)
        )
    }

    private func editorLabel(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(Color.vdTextPrimary)

            Spacer()

            Text(value)
                .font(.headline)
                .foregroundStyle(Color.vdGold)
        }
    }

    private func editableTextField(
        title: String,
        text: Binding<String>,
        prompt: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.vdTextSecondary)

            TextField(prompt, text: text)
                .foregroundStyle(Color.vdTextPrimary)
                .padding(14)
                .background(Color.vdPanelRaised.opacity(0.82), in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.vdStroke.opacity(0.8), lineWidth: 1)
                )
        }
    }

    private func editableTextEditor(title: String, text: Binding<String>, prompt: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.vdTextSecondary)

            TextField(prompt, text: text, axis: .vertical)
                .lineLimit(3...5)
                .foregroundStyle(Color.vdTextPrimary)
                .padding(14)
                .background(Color.vdPanelRaised.opacity(0.82), in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.vdStroke.opacity(0.8), lineWidth: 1)
                )
        }
    }

    private func secondaryButton(
        title: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .bold))

                Text(title)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(tint.opacity(0.45), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func syncState() {
        if let ownedItem {
            ownedQuantity = ownedItem.quantity
            selectedCondition = ownedItem.condition
            selectedVariant = ownedItem.variant
            isAvailableForTrade = ownedItem.isAvailableForTrade
            collectionLanguage = ownedItem.language
            gradedCompany = ownedItem.gradedCompany ?? ""
            gradedScore = ownedItem.gradedScore ?? ""
            collectionNotes = ownedItem.notes ?? ""
            collectionVisibility = ownedItem.visibility
            isAvailableForCredits = ownedItem.isAvailableForCredits
            askingCredits = ownedItem.askingCredits ?? 0
        } else {
            ownedQuantity = 1
            selectedCondition = detailCard.condition
            selectedVariant = .normal
            isAvailableForTrade = false
            collectionLanguage = "English"
            gradedCompany = ""
            gradedScore = ""
            collectionNotes = ""
            collectionVisibility = .private
            isAvailableForCredits = false
            askingCredits = 0
        }

        if let savedWishlistItem {
            wishlistPriority = savedWishlistItem.priority
            wishlistPreferredCondition = savedWishlistItem.preferredCondition
            wishlistBudget = savedWishlistItem.budget
            wishlistNotes = savedWishlistItem.notes
        } else {
            wishlistPriority = .medium
            wishlistPreferredCondition = .nearMint
            wishlistBudget = detailCard.marketValue
            wishlistNotes = ""
        }
    }

    private func loadLiveDetailIfPossible(force: Bool = false) async {
        guard let externalID = card.externalID, !externalID.isEmpty else {
            store.cacheViewedCard(detailCard)
            return
        }
        guard force || liveCard == nil else { return }

        isLoadingLiveCard = true
        detailErrorMessage = nil
        defer { isLoadingLiveCard = false }

        do {
            await ExchangeRateService.shared.refreshRatesIfNeeded()
            let apiCard = try await apiService.fetchCard(id: externalID)
            let refreshedCard = apiCard.localCard
            liveCard = refreshedCard
            store.cacheViewedCard(refreshedCard)
            syncState()
        } catch {
            detailErrorMessage = "This card could not be refreshed right now."
            store.cacheViewedCard(detailCard)
        }
    }

    private func saveCollectionDetails() {
        store.updateCollectionDetails(
            for: detailCard,
            language: collectionLanguage,
            gradedCompany: gradedCompany,
            gradedScore: gradedScore,
            notes: collectionNotes,
            visibility: collectionVisibility,
            availableForCredits: isAvailableForCredits,
            askingCredits: askingCredits
        )
    }
}
