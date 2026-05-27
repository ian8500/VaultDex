import Foundation

protocol AuthRepository {
    func signUp(email: String, password: String) async throws -> SupabaseSession
    func signIn(email: String, password: String) async throws -> SupabaseSession
    func signOut() async throws
}

protocol ProfileRepository {
    func fetchCurrentProfile(userID: UUID) async throws -> RemoteProfile?
    func upsertProfile(_ profile: RemoteProfile) async throws
}

protocol VerificationRepository {
    func fetchCurrentRequest(userID: UUID) async throws -> RemoteVerificationRequest?
    func fetchPendingRequests() async throws -> [RemoteVerificationRequest]
    func submitRequest(_ request: RemoteVerificationRequest) async throws
    func updateRequestStatus(id: UUID, status: String, adminNote: String?) async throws
}

protocol CardCatalogRepository {
    func fetchSets() async throws -> [RemoteCardSet]
    func fetchCards(search: String?) async throws -> [RemoteCard]
    func upsertSet(_ set: RemoteCardSet) async throws
    func upsertCard(_ card: RemoteCard) async throws
}

protocol CollectionRepository {
    func fetchCollection(userID: UUID) async throws -> [RemoteCollectionItem]
    func upsertCollectionItem(_ item: RemoteCollectionItem) async throws
    func deleteCollectionItem(id: UUID) async throws
}

protocol WishlistRepository {
    func fetchWishlist(userID: UUID) async throws -> [RemoteWishlistItem]
    func upsertWishlistItem(_ item: RemoteWishlistItem) async throws
    func deleteWishlistItem(id: UUID) async throws
}

protocol FriendsRepository {
    func fetchFriends(userID: UUID) async throws -> [RemoteFriendship]
    func fetchFriendRequests(userID: UUID) async throws -> [RemoteFriendRequest]
    func searchProfiles(username: String, currentUserID: UUID) async throws -> [RemoteProfile]
    func fetchProfiles(ids: [UUID]) async throws -> [RemoteProfile]
    func fetchVisibleCollection(ownerID: UUID) async throws -> [RemoteCollectionItem]
    func fetchVisibleWishlist(userID: UUID) async throws -> [RemoteWishlistItem]
    func sendFriendRequest(from userID: UUID, to profileID: UUID) async throws
    func acceptFriendRequest(_ request: RemoteFriendRequest) async throws
    func rejectFriendRequest(id: UUID) async throws
    func removeFriendship(id: UUID) async throws
}

protocol BinderRepository {
    func fetchBinderPages(userID: UUID) async throws -> [RemoteBinderPage]
    func upsertBinderPage(_ page: RemoteBinderPage) async throws
    func deleteBinderPage(id: UUID) async throws
}

protocol TradeRepository {
    func fetchTradeListings(userID: UUID?) async throws -> [RemoteTradeListing]
    func fetchTradeOffers(userID: UUID) async throws -> [RemoteTradeOffer]
    func fetchTradeOfferItems(offerIDs: [UUID]) async throws -> [RemoteTradeOfferItem]
    func upsertTradeListing(_ listing: RemoteTradeListing) async throws
    func deleteTradeListing(id: UUID) async throws
    func upsertTradeOffer(_ offer: RemoteTradeOffer) async throws
    func upsertTradeOfferItems(_ items: [RemoteTradeOfferItem]) async throws
    func updateTradeOfferStatus(id: UUID, status: String) async throws
}

protocol MarketplaceRepository {
    func fetchMarketplaceListings(search: String?) async throws -> [RemoteMarketplaceListing]
    func saveListing(userID: UUID, listingID: UUID) async throws
    func reportListing(userID: UUID, listingID: UUID, reason: String) async throws
}

protocol EventsRepository {
    func fetchEvents(userID: UUID) async throws -> [RemoteVaultEvent]
    func upsertEvent(_ event: RemoteVaultEvent) async throws
    func deleteEvent(id: UUID) async throws
}

protocol ReputationRepository {
    func fetchReputation(profileID: UUID) async throws -> RemoteReputation?
    func upsertReputation(_ reputation: RemoteReputation) async throws
}

protocol VaultStorageRepository {
    func uploadAvatar(userID: UUID, data: Data, contentType: String) async throws -> String
    func uploadAvatarFile(userID: UUID, fileName: String, data: Data, contentType: String) async throws -> String
    func uploadCardPhoto(userID: UUID, collectionItemID: UUID, side: CardPhotoSide, data: Data, contentType: String) async throws -> String
}
