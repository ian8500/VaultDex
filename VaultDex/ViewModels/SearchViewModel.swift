import Foundation

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var selectedRarity: CardRarity?
    @Published var selectedSet: CardSet?
    @Published var selectedType: CardType?

    func filteredCards(in store: LocalVaultStore) -> [Card] {
        store.cards.filter { card in
            let matchesQuery = query.isEmpty
                || card.name.localizedCaseInsensitiveContains(query)
                || card.set.name.localizedCaseInsensitiveContains(query)
                || card.cardType.displayName.localizedCaseInsensitiveContains(query)
                || card.typeLine.localizedCaseInsensitiveContains(query)

            let matchesRarity = selectedRarity == nil || card.rarity == selectedRarity
            let matchesSet = selectedSet == nil || card.set == selectedSet
            let matchesType = selectedType == nil || card.cardType == selectedType
            return matchesQuery && matchesRarity && matchesSet && matchesType
        }
    }
}
