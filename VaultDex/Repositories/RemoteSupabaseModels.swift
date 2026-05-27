import Foundation

enum JSONPayloadValue: Codable, Hashable, ExpressibleByStringLiteral {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONPayloadValue])
    case array([JSONPayloadValue])
    case null

    init(stringLiteral value: String) {
        self = .string(value)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode([String: JSONPayloadValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([JSONPayloadValue].self) {
            self = .array(value)
        } else {
            self = .null
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .string(value): try container.encode(value)
        case let .number(value): try container.encode(value)
        case let .bool(value): try container.encode(value)
        case let .object(value): try container.encode(value)
        case let .array(value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }
}

struct RemoteProfile: Codable, Identifiable, Hashable {
    let id: UUID
    var username: String
    var displayName: String
    var location: String?
    var bio: String?
    var collectorType: String?
    var avatarURL: String?
    var avatarPath: String?
    var reputationScore: Int
    var trustBadges: [String]
    var completedTrades: Int
    var collectorScore: Int
    var profileVisibility: String?
    var collectionVisibility: String?
    var wishlistVisibility: String?
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case displayName = "display_name"
        case location
        case bio
        case collectorType = "collector_type"
        case avatarURL = "avatar_url"
        case avatarPath = "avatar_path"
        case reputationScore = "reputation_score"
        case trustBadges = "trust_badges"
        case completedTrades = "completed_trades"
        case collectorScore = "collector_score"
        case profileVisibility = "profile_visibility"
        case collectionVisibility = "collection_visibility"
        case wishlistVisibility = "wishlist_visibility"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(
        id: UUID,
        username: String,
        displayName: String,
        location: String?,
        bio: String?,
        collectorType: String?,
        avatarURL: String?,
        avatarPath: String?,
        reputationScore: Int,
        trustBadges: [String],
        completedTrades: Int,
        collectorScore: Int,
        profileVisibility: String?,
        collectionVisibility: String?,
        wishlistVisibility: String?,
        createdAt: Date?,
        updatedAt: Date?
    ) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.location = location
        self.bio = bio
        self.collectorType = collectorType
        self.avatarURL = avatarURL
        self.avatarPath = avatarPath
        self.reputationScore = reputationScore
        self.trustBadges = trustBadges
        self.completedTrades = completedTrades
        self.collectorScore = collectorScore
        self.profileVisibility = profileVisibility
        self.collectionVisibility = collectionVisibility
        self.wishlistVisibility = wishlistVisibility
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        username = try container.decodeIfPresent(String.self, forKey: .username) ?? ""
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName) ?? ""
        location = try container.decodeIfPresent(String.self, forKey: .location)
        bio = try container.decodeIfPresent(String.self, forKey: .bio)
        collectorType = try container.decodeIfPresent(String.self, forKey: .collectorType)
        avatarURL = try container.decodeIfPresent(String.self, forKey: .avatarURL)
        avatarPath = try container.decodeIfPresent(String.self, forKey: .avatarPath)
        reputationScore = try container.decodeIfPresent(Int.self, forKey: .reputationScore) ?? 0
        trustBadges = try container.decodeIfPresent([String].self, forKey: .trustBadges) ?? []
        completedTrades = try container.decodeIfPresent(Int.self, forKey: .completedTrades) ?? 0
        collectorScore = try container.decodeIfPresent(Int.self, forKey: .collectorScore) ?? 0
        profileVisibility = try container.decodeIfPresent(String.self, forKey: .profileVisibility)
        collectionVisibility = try container.decodeIfPresent(String.self, forKey: .collectionVisibility)
        wishlistVisibility = try container.decodeIfPresent(String.self, forKey: .wishlistVisibility)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
}

struct RemoteVerificationRequest: Codable, Identifiable, Hashable {
    let id: UUID
    var userID: UUID
    var status: String
    var fullName: String
    var dateOfBirth: String?
    var verificationNote: String?
    var submittedAt: Date?
    var reviewedAt: Date?
    var reviewedBy: UUID?
    var adminNote: String?

    enum CodingKeys: String, CodingKey {
        case id, status
        case userID = "user_id"
        case fullName = "full_name"
        case dateOfBirth = "date_of_birth"
        case verificationNote = "verification_note"
        case submittedAt = "submitted_at"
        case reviewedAt = "reviewed_at"
        case reviewedBy = "reviewed_by"
        case adminNote = "admin_note"
    }
}

struct RemoteCardSet: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var code: String
    var releaseYear: Int
    var totalCards: Int
    var source: String?
    var externalID: String?
    var series: String?
    var releaseDate: String?
    var logoURL: String?
    var symbolURL: String?
    var rawPayload: [String: JSONPayloadValue]?
    var cachedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, code, source, series
        case releaseYear = "release_year"
        case totalCards = "total_cards"
        case externalID = "external_id"
        case releaseDate = "release_date"
        case logoURL = "logo_url"
        case symbolURL = "symbol_url"
        case rawPayload = "raw_payload"
        case cachedAt = "cached_at"
    }

    init(
        id: UUID,
        name: String,
        code: String,
        releaseYear: Int,
        totalCards: Int,
        source: String? = nil,
        externalID: String? = nil,
        series: String? = nil,
        releaseDate: String? = nil,
        logoURL: String? = nil,
        symbolURL: String? = nil,
        rawPayload: [String: JSONPayloadValue]? = nil,
        cachedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.code = code
        self.releaseYear = releaseYear
        self.totalCards = totalCards
        self.source = source
        self.externalID = externalID
        self.series = series
        self.releaseDate = releaseDate
        self.logoURL = logoURL
        self.symbolURL = symbolURL
        self.rawPayload = rawPayload
        self.cachedAt = cachedAt
    }
}

