import Foundation

struct CardSearchRequest: Hashable {
    var query: String
    var rarity: CardRarity?
    var type: CardType?
    var setID: String?
    var limit: Int = 20
}

protocol CardProvider {
    func searchCards(_ request: CardSearchRequest) async throws -> [Card]
}

final class PokemonTCGAPIProvider: CardProvider {
    private let apiService: CardAPIService

    init(apiService: CardAPIService = CardAPIService()) {
        self.apiService = apiService
    }

    func searchCards(_ request: CardSearchRequest) async throws -> [Card] {
        let response = try await apiService.searchCards(
            query: request.query,
            rarity: request.rarity,
            type: request.type,
            setID: request.setID,
            sort: .name,
            page: 1,
            pageSize: min(max(request.limit, 1), 20)
        )
        return response.data.map(\.localCard)
    }
}

final class TCGDexProvider: CardProvider {
    func searchCards(_ request: CardSearchRequest) async throws -> [Card] {
        []
    }
}

final class PokemonTCGJSONImportProvider: CardProvider {
    func searchCards(_ request: CardSearchRequest) async throws -> [Card] {
        []
    }
}

final class SupabaseCardRepository: CardProvider {
    private let repository: CardCatalogRepository

    init(repository: CardCatalogRepository) {
        self.repository = repository
    }

    func searchCards(_ request: CardSearchRequest) async throws -> [Card] {
        let trimmedQuery = request.query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty || request.rarity != nil || request.type != nil || request.setID != nil else {
            return []
        }

        let rows = try await repository.fetchCards(search: trimmedQuery.isEmpty ? request.rarity?.displayName ?? request.type?.displayName ?? request.setID : trimmedQuery)
        return rows
            .map(\.localSearchCard)
            .filter { card in
                let matchesRarity = request.rarity == nil || card.rarity == request.rarity
                let matchesType = request.type == nil || card.cardType == request.type || card.types.contains { $0.localizedCaseInsensitiveContains(request.type?.displayName ?? "") }
                let matchesSet = request.setID == nil || card.set.externalID == request.setID || card.set.code == request.setID
                return matchesRarity && matchesType && matchesSet
            }
            .prefix(request.limit)
            .map { $0 }
    }
}

extension RemoteCard {
    var localSearchCard: Card {
        let set = CardSet(
            id: setID ?? UUID(),
            name: setName ?? "Unknown Set",
            code: setExternalID ?? setName ?? "SET",
            releaseYear: cachedAt.map { Calendar.current.component(.year, from: $0) } ?? 0,
            totalCards: 0,
            externalID: setExternalID
        )
        let mappedType = CardType(apiTypes: types.isEmpty ? [cardType, typeLine] : types)
        return Card(
            id: id,
            name: name,
            set: set,
            number: number,
            rarity: CardRarity(apiRarity: rarity),
            cardType: mappedType,
            typeLine: typeLine.isEmpty ? subtypes.joined(separator: ", ") : typeLine,
            power: power,
            condition: .nearMint,
            marketValue: marketValue,
            accent: mappedType.defaultAccent,
            externalID: externalID,
            types: types,
            subtypes: subtypes,
            artist: artistName,
            smallImageURL: (smallImageURL ?? imagePath).flatMap(URL.init(string:)),
            largeImageURL: largeImageURL.flatMap(URL.init(string:))
        )
    }
}
