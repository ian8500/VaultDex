import Foundation

struct UserProfile: Identifiable, Hashable {
    let id: UUID
    var displayName: String
    var handle: String
    var location: String
    var bio: String
    var collectorType: String
    var avatarSymbol: String
    var avatarURL: URL?
    var reputationScore: Int
    var trustBadges: [String]
    var completedTrades: Int
    var collectorScore: Int
    let favoriteSet: CardSet
    let joinedDate: Date
    var followers: Int
    var following: Int

    init(
        id: UUID = UUID(),
        displayName: String,
        handle: String,
        location: String = "London, UK",
        bio: String,
        collectorType: String = "Premium Collector",
        avatarSymbol: String,
        avatarURL: URL? = nil,
        reputationScore: Int = 98,
        trustBadges: [String] = ["Verified Collector", "Safe Trader"],
        completedTrades: Int = 24,
        collectorScore: Int,
        favoriteSet: CardSet,
        joinedDate: Date,
        followers: Int,
        following: Int
    ) {
        self.id = id
        self.displayName = displayName
        self.handle = handle
        self.location = location
        self.bio = bio
        self.collectorType = collectorType
        self.avatarSymbol = avatarSymbol
        self.avatarURL = avatarURL
        self.reputationScore = reputationScore
        self.trustBadges = trustBadges
        self.completedTrades = completedTrades
        self.collectorScore = collectorScore
        self.favoriteSet = favoriteSet
        self.joinedDate = joinedDate
        self.followers = followers
        self.following = following
    }
}
