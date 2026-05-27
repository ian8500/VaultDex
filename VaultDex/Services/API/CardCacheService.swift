import Foundation
import UIKit

actor CardCacheService {
    static let shared = CardCacheService()

    private let fileManager = FileManager.default
    private let searchTTL: TimeInterval = 60 * 60 * 24
    private let setTTL: TimeInterval = 60 * 60 * 24 * 7
    private let popularSearches = ["Pikachu", "Charizard", "Eevee", "Mew", "Snorlax"]

    private var memoryImageCache = NSCache<NSURL, UIImage>()

    private init() {
        memoryImageCache.countLimit = 260
        memoryImageCache.totalCostLimit = 80 * 1024 * 1024
    }

    func searchCacheKey(
        query: String,
        rarity: CardRarity?,
        type: CardType?,
        setID: String?,
        sort: SearchSortOption,
        page: Int,
        pageSize: Int
    ) -> String {
        [
            normalized(query),
            rarity?.rawValue ?? "all-rarities",
            type?.rawValue ?? "all-types",
            setID ?? "all-sets",
            sort.rawValue,
            "page-\(page)",
            "size-\(pageSize)"
        ].joined(separator: "|")
    }

    func cachedSearch(for key: String) -> CachedCardSearch? {
        guard let entry: CachedCardSearchEntry = read(CachedCardSearchEntry.self, from: searchURL(for: key)) else { return nil }
        guard Date().timeIntervalSince(entry.cachedAt) < searchTTL else { return nil }
        return CachedCardSearch(cards: entry.cards.map(\.card), totalResults: entry.totalResults, cachedAt: entry.cachedAt)
    }

    func saveSearch(cards: [Card], totalResults: Int?, key: String) {
        let entry = CachedCardSearchEntry(
            cachedAt: Date(),
            totalResults: totalResults,
            cards: cards.map(CachedCard.init(card:))
        )
        write(entry, to: searchURL(for: key))
    }

    func cacheRecentlyViewed(_ card: Card) {
        var cards = recentlyViewedCards()
        cards.removeAll { $0.id == card.id }
        cards.insert(card, at: 0)
        let entry = CachedRecentlyViewedEntry(
            updatedAt: Date(),
            cards: cards.prefix(40).map(CachedCard.init(card:))
        )
        write(entry, to: recentlyViewedURL)
    }

    func recentlyViewedCards() -> [Card] {
        let entry: CachedRecentlyViewedEntry? = read(CachedRecentlyViewedEntry.self, from: recentlyViewedURL)
        return entry?.cards.map(\.card) ?? []
    }

    func popularDefaultSearches() -> [String] {
        popularSearches
    }

    func cachedSets() -> [CardSet]? {
        guard let entry: CachedCardSetsEntry = read(CachedCardSetsEntry.self, from: setsURL) else { return nil }
        guard Date().timeIntervalSince(entry.cachedAt) < setTTL else { return nil }
        return entry.sets.map(\.cardSet)
    }

    func saveSets(_ sets: [CardSet]) {
        let entry = CachedCardSetsEntry(
            cachedAt: Date(),
            sets: sets.map(CachedCardSet.init(set:))
        )
        write(entry, to: setsURL)
    }

    func image(for url: URL) -> UIImage? {
        let key = url as NSURL
        if let image = memoryImageCache.object(forKey: key) {
            return image
        }

        guard let data = try? Data(contentsOf: imageURL(for: url)),
              let image = UIImage(data: data)
        else { return nil }

        memoryImageCache.setObject(image, forKey: key, cost: data.count)
        return image
    }

    func saveImageData(_ data: Data, for url: URL) {
        guard let image = UIImage(data: data) else { return }
        memoryImageCache.setObject(image, forKey: url as NSURL, cost: data.count)
        writeData(data, to: imageURL(for: url))
    }

    private func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var cacheDirectory: URL {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appending(path: "VaultDex")
            .appending(path: "CardCache")
    }

    private var searchDirectory: URL {
        cacheDirectory.appending(path: "Searches")
    }

    private var imageDirectory: URL {
        cacheDirectory.appending(path: "Images")
    }

    private var recentlyViewedURL: URL {
        cacheDirectory.appending(path: "recently-viewed.json")
    }

    private var setsURL: URL {
        cacheDirectory.appending(path: "sets.json")
    }

    private func searchURL(for key: String) -> URL {
        searchDirectory.appending(path: "\(hashed(key)).json")
    }

    private func imageURL(for url: URL) -> URL {
        imageDirectory.appending(path: "\(hashed(url.absoluteString)).img")
    }

    private func hashed(_ value: String) -> String {
        var hash: UInt64 = 1469598103934665603
        for byte in value.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1099511628211
        }
        return String(hash, radix: 16)
    }

    private func read<T: Decodable>(_ type: T.Type, from url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder.cardCache.decode(T.self, from: data)
    }

    private func write<T: Encodable>(_ value: T, to url: URL) {
        do {
            try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try JSONEncoder.cardCache.encode(value)
            try data.write(to: url, options: [.atomic])
        } catch {
            VaultDexLogger.warning("Card cache write failed")
        }
    }

    private func writeData(_ data: Data, to url: URL) {
        do {
            try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: url, options: [.atomic])
        } catch {
            VaultDexLogger.warning("Image cache write failed")
        }
    }
}

