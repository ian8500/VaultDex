import Foundation

@MainActor
final class LocalVaultStore: ObservableObject {
    private static let fallbackSet = CardSet(name: "VaultDex", code: "VDX", releaseYear: 2026, totalCards: 0)

    let repositories: VaultRepositoryContainer
    let localRepositories: LocalRepositoryContainer
    let importPreviewItems: [ImportPreviewItem]
    let inviteContacts: [InviteContact]

    @Published private(set) var runtimeMode: VaultRuntimeMode
    @Published private(set) var isLoadingCloudData = false
    @Published private(set) var imageUploadMessage: String?
    @Published private(set) var isSavingProfile = false
    @Published private(set) var isUploadingAvatar = false
    @Published private(set) var uploadingCardPhotoSide: CardPhotoSide?
    @Published private(set) var lastSyncError: String?
    @Published var sets: [CardSet]
    @Published var cards: [Card]
    @Published var profile: UserProfile
    @Published var collectionItems: [CollectionItem]
    @Published var wishlistItems: [WishlistItem]
    @Published var events: [VaultEvent]
    @Published var binderPages: [BinderPage]
    @Published var friends: [Friend]
    @Published var friendRequests: [FriendRequest]
    @Published var friendSearchResults: [RemoteProfile] = []
    @Published var isSearchingFriends = false
    @Published var friendWants: [FriendWant]
    @Published var tradeListings: [TradeListing]
    @Published var tradeOffers: [TradeOffer]

    init(
        repository: DemoVaultRepository = .shared,
        repositories: VaultRepositoryContainer = .live(config: .current),
        localRepositories: LocalRepositoryContainer = .demo()
    ) {
        self.repositories = repositories
        self.localRepositories = localRepositories
        let useCloudState = repositories.clientProvider.isRemoteEnabled
        runtimeMode = useCloudState ? .supabase : .demo
        importPreviewItems = useCloudState ? [] : repository.importPreviewItems
        inviteContacts = useCloudState ? [] : repository.inviteContacts

        if useCloudState {
            sets = []
            cards = []
            profile = Self.emptyProfile
            collectionItems = []
            wishlistItems = []
            events = []
            binderPages = []
            friends = []
            friendRequests = []
            friendWants = []
            tradeListings = []
            tradeOffers = []
        } else {
            sets = repository.sets
            cards = repository.cards
            profile = repository.profile
            collectionItems = repository.collectionItems
            wishlistItems = repository.wishlistItems
            events = repository.events
            binderPages = repository.binderPages
            friends = repository.friends
            friendRequests = repository.friendRequests
            friendWants = repository.friendWants
            tradeListings = repository.tradeListings
            tradeOffers = repository.tradeOffers
        }
    }

    var isDemoMode: Bool {
        runtimeMode == .demo
    }

    private static let cloudConnectionMessage = "Unable to connect to VaultDex Cloud. Please try again."
    private static let collectionSyncMessage = "Unable to sync your vault right now. Please try again."
    private static let wantsSyncMessage = "Unable to sync your wants right now. Please try again."
    private static let friendsSyncMessage = "Unable to sync friends right now. Please try again."
    private static let tradeSyncMessage = "Unable to sync trades right now. Please try again."
    private static let imageUploadMessage = "Unable to upload that image right now. Please try again."
    private static let imageUploadSignInMessage = "Sign in before uploading images."

    func useDemoMode(repository: DemoVaultRepository = .shared) {
        runtimeMode = .demo
        lastSyncError = nil
        resetDemoUserState(repository: repository)
    }

    func clearSignedOutState() {
        runtimeMode = .supabase
        lastSyncError = nil
        imageUploadMessage = nil
        sets = []
        cards = []
        collectionItems = []
        wishlistItems = []
        binderPages = []
        friends = []
        friendRequests = []
        friendWants = []
        tradeListings = []
        tradeOffers = []
        events = []
        profile = Self.emptyProfile
    }

    private static var emptyProfile: UserProfile {
        UserProfile(
            displayName: "",
            handle: "",
            location: "",
            bio: "",
            collectorType: "",
            avatarSymbol: "person.crop.circle.fill",
            reputationScore: 0,
            trustBadges: [],
            completedTrades: 0,
            collectorScore: 0,
            favoriteSet: fallbackSet,
            joinedDate: .now,
            followers: 0,
            following: 0
        )
    }

    func loadCloudDataIfPossible(session: SupabaseSession?) async {
        guard repositories.config.isConfigured, repositories.clientProvider.canCreateClient else {
            loadCachedOrDemo(reason: "Supabase is unavailable on this build.")
            return
        }

        guard let session else {
            runtimeMode = .supabase
            lastSyncError = nil
            return
        }

        isLoadingCloudData = true
        defer { isLoadingCloudData = false }

        do {
            let cloudProfile = try await fetchOrCreateCloudProfile(userID: session.userID)
            do {
                let snapshot = try await fetchCloudSnapshot(userID: session.userID, profile: cloudProfile)
                apply(snapshot: snapshot, userID: session.userID)
                CloudVaultCache.save(snapshot, userID: session.userID)
                runtimeMode = .supabase
                lastSyncError = nil
            } catch {
                if var cachedSnapshot = CloudVaultCache.load(userID: session.userID) {
                    cachedSnapshot.profile = cloudProfile
                    apply(snapshot: cachedSnapshot, userID: session.userID)
                } else {
                    apply(snapshot: CloudVaultSnapshot.empty(profile: cloudProfile), userID: session.userID)
                }
                runtimeMode = .offline
                lastSyncError = Self.cloudConnectionMessage
            }
        } catch {
            clearSignedOutState()
            runtimeMode = .offline
            lastSyncError = Self.cloudConnectionMessage
        }
    }

    private func loadCachedOrDemo(reason: String) {
        if let userID = repositories.clientProvider.currentSession?.userID,
           let snapshot = CloudVaultCache.load(userID: userID) {
            apply(snapshot: snapshot, userID: userID)
            runtimeMode = .offline
        } else if repositories.clientProvider.currentSession != nil {
            clearSignedOutState()
            runtimeMode = .offline
        } else {
            runtimeMode = .demo
        }
        lastSyncError = reason
    }

    private func fetchOrCreateCloudProfile(userID: UUID) async throws -> RemoteProfile {
        if let profile = try await repositories.profiles.fetchCurrentProfile(userID: userID) {
            return profile
        }
        return try await createBlankCloudProfile(userID: userID)
    }

    private func fetchCloudSnapshot(userID: UUID, profile: RemoteProfile) async throws -> CloudVaultSnapshot {
        async let remoteSets = repositories.cards.fetchSets()
        async let remoteCards = repositories.cards.fetchCards(search: nil)
        async let remoteCollection = repositories.collection.fetchCollection(userID: userID)
        async let remoteWishlist = repositories.wishlist.fetchWishlist(userID: userID)
        async let remoteFriends = repositories.friends.fetchFriends(userID: userID)
        async let remoteFriendRequests = repositories.friends.fetchFriendRequests(userID: userID)
        async let remoteOffers = repositories.trades.fetchTradeOffers(userID: userID)
        async let remoteListings = repositories.marketplace.fetchMarketplaceListings(search: nil)
        async let remoteEvents = repositories.events.fetchEvents(userID: userID)

        let friendships = try await remoteFriends
        let friendRequests = try await remoteFriendRequests
        let tradeOffers = try await remoteOffers
        let tradeOfferItems = try await repositories.trades.fetchTradeOfferItems(offerIDs: tradeOffers.map(\.id))
        let friendIDs = friendships.map { $0.friendID(for: userID) }
        let requestProfileIDs = friendRequests.map { $0.otherUserID(for: userID) }
        let tradeProfileIDs = tradeOffers.map { $0.senderID == userID ? $0.receiverID : $0.senderID }
        let profiles = try await repositories.friends.fetchProfiles(ids: friendIDs + requestProfileIDs + tradeProfileIDs)

        var visibleFriendData: [RemoteFriendVisibleData] = []
        for friendID in friendIDs {
            async let visibleCollection = repositories.friends.fetchVisibleCollection(ownerID: friendID)
            async let visibleWishlist = repositories.friends.fetchVisibleWishlist(userID: friendID)
            visibleFriendData.append(
                RemoteFriendVisibleData(
                    friendID: friendID,
                    collection: try await visibleCollection,
                    wishlist: try await visibleWishlist
                )
            )
        }

        return try await CloudVaultSnapshot(
            profile: profile,
            sets: remoteSets,
            cards: remoteCards,
            collection: remoteCollection,
            wishlist: remoteWishlist,
            friends: friendships,
            friendRequests: friendRequests,
            friendProfiles: profiles,
            visibleFriendData: visibleFriendData,
            tradeOffers: tradeOffers,
            tradeOfferItems: tradeOfferItems,
            marketplaceListings: remoteListings,
            events: remoteEvents
        )
    }

