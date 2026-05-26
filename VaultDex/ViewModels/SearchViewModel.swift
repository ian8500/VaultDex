import Foundation

enum SearchSortOption: String, CaseIterable, Identifiable {
    case name
    case rarity
    case marketValue
    case newest

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .name: "Name"
        case .rarity: "Rarity"
        case .marketValue: "Market Estimate"
        case .newest: "Newest"
        }
    }

    var apiOrderBy: String {
        switch self {
        case .name, .rarity, .marketValue: "name"
        case .newest: "-set.releaseDate"
        }
    }
}

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var selectedRarity: CardRarity?
    @Published var selectedSet: CardSet?
    @Published var selectedType: CardType?
    @Published var sortOption: SearchSortOption = .name
    @Published private(set) var apiCards: [Card] = []
    @Published private(set) var apiSets: [CardSet] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var didLoadAPI = false
    @Published private(set) var currentPage = 1
    @Published private(set) var canLoadMore = false
    @Published private(set) var totalResults: Int?

    private let apiService: CardAPIService
    private let pageSize = 24

    init(apiService: CardAPIService = CardAPIService()) {
        self.apiService = apiService
    }

    func loadInitialResults(store: LocalVaultStore) async {
        guard !didLoadAPI else { return }
        await search(store: store)
        await loadSets()
    }

    func search(store: LocalVaultStore) async {
        guard !Task.isCancelled else { return }
        currentPage = 1
        canLoadMore = false
        totalResults = nil
        isLoading = true
        errorMessage = nil
        defer {
            isLoading = false
            didLoadAPI = true
        }

        do {
            await ExchangeRateService.shared.refreshRatesIfNeeded()
            let response = try await apiService.searchCards(
                query: query,
                rarity: selectedRarity,
                type: selectedType,
                setID: selectedSet?.externalID ?? selectedSet?.code,
                sort: sortOption,
                page: currentPage,
                pageSize: pageSize
            )
            guard !Task.isCancelled else { return }
            apiCards = sort(response.data.map(\.localCard))
            totalResults = response.totalCount
            canLoadMore = response.count == pageSize && apiCards.count < (response.totalCount ?? Int.max)
            await apiService.cache(cards: response.data, using: store.repositories.clientProvider)
        } catch {
            guard !Task.isCancelled else { return }
            apiCards = []
            errorMessage = "Unable to load cards right now. Please try again."
        }
    }

    func loadMore(store: LocalVaultStore) async {
        guard canLoadMore, !isLoading, !isLoadingMore else { return }
        isLoadingMore = true
        errorMessage = nil
        defer { isLoadingMore = false }

        do {
            await ExchangeRateService.shared.refreshRatesIfNeeded()
            let nextPage = currentPage + 1
            let response = try await apiService.searchCards(
                query: query,
                rarity: selectedRarity,
                type: selectedType,
                setID: selectedSet?.externalID ?? selectedSet?.code,
                sort: sortOption,
                page: nextPage,
                pageSize: pageSize
            )
            currentPage = nextPage
            var seenIDs = Set(apiCards.map(\.id))
            let newCards = response.data.map(\.localCard).filter { seenIDs.insert($0.id).inserted }
            apiCards = sort(apiCards + newCards)
            totalResults = response.totalCount
            canLoadMore = response.count == pageSize && apiCards.count < (response.totalCount ?? Int.max)
            await apiService.cache(cards: response.data, using: store.repositories.clientProvider)
        } catch {
            errorMessage = "Unable to load more cards right now. Please try again."
        }
    }

    func loadSets() async {
        do {
            apiSets = try await apiService.fetchSets().prefix(30).map {
                CardSet(
                    id: .deterministic("pokemon-tcg-set-\($0.id)"),
                    name: $0.name,
                    code: $0.id,
                    releaseYear: $0.releaseYear,
                    totalCards: $0.total ?? $0.printedTotal ?? 0,
                    externalID: $0.id
                )
            }
        } catch {
            if errorMessage == nil {
                errorMessage = "Unable to load card sets right now. Please try again."
            }
        }
    }

    func filteredCards(in store: LocalVaultStore) -> [Card] {
        sort(apiCards.filter { card in
            let matchesQuery = query.isEmpty
                || card.name.localizedCaseInsensitiveContains(query)
                || card.number.localizedCaseInsensitiveContains(query)
                || card.set.name.localizedCaseInsensitiveContains(query)
                || card.set.code.localizedCaseInsensitiveContains(query)
                || card.cardType.displayName.localizedCaseInsensitiveContains(query)
                || card.typeLine.localizedCaseInsensitiveContains(query)
                || card.artist?.localizedCaseInsensitiveContains(query) == true
                || card.types.contains { $0.localizedCaseInsensitiveContains(query) }
                || card.subtypes.contains { $0.localizedCaseInsensitiveContains(query) }

            let matchesRarity = selectedRarity == nil || card.rarity == selectedRarity
            let matchesSet = selectedSet == nil || card.set == selectedSet
            let matchesType = selectedType == nil || card.cardType == selectedType
            return matchesQuery && matchesRarity && matchesSet && matchesType
        })
    }

    func availableSets(in store: LocalVaultStore) -> [CardSet] {
        let combined = apiSets + apiCards.map(\.set)
        var seen = Set<String>()
        return combined.filter { set in
            let key = set.externalID ?? set.code
            guard !seen.contains(key) else { return false }
            seen.insert(key)
            return true
        }
    }

    var isShowingFallback: Bool {
        !isLoading && didLoadAPI && apiCards.isEmpty && errorMessage != nil
    }

    private func sort(_ cards: [Card]) -> [Card] {
        switch sortOption {
        case .name:
            cards.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .rarity:
            cards.sorted {
                if $0.rarity.sortRank != $1.rarity.sortRank { return $0.rarity.sortRank > $1.rarity.sortRank }
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        case .marketValue:
            cards.sorted {
                if $0.marketValue != $1.marketValue { return $0.marketValue > $1.marketValue }
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        case .newest:
            cards.sorted {
                if $0.set.releaseYear != $1.set.releaseYear { return $0.set.releaseYear > $1.set.releaseYear }
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        }
    }
}

private extension CardRarity {
    var sortRank: Int {
        switch self {
        case .common: 0
        case .uncommon: 1
        case .rare: 2
        case .epic: 3
        case .legendary: 4
        case .mythic: 5
        }
    }
}

private extension UUID {
    static func deterministic(_ string: String) -> UUID {
        var bytes = [UInt8](repeating: 0, count: 16)
        for (index, byte) in string.utf8.enumerated() {
            bytes[index % 16] = bytes[index % 16] &* 31 &+ byte
            bytes[(index * 7) % 16] ^= byte
        }
        bytes[6] = (bytes[6] & 0x0F) | 0x50
        bytes[8] = (bytes[8] & 0x3F) | 0x80
        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }
}