struct RemoteCard: Codable, Identifiable, Hashable {
    let id: UUID
    var setID: UUID?
    var name: String
    var number: String
    var rarity: String
    var cardType: String
    var typeLine: String
    var power: Int
    var marketValue: Double
    var marketPrice: Double?
    var accent: String
    var imagePath: String?
    var artistName: String?
    var source: String?
    var externalID: String?
    var setName: String?
    var setExternalID: String?
    var types: [String]
    var subtypes: [String]
    var smallImageURL: String?
    var largeImageURL: String?
    var currency: String?
    var rawPayload: [String: JSONPayloadValue]?
    var cachedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, number, rarity, power, accent, source, types, subtypes, currency
        case setID = "set_id"
        case cardType = "card_type"
        case typeLine = "type_line"
        case marketValue = "market_value"
        case marketPrice = "market_price"
        case imagePath = "image_path"
        case artistName = "artist_name"
        case externalID = "external_id"
        case setName = "set_name"
        case setExternalID = "set_external_id"
        case smallImageURL = "small_image_url"
        case largeImageURL = "large_image_url"
        case rawPayload = "raw_payload"
        case cachedAt = "cached_at"
    }

    init(
        id: UUID,
        setID: UUID?,
        name: String,
        number: String,
        rarity: String,
        cardType: String,
        typeLine: String,
        power: Int,
        marketValue: Double,
        marketPrice: Double? = nil,
        accent: String,
        imagePath: String?,
        artistName: String?,
        source: String? = nil,
        externalID: String? = nil,
        setName: String? = nil,
        setExternalID: String? = nil,
        types: [String] = [],
        subtypes: [String] = [],
        smallImageURL: String? = nil,
        largeImageURL: String? = nil,
        currency: String? = nil,
        rawPayload: [String: JSONPayloadValue]? = nil,
        cachedAt: Date? = nil
    ) {
        self.id = id
        self.setID = setID
        self.name = name
        self.number = number
        self.rarity = rarity
        self.cardType = cardType
        self.typeLine = typeLine
        self.power = power
        self.marketValue = marketValue
        self.marketPrice = marketPrice
        self.accent = accent
        self.imagePath = imagePath
        self.artistName = artistName
        self.source = source
        self.externalID = externalID
        self.setName = setName
        self.setExternalID = setExternalID
        self.types = types
        self.subtypes = subtypes
        self.smallImageURL = smallImageURL
        self.largeImageURL = largeImageURL
        self.currency = currency
        self.rawPayload = rawPayload
        self.cachedAt = cachedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        setID = try container.decodeIfPresent(UUID.self, forKey: .setID)
        name = try container.decode(String.self, forKey: .name)
        number = try container.decodeIfPresent(String.self, forKey: .number) ?? ""
        rarity = try container.decodeIfPresent(String.self, forKey: .rarity) ?? "common"
        cardType = try container.decodeIfPresent(String.self, forKey: .cardType) ?? ""
        typeLine = try container.decodeIfPresent(String.self, forKey: .typeLine) ?? ""
        power = try container.decodeIfPresent(Int.self, forKey: .power) ?? 0
        marketValue = try container.decodeIfPresent(Double.self, forKey: .marketValue)
            ?? container.decodeIfPresent(Double.self, forKey: .marketPrice)
            ?? 0
        marketPrice = try container.decodeIfPresent(Double.self, forKey: .marketPrice) ?? marketValue
        accent = try container.decodeIfPresent(String.self, forKey: .accent) ?? "aurora"
        imagePath = try container.decodeIfPresent(String.self, forKey: .imagePath)
        artistName = try container.decodeIfPresent(String.self, forKey: .artistName)
        source = try container.decodeIfPresent(String.self, forKey: .source)
        externalID = try container.decodeIfPresent(String.self, forKey: .externalID)
        setName = try container.decodeIfPresent(String.self, forKey: .setName)
        setExternalID = try container.decodeIfPresent(String.self, forKey: .setExternalID)
        types = try container.decodeIfPresent([String].self, forKey: .types) ?? []
        subtypes = try container.decodeIfPresent([String].self, forKey: .subtypes) ?? []
        smallImageURL = try container.decodeIfPresent(String.self, forKey: .smallImageURL)
        largeImageURL = try container.decodeIfPresent(String.self, forKey: .largeImageURL)
        currency = try container.decodeIfPresent(String.self, forKey: .currency)
        rawPayload = try container.decodeIfPresent([String: JSONPayloadValue].self, forKey: .rawPayload)
        cachedAt = try container.decodeIfPresent(Date.self, forKey: .cachedAt)
    }
}

