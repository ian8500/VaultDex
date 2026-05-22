import Foundation

class SupabaseTableRepository {
    let client: SupabaseClientProvider

    init(client: SupabaseClientProvider) {
        self.client = client
    }

    func fetchRows<T: Decodable>(from table: String, queryItems: [URLQueryItem] = []) async throws -> [T] {
        let request = try client.restRequest(table: table, queryItems: queryItems)
        return try await client.send(request, decode: [T].self)
    }

    func upsert<T: Encodable>(_ value: T, into table: String) async throws {
        let data = try JSONEncoder.supabase.encode(value)
        let request = try client.restRequest(
            table: table,
            method: .post,
            body: data,
            prefer: "resolution=merge-duplicates"
        )
        try await client.send(request)
    }

    func patch(_ fields: [String: String], table: String, id: UUID) async throws {
        let data = try JSONSerialization.data(withJSONObject: fields)
        let request = try client.restRequest(
            table: table,
            method: .patch,
            queryItems: [URLQueryItem(name: "id", value: "eq.\(id.uuidString)")],
            body: data
        )
        try await client.send(request)
    }

    func delete(from table: String, id: UUID) async throws {
        let request = try client.restRequest(
            table: table,
            method: .delete,
            queryItems: [URLQueryItem(name: "id", value: "eq.\(id.uuidString)")],
            prefer: "return=minimal"
        )
        try await client.send(request)
    }
}

final class SupabaseAuthRepository: AuthRepository {
    private let client: SupabaseClientProvider

    init(client: SupabaseClientProvider) {
        self.client = client
    }

    func signUp(email: String, password: String) async throws -> SupabaseSession {
        let payload = AuthPayload(email: email, password: password)
        let request = try client.authRequest(path: "signup", body: JSONEncoder.supabase.encode(payload))
        let response = try await client.send(request, decode: AuthResponse.self)
        let session = try response.session()
        client.updateSession(session)
        return session
    }

    func signIn(email: String, password: String) async throws -> SupabaseSession {
        let payload = AuthPayload(email: email, password: password)
        let request = try client.authRequest(
            path: "token",
            body: JSONEncoder.supabase.encode(payload),
            queryItems: [URLQueryItem(name: "grant_type", value: "password")]
        )
        let response = try await client.send(request, decode: AuthResponse.self)
        let session = try response.session()
        client.updateSession(session)
        return session
    }

    func signOut() async throws {
        let request = try client.authRequest(path: "logout")
        try await client.send(request)
        client.updateSession(nil)
    }

    private struct AuthPayload: Codable {
        let email: String
        let password: String
    }

    private struct AuthResponse: Codable {
        let accessToken: String?
        let refreshToken: String?
        let expiresIn: Int?
        let user: AuthUser?

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case expiresIn = "expires_in"
            case user
        }

        func session() throws -> SupabaseSession {
            guard let accessToken, let userID = user?.id else {
                throw SupabaseClientError.invalidResponse
            }
            return SupabaseSession(
                accessToken: accessToken,
                refreshToken: refreshToken,
                userID: userID,
                email: user?.email,
                expiresAt: expiresIn.map { Date().addingTimeInterval(TimeInterval($0)) }
            )
        }
    }

    private struct AuthUser: Codable {
        let id: UUID
        let email: String?
    }
}

final class SupabaseProfileRepository: SupabaseTableRepository, ProfileRepository {
    func fetchCurrentProfile(userID: UUID) async throws -> RemoteProfile? {
        try await fetchRows(from: "profiles", queryItems: [
            URLQueryItem(name: "id", value: "eq.\(userID.uuidString)"),
            URLQueryItem(name: "limit", value: "1")
        ]).first
    }

    func upsertProfile(_ profile: RemoteProfile) async throws {
        try await upsert(profile, into: "profiles")
    }
}

