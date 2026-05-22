import Foundation

@MainActor
final class ImportCollectionViewModel: ObservableObject {
    @Published private(set) var previewItems: [ImportPreviewItem]

    init(repository: DemoVaultRepository = .shared) {
        previewItems = repository.importPreviewItems
    }

    var totalCopies: Int {
        previewItems.reduce(0) { $0 + $1.quantity }
    }

    var estimatedValue: Double {
        previewItems.reduce(0) { $0 + ($1.card.marketValue * Double($1.quantity)) }
    }

    var averageConfidence: Double {
        guard !previewItems.isEmpty else { return 0 }
        return previewItems.reduce(0) { $0 + $1.confidence } / Double(previewItems.count)
    }
}

@MainActor
final class WishlistViewModel: ObservableObject {
    func highPriorityItems(in store: LocalVaultStore) -> [WishlistItem] {
        store.wishlistItems.filter { $0.priority == .grail || $0.priority == .high }
    }

    func targetValue(in store: LocalVaultStore) -> Double {
        store.wishlistItems.reduce(0) { $0 + $1.budget }
    }
}

@MainActor
final class FriendsViewModel: ObservableObject {
    @Published private(set) var friends: [Friend]

    init(repository: DemoVaultRepository = .shared) {
        friends = repository.friends
    }

    var onlineFriends: [Friend] {
        friends.filter(\.isOnline)
    }

    var topCollectors: [Friend] {
        friends.sorted { $0.collectorScore > $1.collectorScore }
    }
}

@MainActor
final class BinderDesignerViewModel: ObservableObject {
    @Published private(set) var pages: [BinderPage]

    init(repository: DemoVaultRepository = .shared) {
        pages = repository.binderPages
    }

    var filledSlots: Int {
        pages.flatMap(\.slots).filter { $0.card != nil }.count
    }

    var totalSlots: Int {
        pages.flatMap(\.slots).count
    }
}

@MainActor
final class CompletionTrackerViewModel: ObservableObject {
    func setProgress(in store: LocalVaultStore) -> [SetProgress] {
        store.sets.map { set in
            let owned = Set(store.collectionItems.filter { $0.card.set == set }.map(\.card.id)).count
            let total = store.cards.filter { $0.set == set }.count
            return SetProgress(cardSet: set, owned: owned, total: max(total, 1))
        }
    }

    func overallFraction(in store: LocalVaultStore) -> Double {
        guard !store.cards.isEmpty else { return 0 }
        let owned = Set(store.collectionItems.map(\.card.id)).count
        return Double(owned) / Double(store.cards.count)
    }

    func missingCards(in store: LocalVaultStore) -> [Card] {
        let ownedIDs = Set(store.collectionItems.map(\.card.id))
        return store.cards.filter { !ownedIDs.contains($0.id) }
    }
}

@MainActor
final class EventsViewModel: ObservableObject {
    @Published private(set) var events: [VaultEvent]

    init(repository: DemoVaultRepository = .shared) {
        events = repository.events
    }

    var upcomingEvents: [VaultEvent] {
        events.filter { $0.date >= .now }.sorted { $0.date < $1.date }
    }
}

@MainActor
final class InviteFriendsViewModel: ObservableObject {
    @Published private(set) var contacts: [InviteContact]
    let inviteCode = "VAULT-8420"

    init(repository: DemoVaultRepository = .shared) {
        contacts = repository.inviteContacts
    }

    var pendingContacts: [InviteContact] {
        contacts.filter { !$0.isInvited }
    }
}

@MainActor
final class AccountDeletionViewModel: ObservableObject {
    @Published var confirmationText = ""

    let checklist = [
        "Export collection history",
        "Close active trade offers",
        "Remove social profile",
        "Delete local demo data"
    ]

    var canRequestDeletion: Bool {
        confirmationText == "DELETE"
    }
}
