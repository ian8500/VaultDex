import Foundation

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var selectedRarity: CardRarity?

    private let allCards: [Card]

    init(repository: DemoVaultRepository = .shared) {
        allCards = repository.cards
    }

    var filteredCards: [Card] {
        allCards.filter { card in
            let matchesQuery = query.isEmpty
                || card.name.localizedCaseInsensitiveContains(query)
                || card.set.name.localizedCaseInsensitiveContains(query)
                || card.typeLine.localizedCaseInsensitiveContains(query)

            let matchesRarity = selectedRarity == nil || card.rarity == selectedRarity
            return matchesQuery && matchesRarity
        }
    }
}
