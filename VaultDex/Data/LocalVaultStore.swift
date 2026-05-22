import Foundation

@MainActor
final class LocalVaultStore: ObservableObject {
    let sets: [CardSet]
    let cards: [Card]
    let profile: UserProfile
    let friends: [Friend]
    let friendWants: [FriendWant]
    let binderPages: [BinderPage]
    let tradeListings: [TradeListing]
    let tradeOffers: [TradeOffer]
    let events: [VaultEvent]
    let importPreviewItems: [ImportPreviewItem]
    let inviteContacts: [InviteContact]

    @Published var collectionItems: [CollectionItem]
    @Published var wishlistItems: [WishlistItem]

    init(repository: DemoVaultRepository = .shared) {
        sets = repository.sets
        cards = repository.cards
        profile = repository.profile
        friends = repository.friends
        friendWants = repository.friendWants
        binderPages = repository.binderPages
        tradeListings = repository.tradeListings
        tradeOffers = repository.tradeOffers
        events = repository.events
        importPreviewItems = repository.importPreviewItems
        inviteContacts = repository.inviteContacts
        collectionItems = repository.collectionItems
        wishlistItems = repository.wishlistItems
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
}
