import Foundation

@MainActor
final class LocalVaultStore: ObservableObject {
    let repositories: VaultRepositoryContainer
    let localRepositories: LocalRepositoryContainer
    let importPreviewItems: [ImportPreviewItem]
    let inviteContacts: [InviteContact]

    @Published private(set) var runtimeMode: VaultRuntimeMode
    @Published private(set) var isLoadingCloudData = false
    @Published private(set) var lastSyncError: String?
    @Published var sets: [CardSet]
    @Published var cards: [Card]
    @Published var profile: UserProfile
    @Published var collectionItems: [CollectionItem]
    @Published var wishlistItems: [WishlistItem]
    @Published var events: [VaultEvent]
    @Published var binderPages: [BinderPage]
    @Published var friends: [Friend]
    @Published var friendRequests: [FriendRequest]
    @Published var friendWants: [FriendWant]
    @Published var tradeListings: [TradeListing]
    @Published var tradeOffers: [TradeOffer]

    init(
        repository: DemoVaultRepository = .shared,
        repositories: VaultRepositoryContainer = .live(config: .current),
        localRepositories: LocalRepositoryContainer = .demo()
    ) {
        self.repositories = repositories
        self.localRepositories = localRepositories
        runtimeMode = repositories.clientProvider.isRemoteEnabled ? .supabase : .demo
        sets = repository.sets
        cards = repository.cards
        profile = repository.profile
        events = repository.events
        importPreviewItems = repository.importPreviewItems
        inviteContacts = repository.inviteContacts
        collectionItems = repository.collectionItems
        wishlistItems = repository.wishlistItems
        events = repository.events
        binderPages = repository.binderPages
        friends = repository.friends
        friendRequests = repository.friendRequests
        friendWants = repository.friendWants
        tradeListings = repository.tradeListings
        tradeOffers = repository.tradeOffers
    }

    var isDemoMode: Bool {
        runtimeMode == .demo
    }

    func useDemoMode(repository: DemoVaultRepository = .shared) {
        runtimeMode = .demo
        lastSyncError = nil
        resetDemoUserState(repository: repository)
    }

    func loadCloudDataIfPossible(session: SupabaseSession?) async {
        guard repositories.config.isConfigured, repositories.clientProvider.canCreateClient else {
            loadCachedOrDemo(reason: "Supabase is unavailable on this build.")
            return
        }

        guard let session else {
            runtimeMode = .supabase
            lastSyncError = nil
            return
        }

        isLoadingCloudData = true
        defer { isLoadingCloudData = false }

        do {
            let snapshot = try await fetchCloudSnapshot(userID: session.userID)
            apply(snapshot: snapshot, userID: session.userID)
            CloudVaultCache.save(snapshot)
            runtimeMode = .supabase
            lastSyncError = nil
        } catch {
            loadCachedOrDemo(reason: error.localizedDescription)
        }
    }

    private func loadCachedOrDemo(reason: String) {
        if let snapshot = CloudVaultCache.load(), let userID = repositories.clientProvider.currentSession?.userID {
            apply(snapshot: snapshot, userID: userID)
            runtimeMode = .offline
        } else {
            runtimeMode = .demo
        }
        lastSyncError = reason
    }

    private func fetchCloudSnapshot(userID: UUID) async throws -> CloudVaultSnapshot {
        async let remoteProfile = repositories.profiles.fetchCurrentProfile(userID: userID)
        async let remoteSets = repositories.cards.fetchSets()
        async let remoteCards = repositories.cards.fetchCards(search: nil)
        async let remoteCollection = repositories.collection.fetchCollection(userID: userID)
        async let remoteWishlist = repositories.wishlist.fetchWishlist(userID: userID)
        async let remoteFriends = repositories.friends.fetchFriends(userID: userID)
        async let remoteOffers = repositories.trades.fetchTradeOffers(userID: userID)
        async let remoteListings = repositories.marketplace.fetchMarketplaceListings(search: nil)
        async let remoteEvents = repositories.events.fetchEvents(userID: userID)

        return try await CloudVaultSnapshot(
            profile: remoteProfile,
            sets: remoteSets,
            cards: remoteCards,
            collection: remoteCollection,
            wishlist: remoteWishlist,
            friends: remoteFriends,
            tradeOffers: remoteOffers,
            marketplaceListings: remoteListings,
            events: remoteEvents
        )
    }