    private func createBlankCloudProfile(userID: UUID) async throws -> RemoteProfile {
        let profile = RemoteProfile(
            id: userID,
            username: "collector_\(userID.uuidString.prefix(8).lowercased())",
            displayName: "",
            location: nil,
            bio: nil,
            collectorType: nil,
            avatarURL: nil,
            avatarPath: nil,
            reputationScore: 0,
            trustBadges: [],
            completedTrades: 0,
            collectorScore: 0,
            profileVisibility: "public",
            collectionVisibility: "friends",
            wishlistVisibility: "friends",
            createdAt: nil,
            updatedAt: nil
        )
        try await repositories.profiles.upsertProfile(profile)
        return profile
    }

    private func apply(snapshot: CloudVaultSnapshot, userID: UUID) {
        let mappedSets = snapshot.sets.map(\.localSet)
        let setByID = Dictionary(uniqueKeysWithValues: mappedSets.map { ($0.id, $0) })
        let fallbackSet = mappedSets.first ?? Self.fallbackSet
        let mappedCards = snapshot.cards.map { $0.localCard(set: setByID[$0.setID] ?? fallbackSet) }
        let cardByID = Dictionary(uniqueKeysWithValues: mappedCards.map { ($0.id, $0) })

        sets = mappedSets
        cards = mappedCards
        if let cloudProfile = snapshot.profile {
            profile = cloudProfile.localProfile(favoriteSet: sets.first ?? fallbackSet)
        }
        collectionItems = snapshot.collection.compactMap { $0.localItem(card: cardByID[$0.cardID]) }
        wishlistItems = snapshot.wishlist.compactMap { $0.localItem(card: cardByID[$0.cardID]) }
        let profileByID = Dictionary(uniqueKeysWithValues: (snapshot.friendProfiles ?? []).map { ($0.id, $0) })
        tradeListings = snapshot.marketplaceListings.compactMap { $0.localListing(card: cardByID[$0.cardID], currentUserID: userID) }
        let tradeItemsByOfferID = Dictionary(grouping: snapshot.tradeOfferItems ?? [], by: \.tradeOfferID)
        tradeOffers = snapshot.tradeOffers.map { offer in
            offer.localOffer(
                cards: cardByID,
                items: tradeItemsByOfferID[offer.id] ?? [],
                profiles: profileByID,
                currentUserID: userID
            )
        }
        events = snapshot.events.compactMap { $0.localEvent(featuredSet: sets.first ?? fallbackSet) }
        let visibleDataByID = Dictionary(uniqueKeysWithValues: (snapshot.visibleFriendData ?? []).map { ($0.friendID, $0) })
        friends = snapshot.friends.compactMap { friendship in
            let friendID = friendship.friendID(for: userID)
            return friendship.localFriend(
                profile: profileByID[friendID],
                visibleData: visibleDataByID[friendID],
                cards: cards,
                cardByID: cardByID,
                currentUserID: userID
            )
        }
        friendRequests = (snapshot.friendRequests ?? []).compactMap { request in
            request.localRequest(profile: profileByID[request.otherUserID(for: userID)], currentUserID: userID, previewCard: cards.first)
        }
        friendWants = []
    }

    var totalCopiesOwned: Int {
        collectionItems.reduce(0) { $0 + $1.quantity }
    }

    var uniqueCardsOwned: Int {
        collectionItems.count
    }

    var estimatedCollectionValue: Double {
        collectionItems.reduce(0) { $0 + ($1.card.marketValue * Double($1.quantity)) }
    }

    var uniqueSetsOwned: Int {
        Set(collectionItems.map(\.card.set.id)).count
    }

    var recentlyAdded: [CollectionItem] {
        collectionItems.sorted { $0.acquiredAt > $1.acquiredAt }
    }

    var tradeableCollectionItems: [CollectionItem] {
        collectionItems.filter(\.isAvailableForTrade)
    }

    func collectionItem(for card: Card) -> CollectionItem? {
        collectionItems.first { $0.card.id == card.id }
    }

    func wishlistItem(for card: Card) -> WishlistItem? {
        wishlistItems.first { $0.card.id == card.id }
    }

    func quantityOwned(for card: Card) -> Int? {
        collectionItem(for: card)?.quantity
    }

    func isWishlisted(_ card: Card) -> Bool {
        wishlistItem(for: card) != nil
    }

    func addCard(
        _ card: Card,
        quantity: Int = 1,
        condition: CardCondition? = nil,
        variant: CardVariant = .normal
    ) {
        let safeQuantity = max(quantity, 1)

        if let index = collectionItems.firstIndex(where: { $0.card.id == card.id }) {
            collectionItems[index].quantity += safeQuantity
            collectionItems[index].condition = condition ?? collectionItems[index].condition
            collectionItems[index].variant = variant
            collectionItems[index].acquiredAt = .now
            syncCollectionItem(collectionItems[index])
        } else {
            let item = CollectionItem(
                card: card,
                quantity: safeQuantity,
                condition: condition ?? card.condition,
                variant: variant,
                acquiredAt: .now
            )
            collectionItems.append(item)
            syncCollectionItem(item)
        }
    }

    func removeCard(_ card: Card) {
        let removed = collectionItems.first { $0.card.id == card.id }
        collectionItems.removeAll { $0.card.id == card.id }
        if let removed, runtimeMode == .supabase {
            Task {
                do {
                    try await repositories.collection.deleteCollectionItem(id: removed.id)
                } catch {
                    await MainActor.run {
                        lastSyncError = Self.collectionSyncMessage
                    }
                }
            }
        }
    }

    func updateQuantity(for card: Card, quantity: Int) {
        guard let index = collectionItems.firstIndex(where: { $0.card.id == card.id }) else { return }

        if quantity <= 0 {
            let removed = collectionItems.remove(at: index)
            if runtimeMode == .supabase {
                Task {
                    do {
                        try await repositories.collection.deleteCollectionItem(id: removed.id)
                    } catch {
                        await MainActor.run {
                            lastSyncError = Self.collectionSyncMessage
                        }
                    }
                }
            }
        } else {
            collectionItems[index].quantity = quantity
            syncCollectionItem(collectionItems[index])
        }
    }

    func updateCondition(for card: Card, condition: CardCondition) {
        guard let index = collectionItems.firstIndex(where: { $0.card.id == card.id }) else { return }
        collectionItems[index].condition = condition
        syncCollectionItem(collectionItems[index])
    }

