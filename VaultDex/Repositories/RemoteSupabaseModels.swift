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
    var artistName: String?

    enum CodingKeys: String, CodingKey {
        case id, name, number, rarity, power, accent
        case setID = "set_id"
        case cardType = "card_type"
        case typeLine = "type_line"
        case marketValue = "market_value"
        case imagePath = "image_path"
        case artistName = "artist_name"
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
    var askingFor: String?
    var estimatedValue: Double
    var sellerDisplayName: String?
    var sellerReputation: Int
    var isSaved: Bool?
    var usesSafeTrade: Bool?
    var locationLabel: String?
    var listedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, rarity, condition, variant
        case cardID = "card_id"
        case ownerID = "owner_id"
        case collectionItemID = "collection_item_id"
        case title
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