    private func apply(snapshot: CloudVaultSnapshot, userID: UUID) {
        let mappedSets = snapshot.sets.map(\.localSet)
        let setByID = Dictionary(uniqueKeysWithValues: mappedSets.map { ($0.id, $0) })
        let fallbackSet = mappedSets.first ?? DemoVaultRepository.shared.sets[0]
        let mappedCards = snapshot.cards.map { $0.localCard(set: setByID[$0.setID] ?? fallbackSet) }
        let cardByID = Dictionary(uniqueKeysWithValues: mappedCards.map { ($0.id, $0) })

        sets = mappedSets.isEmpty ? DemoVaultRepository.shared.sets : mappedSets
        cards = mappedCards.isEmpty ? DemoVaultRepository.shared.cards : mappedCards
        profile = snapshot.profile?.localProfile(favoriteSet: sets.first ?? fallbackSet) ?? profile
        collectionItems = snapshot.collection.compactMap { $0.localItem(card: cardByID[$0.cardID]) }
        wishlistItems = snapshot.wishlist.compactMap { $0.localItem(card: cardByID[$0.cardID]) }
        tradeListings = snapshot.marketplaceListings.compactMap { $0.localListing(card: cardByID[$0.cardID], currentUserID: userID) }
        tradeOffers = snapshot.tradeOffers.map { $0.localOffer(cards: cardByID, currentUserID: userID) }
        events = snapshot.events.compactMap { $0.localEvent(featuredSet: sets.first ?? fallbackSet) }
        friends = snapshot.friends.compactMap { $0.localFriend(cards: cards, currentUserID: userID) }
        friendRequests = []
        friendWants = []
    }

    var totalCopiesOwned: Int {
        collectionItems.reduce(0) { $0 + $1.quantity }
    }

    var uniqueCardsOwned: Int {
        collectionItems.count
    }

    var estimatedCollectionValue: Double {
        collectionItems.reduce(0) { $0 + ($1.card.marketValue * Double($1.quantity)) }
    }

    var uniqueSetsOwned: Int {
        Set(collectionItems.map(\.card.set.id)).count
    }

    var recentlyAdded: [CollectionItem] {
        collectionItems.sorted { $0.acquiredAt > $1.acquiredAt }
    }

    var tradeableCollectionItems: [CollectionItem] {
        collectionItems.filter(\.isAvailableForTrade)
    }

    func collectionItem(for card: Card) -> CollectionItem? {
        collectionItems.first { $0.card.id == card.id }
    }

    func wishlistItem(for card: Card) -> WishlistItem? {
        wishlistItems.first { $0.card.id == card.id }
    }

    func quantityOwned(for card: Card) -> Int? {
        collectionItem(for: card)?.quantity
    }

    func isWishlisted(_ card: Card) -> Bool {
        wishlistItem(for: card) != nil
    }

    func addCard(
        _ card: Card,
        quantity: Int = 1,
        condition: CardCondition? = nil,
        variant: CardVariant = .normal
    ) {
        let safeQuantity = max(quantity, 1)

        if let index = collectionItems.firstIndex(where: { $0.card.id == card.id }) {
            collectionItems[index].quantity += safeQuantity
            collectionItems[index].condition = condition ?? collectionItems[index].condition
            collectionItems[index].variant = variant
            collectionItems[index].acquiredAt = .now
            syncCollectionItem(collectionItems[index])
        } else {
            let item = CollectionItem(
                card: card,
                quantity: safeQuantity,
                condition: condition ?? card.condition,
                variant: variant,
                acquiredAt: .now
            )
            collectionItems.append(item)
            syncCollectionItem(item)
        }
    }

