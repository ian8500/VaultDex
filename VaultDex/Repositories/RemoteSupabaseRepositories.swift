import Foundation

#if canImport(Supabase)
import Supabase
#endif

class SupabaseTableRepository {
    let client: SupabaseClientProvider

    init(client: SupabaseClientProvider) {
        self.client = client
    }

    func fetchRows<T: Decodable>(from table: String, queryItems: [URLQueryItem] = []) async throws -> [T] {
        let request = try client.restRequest(table: table, queryItems: queryItems)
        return try await client.send(request, decode: [T].self)
    }

    func upsert<T: Encodable>(_ value: T, into table: String, onConflict: String? = nil) async throws {
        let data = try JSONEncoder.supabase.encode(value)
        let queryItems = onConflict.map { [URLQueryItem(name: "on_conflict", value: $0)] } ?? []
        let request = try client.restRequest(
            table: table,
            method: .post,
            queryItems: queryItems,
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
        #if canImport(Supabase)
        let response = try await client.requireSDKClient().auth.signUp(email: email, password: password)
        guard let sdkSession = response.session else {
            throw SupabaseAuthFlowError.emailConfirmationRequired
        }
        let session = SupabaseSession(sdkSession)
        client.updateSession(session)
        return session
        #else
        throw SupabaseClientError.missingConfiguration
        #endif
    }

    func signIn(email: String, password: String) async throws -> SupabaseSession {
        #if canImport(Supabase)
        let session = SupabaseSession(try await client.requireSDKClient().auth.signIn(email: email, password: password))
        client.updateSession(session)
        return session
        #else
        throw SupabaseClientError.missingConfiguration
        #endif
    }

    func signOut() async throws {
        #if canImport(Supabase)
        try await client.requireSDKClient().auth.signOut()
        #endif
        client.updateSession(nil)
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
        try await upsert(profile, into: "profiles", onConflict: "id")
    }
}

final class SupabaseVerificationRepository: SupabaseTableRepository, VerificationRepository {
    func fetchCurrentRequest(userID: UUID) async throws -> RemoteVerificationRequest? {
        try await fetchRows(from: "verification_requests", queryItems: [
            URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString)"),
            URLQueryItem(name: "order", value: "submitted_at.desc"),
            URLQueryItem(name: "limit", value: "1")
        ]).first
    }

    func fetchPendingRequests() async throws -> [RemoteVerificationRequest] {
        try await fetchRows(from: "verification_requests", queryItems: [
            URLQueryItem(name: "status", value: "eq.pending"),
            URLQueryItem(name: "order", value: "submitted_at.asc")
        ])
    }

    func submitRequest(_ request: RemoteVerificationRequest) async throws {
        try await upsert(request, into: "verification_requests", onConflict: "id")
    }

    func updateRequestStatus(id: UUID, status: String, adminNote: String?) async throws {
        var fields: [String: String] = ["status": status]
        if let adminNote {
            fields["admin_note"] = adminNote
        }
        try await patch(fields, table: "verification_requests", id: id)
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

    func upsertSet(_ set: RemoteCardSet) async throws {
        try await upsert(set, into: "card_sets", onConflict: "id")
    }

    func upsertCard(_ card: RemoteCard) async throws {
        try await upsert(card, into: "cards", onConflict: "id")
    }
}

final class SupabaseCollectionRepository: SupabaseTableRepository, CollectionRepository {
    func fetchCollection(userID: UUID) async throws -> [RemoteCollectionItem] {
        try await fetchRows(from: "collection_items", queryItems: [
            URLQueryItem(name: "owner_id", value: "eq.\(userID.uuidString)"),
            URLQueryItem(name: "order", value: "acquired_at.desc")
        ])
    }

    func upsertCollectionItem(_ item: RemoteCollectionItem) async throws {
        try await upsert(item, into: "collection_items", onConflict: "id")
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
        try await upsert(item, into: "wishlist_items", onConflict: "id")
    }

    func deleteWishlistItem(id: UUID) async throws {
        try await delete(from: "wishlist_items", id: id)
    }
}

final class SupabaseFriendsRepository: SupabaseTableRepository, FriendsRepository {
    func fetchFriends(userID: UUID) async throws -> [RemoteFriendship] {
        try await fetchRows(from: "friendships", queryItems: [
            URLQueryItem(name: "or", value: "(user_a_id.eq.\(userID.uuidString),user_b_id.eq.\(userID.uuidString))"),
            URLQueryItem(name: "status", value: "eq.active"),
            URLQueryItem(name: "order", value: "updated_at.desc")
        ])
    }