    func updateVariant(for card: Card, variant: CardVariant) {
        guard let index = collectionItems.firstIndex(where: { $0.card.id == card.id }) else { return }
        collectionItems[index].variant = variant
        syncCollectionItem(collectionItems[index])
    }

    func updateTradeAvailability(for card: Card, isAvailable: Bool) {
        guard let index = collectionItems.firstIndex(where: { $0.card.id == card.id }) else { return }
        collectionItems[index].isAvailableForTrade = isAvailable
        syncCollectionItem(collectionItems[index])
    }

    func updateCollectionDetails(
        for card: Card,
        language: String,
        gradedCompany: String?,
        gradedScore: String?,
        notes: String?,
        visibility: CollectionVisibility,
        availableForCredits: Bool,
        askingCredits: Int?
    ) {
        guard let index = collectionItems.firstIndex(where: { $0.card.id == card.id }) else { return }
        collectionItems[index].language = language.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "English" : language
        collectionItems[index].gradedCompany = gradedCompany?.nilIfBlank
        collectionItems[index].gradedScore = gradedScore?.nilIfBlank
        collectionItems[index].notes = notes?.nilIfBlank
        collectionItems[index].visibility = visibility
        collectionItems[index].isAvailableForCredits = availableForCredits
        collectionItems[index].askingCredits = availableForCredits ? askingCredits.map { max($0, 0) } : nil
        syncCollectionItem(collectionItems[index])
    }

    func addToWishlist(
        _ card: Card,
        priority: WishlistPriority = .medium,
        preferredCondition: CardCondition = .nearMint,
        budget: Double? = nil,
        notes: String = ""
    ) {
        if let index = wishlistItems.firstIndex(where: { $0.card.id == card.id }) {
            wishlistItems[index].priority = priority
            wishlistItems[index].preferredCondition = preferredCondition
            wishlistItems[index].budget = budget ?? wishlistItems[index].budget
            wishlistItems[index].notes = notes
            syncWishlistItem(wishlistItems[index])
        } else {
            let item = WishlistItem(
                card: card,
                priority: priority,
                preferredCondition: preferredCondition,
                budget: budget ?? card.marketValue,
                notes: notes
            )
            wishlistItems.append(item)
            syncWishlistItem(item)
        }
    }

    func updateWishlist(
        for card: Card,
        priority: WishlistPriority,
        preferredCondition: CardCondition = .nearMint,
        budget: Double,
        notes: String
    ) {
        guard let index = wishlistItems.firstIndex(where: { $0.card.id == card.id }) else { return }
        wishlistItems[index].priority = priority
        wishlistItems[index].preferredCondition = preferredCondition
        wishlistItems[index].budget = max(budget, 0)
        wishlistItems[index].notes = notes
        syncWishlistItem(wishlistItems[index])
    }

    func removeFromWishlist(_ card: Card) {
        let removed = wishlistItems.first { $0.card.id == card.id }
        wishlistItems.removeAll { $0.card.id == card.id }
        if let removed, runtimeMode == .supabase {
            Task {
                do {
                    try await repositories.wishlist.deleteWishlistItem(id: removed.id)
                    await MainActor.run {
                        if lastSyncError?.contains("Wants delete failed") == true {
                            lastSyncError = nil
                        }
                    }
                } catch {
                    await MainActor.run {
                        lastSyncError = Self.wantsSyncMessage
                    }
                }
            }
        }
    }

    func sendFriendRequest(to handleOrEmail: String) {
        let trimmed = handleOrEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let normalized = trimmed.lowercased()
        guard !friends.contains(where: { $0.handle.lowercased() == normalized || $0.email.lowercased() == normalized }) else { return }
        guard !friendRequests.contains(where: { $0.handleOrEmail.lowercased() == normalized }) else { return }

        if runtimeMode == .supabase, let userID = repositories.clientProvider.currentSession?.userID {
            Task {
                do {
                    let matches = try await repositories.friends.searchProfiles(username: trimmed, currentUserID: userID)
                    guard let matchedProfile = matches.first else {
                        await MainActor.run {
                            friendSearchResults = []
                            lastSyncError = "Friend request failed: no VaultDex user found for \(trimmed)."
                        }
                        return
                    }

                    try await repositories.friends.sendFriendRequest(from: userID, to: matchedProfile.id)
                    let request = FriendRequest(
                        requesterID: userID,
                        addresseeID: matchedProfile.id,
                        displayName: matchedProfile.displayName.nilIfBlank ?? matchedProfile.username,
                        handleOrEmail: "@\(matchedProfile.username)",
                        avatarSymbol: "paperplane.fill",
                        direction: .outgoing,
                        previewCard: cards.first
                    )
                    await MainActor.run {
                        friendRequests.removeAll { $0.addresseeID == matchedProfile.id || $0.handleOrEmail.lowercased() == request.handleOrEmail.lowercased() }
                        friendRequests.insert(request, at: 0)
                        friendSearchResults = []
                        if lastSyncError?.contains("Friend request failed") == true {
                            lastSyncError = nil
                        }
                    }
                } catch {
                    await MainActor.run {
                        lastSyncError = Self.friendsSyncMessage
                    }
                }
            }
            return
        }

        friendRequests.insert(
            FriendRequest(
                displayName: trimmed.replacingOccurrences(of: "@", with: "").capitalized,
                handleOrEmail: trimmed,
                avatarSymbol: "paperplane.fill",
                direction: .outgoing,
                previewCard: cards.first
            ),
            at: 0
        )
    }

    func sendFriendRequest(to profile: RemoteProfile) {
        guard runtimeMode == .supabase, let userID = repositories.clientProvider.currentSession?.userID else { return }
        guard profile.id != userID else { return }
        guard !friends.contains(where: { $0.id == profile.id }) else { return }
        guard !friendRequests.contains(where: { $0.requesterID == userID && $0.addresseeID == profile.id }) else { return }

        Task {
            do {
                try await repositories.friends.sendFriendRequest(from: userID, to: profile.id)
                let request = FriendRequest(
                    requesterID: userID,
                    addresseeID: profile.id,
                    displayName: profile.displayName.nilIfBlank ?? profile.username,
                    handleOrEmail: "@\(profile.username)",
                    avatarSymbol: "paperplane.fill",
                    direction: .outgoing,
                    previewCard: cards.first
                )
                await MainActor.run {
                    friendRequests.removeAll { $0.addresseeID == profile.id }
                    friendRequests.insert(request, at: 0)
                    friendSearchResults = []
                    if lastSyncError?.contains("Friend request failed") == true {
                        lastSyncError = nil
                    }
                }
            } catch {
                await MainActor.run {
                    lastSyncError = Self.friendsSyncMessage
                }
            }
        }
    }

    func searchFriendUsers(matching query: String) {
        guard runtimeMode == .supabase, let userID = repositories.clientProvider.currentSession?.userID else {
            friendSearchResults = []
            return
        }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            friendSearchResults = []
            return
        }