final class SupabaseCardCatalogRepository: SupabaseTableRepository, CardCatalogRepository {
    func fetchSets() async throws -> [RemoteCardSet] {
        try await fetchRows(from: "card_sets", queryItems: [URLQueryItem(name: "order", value: "release_year.desc")])
    }

    func fetchCards(search: String?) async throws -> [RemoteCard] {
        var queryItems = [URLQueryItem(name: "order", value: "name.asc")]
        if let search, !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            queryItems.append(URLQueryItem(name: "name", value: "ilike.*\(search)*"))
        }
        return try await fetchRows(from: "cards", queryItems: queryItems)
    }
}

final class SupabaseCollectionRepository: SupabaseTableRepository, CollectionRepository {
    func fetchCollection(userID: UUID) async throws -> [RemoteCollectionItem] {
        try await fetchRows(from: "collection_items", queryItems: [
            URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString)"),
            URLQueryItem(name: "order", value: "acquired_at.desc")
        ])
    }

    func upsertCollectionItem(_ item: RemoteCollectionItem) async throws {
        try await upsert(item, into: "collection_items")
    }

    func deleteCollectionItem(id: UUID) async throws {
        try await delete(from: "collection_items", id: id)
    }
}

final class SupabaseWishlistRepository: SupabaseTableRepository, WishlistRepository {
    func fetchWishlist(userID: UUID) async throws -> [RemoteWishlistItem] {
        try await fetchRows(from: "wishlist_items", queryItems: [
            URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString)"),
            URLQueryItem(name: "order", value: "added_at.desc")
        ])
    }

    func upsertWishlistItem(_ item: RemoteWishlistItem) async throws {
        try await upsert(item, into: "wishlist_items")
    }

    func deleteWishlistItem(id: UUID) async throws {
        try await delete(from: "wishlist_items", id: id)
    }
}

final class SupabaseFriendsRepository: SupabaseTableRepository, FriendsRepository {
    func fetchFriends(userID: UUID) async throws -> [RemoteFriendship] {
        try await fetchRows(from: "friendships", queryItems: [
            URLQueryItem(name: "or", value: "(requester_id.eq.\(userID.uuidString),addressee_id.eq.\(userID.uuidString))"),
            URLQueryItem(name: "order", value: "updated_at.desc")
        ])
    }

    func sendFriendRequest(from userID: UUID, to profileID: UUID) async throws {
        let friendship = RemoteFriendship(id: UUID(), requesterID: userID, addresseeID: profileID, status: "pending", createdAt: nil, updatedAt: nil)
        try await upsert(friendship, into: "friendships")
    }

    func updateFriendship(id: UUID, status: String) async throws {
        try await patch(["status": status], table: "friendships", id: id)
    }
}

final class SupabaseBinderRepository: SupabaseTableRepository, BinderRepository {
    func fetchBinderPages(userID: UUID) async throws -> [RemoteBinderPage] {
        try await fetchRows(from: "binder_pages", queryItems: [
            URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString)"),
            URLQueryItem(name: "order", value: "updated_at.desc")
        ])
    }

    func upsertBinderPage(_ page: RemoteBinderPage) async throws {
        try await upsert(page, into: "binder_pages")
    }

    func deleteBinderPage(id: UUID) async throws {
        try await delete(from: "binder_pages", id: id)
    }
}

final class SupabaseTradeRepository: SupabaseTableRepository, TradeRepository {
    func fetchTradeListings(userID: UUID?) async throws -> [RemoteTradeListing] {
        var queryItems = [URLQueryItem(name: "order", value: "listed_at.desc")]
        if let userID {
            queryItems.append(URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString)"))
        }
        return try await fetchRows(from: "trade_listings", queryItems: queryItems)
    }

    func fetchTradeOffers(userID: UUID) async throws -> [RemoteTradeOffer] {
        try await fetchRows(from: "trade_offers", queryItems: [
            URLQueryItem(name: "or", value: "(sender_id.eq.\(userID.uuidString),receiver_id.eq.\(userID.uuidString))"),
            URLQueryItem(name: "order", value: "created_at.desc")
        ])
    }