    func removeCard(_ card: Card) {
        let removed = collectionItems.first { $0.card.id == card.id }
        collectionItems.removeAll { $0.card.id == card.id }
        if let removed, runtimeMode == .supabase {
            Task { try? await repositories.collection.deleteCollectionItem(id: removed.id) }
        }
    }

    func updateQuantity(for card: Card, quantity: Int) {
        guard let index = collectionItems.firstIndex(where: { $0.card.id == card.id }) else { return }

        if quantity <= 0 {
            collectionItems.remove(at: index)
        } else {
            collectionItems[index].quantity = quantity
            syncCollectionItem(collectionItems[index])
        }
    }

    func updateCondition(for card: Card, condition: CardCondition) {
        guard let index = collectionItems.firstIndex(where: { $0.card.id == card.id }) else { return }
        collectionItems[index].condition = condition
        syncCollectionItem(collectionItems[index])
    }

    func updateVariant(for card: Card, variant: CardVariant) {
        guard let index = collectionItems.firstIndex(where: { $0.card.id == card.id }) else { return }
        collectionItems[index].variant = variant
        syncCollectionItem(collectionItems[index])
    }

    func updateTradeAvailability(for card: Card, isAvailable: Bool) {
        guard let index = collectionItems.firstIndex(where: { $0.card.id == card.id }) else { return }
        collectionItems[index].isAvailableForTrade = isAvailable
        syncCollectionItem(collectionItems[index])
    }

    func addToWishlist(
        _ card: Card,
        priority: WishlistPriority = .medium,
        budget: Double? = nil,
        notes: String = ""
    ) {
        if let index = wishlistItems.firstIndex(where: { $0.card.id == card.id }) {
            wishlistItems[index].priority = priority
            wishlistItems[index].budget = budget ?? wishlistItems[index].budget
            wishlistItems[index].notes = notes
            syncWishlistItem(wishlistItems[index])
        } else {
            let item = WishlistItem(
                card: card,
                priority: priority,
                budget: budget ?? card.marketValue,
                notes: notes
            )
            wishlistItems.append(item)
            syncWishlistItem(item)
        }
    }

    func updateWishlist(
        for card: Card,
        priority: WishlistPriority,
        budget: Double,
        notes: String
    ) {
        guard let index = wishlistItems.firstIndex(where: { $0.card.id == card.id }) else { return }
        wishlistItems[index].priority = priority
        wishlistItems[index].budget = max(budget, 0)
        wishlistItems[index].notes = notes
        syncWishlistItem(wishlistItems[index])
    }

    func removeFromWishlist(_ card: Card) {
        let removed = wishlistItems.first { $0.card.id == card.id }
        wishlistItems.removeAll { $0.card.id == card.id }
        if let removed, runtimeMode == .supabase {
            Task { try? await repositories.wishlist.deleteWishlistItem(id: removed.id) }
        }
    }

    func sendFriendRequest(to handleOrEmail: String) {
        let trimmed = handleOrEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let normalized = trimmed.lowercased()
        guard !friends.contains(where: { $0.handle.lowercased() == normalized || $0.email.lowercased() == normalized }) else { return }
        guard !friendRequests.contains(where: { $0.handleOrEmail.lowercased() == normalized }) else { return }

        friendRequests.insert(
            FriendRequest(
                displayName: trimmed.replacingOccurrences(of: "@", with: "").capitalized,
                handleOrEmail: trimmed,
                avatarSymbol: "paperplane.fill",
                direction: .outgoing,
                previewCard: cards.first
            ),
            at: 0
        )
    }

