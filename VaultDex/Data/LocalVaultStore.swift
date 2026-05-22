import Foundation

@MainActor
final class LocalVaultStore: ObservableObject {
    let sets: [CardSet]
    let cards: [Card]
    let importPreviewItems: [ImportPreviewItem]
    let inviteContacts: [InviteContact]

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

    init(repository: DemoVaultRepository = .shared) {
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
        } else {
            collectionItems.append(
                CollectionItem(
                    card: card,
                    quantity: safeQuantity,
                    condition: condition ?? card.condition,
                    variant: variant,
                    acquiredAt: .now
                )
            )
        }
    }

    func removeCard(_ card: Card) {
        collectionItems.removeAll { $0.card.id == card.id }
    }

    func updateQuantity(for card: Card, quantity: Int) {
        guard let index = collectionItems.firstIndex(where: { $0.card.id == card.id }) else { return }

        if quantity <= 0 {
            collectionItems.remove(at: index)
        } else {
            collectionItems[index].quantity = quantity
        }
    }

    func updateCondition(for card: Card, condition: CardCondition) {
        guard let index = collectionItems.firstIndex(where: { $0.card.id == card.id }) else { return }
        collectionItems[index].condition = condition
    }

    func updateVariant(for card: Card, variant: CardVariant) {
        guard let index = collectionItems.firstIndex(where: { $0.card.id == card.id }) else { return }
        collectionItems[index].variant = variant
    }

    func updateTradeAvailability(for card: Card, isAvailable: Bool) {
        guard let index = collectionItems.firstIndex(where: { $0.card.id == card.id }) else { return }
        collectionItems[index].isAvailableForTrade = isAvailable
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
        } else {
            wishlistItems.append(
                WishlistItem(
                    card: card,
                    priority: priority,
                    budget: budget ?? card.marketValue,
                    notes: notes
                )
            )
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
    }

    func removeFromWishlist(_ card: Card) {
        wishlistItems.removeAll { $0.card.id == card.id }
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
}