struct RemoteCollectionItem: Codable, Identifiable, Hashable {
    let id: UUID
    var ownerID: UUID
    var cardID: UUID
    var quantity: Int
    var condition: String
    var variant: String
    var language: String
    var gradedCompany: String?
    var gradedScore: String?
    var notes: String?
    var visibility: String
    var isAvailableForTrade: Bool
    var isAvailableForCredits: Bool
    var askingCredits: Int?
    var frontPhotoURL: String?
    var backPhotoURL: String?
    var isFavorite: Bool
    var acquiredAt: Date

    enum CodingKeys: String, CodingKey {
        case id, quantity, condition, variant, language, notes, visibility
        case ownerID = "owner_id"
        case cardID = "card_id"
        case gradedCompany = "graded_company"
        case gradedScore = "graded_score"
        case isAvailableForTrade = "available_for_trade"
        case isAvailableForCredits = "available_for_credits"
        case askingCredits = "asking_credits"
        case frontPhotoURL = "front_photo_url"
        case backPhotoURL = "back_photo_url"
        case isFavorite = "is_favorite"
        case acquiredAt = "acquired_at"
    }
}

struct RemoteWishlistItem: Codable, Identifiable, Hashable {
    let id: UUID
    var userID: UUID
    var cardID: UUID
    var priority: String
    var preferredCondition: String
    var budget: Double
    var notes: String
    var addedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, priority, notes
        case userID = "user_id"
        case cardID = "card_id"
        case preferredCondition = "preferred_condition"
        case budget = "max_trade_value"
        case addedAt = "added_at"
    }
}

struct RemoteFriendship: Codable, Identifiable, Hashable {
    let id: UUID
    var requesterID: UUID
    var addresseeID: UUID
    var status: String
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, status
        case requesterID = "user_a_id"
        case addresseeID = "user_b_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct RemoteFriendRequest: Codable, Identifiable, Hashable {
    let id: UUID
    var requesterID: UUID
    var addresseeID: UUID
    var message: String?
    var status: String
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, message, status
        case requesterID = "requester_id"
        case addresseeID = "addressee_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct RemoteBinderPage: Codable, Identifiable, Hashable {
    let id: UUID
    var userID: UUID
    var title: String
    var theme: String
    var visibility: String
    var slots: [RemoteBinderSlot]
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, title, theme, visibility, slots
        case userID = "user_id"
        case updatedAt = "updated_at"
    }
}

struct RemoteBinderSlot: Codable, Hashable {
    var index: Int
    var cardID: UUID?
    var note: String

    enum CodingKeys: String, CodingKey {
        case index, note
        case cardID = "card_id"
    }
}

