import Foundation

final class DemoVaultRepository {
    static let shared = DemoVaultRepository()

    let sets: [CardSet]
    let cards: [Card]
    let collectionItems: [CollectionItem]
    let profile: UserProfile
    let tradeOffers: [TradeOffer]
    let wishlistItems: [WishlistItem]
    let friends: [Friend]
    let binderPages: [BinderPage]
    let tradeListings: [TradeListing]
    let events: [VaultEvent]
    let importPreviewItems: [ImportPreviewItem]
    let inviteContacts: [InviteContact]
    let friendWants: [FriendWant]
    let friendRequests: [FriendRequest]

    private init() {
        let fallbackSet = CardSet(name: "VaultDex", code: "VDX", releaseYear: 2026, totalCards: 0)

        sets = []
        cards = []
        collectionItems = []
        tradeOffers = []
        wishlistItems = []
        friends = []
        binderPages = []
        tradeListings = []
        events = []
        importPreviewItems = []
        inviteContacts = []
        friendWants = []
        friendRequests = []

        profile = UserProfile(
            displayName: "VaultDex Collector",
            handle: "@collector",
            location: "",
            bio: "Sign in to start building your collection.",
            collectorType: "Collector",
            avatarSymbol: "person.crop.circle.fill",
            reputationScore: 0,
            trustBadges: [],
            completedTrades: 0,
            collectorScore: 0,
            favoriteSet: fallbackSet,
            joinedDate: .now,
            followers: 0,
            following: 0
        )
    }
}
