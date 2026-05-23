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

enum CardType: String, CaseIterable, Identifiable, Hashable {
    case fire
    case water
    case grass
    case electric
    case psychic
    case dragon
    case dark
    case metal
    case colorless

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fire: "Fire"
        case .water: "Water"
        case .grass: "Grass"
        case .electric: "Electric"
        case .psychic: "Psychic"
        case .dragon: "Dragon"
        case .dark: "Dark"
        case .metal: "Metal"
        case .colorless: "Colorless"
        }
    }
}

enum CardVariant: String, CaseIterable, Identifiable, Hashable {
    case normal
    case holo
    case reverseHolo
    case fullArt
    case secretRare
    case promo

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .normal: "Normal"
        case .holo: "Holo"
        case .reverseHolo: "Reverse Holo"
        case .fullArt: "Full Art"
        case .secretRare: "Secret Rare"
        case .promo: "Promo"
        }
    }
}

enum CollectionVisibility: String, CaseIterable, Identifiable, Hashable {
    case `private`
    case friends
    case `public`

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .private: "Private"
        case .friends: "Friends"
        case .public: "Public"
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
    let externalID: String?

    init(
        id: UUID = UUID(),
        name: String,
        code: String,
        releaseYear: Int,
        totalCards: Int,
        externalID: String? = nil
    ) {
        self.id = id
        self.name = name
        self.code = code
        self.releaseYear = releaseYear
        self.totalCards = totalCards
        self.externalID = externalID
    }
}

struct CardPriceInfo: Hashable {
    var low: Double?
    var mid: Double?
    var high: Double?
    var market: Double?
    var directLow: Double?
    var averageSellPrice: Double?
    var trendPrice: Double?
}

struct Card: Identifiable, Hashable {
    let id: UUID
    let name: String
    let set: CardSet
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

    init(
        id: UUID = UUID(),
        name: String,
        set: CardSet,
        number: String,
        rarity: CardRarity,
        cardType: CardType,
        typeLine: String,
        power: Int,
        condition: CardCondition,
        marketValue: Double,
        accent: CardAccent,
        externalID: String? = nil,
        types: [String] = [],
        subtypes: [String] = [],
        artist: String? = nil,
        smallImageURL: URL? = nil,
        largeImageURL: URL? = nil,
        tcgplayerPrices: CardPriceInfo? = nil,
        cardmarketPrices: CardPriceInfo? = nil
    ) {
        self.id = id
        self.name = name
        self.set = set
        self.number = number
        self.rarity = rarity
        self.cardType = cardType
        self.typeLine = typeLine
        self.power = power
        self.condition = condition
        self.marketValue = marketValue
        self.accent = accent
        self.externalID = externalID
        self.types = types
        self.subtypes = subtypes
        self.artist = artist
        self.smallImageURL = smallImageURL
        self.largeImageURL = largeImageURL
        self.tcgplayerPrices = tcgplayerPrices
        self.cardmarketPrices = cardmarketPrices
    }
}

struct CollectionItem: Identifiable, Hashable {
    let id: UUID
    let card: Card
    var quantity: Int
    var condition: CardCondition
    var variant: CardVariant
    var isAvailableForTrade: Bool
    var language: String
    var gradedCompany: String?
    var gradedScore: String?
    var visibility: CollectionVisibility
    var isAvailableForCredits: Bool
    var askingCredits: Int?
    var isFavorite: Bool
    var acquiredAt: Date
    var notes: String?
    var frontPhotoURL: URL?
    var backPhotoURL: URL?

    init(
        id: UUID = UUID(),
        card: Card,
        quantity: Int,
        condition: CardCondition? = nil,
        variant: CardVariant = .normal,
        isAvailableForTrade: Bool = false,
        language: String = "English",
        gradedCompany: String? = nil,
        gradedScore: String? = nil,
        visibility: CollectionVisibility = .private,
        isAvailableForCredits: Bool = false,
        askingCredits: Int? = nil,
        isFavorite: Bool = false,
        acquiredAt: Date = .now,
        notes: String? = nil,
        frontPhotoURL: URL? = nil,
        backPhotoURL: URL? = nil
    ) {
        self.id = id
        self.card = card
        self.quantity = quantity
        self.condition = condition ?? card.condition
        self.variant = variant
        self.isAvailableForTrade = isAvailableForTrade
        self.language = language
        self.gradedCompany = gradedCompany
        self.gradedScore = gradedScore
        self.visibility = visibility
        self.isAvailableForCredits = isAvailableForCredits
        self.askingCredits = askingCredits
        self.isFavorite = isFavorite
        self.acquiredAt = acquiredAt
        self.notes = notes
        self.frontPhotoURL = frontPhotoURL
        self.backPhotoURL = backPhotoURL
    }
}