    func acceptFriendRequest(_ request: FriendRequest) {
        guard request.direction == .incoming else { return }
        let favorite = request.previewCard ?? cards.first
        guard let favorite else { return }
        let newFriend = Friend(
            displayName: request.displayName,
            handle: request.handleOrEmail.hasPrefix("@") ? request.handleOrEmail : "@" + request.displayName.lowercased().replacingOccurrences(of: " ", with: ""),
            email: request.handleOrEmail.contains("@") && !request.handleOrEmail.hasPrefix("@") ? request.handleOrEmail : "",
            avatarSymbol: request.avatarSymbol,
            collectorScore: 4100 + friends.count * 275,
            favoriteCard: favorite,
            completionPercent: 0.42,
            mutualTrades: 0,
            isOnline: true,
            visibleCollection: [
                CollectionItem(card: favorite, quantity: 1, variant: .normal, acquiredAt: .now)
            ],
            wishlist: wishlistItems.prefix(2).map { item in
                WishlistItem(card: item.card, priority: item.priority, budget: item.budget, notes: "Shared target from accepted request.")
            }
        )
        friends.insert(newFriend, at: 0)
        friendRequests.removeAll { $0.id == request.id }
    }

    func rejectFriendRequest(_ request: FriendRequest) {
        friendRequests.removeAll { $0.id == request.id }
    }

    func removeFriend(_ friend: Friend) {
        friends.removeAll { $0.id == friend.id }
        friendWants.removeAll { $0.friend.id == friend.id }
    }

    func blockFriend(_ friend: Friend) {
        removeFriend(friend)
    }

    func friendsWanting(_ card: Card) -> [Friend] {
        friends.filter { friend in
            friend.wishlist.contains { $0.card.id == card.id }
        }
    }

    func cardsIWantThatFriendOwns(_ friend: Friend) -> [CollectionItem] {
        let wantedIDs = Set(wishlistItems.map(\.card.id))
        return friend.visibleCollection.filter { wantedIDs.contains($0.card.id) }
    }

    func cardsFriendWantsThatIOwn(_ friend: Friend) -> [CollectionItem] {
        let friendWantedIDs = Set(friend.wishlist.map(\.card.id))
        return collectionItems.filter { friendWantedIDs.contains($0.card.id) }
    }

    func tradeOpportunities() -> [FriendTradeOpportunity] {
        friends.compactMap { friend in
            let theyOwn = cardsIWantThatFriendOwns(friend)
            let youOwn = cardsFriendWantsThatIOwn(friend)
            guard !theyOwn.isEmpty || !youOwn.isEmpty else { return nil }
            return FriendTradeOpportunity(friend: friend, theyOwn: theyOwn, youOwn: youOwn)
        }
        .sorted { $0.score > $1.score }
    }

    func listCardForTrade(_ item: CollectionItem, askingFor: String, usesSafeTrade: Bool) {
        guard !tradeListings.contains(where: { $0.isMine && $0.card.id == item.card.id }) else { return }
        tradeListings.insert(
            TradeListing(
                ownerName: profile.displayName,
                ownerHandle: profile.handle,
                card: item.card,
                condition: item.condition,
                variant: item.variant,
                askingFor: askingFor.isEmpty ? "Open to fair offers" : askingFor,
                locationLabel: "My vault",
                sellerReputation: 100,
                isFeatured: true,
                isMine: true,
                usesSafeTrade: usesSafeTrade
            ),
            at: 0
        )
        updateTradeAvailability(for: item.card, isAvailable: true)
    }

    func removeTradeListing(_ listing: TradeListing) {
        tradeListings.removeAll { $0.id == listing.id }
    }

    func toggleSavedListing(_ listing: TradeListing) {
        guard let index = tradeListings.firstIndex(where: { $0.id == listing.id }) else { return }
        tradeListings[index].isSaved.toggle()
    }

    func sendTradeOffer(
        to listing: TradeListing,
        offeredCards: [Card],
        requestedCards: [Card],
        internalCredits: Int,
        message: String,
        usesSafeTrade: Bool
    ) {
        guard !offeredCards.isEmpty || internalCredits > 0 else { return }
        guard !requestedCards.isEmpty else { return }
        tradeOffers.insert(
            TradeOffer(
                partnerName: listing.ownerName,
                partnerHandle: listing.ownerHandle,
                offeredCards: offeredCards,
                requestedCards: requestedCards,
                status: .pending,
                direction: .sent,
                internalCredits: max(internalCredits, 0),
                expiresInDays: 7,
                note: message.isEmpty ? "Trade offer sent from marketplace." : message,
                usesSafeTrade: usesSafeTrade
            ),
            at: 0
        )
    }

