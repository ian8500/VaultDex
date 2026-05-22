import Foundation

enum WishlistPriority: String, CaseIterable, Identifiable, Hashable {
    case low
    case medium
    case high
    case grail

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .low: "Low"
        case .medium: "Medium"
        case .high: "High"
        case .grail: "Grail"
        }
    }
}

struct WishlistItem: Identifiable, Hashable {
    let id: UUID
    let card: Card
    var priority: WishlistPriority
    var budget: Double
    var notes: String
    var addedAt: Date

    init(
        id: UUID = UUID(),
        card: Card,
        priority: WishlistPriority,
        budget: Double,
        notes: String,
        addedAt: Date = .now
    ) {
        self.id = id
        self.card = card
        self.priority = priority
        self.budget = budget
        self.notes = notes
        self.addedAt = addedAt
    }
}

struct FriendWant: Identifiable, Hashable {
    let id: UUID
    let friend: Friend
    let card: Card
    let priority: WishlistPriority
    let note: String

    init(
        id: UUID = UUID(),
        friend: Friend,
        card: Card,
        priority: WishlistPriority,
        note: String
    ) {
        self.id = id
        self.friend = friend
        self.card = card
        self.priority = priority
        self.note = note
    }
}

enum FriendRequestDirection: String, CaseIterable, Identifiable, Hashable {
    case incoming
    case outgoing

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .incoming: "Incoming"
        case .outgoing: "Outgoing"
        }
    }
}

struct FriendRequest: Identifiable, Hashable {
    let id: UUID
    let displayName: String
    let handleOrEmail: String
    let avatarSymbol: String
    let direction: FriendRequestDirection
    let requestedAt: Date
    let previewCard: Card?

    init(
        id: UUID = UUID(),
        displayName: String,
        handleOrEmail: String,
        avatarSymbol: String,
        direction: FriendRequestDirection,
        requestedAt: Date = .now,
        previewCard: Card? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.handleOrEmail = handleOrEmail
        self.avatarSymbol = avatarSymbol
        self.direction = direction
        self.requestedAt = requestedAt
        self.previewCard = previewCard
    }
}

struct Friend: Identifiable, Hashable {
    let id: UUID
    let displayName: String
    let handle: String
    let email: String
    let avatarSymbol: String
    let collectorScore: Int
    let favoriteCard: Card
    let completionPercent: Double
    let mutualTrades: Int
    let isOnline: Bool
    let collectionVisibility: BinderVisibility
    let wishlistVisibility: BinderVisibility
    let visibleCollection: [CollectionItem]
    let wishlist: [WishlistItem]

    init(
        id: UUID = UUID(),
        displayName: String,
        handle: String,
        email: String = "",
        avatarSymbol: String,
        collectorScore: Int,
        favoriteCard: Card,
        completionPercent: Double,
        mutualTrades: Int,
        isOnline: Bool,
        collectionVisibility: BinderVisibility = .friends,
        wishlistVisibility: BinderVisibility = .friends,
        visibleCollection: [CollectionItem] = [],
        wishlist: [WishlistItem] = []
    ) {
        self.id = id
        self.displayName = displayName
        self.handle = handle
        self.email = email
        self.avatarSymbol = avatarSymbol
        self.collectorScore = collectorScore
        self.favoriteCard = favoriteCard
        self.completionPercent = completionPercent
        self.mutualTrades = mutualTrades
        self.isOnline = isOnline
        self.collectionVisibility = collectionVisibility
        self.wishlistVisibility = wishlistVisibility
        self.visibleCollection = visibleCollection
        self.wishlist = wishlist
    }
}

struct FriendTradeOpportunity: Identifiable, Hashable {
    let id: UUID
    let friend: Friend
    let theyOwn: [CollectionItem]
    let youOwn: [CollectionItem]

    init(
        id: UUID = UUID(),
        friend: Friend,
        theyOwn: [CollectionItem],
        youOwn: [CollectionItem]
    ) {
        self.id = id
        self.friend = friend
        self.theyOwn = theyOwn
        self.youOwn = youOwn
    }

    var score: Int {
        theyOwn.count + youOwn.count
    }
}

struct BinderSlot: Identifiable, Hashable {
    let id: UUID
    let index: Int
    let card: Card?
    let note: String

    init(id: UUID = UUID(), index: Int, card: Card?, note: String = "") {
        self.id = id
        self.index = index
        self.card = card
        self.note = note
    }
}

enum BinderVisibility: String, CaseIterable, Identifiable, Hashable {
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

    var systemImage: String {
        switch self {
        case .private: "lock.fill"
        case .friends: "person.2.fill"
        case .public: "globe"
        }
    }
}

struct BinderPage: Identifiable, Hashable {
    let id: UUID
    let title: String
    let theme: String
    let slots: [BinderSlot]
    let visibility: BinderVisibility
    let updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        theme: String,
        slots: [BinderSlot],
        visibility: BinderVisibility = .private,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.theme = theme
        self.slots = slots
        self.visibility = visibility
        self.updatedAt = updatedAt
    }
}

struct TradeListing: Identifiable, Hashable {
    let id: UUID
    let ownerName: String
    let ownerHandle: String
    let card: Card
    let askingFor: String
    let listedAt: Date
    let locationLabel: String
    let isFeatured: Bool

    init(
        id: UUID = UUID(),
        ownerName: String,
        ownerHandle: String,
        card: Card,
        askingFor: String,
        listedAt: Date = .now,
        locationLabel: String,
        isFeatured: Bool = false
    ) {
        self.id = id
        self.ownerName = ownerName
        self.ownerHandle = ownerHandle
        self.card = card
        self.askingFor = askingFor
        self.listedAt = listedAt
        self.locationLabel = locationLabel
        self.isFeatured = isFeatured
    }
}

enum VaultEventKind: String, CaseIterable, Identifiable, Hashable {
    case tournament
    case tradeNight
    case release
    case community

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .tournament: "Tournament"
        case .tradeNight: "Trade Night"
        case .release: "Release"
        case .community: "Community"
        }
    }
}

struct VaultEvent: Identifiable, Hashable {
    let id: UUID
    let title: String
    let venue: String
    let date: Date
    let kind: VaultEventKind
    let prize: String
    let attendingFriends: Int
    let featuredSet: CardSet

    init(
        id: UUID = UUID(),
        title: String,
        venue: String,
        date: Date,
        kind: VaultEventKind,
        prize: String,
        attendingFriends: Int,
        featuredSet: CardSet
    ) {
        self.id = id
        self.title = title
        self.venue = venue
        self.date = date
        self.kind = kind
        self.prize = prize
        self.attendingFriends = attendingFriends
        self.featuredSet = featuredSet
    }
}

struct ImportPreviewItem: Identifiable, Hashable {
    let id: UUID
    let sourceName: String
    let card: Card
    let quantity: Int
    let condition: CardCondition
    let confidence: Double

    init(
        id: UUID = UUID(),
        sourceName: String,
        card: Card,
        quantity: Int,
        condition: CardCondition,
        confidence: Double
    ) {
        self.id = id
        self.sourceName = sourceName
        self.card = card
        self.quantity = quantity
        self.condition = condition
        self.confidence = confidence
    }
}

struct InviteContact: Identifiable, Hashable {
    let id: UUID
    let name: String
    let handleHint: String
    let channel: String
    let isInvited: Bool

    init(
        id: UUID = UUID(),
        name: String,
        handleHint: String,
        channel: String,
        isInvited: Bool
    ) {
        self.id = id
        self.name = name
        self.handleHint = handleHint
        self.channel = channel
        self.isInvited = isInvited
    }
}
