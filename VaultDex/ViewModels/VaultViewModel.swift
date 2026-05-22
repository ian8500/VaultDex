import Foundation

@MainActor
final class VaultViewModel: ObservableObject {
    @Published private(set) var collectionItems: [CollectionItem]

    init(repository: DemoVaultRepository = .shared) {
        collectionItems = repository.collectionItems
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
}