    func updateTradeOfferStatus(_ offer: TradeOffer, status: TradeStatus) {
        guard let index = tradeOffers.firstIndex(where: { $0.id == offer.id }) else { return }
        tradeOffers[index].status = status
    }

    func updateProfile(_ updatedProfile: UserProfile) {
        profile = updatedProfile
        syncProfile(updatedProfile)
    }

    func resetDemoUserState(repository: DemoVaultRepository = .shared) {
        profile = repository.profile
        collectionItems = repository.collectionItems
        wishlistItems = repository.wishlistItems
        binderPages = repository.binderPages
        friends = repository.friends
        friendRequests = repository.friendRequests
        friendWants = repository.friendWants
        tradeListings = repository.tradeListings
        tradeOffers = repository.tradeOffers
        events = repository.events
    }

    func addMissingCardToWishlist(_ card: Card) {
        guard collectionItem(for: card) == nil else { return }
        addToWishlist(card, priority: .high, budget: card.marketValue, notes: "Added from Pokédex missing tracker.")
    }

    func addEvent(_ event: VaultEvent) {
        events.append(event)
        events.sort { $0.date < $1.date }
    }

    func updateEvent(_ event: VaultEvent) {
        guard let index = events.firstIndex(where: { $0.id == event.id }) else { return }
        events[index] = event
        events.sort { $0.date < $1.date }
    }

    func deleteEvent(_ event: VaultEvent) {
        events.removeAll { $0.id == event.id }
    }

    func createBinderPage(title: String? = nil) -> BinderPage {
        let pageNumber = binderPages.count + 1
        let page = BinderPage(
            title: title ?? "Binder Page \(pageNumber)",
            theme: "Custom vault layout",
            slots: Self.emptyBinderSlots(),
            visibility: .private,
            updatedAt: .now
        )
        binderPages.insert(page, at: 0)
        return page
    }

    func renameBinderPage(_ pageID: BinderPage.ID, title: String) {
        guard let page = binderPages.first(where: { $0.id == pageID }) else { return }
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        updateBinderPage(
            BinderPage(
                id: page.id,
                title: trimmed.isEmpty ? page.title : trimmed,
                theme: page.theme,
                slots: page.slots,
                visibility: page.visibility,
                updatedAt: .now
            )
        )
    }

    func updateBinderVisibility(_ pageID: BinderPage.ID, visibility: BinderVisibility) {
        guard let page = binderPages.first(where: { $0.id == pageID }) else { return }
        updateBinderPage(
            BinderPage(
                id: page.id,
                title: page.title,
                theme: page.theme,
                slots: page.slots,
                visibility: visibility,
                updatedAt: .now
            )
        )
    }

    func updateBinderSlot(pageID: BinderPage.ID, slotID: BinderSlot.ID, card: Card?) {
        guard let page = binderPages.first(where: { $0.id == pageID }) else { return }
        let slots = page.slots.map { slot in
            slot.id == slotID ? BinderSlot(id: slot.id, index: slot.index, card: card, note: slot.note) : slot
        }
        updateBinderPage(
            BinderPage(
                id: page.id,
                title: page.title,
                theme: page.theme,
                slots: slots,
                visibility: page.visibility,
                updatedAt: .now
            )
        )
    }

    func deleteBinderPage(_ pageID: BinderPage.ID) {
        binderPages.removeAll { $0.id == pageID }
    }

    func updateBinderPage(_ page: BinderPage) {
        guard let index = binderPages.firstIndex(where: { $0.id == page.id }) else { return }
        binderPages[index] = page
    }

    static func emptyBinderSlots() -> [BinderSlot] {
        (1...9).map { BinderSlot(index: $0, card: nil) }
    }

