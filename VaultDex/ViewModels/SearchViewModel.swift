import Foundation

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var selectedRarity: CardRarity?
    @Published var selectedSet: CardSet?

    private let allCards: [Card]
    private let collectionItems: [CollectionItem]
    private let wishlistItems: [WishlistItem]

    let allSets: [CardSet]

    init(repository: DemoVaultRepository = .shared) {
        allCards = repository.cards
        collectionItems = repository.collectionItems
        wishlistItems = repository.wishlistItems
        allSets = repository.sets
    }

    var filteredCards: [Card] {
        allCards.filter { card in
            let matchesQuery = query.isEmpty
                || card.name.localizedCaseInsensitiveContains(query)
                || card.set.name.localizedCaseInsensitiveContains(query)
                || card.typeLine.localizedCaseInsensitiveContains(query)

            let matchesRarity = selectedRarity == nil || card.rarity == selectedRarity
            let matchesSet = selectedSet == nil || card.set == selectedSet
            return matchesQuery && matchesRarity && matchesSet
        }
    }

    func quantityOwned(for card: Card) -> Int? {
        collectionItems.first { $0.card.id == card.id }?.quantity
    }

    func isWishlisted(_ card: Card) -> Bool {
        wishlistItems.contains { $0.card.id == card.id }
    }
}