    func upsertTradeListing(_ listing: RemoteTradeListing) async throws {
        try await upsert(listing, into: "trade_listings")
    }

    func upsertTradeOffer(_ offer: RemoteTradeOffer) async throws {
        try await upsert(offer, into: "trade_offers")
    }

    func updateTradeOfferStatus(id: UUID, status: String) async throws {
        try await patch(["status": status], table: "trade_offers", id: id)
    }
}

final class SupabaseMarketplaceRepository: SupabaseTableRepository, MarketplaceRepository {
    func fetchMarketplaceListings(search: String?) async throws -> [RemoteMarketplaceListing] {
        var queryItems = [URLQueryItem(name: "order", value: "estimated_value.desc")]
        if let search, !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            queryItems.append(URLQueryItem(name: "card_name", value: "ilike.*\(search)*"))
        }
        return try await fetchRows(from: "marketplace_listings", queryItems: queryItems)
    }

    func saveListing(userID: UUID, listingID: UUID) async throws {
        let data = try JSONSerialization.data(withJSONObject: [
            "user_id": userID.uuidString,
            "trade_listing_id": listingID.uuidString
        ])
        let request = try client.restRequest(table: "saved_marketplace_listings", method: .post, body: data, prefer: "resolution=ignore-duplicates")
        try await client.send(request)
    }

    func reportListing(userID: UUID, listingID: UUID, reason: String) async throws {
        let data = try JSONSerialization.data(withJSONObject: [
            "reporter_id": userID.uuidString,
            "trade_listing_id": listingID.uuidString,
            "reason": reason
        ])
        let request = try client.restRequest(table: "listing_reports", method: .post, body: data)
        try await client.send(request)
    }
}

final class SupabaseEventsRepository: SupabaseTableRepository, EventsRepository {
    func fetchEvents(userID: UUID) async throws -> [RemoteVaultEvent] {
        try await fetchRows(from: "events", queryItems: [
            URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString)"),
            URLQueryItem(name: "order", value: "event_date.asc")
        ])
    }

    func upsertEvent(_ event: RemoteVaultEvent) async throws {
        try await upsert(event, into: "events")
    }

    func deleteEvent(id: UUID) async throws {
        try await delete(from: "events", id: id)
    }
}

final class SupabaseReputationRepository: SupabaseTableRepository, ReputationRepository {
    func fetchReputation(profileID: UUID) async throws -> RemoteReputation? {
        try await fetchRows(from: "reputation", queryItems: [
            URLQueryItem(name: "profile_id", value: "eq.\(profileID.uuidString)"),
            URLQueryItem(name: "limit", value: "1")
        ]).first
    }

    func upsertReputation(_ reputation: RemoteReputation) async throws {
        try await upsert(reputation, into: "reputation")
    }
}

final class SupabaseStorageRepository: VaultStorageRepository {
    private let client: SupabaseClientProvider

    init(client: SupabaseClientProvider) {
        self.client = client
    }

    func uploadAvatar(userID: UUID, data: Data, contentType: String) async throws -> String {
        let path = "\(userID.uuidString)/avatar-\(UUID().uuidString)"
        let request = try client.storageRequest(bucket: "avatars", path: path, method: .post, contentType: contentType, body: data)
        try await client.send(request)
        return "avatars/\(path)"
    }

    func uploadCardPhoto(userID: UUID, cardID: UUID, data: Data, contentType: String) async throws -> String {
        let path = "\(userID.uuidString)/\(cardID.uuidString)-\(UUID().uuidString)"
        let request = try client.storageRequest(bucket: "card-photos", path: path, method: .post, contentType: contentType, body: data)
        try await client.send(request)
        return "card-photos/\(path)"
    }
}

