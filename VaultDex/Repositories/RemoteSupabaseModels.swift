import Foundation

struct RemoteProfile: Codable, Identifiable, Hashable {
    let id: UUID
    var username: String
    var displayName: String
    var location: String?
    var bio: String?
    var collectorType: String?
    var avatarPath: String?
    var reputationScore: Int
    var trustBadges: [String]
    var completedTrades: Int
    var collectorScore: Int
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case displayName = "display_name"
        case location
        case bio
        case collectorType = "collector_type"
        case avatarPath = "avatar_path"
        case reputationScore = "reputation_score"
        case trustBadges = "trust_badges"
        case completedTrades = "completed_trades"
        case collectorScore = "collector_score"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct RemoteCardSet: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var code: String
    var releaseYear: Int
    var totalCards: Int

    enum CodingKeys: String, CodingKey {
        case id, name, code
        case releaseYear = "release_year"
        case totalCards = "total_cards"
    }
}

struct RemoteCard: Codable, Identifiable, Hashable {
    let id: UUID
    var setID: UUID
    var name: String
    var number: String
    var rarity: String
    var cardType: String
    var typeLine: String
    var power: Int
    var marketValue: Double
    var accent: String
    var imagePath: String?

    enum CodingKeys: String, CodingKey {
        case id, name, number, rarity, power, accent
        case setID = "set_id"
        case cardType = "card_type"
        case typeLine = "type_line"
        case marketValue = "market_value"
        case imagePath = "image_path"
    }
}

struct RemoteCollectionItem: Codable, Identifiable, Hashable {
    let id: UUID
    var userID: UUID
    var cardID: UUID
    var quantity: Int
    var condition: String
    var variant: String
    var isAvailableForTrade: Bool
    var isFavorite: Bool
    var acquiredAt: Date
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case id, quantity, condition, variant, notes
        case userID = "user_id"
        case cardID = "card_id"
        case isAvailableForTrade = "is_available_for_trade"
        case isFavorite = "is_favorite"
        case acquiredAt = "acquired_at"
    }
}

struct RemoteWishlistItem: Codable, Identifiable, Hashable {
    let id: UUID
    var userID: UUID
    var cardID: UUID
    var priority: String
    var budget: Double
    var notes: String
    var addedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, priority, budget, notes
        case userID = "user_id"
        case cardID = "card_id"
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
    var userID: UUID
    var cardID: UUID
    var condition: String
    var variant: String
    var askingFor: String
    var locationLabel: String?
    var sellerReputation: Int
    var isPublic: Bool
    var usesSafeTrade: Bool
    var listedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, condition, variant
        case userID = "user_id"
        case cardID = "card_id"
        case askingFor = "asking_for"
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

struct RemoteMarketplaceListing: Codable, Identifiable, Hashable {
    let id: UUID
    var tradeListingID: UUID
    var cardID: UUID
    var ownerID: UUID
    var rarity: String
    var condition: String
    var estimatedValue: Double
    var sellerReputation: Int
    var isSaved: Bool?

    enum CodingKeys: String, CodingKey {
        case id, rarity, condition
        case tradeListingID = "trade_listing_id"
        case cardID = "card_id"
        case ownerID = "owner_id"
        case estimatedValue = "estimated_value"
        case sellerReputation = "seller_reputation"
        case isSaved = "is_saved"
    }
}

struct RemoteVaultEvent: Codable, Identifiable, Hashable {
    let id: UUID
    var userID: UUID
    var title: String
    var eventDate: Date
    var emojiMarker: String
    var location: String
    var notes: String
    var visibility: String

    enum CodingKeys: String, CodingKey {
        case id, title, location, notes, visibility
        case userID = "user_id"
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

