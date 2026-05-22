import Foundation

@MainActor
final class VaultViewModel: ObservableObject {
    @Published private(set) var collectionItems: [CollectionItem]
    @Published private(set) var wishlistItems: [WishlistItem]
    @Published private(set) var binderPages: [BinderPage]

    private let cards: [Card]

    init(repository: DemoVaultRepository = .shared) {
        collectionItems = repository.collectionItems
        wishlistItems = repository.wishlistItems
        binderPages = repository.binderPages
        cards = repository.cards
    }

    var sortedItems: [CollectionItem] {
        collectionItems.sorted { first, second in
            if first.isFavorite != second.isFavorite {
                return first.isFavorite && !second.isFavorite
            }
            return first.card.marketValue > second.card.marketValue
        }
    }

    var favoriteItems: [CollectionItem] {
        collectionItems.filter(\.isFavorite)
    }

    var totalCopies: Int {
        collectionItems.reduce(0) { $0 + $1.quantity }
    }

    var totalValue: Double {
        collectionItems.reduce(0) { $0 + ($1.card.marketValue * Double($1.quantity)) }
    }

    var binderFilledSlots: Int {
        binderPages.flatMap(\.slots).filter { $0.card != nil }.count
    }

    var binderTotalSlots: Int {
        binderPages.flatMap(\.slots).count
    }

    var completionPercent: Double {
        guard !cards.isEmpty else { return 0 }
        let ownedIDs = Set(collectionItems.map(\.card.id))
        return Double(ownedIDs.count) / Double(cards.count)
    }
}
