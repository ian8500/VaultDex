import Foundation

@MainActor
final class VaultViewModel: ObservableObject {
    func sortedItems(in store: LocalVaultStore) -> [CollectionItem] {
        store.collectionItems.sorted { first, second in
            if first.isFavorite != second.isFavorite {
                return first.isFavorite && !second.isFavorite
            }
            return first.card.marketValue > second.card.marketValue
        }
    }

    func favoriteItems(in store: LocalVaultStore) -> [CollectionItem] {
        store.collectionItems.filter(\.isFavorite)
    }

    func binderFilledSlots(in store: LocalVaultStore) -> Int {
        store.binderPages.flatMap(\.slots).filter { $0.card != nil }.count
    }

    func binderTotalSlots(in store: LocalVaultStore) -> Int {
        store.binderPages.flatMap(\.slots).count
    }

    func completionPercent(in store: LocalVaultStore) -> Double {
        guard !store.cards.isEmpty else { return 0 }
        let ownedIDs = Set(store.collectionItems.map(\.card.id))
        return Double(ownedIDs.count) / Double(store.cards.count)
    }
}
