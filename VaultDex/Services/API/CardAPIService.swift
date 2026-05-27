import Foundation

final class CardAPIService {
    private let baseURL: URL
    private let apiKey: String?
    private let urlSession: URLSession
    private let listCardSelectFields = "id,name,set,number,rarity,types,images"
    private let fullCardSelectFields = "id,name,set,number,rarity,types,subtypes,artist,images,tcgplayer,cardmarket,legalities"

    init(
        baseURL: URL = URL(string: "https://api.pokemontcg.io/v2")!,
        apiKey: String? = PokemonTCGConfig.apiKey,
        urlSession: URLSession = CardAPIService.defaultSession
    ) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.urlSession = urlSession
    }

    private static let defaultSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = true
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 15
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: configuration)
    }()

    func searchCards(query: String) async throws -> [PokemonTCGCard] {
        try await searchCards(query: query, page: 1, pageSize: 8).data
    }

    func searchCardsForScan(name: String, pageSize: Int = 5) async throws -> PokemonTCGListResponse<PokemonTCGCard> {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { throw CardAPIError.invalidURL }

        return try await request("cards", queryItems: [
            URLQueryItem(name: "q", value: "name:\"\(apiEscaped(trimmedName))\""),
            URLQueryItem(name: "page", value: "1"),
            URLQueryItem(name: "pageSize", value: "\(pageSize)"),
            URLQueryItem(name: "select", value: listCardSelectFields)
        ], decode: PokemonTCGListResponse<PokemonTCGCard>.self)
    }

    func searchCards(
        query: String,
        rarity: CardRarity? = nil,
        type: CardType? = nil,
        setID: String? = nil,
        sort: SearchSortOption = .name,
        page: Int,
        pageSize: Int
    ) async throws -> PokemonTCGListResponse<PokemonTCGCard> {
        try await searchCardsResponse(
            query: query,
            rarity: rarity,
            type: type,
            setID: setID,
            sort: sort,
            page: page,
            pageSize: pageSize
        )
    }

    private func searchCardsResponse(
        query: String,
        rarity: CardRarity?,
        type: CardType?,
        setID: String?,
        sort: SearchSortOption,
        page: Int,
        pageSize: Int
    ) async throws -> PokemonTCGListResponse<PokemonTCGCard> {
        var queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "pageSize", value: "\(pageSize)"),
            URLQueryItem(name: "select", value: listCardSelectFields)
        ]

        let filterParts = buildFilterParts(rarity: rarity, type: type, setID: setID)
        let textQuery = buildTextQuery(query: query)

        if let textQuery {
            queryItems.append(URLQueryItem(name: "q", value: ([textQuery] + filterParts).joined(separator: " ")))
        } else if !filterParts.isEmpty {
            queryItems.append(URLQueryItem(name: "q", value: filterParts.joined(separator: " ")))
        } else {
            queryItems.append(URLQueryItem(name: "q", value: "name:pikachu"))
        }

        if sort != .newest {
            queryItems.append(URLQueryItem(name: "orderBy", value: sort.apiOrderBy))
        }
        return try await request("cards", queryItems: queryItems, decode: PokemonTCGListResponse<PokemonTCGCard>.self)
    }

    private func buildFilterParts(
        rarity: CardRarity?,
        type: CardType?,
        setID: String?
    ) -> [String] {
        var parts: [String] = []

        if let rarityQuery = rarity?.apiQuery {
            parts.append(rarityQuery)
        }

        if let typeQuery = type?.apiQuery {
            parts.append(typeQuery)
        }

        if let setID, !setID.isEmpty {
            parts.append("set.id:\(setID)")
        }

        return parts
    }

    private func buildTextQuery(query: String) -> String? {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return nil }

        let escaped = apiEscaped(trimmedQuery)
        let textToken = trimmedQuery.contains(" ") ? "\"\(escaped)\"" : "*\(escaped)*"
        let exactToken = trimmedQuery.contains(" ") ? "\"\(escaped)\"" : escaped
        var clauses = [
            "name:\(textToken)",
            "set.name:\(textToken)",
            "rarity:\(textToken)",
            "types:\(exactToken)",
            "subtypes:\(textToken)"
        ]

        if trimmedQuery.rangeOfCharacter(from: .decimalDigits) != nil {
            clauses.insert("number:\(escaped)", at: 2)
        }

        return "(\(clauses.joined(separator: " OR ")))"
    }

    private func apiEscaped(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: ":", with: "\\:")
    }

    func fetchCard(id: String) async throws -> PokemonTCGCard {
        try await request("cards/\(id)", queryItems: [
            URLQueryItem(name: "select", value: fullCardSelectFields)
        ], decode: PokemonTCGSingleResponse<PokemonTCGCard>.self).data
    }

    func fetchSets() async throws -> [PokemonTCGSet] {
        try await request("sets", queryItems: [
            URLQueryItem(name: "page", value: "1"),
            URLQueryItem(name: "pageSize", value: "30")
        ], decode: PokemonTCGListResponse<PokemonTCGSet>.self).data
    }

    func fetchCardsForSet(setID: String) async throws -> [PokemonTCGCard] {
        try await request("cards", queryItems: [
            URLQueryItem(name: "q", value: "set.id:\(setID)"),
            URLQueryItem(name: "pageSize", value: "100"),
            URLQueryItem(name: "select", value: listCardSelectFields)
        ], decode: PokemonTCGListResponse<PokemonTCGCard>.self).data
    }

    func cache(cards: [PokemonTCGCard], using clientProvider: SupabaseClientProvider) async {
        guard !cards.isEmpty, clientProvider.isRemoteEnabled else { return }

        do {
            let setPayloads = Array(
                Dictionary(grouping: cards.map(\.cacheSetPayload), by: \.code)
                    .compactMap { $0.value.first }
            )
            let setData = try JSONEncoder.supabase.encode(setPayloads)
            let setRequest = try clientProvider.restRequest(
                table: "card_sets",
                method: .post,
                queryItems: [URLQueryItem(name: "on_conflict", value: "source,external_id")],
                body: setData,
                prefer: "resolution=merge-duplicates"
            )
            try await clientProvider.send(setRequest)

            let cardPayloads = cards.map(\.cacheCardPayload)
            let cardData = try JSONEncoder.supabase.encode(cardPayloads)
            let cardRequest = try clientProvider.restRequest(
                table: "cards",
                method: .post,
                queryItems: [URLQueryItem(name: "on_conflict", value: "source,external_id")],
                body: cardData,
                prefer: "resolution=merge-duplicates"
            )
            try await clientProvider.send(cardRequest)
        } catch {
            return
        }
    }

    private func request<T: Decodable>(
        _ path: String,
        queryItems: [URLQueryItem] = [],
        decode type: T.Type
    ) async throws -> T {
        var components = URLComponents(url: baseURL.appending(path: path), resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems.isEmpty ? nil : queryItems
        guard let url = components?.url else { throw CardAPIError.invalidURL }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("VaultDex/1.0", forHTTPHeaderField: "User-Agent")
        if let apiKey, !apiKey.isEmpty {
            request.setValue(apiKey, forHTTPHeaderField: "X-Api-Key")
        }

        var lastError: Error?
        for attempt in 0..<2 {
            do {
                let (data, response) = try await urlSession.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse else { throw CardAPIError.invalidResponse }
                guard 200..<300 ~= httpResponse.statusCode else {
                    throw CardAPIError.requestFailed(httpResponse.statusCode, String(data: data, encoding: .utf8) ?? "")
                }
                return try JSONDecoder.pokemonTCG.decode(T.self, from: data)
            } catch {
                lastError = error
                guard attempt < 1, Self.isTransient(error) else { break }
                try? await Task.sleep(nanoseconds: UInt64(350_000_000 * (attempt + 1)))
            }
        }
        throw lastError ?? CardAPIError.invalidResponse
    }

    private static func isTransient(_ error: Error) -> Bool {
        let nsError = error as NSError
        guard nsError.domain == NSURLErrorDomain else { return false }
        return [
            NSURLErrorTimedOut,
            NSURLErrorNetworkConnectionLost
        ].contains(nsError.code)
    }
}

