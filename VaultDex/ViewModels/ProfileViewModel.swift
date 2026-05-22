import Foundation

struct SetProgress: Identifiable, Hashable {
    var id: UUID { cardSet.id }
    let cardSet: CardSet
    let owned: Int
    let total: Int

    var fraction: Double {
        guard total > 0 else { return 0 }
        return Double(owned) / Double(total)
    }
}

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published private(set) var profile: UserProfile
    @Published private(set) var collectionItems: [CollectionItem]
    @Published private(set) var friends: [Friend]
    @Published private(set) var events: [VaultEvent]
    private let sets: [CardSet]
    private let cards: [Card]

    init(repository: DemoVaultRepository = .shared) {
        profile = repository.profile
        collectionItems = repository.collectionItems
        friends = repository.friends
        events = repository.events
        sets = repository.sets
        cards = repository.cards
    }

    var collectionValue: Double {
        collectionItems.reduce(0) { $0 + ($1.card.marketValue * Double($1.quantity)) }
    }

    var mythicCount: Int {
        collectionItems.filter { $0.card.rarity == .mythic }.reduce(0) { $0 + $1.quantity }
    }

    var setProgress: [SetProgress] {
        sets.map { set in
            let owned = Set(collectionItems.filter { $0.card.set == set }.map(\.card.id)).count
            let total = cards.filter { $0.set == set }.count
            return SetProgress(cardSet: set, owned: owned, total: max(total, 1))
        }
    }

    var onlineFriends: Int {
        friends.filter(\.isOnline).count
    }

    var nextEvent: VaultEvent? {
        events.sorted { $0.date < $1.date }.first
    }
}