    private func syncProfile(_ profile: UserProfile) {
        guard runtimeMode == .supabase, let userID = repositories.clientProvider.currentSession?.userID else { return }
        let remoteProfile = RemoteProfile(
            id: userID,
            username: profile.handle.replacingOccurrences(of: "@", with: ""),
            displayName: profile.displayName,
            location: profile.location,
            bio: profile.bio,
            collectorType: profile.collectorType,
            avatarPath: nil,
            reputationScore: profile.reputationScore,
            trustBadges: profile.trustBadges,
            completedTrades: profile.completedTrades,
            collectorScore: profile.collectorScore,
            createdAt: nil,
            updatedAt: nil
        )
        Task { try? await repositories.profiles.upsertProfile(remoteProfile) }
    }

    private func syncCollectionItem(_ item: CollectionItem) {
        guard runtimeMode == .supabase, let userID = repositories.clientProvider.currentSession?.userID else { return }
        let remoteItem = RemoteCollectionItem(
            id: item.id,
            userID: userID,
            cardID: item.card.id,
            quantity: item.quantity,
            condition: item.condition.rawValue,
            variant: item.variant.rawValue,
            isAvailableForTrade: item.isAvailableForTrade,
            isFavorite: item.isFavorite,
            acquiredAt: item.acquiredAt,
            notes: item.notes
        )
        Task { try? await repositories.collection.upsertCollectionItem(remoteItem) }
    }

    private func syncWishlistItem(_ item: WishlistItem) {
        guard runtimeMode == .supabase, let userID = repositories.clientProvider.currentSession?.userID else { return }
        let remoteItem = RemoteWishlistItem(
            id: item.id,
            userID: userID,
            cardID: item.card.id,
            priority: item.priority.rawValue,
            budget: item.budget,
            notes: item.notes,
            addedAt: item.addedAt
        )
        Task { try? await repositories.wishlist.upsertWishlistItem(remoteItem) }
    }
}

private struct CloudVaultSnapshot: Codable {
    let profile: RemoteProfile?
    let sets: [RemoteCardSet]
    let cards: [RemoteCard]
    let collection: [RemoteCollectionItem]
    let wishlist: [RemoteWishlistItem]
    let friends: [RemoteFriendship]
    let tradeOffers: [RemoteTradeOffer]
    let marketplaceListings: [RemoteMarketplaceListing]
    let events: [RemoteVaultEvent]
}

private enum CloudVaultCache {
    private static let fileName = "vaultdex-cloud-cache.json"

    static func load() -> CloudVaultSnapshot? {
        guard let data = try? Data(contentsOf: cacheURL) else { return nil }
        return try? JSONDecoder.supabase.decode(CloudVaultSnapshot.self, from: data)
    }

    static func save(_ snapshot: CloudVaultSnapshot) {
        do {
            try FileManager.default.createDirectory(at: cacheURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try JSONEncoder.supabase.encode(snapshot)
            try data.write(to: cacheURL, options: [.atomic])
        } catch {
            assertionFailure("Failed to write cloud cache: \(error.localizedDescription)")
        }
    }

    private static var cacheURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appending(path: "VaultDex")
            .appending(path: fileName)
    }
}

private extension RemoteCardSet {
    var localSet: CardSet {
        CardSet(id: id, name: name, code: code, releaseYear: releaseYear, totalCards: totalCards)
    }
}

private extension RemoteCard {
    func localCard(set: CardSet) -> Card {
        Card(
            id: id,
            name: name,
            set: set,
            number: number,
            rarity: CardRarity(rawValue: rarity) ?? .common,
            cardType: CardType(rawValue: cardType) ?? .colorless,
            typeLine: typeLine,
            power: power,
            condition: .nearMint,
            marketValue: marketValue,
            accent: CardAccent(rawValue: accent) ?? .aurora
        )
    }
}

private extension RemoteProfile {
    func localProfile(favoriteSet: CardSet) -> UserProfile {
        UserProfile(
            id: id,
            displayName: displayName,
            handle: "@\(username)",
            location: location ?? "Cloud Vault",
            bio: bio ?? "Synced VaultDex collector profile.",
            collectorType: collectorType ?? "Cloud Collector",
            avatarSymbol: "person.crop.circle.fill",
            reputationScore: reputationScore,
            trustBadges: trustBadges.isEmpty ? ["Cloud Synced"] : trustBadges,
            completedTrades: completedTrades,
            collectorScore: collectorScore,
            favoriteSet: favoriteSet,
            joinedDate: createdAt ?? .now,
            followers: 0,
            following: 0
        )
    }
}