enum CardAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case requestFailed(Int, String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "The card API URL could not be built."
        case .invalidResponse:
            "The card API returned an invalid response."
        case let .requestFailed(statusCode, body):
            "The card API request failed with status \(statusCode): \(body)"
        }
    }
}

struct PokemonTCGListResponse<T: Decodable>: Decodable {
    let data: [T]
    let page: Int?
    let pageSize: Int?
    let count: Int?
    let totalCount: Int?
}

struct PokemonTCGSingleResponse<T: Decodable>: Decodable {
    let data: T
}

struct PokemonTCGSet: Decodable, Hashable {
    let id: String
    let name: String
    let series: String?
    let printedTotal: Int?
    let total: Int?
    let releaseDate: String?
}

struct PokemonTCGCard: Decodable, Hashable {
    let id: String
    let name: String
    let set: PokemonTCGSet
    let number: String
    let rarity: String?
    let types: [String]?
    let subtypes: [String]?
    let artist: String?
    let images: PokemonTCGImages?
    let tcgplayer: PokemonTCGPlayer?
    let cardmarket: PokemonCardmarket?
}

struct PokemonTCGImages: Decodable, Hashable {
    let small: URL?
    let large: URL?
}

struct PokemonTCGPlayer: Decodable, Hashable {
    let prices: [String: PokemonTCGPrice]?