        isSearchingFriends = true
        Task {
            do {
                let matches = try await repositories.friends.searchProfiles(username: trimmed, currentUserID: userID)
                await MainActor.run {
                    friendSearchResults = matches
                    isSearchingFriends = false
                }
            } catch {
                await MainActor.run {
                    friendSearchResults = []
                    isSearchingFriends = false
                    lastSyncError = Self.friendsSyncMessage
                }
            }
        }
    }

    func acceptFriendRequest(_ request: FriendRequest) {
        guard request.direction == .incoming else { return }
        if runtimeMode == .supabase,
           let requesterID = request.requesterID,
           let addresseeID = request.addresseeID {
            let remoteRequest = RemoteFriendRequest(
                id: request.id,
                requesterID: requesterID,
                addresseeID: addresseeID,
                message: nil,
                status: "pending",
                createdAt: nil,
                updatedAt: nil
            )
            Task {
                do {
                    try await repositories.friends.acceptFriendRequest(remoteRequest)
                    let cloudProfile = try await fetchOrCreateCloudProfile(userID: addresseeID)
                    let snapshot = try await fetchCloudSnapshot(userID: addresseeID, profile: cloudProfile)
                    await MainActor.run {
                        apply(snapshot: snapshot, userID: addresseeID)
                        CloudVaultCache.save(snapshot, userID: addresseeID)
                        lastSyncError = nil
                    }
                } catch {
                    await MainActor.run {
                        lastSyncError = Self.friendsSyncMessage
                    }
                }
            }
            return
        }

        let favorite = request.previewCard ?? cards.first
        guard let favorite else { return }
        let newFriend = Friend(
            displayName: request.displayName,
            handle: request.handleOrEmail.hasPrefix("@") ? request.handleOrEmail : "@" + request.displayName.lowercased().replacingOccurrences(of: " ", with: ""),
            email: request.handleOrEmail.contains("@") && !request.handleOrEmail.hasPrefix("@") ? request.handleOrEmail : "",
            avatarSymbol: request.avatarSymbol,
            collectorScore: 4100 + friends.count * 275,
            favoriteCard: favorite,
            completionPercent: 0.42,
            mutualTrades: 0,
            isOnline: true,
            visibleCollection: [
                CollectionItem(card: favorite, quantity: 1, variant: .normal, acquiredAt: .now)
            ],
            wishlist: wishlistItems.prefix(2).map { item in
                WishlistItem(card: item.card, priority: item.priority, budget: item.budget, notes: "Shared target from accepted request.")
            }
        )
        friends.insert(newFriend, at: 0)
        friendRequests.removeAll { $0.id == request.id }
    }

    func rejectFriendRequest(_ request: FriendRequest) {
        friendRequests.removeAll { $0.id == request.id }
        if runtimeMode == .supabase {
            Task {
                do {
                    try await repositories.friends.rejectFriendRequest(id: request.id)
                } catch {
                    await MainActor.run {
                        lastSyncError = Self.friendsSyncMessage
                    }
                }
            }
        }
    }

    func removeFriend(_ friend: Friend) {
        friends.removeAll { $0.id == friend.id }
        friendWants.removeAll { $0.friend.id == friend.id }
        if runtimeMode == .supabase, let friendshipID = friend.friendshipID {
            Task {
                do {
                    try await repositories.friends.removeFriendship(id: friendshipID)
                } catch {
                    await MainActor.run {
                        lastSyncError = Self.friendsSyncMessage
                    }
                }
            }
        }
    }

    func blockFriend(_ friend: Friend) {
        removeFriend(friend)
    }

    func friendsWanting(_ card: Card) -> [Friend] {
        friends.filter { friend in
            friend.wishlist.contains { $0.card.id == card.id }
        }
    }

    func cardsIWantThatFriendOwns(_ friend: Friend) -> [CollectionItem] {
        let wantedIDs = Set(wishlistItems.map(\.card.id))
        return friend.visibleCollection.filter { wantedIDs.contains($0.card.id) }
    }

    func cardsFriendWantsThatIOwn(_ friend: Friend) -> [CollectionItem] {
        let friendWantedIDs = Set(friend.wishlist.map(\.card.id))
        return collectionItems.filter { friendWantedIDs.contains($0.card.id) }
    }

    func tradeOpportunities() -> [FriendTradeOpportunity] {
        friends.compactMap { friend in
            let theyOwn = cardsIWantThatFriendOwns(friend)
            let youOwn = cardsFriendWantsThatIOwn(friend)
            guard !theyOwn.isEmpty || !youOwn.isEmpty else { return nil }
            return FriendTradeOpportunity(friend: friend, theyOwn: theyOwn, youOwn: youOwn)
        }
        .sorted { $0.score > $1.score }
    }

    func listCardForTrade(
        _ item: CollectionItem,
        listingKind: TradeListingKind,
        askingCredits: Int?,
        description: String,
        askingFor: String,
        usesSafeTrade: Bool
    ) {
        guard !tradeListings.contains(where: { $0.isMine && $0.card.id == item.card.id }) else { return }
        let listing = TradeListing(
            ownerID: repositories.clientProvider.currentSession?.userID,
            collectionItemID: item.id,
            ownerName: profile.displayName,
            ownerHandle: profile.handle,
            card: item.card,
            condition: item.condition,
            variant: item.variant,
            listingKind: listingKind,
            askingFor: askingFor.isEmpty ? listingKind.defaultAskText(askingCredits: askingCredits) : askingFor,
            askingCredits: askingCredits,
            description: description,
            locationLabel: "My vault",
            sellerReputation: max(profile.reputationScore, 0),
            isFeatured: true,
            isMine: true,
            usesSafeTrade: usesSafeTrade
        )
        tradeListings.insert(listing, at: 0)
        updateTradeAvailability(for: item.card, isAvailable: true)
        syncTradeListing(listing)
    }

    func removeTradeListing(_ listing: TradeListing) {
        tradeListings.removeAll { $0.id == listing.id }
        if runtimeMode == .supabase {
            Task {
                do {
                    try await repositories.trades.deleteTradeListing(id: listing.id)
                } catch {
                    await MainActor.run {
                        lastSyncError = Self.tradeSyncMessage
                    }
                }
            }
        }
    }

    func toggleSavedListing(_ listing: TradeListing) {
        guard let index = tradeListings.firstIndex(where: { $0.id == listing.id }) else { return }
        tradeListings[index].isSaved.toggle()
    }

    func sendTradeOffer(
        to listing: TradeListing,
        offeredCards: [Card],
        requestedCards: [Card],
        internalCredits: Int,
        message: String,
        usesSafeTrade: Bool
    ) {
        guard !offeredCards.isEmpty || internalCredits > 0 else { return }
        guard !requestedCards.isEmpty else { return }

        let offer = TradeOffer(
            senderID: repositories.clientProvider.currentSession?.userID,
            receiverID: listing.ownerID,
            partnerName: listing.ownerName,
            partnerHandle: listing.ownerHandle,
            offeredCards: offeredCards,
            requestedCards: requestedCards,
            status: .pending,
            direction: .sent,
            internalCredits: max(internalCredits, 0),
            expiresInDays: 7,
            note: message.isEmpty ? "Trade offer sent from marketplace." : message,
            usesSafeTrade: usesSafeTrade
        )
        tradeOffers.insert(offer, at: 0)

        if runtimeMode == .supabase {
            let requestedItems = collectionItemsForListing(listing, requestedCards: requestedCards)
            syncTradeOffer(offer, receiverID: listing.ownerID, offeredItems: offeredCollectionItems(for: offeredCards), requestedItems: requestedItems)
        }
    }

    func sendTradeOffer(
        to friend: Friend,
        offeredItems: [CollectionItem],
        requestedItems: [CollectionItem],
        internalCredits: Int,
        message: String,
        usesSafeTrade: Bool
    ) {
        guard !offeredItems.isEmpty || internalCredits > 0 else { return }
        guard !requestedItems.isEmpty else { return }

        let offer = TradeOffer(
            senderID: repositories.clientProvider.currentSession?.userID,
            receiverID: friend.id,
            partnerName: friend.displayName,
            partnerHandle: friend.handle,
            offeredCards: offeredItems.map(\.card),
            requestedCards: requestedItems.map(\.card),
            status: .pending,
            direction: .sent,
            internalCredits: max(internalCredits, 0),
            expiresInDays: 7,
            note: message.isEmpty ? "Trade offer sent to \(friend.displayName)." : message,
            usesSafeTrade: usesSafeTrade
        )
        tradeOffers.insert(offer, at: 0)

        if runtimeMode == .supabase {
            syncTradeOffer(offer, receiverID: friend.id, offeredItems: offeredItems, requestedItems: requestedItems)
        }
    }

    func updateTradeOfferStatus(_ offer: TradeOffer, status: TradeStatus) {
        guard let index = tradeOffers.firstIndex(where: { $0.id == offer.id }) else { return }
        tradeOffers[index].status = status
        if runtimeMode == .supabase {
            Task {
                do {
                    try await repositories.trades.updateTradeOfferStatus(id: offer.id, status: status.rawValue)
                    await MainActor.run {
                        if lastSyncError?.contains("Trade offer") == true {
                            lastSyncError = nil
                        }
                    }
                } catch {
                    await MainActor.run {
                        lastSyncError = Self.tradeSyncMessage
                    }
                }
            }
        }
    }

    func updateProfile(_ updatedProfile: UserProfile) async throws {
        let shouldSaveToCloud = runtimeMode != .demo
            && repositories.clientProvider.canCreateClient
            && repositories.clientProvider.currentSession?.userID != nil

        guard shouldSaveToCloud else {
            profile = updatedProfile
            return
        }

        guard let userID = repositories.clientProvider.currentSession?.userID else {
            lastSyncError = Self.cloudConnectionMessage
            throw SupabaseClientError.missingConfiguration
        }

        isSavingProfile = true
        defer { isSavingProfile = false }

        do {
            let profileForCurrentUser = updatedProfile.replacingID(with: userID)
            try await repositories.profiles.upsertProfile(remoteProfile(from: profileForCurrentUser, userID: userID))
            profile = profileForCurrentUser
            runtimeMode = .supabase
            lastSyncError = nil
        } catch {
            lastSyncError = Self.cloudConnectionMessage
            throw error
        }
    }

    func deleteSignedInAccountData() async throws {
        guard let userID = repositories.clientProvider.currentSession?.userID else {
            clearSignedOutState()
            return
        }

        let request = try repositories.clientProvider.restRequest(
            table: "profiles",
            method: .delete,
            queryItems: [URLQueryItem(name: "id", value: "eq.\(userID.uuidString)")],
            prefer: "return=minimal"
        )
        try await repositories.clientProvider.send(request)
        CloudVaultCache.delete(userID: userID)
        clearSignedOutState()
    }

    func reportImagePickerError(_ message: String) {
        imageUploadMessage = message
        isUploadingAvatar = false
        uploadingCardPhotoSide = nil
        lastSyncError = message
    }

    func uploadAvatarImageData(_ data: Data) async throws {
        guard runtimeMode != .demo, let userID = repositories.clientProvider.currentSession?.userID else {
            lastSyncError = Self.imageUploadSignInMessage
            imageUploadMessage = "We couldn’t save your profile picture. Please try again."
            isUploadingAvatar = false
            throw ImageUploadError.missingSession
        }

        guard repositories.clientProvider.canCreateClient else {
            lastSyncError = Self.imageUploadMessage
            imageUploadMessage = "We couldn’t save your profile picture. Please try again."
            isUploadingAvatar = false
            throw SupabaseClientError.missingConfiguration
        }

        isUploadingAvatar = true
        imageUploadMessage = nil
        defer { isUploadingAvatar = false }
        do {
            let service = ImageUploadService(storage: repositories.storage)
            let urlString = try await service.uploadAvatar(userID: userID, imageData: data)
            var updatedProfile = profile.replacingID(with: userID)
            updatedProfile.avatarURL = URL(string: Self.cacheBustedAvatarURL(urlString))
            try await repositories.profiles.upsertProfile(remoteProfile(from: updatedProfile, userID: userID))
            if let refreshedProfile = try? await repositories.profiles.fetchCurrentProfile(userID: userID) {
                profile = refreshedProfile.localProfile(favoriteSet: profile.favoriteSet)
            } else {
                profile = updatedProfile
            }
            runtimeMode = .supabase
            imageUploadMessage = "Profile picture saved"
            lastSyncError = nil
        } catch {
            imageUploadMessage = "We couldn’t save your profile picture. Please try again."
            lastSyncError = Self.imageUploadMessage
            throw error
        }
    }

    private static func cacheBustedAvatarURL(_ urlString: String) -> String {
        guard var components = URLComponents(string: urlString) else { return urlString }
        components.queryItems = [URLQueryItem(name: "v", value: "\(Int(Date().timeIntervalSince1970))")]
        return components.url?.absoluteString ?? urlString
    }

    func uploadAvatarImageData(_ data: Data) {
        Task {
            do {
                try await uploadAvatarImageData(data)
            } catch {
                await MainActor.run {
                    isUploadingAvatar = false
                }
            }
        }
    }

    func uploadCardPhotoImageData(_ data: Data, for item: CollectionItem, side: CardPhotoSide) {
        guard runtimeMode == .supabase, let userID = repositories.clientProvider.currentSession?.userID else {
            lastSyncError = Self.imageUploadSignInMessage
            return
        }

        uploadingCardPhotoSide = side
        imageUploadMessage = "Preparing \(side.displayName.lowercased()) photo..."
        Task {
            do {
                let service = ImageUploadService(storage: repositories.storage)
                let urlString = try await service.uploadCardPhoto(
                    userID: userID,
                    collectionItemID: item.id,
                    side: side,
                    imageData: data
                )
                await MainActor.run {
                    guard let index = collectionItems.firstIndex(where: { $0.id == item.id }) else {
                        imageUploadMessage = nil
                        uploadingCardPhotoSide = nil
                        lastSyncError = "\(side.displayName) photo upload failed: collection item was not found."
                        return
                    }
                    let url = URL(string: urlString)
                    switch side {
                    case .front:
                        collectionItems[index].frontPhotoURL = url
                    case .back:
                        collectionItems[index].backPhotoURL = url
                    }
                    imageUploadMessage = "\(side.displayName) photo uploaded"
                    uploadingCardPhotoSide = nil
                    syncCollectionItem(collectionItems[index])
                    if lastSyncError?.contains("upload") == true || lastSyncError?.contains("Collection save failed") == true {
                        lastSyncError = nil
                    }
                }
            } catch {
                await MainActor.run {
                    imageUploadMessage = nil
                    uploadingCardPhotoSide = nil
                    lastSyncError = Self.imageUploadMessage
                }
            }
        }
    }

    func resetDemoUserState(repository: DemoVaultRepository = .shared) {
        sets = repository.sets
        cards = repository.cards
        profile = repository.profile
        collectionItems = repository.collectionItems
        wishlistItems = repository.wishlistItems
        binderPages = repository.binderPages
        friends = repository.friends
        friendRequests = repository.friendRequests
        friendWants = repository.friendWants
        tradeListings = repository.tradeListings
        tradeOffers = repository.tradeOffers
        events = repository.events
    }

    func addMissingCardToWishlist(_ card: Card) {
        guard collectionItem(for: card) == nil else { return }
        addToWishlist(card, priority: .high, budget: card.marketValue, notes: "Added from Pokédex missing tracker.")
    }

    func cacheViewedCard(_ card: Card) {
        guard runtimeMode == .supabase else { return }
        Task {
            do {
                try await repositories.cards.upsertSet(card.remoteSet)
                try await repositories.cards.upsertCard(card.remoteCard)
            } catch {
                return
            }
        }
    }

    func addEvent(_ event: VaultEvent) {
        events.append(event)
        events.sort { $0.date < $1.date }
    }

    func updateEvent(_ event: VaultEvent) {
        guard let index = events.firstIndex(where: { $0.id == event.id }) else { return }
        events[index] = event
        events.sort { $0.date < $1.date }
    }

    func deleteEvent(_ event: VaultEvent) {
        events.removeAll { $0.id == event.id }
    }

    func createBinderPage(title: String? = nil) -> BinderPage {
        let pageNumber = binderPages.count + 1
        let page = BinderPage(
            title: title ?? "Binder Page \(pageNumber)",
            theme: "Custom vault layout",
            slots: Self.emptyBinderSlots(),
            visibility: .private,
            updatedAt: .now
        )
        binderPages.insert(page, at: 0)
        return page
    }

    func renameBinderPage(_ pageID: BinderPage.ID, title: String) {
        guard let page = binderPages.first(where: { $0.id == pageID }) else { return }
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        updateBinderPage(
            BinderPage(
                id: page.id,
                title: trimmed.isEmpty ? page.title : trimmed,
                theme: page.theme,
                slots: page.slots,
                visibility: page.visibility,
                updatedAt: .now
            )
        )
    }

    func updateBinderVisibility(_ pageID: BinderPage.ID, visibility: BinderVisibility) {
        guard let page = binderPages.first(where: { $0.id == pageID }) else { return }
        updateBinderPage(
            BinderPage(
                id: page.id,
                title: page.title,
                theme: page.theme,
                slots: page.slots,
                visibility: visibility,
                updatedAt: .now
            )
        )
    }

    func updateBinderSlot(pageID: BinderPage.ID, slotID: BinderSlot.ID, card: Card?) {
        guard let page = binderPages.first(where: { $0.id == pageID }) else { return }
        let slots = page.slots.map { slot in
            slot.id == slotID ? BinderSlot(id: slot.id, index: slot.index, card: card, note: slot.note) : slot
        }
        updateBinderPage(
            BinderPage(
                id: page.id,
                title: page.title,
                theme: page.theme,
                slots: slots,
                visibility: page.visibility,
                updatedAt: .now
            )
        )
    }

    func deleteBinderPage(_ pageID: BinderPage.ID) {
        binderPages.removeAll { $0.id == pageID }
    }

    func updateBinderPage(_ page: BinderPage) {
        guard let index = binderPages.firstIndex(where: { $0.id == page.id }) else { return }
        binderPages[index] = page
    }

    static func emptyBinderSlots() -> [BinderSlot] {
        (1...9).map { BinderSlot(index: $0, card: nil) }
    }

    private func syncProfile(_ profile: UserProfile) {
        guard runtimeMode == .supabase, let userID = repositories.clientProvider.currentSession?.userID else { return }
        let remoteProfile = remoteProfile(from: profile, userID: userID)
        Task { try? await repositories.profiles.upsertProfile(remoteProfile) }
    }

    private func remoteProfile(from profile: UserProfile, userID: UUID? = nil) -> RemoteProfile {
        let profileID = userID ?? profile.id
        let remoteProfile = RemoteProfile(
            id: profileID,
            username: profile.handle.replacingOccurrences(of: "@", with: ""),
            displayName: profile.displayName,
            location: profile.location,
            bio: profile.bio,
            collectorType: profile.collectorType,
            avatarURL: profile.avatarURL?.absoluteString,
            avatarPath: nil,
            reputationScore: profile.reputationScore,
            trustBadges: profile.trustBadges,
            completedTrades: profile.completedTrades,
            collectorScore: profile.collectorScore,
            profileVisibility: "public",
            collectionVisibility: "friends",
            wishlistVisibility: "friends",
            createdAt: nil,
            updatedAt: nil
        )
        return remoteProfile
    }

    private func syncCollectionItem(_ item: CollectionItem) {
        guard runtimeMode == .supabase, let userID = repositories.clientProvider.currentSession?.userID else { return }
        let remoteItem = RemoteCollectionItem(
            id: item.id,
            ownerID: userID,
            cardID: item.card.id,
            quantity: item.quantity,
            condition: item.condition.rawValue,
            variant: item.variant.rawValue,
            language: item.language,
            gradedCompany: item.gradedCompany,
            gradedScore: item.gradedScore,
            notes: item.notes,
            visibility: item.visibility.rawValue,
            isAvailableForTrade: item.isAvailableForTrade,
            isAvailableForCredits: item.isAvailableForCredits,
            askingCredits: item.askingCredits,
            frontPhotoURL: item.frontPhotoURL?.absoluteString,
            backPhotoURL: item.backPhotoURL?.absoluteString,
            isFavorite: item.isFavorite,
            acquiredAt: item.acquiredAt
        )
        Task {
            do {
                try await repositories.cards.upsertSet(item.card.remoteSet)
                try await repositories.cards.upsertCard(item.card.remoteCard)
                try await repositories.collection.upsertCollectionItem(remoteItem)
                await MainActor.run {
                    if lastSyncError?.contains("Collection save failed") == true {
                        lastSyncError = nil
                    }
                }
            } catch {
                await MainActor.run {
                    lastSyncError = Self.collectionSyncMessage
                }
            }
        }
    }

    private func syncWishlistItem(_ item: WishlistItem) {
        guard runtimeMode == .supabase, let userID = repositories.clientProvider.currentSession?.userID else { return }
        let remoteItem = RemoteWishlistItem(
            id: item.id,
            userID: userID,
            cardID: item.card.id,
            priority: item.priority.rawValue,
            preferredCondition: item.preferredCondition.rawValue,
            budget: item.budget,
            notes: item.notes,
            addedAt: item.addedAt
        )
        Task {
            do {
                try await repositories.cards.upsertSet(item.card.remoteSet)
                try await repositories.cards.upsertCard(item.card.remoteCard)
                try await repositories.wishlist.upsertWishlistItem(remoteItem)
                await MainActor.run {
                    if lastSyncError?.contains("Wants save failed") == true {
                        lastSyncError = nil
                    }
                }
            } catch {
                await MainActor.run {
                    lastSyncError = Self.wantsSyncMessage
                }
            }
        }
    }

    private func syncTradeListing(_ listing: TradeListing) {
        guard runtimeMode == .supabase,
              let ownerID = repositories.clientProvider.currentSession?.userID
        else { return }

        let remoteListing = RemoteTradeListing(
            id: listing.id,
            ownerID: ownerID,
            cardID: listing.card.id,
            collectionItemID: listing.collectionItemID,
            title: listing.card.name,
            condition: listing.condition.rawValue,
            variant: listing.variant.rawValue,
            rarity: listing.card.rarity.rawValue,
            estimatedValue: listing.estimatedValue,
            listingKind: listing.listingKind.rawValue,
            askingCredits: listing.askingCredits,
            description: listing.description.nilIfBlank,
            askingFor: listing.askingFor,
            sellerDisplayName: profile.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Collector" : profile.displayName,
            locationLabel: listing.locationLabel,
            sellerReputation: listing.sellerReputation,
            isPublic: true,
            status: "active",
            usesSafeTrade: listing.usesSafeTrade,
            listedAt: listing.listedAt
        )

        Task {
            do {
                try await repositories.cards.upsertSet(listing.card.remoteSet)
                try await repositories.cards.upsertCard(listing.card.remoteCard)
                try await repositories.trades.upsertTradeListing(remoteListing)
                await MainActor.run {
                    if lastSyncError?.contains("listing") == true {
                        lastSyncError = nil
                    }
                }
            } catch {
                await MainActor.run {
                    lastSyncError = Self.tradeSyncMessage
                }
            }
        }
    }

    private func offeredCollectionItems(for cards: [Card]) -> [CollectionItem] {
        let cardIDs = Set(cards.map(\.id))
        return collectionItems.filter { cardIDs.contains($0.card.id) }
    }

    private func collectionItemsForListing(_ listing: TradeListing, requestedCards: [Card]) -> [CollectionItem] {
        if let collectionItemID = listing.collectionItemID {
            return requestedCards.map { card in
                CollectionItem(
                    id: collectionItemID,
                    card: card,
                    quantity: 1,
                    condition: listing.condition,
                    variant: listing.variant,
                    isAvailableForTrade: true,
                    visibility: .friends
                )
            }
        }
        return requestedCards.map { card in
            CollectionItem(
                card: card,
                quantity: 1,
                condition: listing.condition,
                variant: listing.variant,
                isAvailableForTrade: true,
                visibility: .public
            )
        }
    }

    private func syncTradeOffer(_ offer: TradeOffer, receiverID: UUID?, offeredItems: [CollectionItem], requestedItems: [CollectionItem]) {
        guard runtimeMode == .supabase,
              let senderID = repositories.clientProvider.currentSession?.userID,
              let receiverID,
              senderID != receiverID
        else {
            lastSyncError = "Trade offer save failed: this listing is missing a cloud friend owner."
            return
        }

        let remoteOffer = RemoteTradeOffer(
            id: offer.id,
            senderID: senderID,
            receiverID: receiverID,
            offeredCardIDs: offer.offeredCards.map(\.id),
            requestedCardIDs: offer.requestedCards.map(\.id),
            internalCredits: offer.internalCredits,
            message: offer.note,
            status: offer.status.rawValue,
            usesSafeTrade: offer.usesSafeTrade,
            createdAt: offer.createdAt
        )
        let remoteOfferedItems = offeredItems.map { item in
            RemoteTradeOfferItem(
                id: UUID(),
                tradeOfferID: offer.id,
                ownerID: senderID,
                cardID: item.card.id,
                collectionItemID: item.id,
                side: "offered",
                quantity: 1,
                estimatedValue: item.card.marketValue,
                createdAt: nil
            )
        }
        let remoteRequestedItems = requestedItems.map { item in
            RemoteTradeOfferItem(
                id: UUID(),
                tradeOfferID: offer.id,
                ownerID: receiverID,
                cardID: item.card.id,
                collectionItemID: item.id,
                side: "requested",
                quantity: 1,
                estimatedValue: item.card.marketValue,
                createdAt: nil
            )
        }

        Task {
            do {
                let cardsToCache = offer.offeredCards + offer.requestedCards
                for card in cardsToCache {
                    try await repositories.cards.upsertSet(card.remoteSet)
                    try await repositories.cards.upsertCard(card.remoteCard)
                }
                try await repositories.trades.upsertTradeOffer(remoteOffer)
                try await repositories.trades.upsertTradeOfferItems(remoteOfferedItems + remoteRequestedItems)
                await MainActor.run {
                    if lastSyncError?.contains("Trade offer save failed") == true {
                        lastSyncError = nil
                    }
                }
            } catch {
                await MainActor.run {
                    lastSyncError = Self.tradeSyncMessage
                }
            }
        }
    }
}