struct CachedCardSearch {
    let cards: [Card]
    let totalResults: Int?
    let cachedAt: Date
}

private struct CachedCardSearchEntry: Codable {
    let cachedAt: Date
    let totalResults: Int?
    let cards: [CachedCard]
}

private struct CachedRecentlyViewedEntry: Codable {
    let updatedAt: Date
    let cards: [CachedCard]
}

private struct CachedCardSetsEntry: Codable {
    let cachedAt: Date
    let sets: [CachedCardSet]
}

private struct CachedCard: Codable {
    let id: UUID
    let name: String
    let set: CachedCardSet
    let number: String
    let rarity: CardRarity
    let cardType: CardType
    let typeLine: String
    let power: Int
    let condition: CardCondition
    let marketValue: Double
    let accent: CardAccent
    let externalID: String?
    let types: [String]
    let subtypes: [String]
    let artist: String?
    let smallImageURL: URL?
    let largeImageURL: URL?
    let tcgplayerPrices: CardPriceInfo?
    let cardmarketPrices: CardPriceInfo?

    init(card: Card) {
        id = card.id
        name = card.name
        set = CachedCardSet(set: card.set)
        number = card.number
        rarity = card.rarity
        cardType = card.cardType
        typeLine = card.typeLine
        power = card.power
        condition = card.condition
        marketValue = card.marketValue
        accent = card.accent
        externalID = card.externalID
        types = card.types
        subtypes = card.subtypes
        artist = card.artist
        smallImageURL = card.smallImageURL
        largeImageURL = card.largeImageURL
        tcgplayerPrices = card.tcgplayerPrices
        cardmarketPrices = card.cardmarketPrices
    }

    var card: Card {
        Card(
            id: id,
            name: name,
            set: set.cardSet,
            number: number,
            rarity: rarity,
            cardType: cardType,
            typeLine: typeLine,
            power: power,
            condition: condition,
            marketValue: marketValue,
            accent: accent,
            externalID: externalID,
            types: types,
            subtypes: subtypes,
            artist: artist,
            smallImageURL: smallImageURL,
            largeImageURL: largeImageURL,
            tcgplayerPrices: tcgplayerPrices,
            cardmarketPrices: cardmarketPrices
        )
    }
}

private struct CachedCardSet: Codable {
    let id: UUID
    let name: String
    let code: String
    let releaseYear: Int
    let totalCards: Int
    let externalID: String?

    init(set: CardSet) {
        id = set.id
        name = set.name
        code = set.code
        releaseYear = set.releaseYear
        totalCards = set.totalCards
        externalID = set.externalID
    }

    var cardSet: CardSet {
        CardSet(
            id: id,
            name: name,
            code: code,
            releaseYear: releaseYear,
            totalCards: totalCards,
            externalID: externalID
        )
    }
}

extension CardPriceInfo: Codable {
    private enum CodingKeys: String, CodingKey {
        case low
        case mid
        case high
        case market
        case directLow
        case averageSellPrice
        case trendPrice
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            low: try container.decodeIfPresent(Double.self, forKey: .low),
            mid: try container.decodeIfPresent(Double.self, forKey: .mid),
            high: try container.decodeIfPresent(Double.self, forKey: .high),
            market: try container.decodeIfPresent(Double.self, forKey: .market),
            directLow: try container.decodeIfPresent(Double.self, forKey: .directLow),
            averageSellPrice: try container.decodeIfPresent(Double.self, forKey: .averageSellPrice),
            trendPrice: try container.decodeIfPresent(Double.self, forKey: .trendPrice)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(low, forKey: .low)
        try container.encodeIfPresent(mid, forKey: .mid)
        try container.encodeIfPresent(high, forKey: .high)
        try container.encodeIfPresent(market, forKey: .market)
        try container.encodeIfPresent(directLow, forKey: .directLow)
        try container.encodeIfPresent(averageSellPrice, forKey: .averageSellPrice)
        try container.encodeIfPresent(trendPrice, forKey: .trendPrice)
    }
}
extension CardRarity: Codable {}
extension CardCondition: Codable {}
extension CardType: Codable {}
extension CardAccent: Codable {}

private extension JSONEncoder {
    static var cardCache: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    static var cardCache: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