    var preferredPrice: Double? {
        prices?["holofoil"]?.market
            ?? prices?["reverseHolofoil"]?.market
            ?? prices?["normal"]?.market
            ?? prices?["1stEditionHolofoil"]?.market
            ?? prices?["1stEditionNormal"]?.market
    }
}

struct PokemonTCGPrice: Decodable, Hashable {
    let low: Double?
    let mid: Double?
    let high: Double?
    let market: Double?
    let directLow: Double?
}

struct PokemonCardmarket: Decodable, Hashable {
    let prices: PokemonCardmarketPrices?
}

struct PokemonCardmarketPrices: Decodable, Hashable {
    let averageSellPrice: Double?
    let lowPrice: Double?
    let trendPrice: Double?
    let avg1: Double?

    var preferredPrice: Double? {
        averageSellPrice ?? trendPrice ?? avg1
    }
}

private extension PokemonTCGCard {
    var cacheSetPayload: RemoteCardSet {
        RemoteCardSet(
            id: .deterministic("pokemon-tcg-set-\(set.id)"),
            name: set.name,
            code: set.id,
            releaseYear: set.releaseYear,
            totalCards: set.total ?? set.printedTotal ?? 0,
            source: "pokemon_tcg",
            externalID: set.id,
            series: set.series,
            releaseDate: set.releaseDate
        )
    }

    var cacheCardPayload: RemoteCard {
        let local = localCard
        return RemoteCard(
            id: local.id,
            setID: local.set.id,
            name: local.name,
            number: local.number,
            rarity: local.rarity.rawValue,
            cardType: local.cardType.rawValue,
            typeLine: local.typeLine,
            power: local.power,
            marketValue: local.marketValue,
            marketPrice: local.marketValue,
            accent: local.accent.rawValue,
            imagePath: local.smallImageURL?.absoluteString,
            artistName: local.artist,
            source: "pokemon_tcg",
            externalID: id,
            setName: set.name,
            setExternalID: set.id,
            types: types ?? [],
            subtypes: subtypes ?? [],
            smallImageURL: images?.small?.absoluteString,
            largeImageURL: images?.large?.absoluteString,
            currency: "GBP"
        )
    }
}

extension PokemonTCGCard {
    var localCard: Card {
        let mappedType = CardType(apiTypes: types)
        let mappedRarity = CardRarity(apiRarity: rarity)
        let value = PriceService.estimatedGBP(cardmarket: cardmarket, tcgplayer: tcgplayer) ?? 0
        let setModel = CardSet(
            id: .deterministic("pokemon-tcg-set-\(set.id)"),
            name: set.name,
            code: set.id,
            releaseYear: set.releaseYear,
            totalCards: set.total ?? set.printedTotal ?? 0,
            externalID: set.id
        )

        return Card(
            id: .deterministic("pokemon-tcg-card-\(id)"),
            name: name,
            set: setModel,
            number: number,
            rarity: mappedRarity,
            cardType: mappedType,
            typeLine: (subtypes ?? []).joined(separator: ", "),
            power: Int(value.rounded()),
            condition: .nearMint,
            marketValue: value,
            accent: mappedType.defaultAccent,
            externalID: id,
            types: types ?? [],
            subtypes: subtypes ?? [],
            artist: artist,
            smallImageURL: images?.small,
            largeImageURL: images?.large,
            tcgplayerPrices: tcgplayer?.prices?.values.first?.localPriceInfo(sourceCurrency: .usd),
            cardmarketPrices: cardmarket?.prices?.localPriceInfo(sourceCurrency: .eur)
        )
    }
}