    func fetchFriendRequests(userID: UUID) async throws -> [RemoteFriendRequest] {
        try await fetchRows(from: "friend_requests", queryItems: [
            URLQueryItem(name: "or", value: "(requester_id.eq.\(userID.uuidString),addressee_id.eq.\(userID.uuidString))"),
            URLQueryItem(name: "status", value: "eq.pending"),
            URLQueryItem(name: "order", value: "created_at.desc")
        ])
    }

    func searchProfiles(username: String, currentUserID: UUID) async throws -> [RemoteProfile] {
        let trimmed = username
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "@", with: "")
        guard !trimmed.isEmpty else { return [] }
        return try await fetchRows(from: "profiles", queryItems: [
            URLQueryItem(name: "or", value: "(username.ilike.*\(trimmed)*,display_name.ilike.*\(trimmed)*)"),
            URLQueryItem(name: "id", value: "neq.\(currentUserID.uuidString)"),
            URLQueryItem(name: "limit", value: "8")
        ])
    }

    func fetchProfiles(ids: [UUID]) async throws -> [RemoteProfile] {
        let uniqueIDs = Array(Set(ids))
        guard !uniqueIDs.isEmpty else { return [] }
        let idList = uniqueIDs.map(\.uuidString).joined(separator: ",")
        return try await fetchRows(from: "profiles", queryItems: [
            URLQueryItem(name: "id", value: "in.(\(idList))")
        ])
    }

    func fetchVisibleCollection(ownerID: UUID) async throws -> [RemoteCollectionItem] {
        try await fetchRows(from: "collection_items", queryItems: [
            URLQueryItem(name: "owner_id", value: "eq.\(ownerID.uuidString)"),
            URLQueryItem(name: "order", value: "acquired_at.desc")
        ])
    }

    func fetchVisibleWishlist(userID: UUID) async throws -> [RemoteWishlistItem] {
        try await fetchRows(from: "wishlist_items", queryItems: [
            URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString)"),
            URLQueryItem(name: "order", value: "added_at.desc")
        ])
    }

    func sendFriendRequest(from userID: UUID, to profileID: UUID) async throws {
        let request = RemoteFriendRequest(
            id: UUID(),
            requesterID: userID,
            addresseeID: profileID,
            message: nil,
            status: "pending",
            createdAt: nil,
            updatedAt: nil
        )
        try await upsert(request, into: "friend_requests", onConflict: "requester_id,addressee_id")
    }

    func acceptFriendRequest(_ request: RemoteFriendRequest) async throws {
        try await patch(["status": "accepted"], table: "friend_requests", id: request.id)
        let friendship = RemoteFriendship(
            id: UUID(),
            requesterID: request.requesterID,
            addresseeID: request.addresseeID,
            status: "active",
            createdAt: nil,
            updatedAt: nil
        )
        try await upsert(friendship, into: "friendships", onConflict: "user_a_id,user_b_id")
    }

    func rejectFriendRequest(id: UUID) async throws {
        try await patch(["status": "rejected"], table: "friend_requests", id: id)
    }

    func removeFriendship(id: UUID) async throws {
        try await delete(from: "friendships", id: id)
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
        var queryItems = [
            URLQueryItem(name: "status", value: "eq.active"),
            URLQueryItem(name: "order", value: "listed_at.desc")
        ]
        if let userID {
            queryItems.append(URLQueryItem(name: "owner_id", value: "eq.\(userID.uuidString)"))
        }
        return try await fetchRows(from: "marketplace_listings", queryItems: queryItems)
    }

    func fetchTradeOffers(userID: UUID) async throws -> [RemoteTradeOffer] {
        try await fetchRows(from: "trade_offers", queryItems: [
            URLQueryItem(name: "or", value: "(sender_id.eq.\(userID.uuidString),receiver_id.eq.\(userID.uuidString))"),
            URLQueryItem(name: "order", value: "created_at.desc")
        ])
    }

    func fetchTradeOfferItems(offerIDs: [UUID]) async throws -> [RemoteTradeOfferItem] {
        let uniqueIDs = Array(Set(offerIDs))
        guard !uniqueIDs.isEmpty else { return [] }
        let idList = uniqueIDs.map(\.uuidString).joined(separator: ",")
        return try await fetchRows(from: "trade_offer_items", queryItems: [
            URLQueryItem(name: "trade_offer_id", value: "in.(\(idList))")
        ])
    }

    func upsertTradeListing(_ listing: RemoteTradeListing) async throws {
        try await upsert(listing, into: "marketplace_listings")
    }

    func deleteTradeListing(id: UUID) async throws {
        try await delete(from: "marketplace_listings", id: id)
    }

    func upsertTradeOffer(_ offer: RemoteTradeOffer) async throws {
        try await upsert(offer, into: "trade_offers", onConflict: "id")
    }

    func upsertTradeOfferItems(_ items: [RemoteTradeOfferItem]) async throws {
        guard !items.isEmpty else { return }
        try await upsert(items, into: "trade_offer_items", onConflict: "id")
    }

    func updateTradeOfferStatus(id: UUID, status: String) async throws {
        try await patch(["status": status], table: "trade_offers", id: id)
    }
}