private struct CloudVaultSnapshot: Codable {
    var profile: RemoteProfile?
    let sets: [RemoteCardSet]
    let cards: [RemoteCard]
    let collection: [RemoteCollectionItem]
    let wishlist: [RemoteWishlistItem]
    let friends: [RemoteFriendship]
    let friendRequests: [RemoteFriendRequest]?
    let friendProfiles: [RemoteProfile]?
    let visibleFriendData: [RemoteFriendVisibleData]?
    let tradeOffers: [RemoteTradeOffer]
    let tradeOfferItems: [RemoteTradeOfferItem]?
    let marketplaceListings: [RemoteMarketplaceListing]
    let events: [RemoteVaultEvent]

    static func empty(profile: RemoteProfile?) -> CloudVaultSnapshot {
        CloudVaultSnapshot(
            profile: profile,
            sets: [],
            cards: [],
            collection: [],
            wishlist: [],
            friends: [],
            friendRequests: [],
            friendProfiles: [],
            visibleFriendData: [],
            tradeOffers: [],
            tradeOfferItems: [],
            marketplaceListings: [],
            events: []
        )
    }
}

private struct RemoteFriendVisibleData: Codable {
    let friendID: UUID
    let collection: [RemoteCollectionItem]
    let wishlist: [RemoteWishlistItem]
}