private extension PokemonTCGPrice {
    func localPriceInfo(sourceCurrency: MarketCurrency) -> CardPriceInfo {
        CardPriceInfo(
            low: low.map { PriceFormatter.displayAmount($0, sourceCurrency: sourceCurrency) },
            mid: mid.map { PriceFormatter.displayAmount($0, sourceCurrency: sourceCurrency) },
            high: high.map { PriceFormatter.displayAmount($0, sourceCurrency: sourceCurrency) },
            market: market.map { PriceFormatter.displayAmount($0, sourceCurrency: sourceCurrency) },
            directLow: directLow.map { PriceFormatter.displayAmount($0, sourceCurrency: sourceCurrency) }
        )
    }
}

private extension PokemonCardmarketPrices {
    func localPriceInfo(sourceCurrency: MarketCurrency) -> CardPriceInfo {
        CardPriceInfo(
            low: lowPrice.map { PriceFormatter.displayAmount($0, sourceCurrency: sourceCurrency) },
            averageSellPrice: averageSellPrice.map { PriceFormatter.displayAmount($0, sourceCurrency: sourceCurrency) },
            trendPrice: trendPrice.map { PriceFormatter.displayAmount($0, sourceCurrency: sourceCurrency) }
        )
    }
}

extension PokemonTCGSet {
    var releaseYear: Int {
        guard let releaseDate, let year = Int(releaseDate.prefix(4)) else { return 0 }
        return year
    }
}

extension CardType {
    init(apiTypes: [String]?) {
        let rawType = apiTypes?.first?.lowercased()
        switch rawType {
        case "fire": self = .fire
        case "water": self = .water
        case "grass": self = .grass
        case "lightning": self = .electric
        case "psychic": self = .psychic
        case "dragon": self = .dragon
        case "darkness": self = .dark
        case "metal": self = .metal
        default: self = .colorless
        }
    }

    var apiQuery: String {
        switch self {
        case .fire: "types:Fire"
        case .water: "types:Water"
        case .grass: "types:Grass"
        case .electric: "types:Lightning"
        case .psychic: "types:Psychic"
        case .dragon: "types:Dragon"
        case .dark: "types:Darkness"
        case .metal: "types:Metal"
        case .colorless: "types:Colorless"
        }
    }

    var defaultAccent: CardAccent {
        switch self {
        case .fire: .ember
        case .water: .frost
        case .grass: .venom
        case .electric: .solar
        case .psychic, .dark, .dragon: .void
        case .metal, .colorless: .aurora
        }
    }
}

extension CardRarity {
    init(apiRarity: String?) {
        let value = apiRarity?.lowercased() ?? ""
        if value.contains("secret") || value.contains("rainbow") {
            self = .mythic
        } else if value.contains("rare") && (value.contains("holo") || value.contains("ultra") || value.contains("illustration")) {
            self = .legendary
        } else if value.contains("rare") {
            self = .rare
        } else if value.contains("uncommon") {
            self = .uncommon
        } else {
            self = .common
        }
    }

    var apiQuery: String? {
        switch self {
        case .common: "rarity:Common"
        case .uncommon: "rarity:Uncommon"
        case .rare: "rarity:Rare"
        case .epic: "rarity:\"Double Rare\""
        case .legendary: "rarity:\"Rare Holo\""
        case .mythic: "rarity:\"Rare Secret\""
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

private extension JSONDecoder {
    static var pokemonTCG: JSONDecoder {
        let decoder = JSONDecoder()
        return decoder
    }
}