struct RemoteTradeListing: Codable, Identifiable, Hashable {
    let id: UUID
    var ownerID: UUID
    var cardID: UUID
    var collectionItemID: UUID?
    var title: String
    var condition: String
    var variant: String
    var rarity: String
    var estimatedValue: Double
    var listingKind: String
    var askingCredits: Int?
    var description: String?
    var askingFor: String
    var sellerDisplayName: String
    var locationLabel: String?
    var sellerReputation: Int
    var isPublic: Bool
    var status: String
    var usesSafeTrade: Bool
    var listedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, title, condition, variant, rarity, status, description
        case ownerID = "owner_id"
        case cardID = "card_id"
        case collectionItemID = "collection_item_id"
        case estimatedValue = "estimated_value"
        case listingKind = "listing_kind"
        case askingCredits = "asking_credits"
        case askingFor = "asking_for"
        case sellerDisplayName = "seller_display_name"
        case locationLabel = "location_label"
        case sellerReputation = "seller_reputation"
        case isPublic = "is_public"
        case usesSafeTrade = "uses_safe_trade"
        case listedAt = "listed_at"
    }
}

struct RemoteTradeOffer: Codable, Identifiable, Hashable {
    let id: UUID
    var senderID: UUID
    var receiverID: UUID
    var offeredCardIDs: [UUID]
    var requestedCardIDs: [UUID]
    var internalCredits: Int
    var message: String
    var status: String
    var usesSafeTrade: Bool
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, message, status
        case senderID = "sender_id"
        case receiverID = "receiver_id"
        case offeredCardIDs = "offered_card_ids"
        case requestedCardIDs = "requested_card_ids"
        case internalCredits = "internal_credits"
        case usesSafeTrade = "uses_safe_trade"
        case createdAt = "created_at"
    }
}

struct RemoteTradeOfferItem: Codable, Identifiable, Hashable {
    let id: UUID
    var tradeOfferID: UUID
    var ownerID: UUID?
    var cardID: UUID
    var collectionItemID: UUID?
    var side: String
    var quantity: Int
    var estimatedValue: Double
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, side, quantity
        case tradeOfferID = "trade_offer_id"
        case ownerID = "owner_id"
        case cardID = "card_id"
        case collectionItemID = "collection_item_id"
        case estimatedValue = "estimated_value"
        case createdAt = "created_at"
    }
}

struct RemoteMarketplaceListing: Codable, Identifiable, Hashable {
    let id: UUID
    var cardID: UUID
    var ownerID: UUID?
    var collectionItemID: UUID?
    var title: String?
    var rarity: String
    var condition: String
    var variant: String?
    var listingKind: String?
    var askingCredits: Int?
    var description: String?
    var askingFor: String?
    var estimatedValue: Double
    var sellerDisplayName: String?
    var sellerReputation: Int
    var isSaved: Bool?
    var usesSafeTrade: Bool?
    var locationLabel: String?
    var listedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, rarity, condition, variant, description
        case cardID = "card_id"
        case ownerID = "owner_id"
        case collectionItemID = "collection_item_id"
        case title
        case listingKind = "listing_kind"
        case askingCredits = "asking_credits"
        case askingFor = "asking_for"
        case estimatedValue = "estimated_value"
        case sellerDisplayName = "seller_display_name"
        case sellerReputation = "seller_reputation"
        case isSaved = "is_saved"
        case usesSafeTrade = "uses_safe_trade"
        case locationLabel = "location_label"
        case listedAt = "listed_at"
    }
}

struct RemoteVaultEvent: Codable, Identifiable, Hashable {
    let id: UUID
    var userID: UUID?
    var title: String
    var eventDate: Date
    var emojiMarker: String
    var location: String
    var notes: String
    var visibility: String

    enum CodingKeys: String, CodingKey {
        case id, title, location, notes, visibility
        case userID = "owner_id"
        case eventDate = "event_date"
        case emojiMarker = "emoji_marker"
    }
}

struct RemoteReputation: Codable, Identifiable, Hashable {
    let id: UUID
    var profileID: UUID
    var score: Int
    var completedTrades: Int
    var disputesOpened: Int
    var reportsReceived: Int
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, score
        case profileID = "profile_id"
        case completedTrades = "completed_trades"
        case disputesOpened = "disputes_opened"
        case reportsReceived = "reports_received"
        case updatedAt = "updated_at"
    }
}