private enum CloudVaultCache {
    static func load(userID: UUID) -> CloudVaultSnapshot? {
        guard let data = try? Data(contentsOf: cacheURL(userID: userID)) else { return nil }
        return try? JSONDecoder.supabase.decode(CloudVaultSnapshot.self, from: data)
    }

    static func save(_ snapshot: CloudVaultSnapshot, userID: UUID) {
        do {
            let url = cacheURL(userID: userID)
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try JSONEncoder.supabase.encode(snapshot)
            try data.write(to: url, options: [.atomic])
        } catch {
            VaultDexLogger.warning("Cloud cache write failed")
        }
    }

    static func delete(userID: UUID) {
        try? FileManager.default.removeItem(at: cacheURL(userID: userID))
    }

    private static func cacheURL(userID: UUID) -> URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appending(path: "VaultDex")
            .appending(path: "vaultdex-cloud-cache-\(userID.uuidString).json")
    }
}

private extension RemoteCardSet {
    var localSet: CardSet {
        CardSet(id: id, name: name, code: code, releaseYear: releaseYear, totalCards: totalCards)
    }
}

private extension Card {
    var remoteSet: RemoteCardSet {
        RemoteCardSet(
            id: set.id,
            name: set.name,
            code: set.code,
            releaseYear: set.releaseYear,
            totalCards: set.totalCards
        )
    }

