import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published private(set) var profile: UserProfile
    @Published private(set) var collectionItems: [CollectionItem]
    private let sets: [CardSet]

    init(repository: DemoVaultRepository = .shared) {
        profile = repository.profile
        collectionItems = repository.collectionItems
        sets = repository.sets
    }

    var collectionValue: Double {
        collectionItems.reduce(0) { $0 + ($1.card.marketValue * Double($1.quantity)) }
    }

    var mythicCount: Int {
        collectionItems.filter { $0.card.rarity == .mythic }.reduce(0) { $0 + $1.quantity }
    }

    var setProgress: [(set: CardSet, owned: Int, total: Int)] {
        sets.map { set in
            let owned = collectionItems.filter { $0.card.set == set }.count
            return (set, owned, set.totalCards)
        }
    }
}
