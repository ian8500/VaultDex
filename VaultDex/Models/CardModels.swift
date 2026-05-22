import Foundation

enum CardRarity: String, CaseIterable, Identifiable, Hashable {
    case common
    case uncommon
    case rare
    case epic
    case legendary
    case mythic

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .common: "Common"
        case .uncommon: "Uncommon"
        case .rare: "Rare"
        case .epic: "Epic"
        case .legendary: "Legendary"
        case .mythic: "Mythic"
        }
    }
}

enum CardCondition: String, CaseIterable, Identifiable, Hashable {
    case mint
    case nearMint
    case excellent
    case played

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mint: "Mint"
        case .nearMint: "Near Mint"
        case .excellent: "Excellent"
        case .played: "Played"
        }
    }
}

enum CardAccent: String, CaseIterable, Identifiable, Hashable {
    case aurora
    case ember
    case frost
    case solar
    case venom
    case void

    var id: String { rawValue }
}

struct CardSet: Identifiable, Hashable {
    let id: UUID
    let name: String
    let code: String
    let releaseYear: Int
    let totalCards: Int

    init(
        id: UUID = UUID(),
        name: String,
        code: String,
        releaseYear: Int,
        totalCards: Int
    ) {
        self.id = id
        self.name = name
        self.code = code
        self.releaseYear = releaseYear
        self.totalCards = totalCards
    }
}

struct Card: Identifiable, Hashable {
    let id: UUID
    let name: String
    let set: CardSet
    let rarity: CardRarity
    let typeLine: String
    let power: Int
    let condition: CardCondition
    let marketValue: Double
    let accent: CardAccent

    init(
        id: UUID = UUID(),
        name: String,
        set: CardSet,
        rarity: CardRarity,
        typeLine: String,
        power: Int,
        condition: CardCondition,
        marketValue: Double,
        accent: CardAccent
    ) {
        self.id = id
        self.name = name
        self.set = set
        self.rarity = rarity
        self.typeLine = typeLine
        self.power = power
        self.condition = condition
        self.marketValue = marketValue
        self.accent = accent
    }
}

struct CollectionItem: Identifiable, Hashable {
    let id: UUID
    let card: Card
    var quantity: Int
    var isFavorite: Bool
    var acquiredAt: Date
    var notes: String?

    init(
        id: UUID = UUID(),
        card: Card,
        quantity: Int,
        isFavorite: Bool = false,
        acquiredAt: Date = .now,
        notes: String? = nil
    ) {
        self.id = id
        self.card = card
        self.quantity = quantity
        self.isFavorite = isFavorite
        self.acquiredAt = acquiredAt
        self.notes = notes
    }
}