    var remoteCard: RemoteCard {
        RemoteCard(
            id: id,
            setID: set.id,
            name: name,
            number: number,
            rarity: rarity.rawValue,
            cardType: cardType.rawValue,
            typeLine: typeLine,
            power: power,
            marketValue: marketValue,
            accent: accent.rawValue,
            imagePath: smallImageURL?.absoluteString,
            artistName: artist
        )
    }
}

private extension RemoteCard {
    func localCard(set: CardSet) -> Card {
        Card(
            id: id,
            name: name,
            set: set,
            number: number,
            rarity: CardRarity(rawValue: rarity) ?? .common,
            cardType: CardType(rawValue: cardType) ?? .colorless,
            typeLine: typeLine,
            power: power,
            condition: .nearMint,
            marketValue: marketValue,
            accent: CardAccent(rawValue: accent) ?? .aurora,
            artist: artistName,
            smallImageURL: imagePath.flatMap(URL.init(string:))
        )
    }
}

private extension RemoteProfile {
    func localProfile(favoriteSet: CardSet) -> UserProfile {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        return UserProfile(
            id: id,
            displayName: displayName,
            handle: trimmedUsername.isEmpty ? "" : "@\(trimmedUsername)",
            location: location ?? "",
            bio: bio ?? "",
            collectorType: collectorType ?? "",
            avatarSymbol: "person.crop.circle.fill",
            avatarURL: avatarURL.flatMap(URL.init(string:)),
            reputationScore: reputationScore,
            trustBadges: trustBadges,
            completedTrades: completedTrades,
            collectorScore: collectorScore,
            favoriteSet: favoriteSet,
            joinedDate: createdAt ?? .now,
            followers: 0,
            following: 0
        )
    }
}

