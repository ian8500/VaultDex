import Foundation

struct DashboardActivity: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let systemImage: String
}

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published private(set) var collectionItems: [CollectionItem]
    @Published private(set) var tradeOffers: [TradeOffer]
    @Published private(set) var profile: UserProfile
    @Published private(set) var wishlistItems: [WishlistItem]
    @Published private(set) var friends: [Friend]
    @Published private(set) var events: [VaultEvent]

    private let cards: [Card]

    let recentActivity: [DashboardActivity]

    init(repository: DemoVaultRepository = .shared) {
        collectionItems = repository.collectionItems
        tradeOffers = repository.tradeOffers
        profile = repository.profile
        wishlistItems = repository.wishlistItems
        friends = repository.friends
        events = repository.events
        cards = repository.cards
        recentActivity = [
            DashboardActivity(title: "Astra Prime secured", subtitle: "Mint pull from Nebula Crown", systemImage: "sparkles"),
            DashboardActivity(title: "Trade counter received", subtitle: "Theo Vale adjusted a bundle", systemImage: "arrow.left.arrow.right"),
            DashboardActivity(title: "Binder updated", subtitle: "Mythic Front Page has 7 slots filled", systemImage: "rectangle.grid.3x2.fill"),
            DashboardActivity(title: "Event RSVP ready", subtitle: "Nebula Crown Launch League starts soon", systemImage: "calendar")
        ]
    }

    var totalCopies: Int {
        collectionItems.reduce(0) { $0 + $1.quantity }
    }

    var uniqueCards: Int {
        collectionItems.count
    }

    var vaultValue: Double {
        collectionItems.reduce(0) { $0 + ($1.card.marketValue * Double($1.quantity)) }
    }

    var pendingTrades: Int {
        tradeOffers.filter { $0.status == .pending || $0.status == .countered }.count
    }

    var wishlistCount: Int {
        wishlistItems.count
    }

    var onlineFriends: Int {
        friends.filter(\.isOnline).count
    }

    var completionPercent: Double {
        guard !cards.isEmpty else { return 0 }
        let ownedIDs = Set(collectionItems.map(\.card.id))
        return Double(ownedIDs.count) / Double(cards.count)
    }

    var nextEvent: VaultEvent? {
        events.sorted { $0.date < $1.date }.first
    }

    var highlightCards: [Card] {
        collectionItems
            .sorted { $0.card.marketValue > $1.card.marketValue }
            .prefix(4)
            .map(\.card)
    }
}
