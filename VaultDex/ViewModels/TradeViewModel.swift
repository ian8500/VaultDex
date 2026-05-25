import Foundation

@MainActor
final class TradeViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var selectedRarity: CardRarity?
    @Published var selectedCondition: CardCondition?
    @Published var maximumValue: Double = 250
    @Published var minimumReputation = 0
    @Published var listingAsk = ""
    @Published var listingDescription = ""
    @Published var listingKind: TradeListingKind = .both
    @Published var listingAskingCredits = 0
    @Published var listingUsesSafeTrade = true
    @Published var offerMessage = ""
    @Published var internalCredits = 0
    @Published var selectedOfferCardIDs: Set<Card.ID> = []
    @Published var requestedCardIDs: Set<Card.ID> = []
    @Published var selectedFriendID: Friend.ID?
    @Published var requestedFriendCollectionItemIDs: Set<CollectionItem.ID> = []
    @Published var offerUsesSafeTrade = true

    func publicListings(in store: LocalVaultStore) -> [TradeListing] {
        store.tradeListings.filter { !$0.isMine }
    }

    func myListings(in store: LocalVaultStore) -> [TradeListing] {
        store.tradeListings.filter(\.isMine)
    }

    func filteredListings(in store: LocalVaultStore) -> [TradeListing] {
        publicListings(in: store).filter { listing in
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let matchesSearch = query.isEmpty ||
                listing.card.name.lowercased().contains(query) ||
                listing.ownerName.lowercased().contains(query) ||
                listing.askingFor.lowercased().contains(query) ||
                listing.description.lowercased().contains(query)
            let matchesRarity = selectedRarity == nil || listing.card.rarity == selectedRarity
            let matchesCondition = selectedCondition == nil || listing.condition == selectedCondition
            let matchesValue = listing.estimatedValue <= maximumValue
            let matchesReputation = listing.sellerReputation >= minimumReputation
            return matchesSearch && matchesRarity && matchesCondition && matchesValue && matchesReputation
        }
        .sorted { lhs, rhs in
            if lhs.isFeatured != rhs.isFeatured { return lhs.isFeatured }
            return lhs.listedAt > rhs.listedAt
        }
    }

    func receivedOffers(in store: LocalVaultStore) -> [TradeOffer] {
        store.tradeOffers.filter { $0.direction == .received }
    }

    func sentOffers(in store: LocalVaultStore) -> [TradeOffer] {
        store.tradeOffers.filter { $0.direction == .sent }
    }

    func selectedOfferCards(in store: LocalVaultStore) -> [Card] {
        selectedOfferItems(in: store).map(\.card)
    }

    func selectedOfferItems(in store: LocalVaultStore) -> [CollectionItem] {
        store.collectionItems
            .filter { selectedOfferCardIDs.contains($0.card.id) }
    }

    func requestedCards(from listing: TradeListing) -> [Card] {
        requestedCardIDs.contains(listing.card.id) ? [listing.card] : []
    }

    func selectedFriend(in store: LocalVaultStore) -> Friend? {
        guard let selectedFriendID else { return store.friends.first }
        return store.friends.first { $0.id == selectedFriendID }
    }

    func requestedItems(from friend: Friend?) -> [CollectionItem] {
        guard let friend else { return [] }
        return friend.visibleCollection.filter { requestedFriendCollectionItemIDs.contains($0.id) }
    }

    func resetOffer(for listing: TradeListing) {
        offerMessage = ""
        internalCredits = 0
        selectedOfferCardIDs = []
        requestedCardIDs = [listing.card.id]
        selectedFriendID = nil
        requestedFriendCollectionItemIDs = []
        offerUsesSafeTrade = listing.usesSafeTrade
    }

    func resetFriendOffer(in store: LocalVaultStore) {
        offerMessage = ""
        internalCredits = 0
        selectedOfferCardIDs = []
        requestedCardIDs = []
        selectedFriendID = store.friends.first?.id
        requestedFriendCollectionItemIDs = []
        offerUsesSafeTrade = true
    }

    func valueBalance(offeredCards: [Card], requestedCards: [Card], credits: Int) -> Double {
        offeredCards.reduce(0) { $0 + $1.marketValue } + Double(max(credits, 0)) - requestedCards.reduce(0) { $0 + $1.marketValue }
    }

    func fairnessScore(offeredCards: [Card], requestedCards: [Card], credits: Int) -> Double {
        let offered = offeredCards.reduce(0) { $0 + $1.marketValue } + Double(max(credits, 0))
        let requested = requestedCards.reduce(0) { $0 + $1.marketValue }
        let larger = max(offered, requested)
        guard larger > 0 else { return 1 }
        return max(0, 1 - abs(offered - requested) / larger)
    }

    func fairnessLabel(score: Double) -> String {
        switch score {
        case 0.86...: "Fair"
        case 0.65..<0.86: "Close"
        default: "Uneven"
        }
    }
}