private extension RemoteCollectionItem {
    func localItem(card: Card?) -> CollectionItem? {
        guard let card else { return nil }
        return CollectionItem(
            id: id,
            card: card,
            quantity: quantity,
            condition: CardCondition(rawValue: condition) ?? .nearMint,
            variant: CardVariant(rawValue: variant) ?? .normal,
            isAvailableForTrade: isAvailableForTrade,
            language: language,
            gradedCompany: gradedCompany,
            gradedScore: gradedScore,
            visibility: CollectionVisibility(rawValue: visibility) ?? .private,
            isAvailableForCredits: isAvailableForCredits,
            askingCredits: askingCredits,
            isFavorite: isFavorite,
            acquiredAt: acquiredAt,
            notes: notes,
            frontPhotoURL: frontPhotoURL.flatMap(URL.init(string:)),
            backPhotoURL: backPhotoURL.flatMap(URL.init(string:))
        )
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

private extension TradeListingKind {
    func defaultAskText(askingCredits: Int?) -> String {
        switch self {
        case .trade:
            return "Open to fair trade offers"
        case .credits:
            return askingCredits.map { "Asking \($0) credits" } ?? "Open to credit offers"
        case .both:
            if let askingCredits {
                return "Open to trades or \((askingCredits)) credits"
            }
            return "Open to trades or credits"
        }
    }
}

private extension RemoteWishlistItem {
    func localItem(card: Card?) -> WishlistItem? {
        guard let card else { return nil }
        return WishlistItem(
            id: id,
            card: card,
            priority: WishlistPriority(rawValue: priority) ?? .medium,
            preferredCondition: CardCondition(rawValue: preferredCondition) ?? .nearMint,
            budget: budget,
            notes: notes,
            addedAt: addedAt
        )
    }
}

private extension RemoteMarketplaceListing {
    func localListing(card: Card?, currentUserID: UUID) -> TradeListing? {
        guard let card else { return nil }
        return TradeListing(
            id: id,
            ownerID: ownerID,
            collectionItemID: collectionItemID,
            ownerName: sellerDisplayName ?? "Cloud Collector",
            ownerHandle: ownerID == currentUserID ? "@me" : "@collector",
            card: card,
            condition: CardCondition(rawValue: condition) ?? .nearMint,
            variant: CardVariant(rawValue: variant ?? "normal") ?? .normal,
            listingKind: TradeListingKind(rawValue: listingKind ?? "trade") ?? .trade,
            askingFor: askingFor ?? "Open to fair offers",
            askingCredits: askingCredits,
            description: description ?? "",
            listedAt: listedAt ?? .now,
            locationLabel: locationLabel ?? "Cloud listing",
            sellerReputation: sellerReputation,
            isFeatured: rarity == "mythic" || rarity == "legendary",
            isSaved: isSaved ?? false,
            isMine: ownerID == currentUserID,
            usesSafeTrade: usesSafeTrade ?? false
        )
    }
}

private extension RemoteTradeOffer {
    func localOffer(
        cards: [UUID: Card],
        items: [RemoteTradeOfferItem],
        profiles: [UUID: RemoteProfile],
        currentUserID: UUID
    ) -> TradeOffer {
        let partnerID = senderID == currentUserID ? receiverID : senderID
        let partner = profiles[partnerID]
        let offeredFromItems = items
            .filter { $0.side == "offered" }
            .compactMap { cards[$0.cardID] }
        let requestedFromItems = items
            .filter { $0.side == "requested" }
            .compactMap { cards[$0.cardID] }
        return TradeOffer(
            id: id,
            senderID: senderID,
            receiverID: receiverID,
            partnerName: partner?.displayName.nilIfBlank ?? (senderID == currentUserID ? "Cloud Collector" : "Trade Partner"),
            partnerHandle: partner?.username.nilIfBlank.map { "@\($0)" } ?? (senderID == currentUserID ? "@sent" : "@received"),
            offeredCards: offeredFromItems.isEmpty ? offeredCardIDs.compactMap { cards[$0] } : offeredFromItems,
            requestedCards: requestedFromItems.isEmpty ? requestedCardIDs.compactMap { cards[$0] } : requestedFromItems,
            status: TradeStatus(rawValue: status) ?? .pending,
            direction: senderID == currentUserID ? .sent : .received,
            internalCredits: internalCredits,
            createdAt: createdAt ?? .now,
            expiresInDays: 7,
            note: message,
            usesSafeTrade: usesSafeTrade
        )
    }
}

private extension RemoteVaultEvent {
    func localEvent(featuredSet: CardSet) -> VaultEvent {
        VaultEvent(
            id: id,
            title: title,
            venue: location,
            date: eventDate,
            kind: VaultEventKind(rawValue: "tradeNight") ?? .community,
            prize: "Community event",
            attendingFriends: 0,
            featuredSet: featuredSet,
            emojiMarker: emojiMarker,
            notes: notes,
            visibility: BinderVisibility(rawValue: visibility) ?? .public
        )
    }
}

private extension UserProfile {
    func replacingID(with id: UUID) -> UserProfile {
        UserProfile(
            id: id,
            displayName: displayName,
            handle: handle,
            location: location,
            bio: bio,
            collectorType: collectorType,
            avatarSymbol: avatarSymbol,
            avatarURL: avatarURL,
            reputationScore: reputationScore,
            trustBadges: trustBadges,
            completedTrades: completedTrades,
            collectorScore: collectorScore,
            favoriteSet: favoriteSet,
            joinedDate: joinedDate,
            followers: followers,
            following: following
        )
    }
}

private extension RemoteFriendship {
    func friendID(for currentUserID: UUID) -> UUID {
        requesterID == currentUserID ? addresseeID : requesterID
    }

    func localFriend(
        profile: RemoteProfile?,
        visibleData: RemoteFriendVisibleData?,
        cards: [Card],
        cardByID: [UUID: Card],
        currentUserID: UUID
    ) -> Friend? {
        let friendID = friendID(for: currentUserID)
        let displayName = profile?.displayName.nilIfBlank ?? "Cloud Friend"
        let handle = profile?.username.nilIfBlank.map { "@\($0)" } ?? "@\(friendID.uuidString.prefix(8))"
        let visibleCollection = visibleData?.collection.compactMap { $0.localItem(card: cardByID[$0.cardID]) } ?? []
        let visibleWishlist = visibleData?.wishlist.compactMap { $0.localItem(card: cardByID[$0.cardID]) } ?? []
        return Friend(
            id: friendID,
            friendshipID: id,
            displayName: displayName,
            handle: handle,
            avatarSymbol: "person.2.fill",
            collectorScore: profile?.collectorScore ?? 0,
            favoriteCard: visibleCollection.first?.card ?? visibleWishlist.first?.card ?? cards.first,
            completionPercent: min(Double(visibleCollection.count) / 100.0, 1.0),
            mutualTrades: profile?.completedTrades ?? 0,
            isOnline: false,
            collectionVisibility: BinderVisibility(rawValue: profile?.collectionVisibility ?? "friends") ?? .friends,
            wishlistVisibility: BinderVisibility(rawValue: profile?.wishlistVisibility ?? "friends") ?? .friends,
            visibleCollection: visibleCollection,
            wishlist: visibleWishlist
        )
    }
}

private extension RemoteFriendRequest {
    func otherUserID(for currentUserID: UUID) -> UUID {
        requesterID == currentUserID ? addresseeID : requesterID
    }

    func localRequest(profile: RemoteProfile?, currentUserID: UUID, previewCard: Card?) -> FriendRequest {
        let direction: FriendRequestDirection = requesterID == currentUserID ? .outgoing : .incoming
        let fallbackID = otherUserID(for: currentUserID)
        return FriendRequest(
            id: id,
            requesterID: requesterID,
            addresseeID: addresseeID,
            displayName: profile?.displayName.nilIfBlank ?? "Cloud Collector",
            handleOrEmail: profile?.username.nilIfBlank.map { "@\($0)" } ?? "@\(fallbackID.uuidString.prefix(8))",
            avatarSymbol: direction == .incoming ? "person.crop.circle.badge.plus" : "paperplane.fill",
            direction: direction,
            requestedAt: createdAt ?? .now,
            previewCard: previewCard
        )
    }
}