final class SupabaseMarketplaceRepository: SupabaseTableRepository, MarketplaceRepository {
    func fetchMarketplaceListings(search: String?) async throws -> [RemoteMarketplaceListing] {
        var queryItems = [
            URLQueryItem(name: "status", value: "eq.active"),
            URLQueryItem(name: "order", value: "estimated_value.desc")
        ]
        if let search, !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            queryItems.append(URLQueryItem(name: "title", value: "ilike.*\(search)*"))
        }
        return try await fetchRows(from: "marketplace_listings", queryItems: queryItems)
    }

    func saveListing(userID: UUID, listingID: UUID) async throws {
        let data = try JSONSerialization.data(withJSONObject: [
            "user_id": userID.uuidString,
            "marketplace_listing_id": listingID.uuidString
        ])
        let request = try client.restRequest(table: "marketplace_listings", method: .patch, queryItems: [URLQueryItem(name: "id", value: "eq.\(listingID.uuidString)")], body: data)
        try await client.send(request)
    }

    func reportListing(userID: UUID, listingID: UUID, reason: String) async throws {
        let data = try JSONSerialization.data(withJSONObject: [
            "reporter_id": userID.uuidString,
            "marketplace_listing_id": listingID.uuidString,
            "reason": reason,
            "details": "Reported from iOS app"
        ])
        let request = try client.restRequest(table: "safety_reports", method: .post, body: data)
        try await client.send(request)
    }
}

final class SupabaseEventsRepository: SupabaseTableRepository, EventsRepository {
    func fetchEvents(userID: UUID) async throws -> [RemoteVaultEvent] {
        try await fetchRows(from: "app_events", queryItems: [
            URLQueryItem(name: "or", value: "(owner_id.eq.\(userID.uuidString),visibility.eq.public)"),
            URLQueryItem(name: "order", value: "event_date.asc")
        ])
    }

    func upsertEvent(_ event: RemoteVaultEvent) async throws {
        try await upsert(event, into: "app_events")
    }

    func deleteEvent(id: UUID) async throws {
        try await delete(from: "app_events", id: id)
    }
}

final class SupabaseReputationRepository: SupabaseTableRepository, ReputationRepository {
    func fetchReputation(profileID: UUID) async throws -> RemoteReputation? {
        try await fetchRows(from: "reputation_events", queryItems: [
            URLQueryItem(name: "profile_id", value: "eq.\(profileID.uuidString)"),
            URLQueryItem(name: "limit", value: "1")
        ]).first
    }

    func upsertReputation(_ reputation: RemoteReputation) async throws {
        try await upsert(reputation, into: "reputation_events")
    }
}

final class SupabaseStorageRepository: VaultStorageRepository {
    private let client: SupabaseClientProvider

    init(client: SupabaseClientProvider) {
        self.client = client
    }

    func uploadAvatar(userID: UUID, data: Data, contentType: String) async throws -> String {
        try await uploadAvatarFile(userID: userID, fileName: "profile.jpg", data: data, contentType: contentType)
    }

    func uploadAvatarFile(userID: UUID, fileName: String, data: Data, contentType: String) async throws -> String {
        let safeFileName = fileName.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let path = "\(userID.uuidString)/\(safeFileName)"
        let request = try client.storageRequest(
            bucket: "avatars",
            path: path,
            method: .post,
            contentType: contentType,
            body: data,
            upsert: true
        )
        do {
            try await client.send(request)
        } catch SupabaseClientError.requestFailed(let statusCode, _) where statusCode == 400 || statusCode == 409 {
            let overwriteRequest = try client.storageRequest(
                bucket: "avatars",
                path: path,
                method: .put,
                contentType: contentType,
                body: data,
                upsert: true
            )
            try await client.send(overwriteRequest)
        }
        return try client.publicStorageURL(bucket: "avatars", path: path).absoluteString
    }

    func uploadCardPhoto(userID: UUID, collectionItemID: UUID, side: CardPhotoSide, data: Data, contentType: String) async throws -> String {
        let path = "\(userID.uuidString)/collection/\(collectionItemID.uuidString)-\(side.rawValue)-\(UUID().uuidString).jpg"
        let request = try client.storageRequest(bucket: "card-photos", path: path, method: .post, contentType: contentType, body: data)
        try await client.send(request)
        return try client.publicStorageURL(bucket: "card-photos", path: path).absoluteString
    }
}