private extension RemoteCollectionItem {
    func localItem(card: Card?) -> CollectionItem? {
        guard let card else { return nil }
        return CollectionItem(
            id: id,
            card: card,
            quantity: quantity,
            condition: CardCondition(rawValue: condition) ?? .nearMint,
            variant: CardVariant(rawValue: variant) ?? .normal,
            isAvailableForTrade: isAvailableForTrade,
            isFavorite: isFavorite,
            acquiredAt: acquiredAt,
            notes: notes
        )
    }
}

private extension RemoteWishlistItem {
    func localItem(card: Card?) -> WishlistItem? {
        guard let card else { return nil }
        return WishlistItem(
            id: id,
            card: card,
            priority: WishlistPriority(rawValue: priority) ?? .medium,
            budget: budget,
            notes: notes,
            addedAt: addedAt
        )
    }
}

private extension RemoteMarketplaceListing {
    func localListing(card: Card?, currentUserID: UUID) -> TradeListing? {
        guard let card else { return nil }
        return TradeListing(
            id: id,
            ownerName: sellerDisplayName ?? "Cloud Collector",
            ownerHandle: ownerID == currentUserID ? "@me" : "@collector",
            card: card,
            condition: CardCondition(rawValue: condition) ?? .nearMint,
            variant: CardVariant(rawValue: variant ?? "normal") ?? .normal,
            askingFor: askingFor ?? "Open to fair offers",
            listedAt: listedAt ?? .now,
            locationLabel: locationLabel ?? "Cloud listing",
            sellerReputation: sellerReputation,
            isFeatured: rarity == "mythic" || rarity == "legendary",
            isSaved: isSaved ?? false,
            isMine: ownerID == currentUserID,
            usesSafeTrade: usesSafeTrade ?? false
        )
    }
}

private extension RemoteTradeOffer {
    func localOffer(cards: [UUID: Card], currentUserID: UUID) -> TradeOffer {
        TradeOffer(
            id: id,
            partnerName: senderID == currentUserID ? "Cloud Collector" : "Trade Partner",
            partnerHandle: senderID == currentUserID ? "@sent" : "@received",
            offeredCards: offeredCardIDs.compactMap { cards[$0] },
            requestedCards: requestedCardIDs.compactMap { cards[$0] },
            status: TradeStatus(rawValue: status) ?? .pending,
            direction: senderID == currentUserID ? .sent : .received,
            internalCredits: internalCredits,
            createdAt: createdAt ?? .now,
            expiresInDays: 7,
            note: message,
            usesSafeTrade: usesSafeTrade
        )
    }
}

private extension RemoteVaultEvent {
    func localEvent(featuredSet: CardSet) -> VaultEvent {
        VaultEvent(
            id: id,
            title: title,
            venue: location,
            date: eventDate,
            kind: VaultEventKind(rawValue: "tradeNight") ?? .community,
            prize: "Community event",
            attendingFriends: 0,
            featuredSet: featuredSet,
            emojiMarker: emojiMarker,
            notes: notes,
            visibility: BinderVisibility(rawValue: visibility) ?? .public
        )
    }
}

private extension RemoteFriendship {
    func localFriend(cards: [Card], currentUserID: UUID) -> Friend? {
        guard let favoriteCard = cards.first else { return nil }
        let friendID = requesterID == currentUserID ? addresseeID : requesterID
        return Friend(
            id: friendID,
            displayName: "Cloud Friend",
            handle: "@\(friendID.uuidString.prefix(8))",
            avatarSymbol: "person.2.fill",
            collectorScore: 0,
            favoriteCard: favoriteCard,
            completionPercent: 0,
            mutualTrades: 0,
            isOnline: false,
            visibleCollection: [],
            wishlist: []
        )
    }
}
