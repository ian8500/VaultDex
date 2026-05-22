import Foundation

struct UserProfile: Identifiable, Hashable {
    let id: UUID
    let displayName: String
    let handle: String
    let bio: String
    let avatarSymbol: String
    let collectorScore: Int
    let favoriteSet: CardSet
    let joinedDate: Date
    let followers: Int
    let following: Int

    init(
        id: UUID = UUID(),
        displayName: String,
        handle: String,
        bio: String,
        avatarSymbol: String,
        collectorScore: Int,
        favoriteSet: CardSet,
        joinedDate: Date,
        followers: Int,
        following: Int
    ) {
        self.id = id
        self.displayName = displayName
        self.handle = handle
        self.bio = bio
        self.avatarSymbol = avatarSymbol
        self.collectorScore = collectorScore
        self.favoriteSet = favoriteSet
        self.joinedDate = joinedDate
        self.followers = followers
        self.following = following
    }
}
