import Foundation

final class CardImportService {
    private let apiService: CardAPIService

    init(apiService: CardAPIService = CardAPIService()) {
        self.apiService = apiService
    }

    func fetchByCardName(
        _ name: String,
        page: Int = 1,
        pageSize: Int = 8,
        using clientProvider: SupabaseClientProvider
    ) async throws -> [Card] {
        let response = try await apiService.searchCards(
            query: name,
            page: page,
            pageSize: pageSize
        )
        await cache(response.data, using: clientProvider)
        return response.data.map(\.localCard)
    }

    func searchAndCache(
        query: String,
        rarity: CardRarity?,
        type: CardType?,
        setID: String?,
        quickQuery: String?,
        page: Int,
        pageSize: Int,
        using clientProvider: SupabaseClientProvider
    ) async throws -> [Card] {
        let response = try await apiService.searchCards(
            query: query,
            rarity: rarity,
            type: type,
            setID: setID,
            quickQuery: quickQuery,
            sort: .name,
            page: page,
            pageSize: pageSize
        )
        await cache(response.data, using: clientProvider)
        return response.data.map(\.localCard)
    }

    func fetchByCardID(_ id: String, using clientProvider: SupabaseClientProvider) async throws -> Card {
        let card = try await apiService.fetchCard(id: id)
        await cache([card], using: clientProvider)
        return card.localCard
    }

    func fetchBySet(_ setID: String, using clientProvider: SupabaseClientProvider) async throws -> [Card] {
        let cards = try await apiService.fetchCardsForSet(setID: setID)
        await cache(cards, using: clientProvider)
        return cards.map(\.localCard)
    }

    func cache(_ cards: [PokemonTCGCard], using clientProvider: SupabaseClientProvider) async {
        await apiService.cache(cards: cards, using: clientProvider)
    }

    func refreshPopularCardsIfNeeded(
        using cardRepository: CardCatalogRepository,
        clientProvider: SupabaseClientProvider
    ) async {
        guard clientProvider.isRemoteEnabled else { return }

        let popularNames = ["Pikachu", "Charizard", "Eevee", "Mew", "Umbreon", "Gengar", "Snorlax"]
        do {
            for name in popularNames {
                let existing = try await cardRepository.fetchCards(name: name, limit: 1)
                guard existing.isEmpty else { continue }
                _ = try await fetchByCardName(name, pageSize: 8, using: clientProvider)
            }
        } catch {
            return
        }
    }

    func enrichStaleCards(
        using cardRepository: CardCatalogRepository,
        clientProvider: SupabaseClientProvider,
        limit: Int = 8
    ) async {
        guard clientProvider.isRemoteEnabled else { return }

        do {
            let staleCards = try await cardRepository.fetchStaleCards(limit: limit)
            for card in staleCards {
                guard let externalID = card.externalID, !externalID.isEmpty else { continue }
                _ = try? await fetchByCardID(externalID, using: clientProvider)
            }
        } catch {
            return
        }
    }
}
