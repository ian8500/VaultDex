import Foundation

struct DashboardActivity: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let systemImage: String
}

@MainActor
final class DashboardViewModel: ObservableObject {
    func completionPercent(in store: LocalVaultStore) -> Double {
        guard !store.cards.isEmpty else { return 0 }
        let ownedIDs = Set(store.collectionItems.map(\.card.id))
        return Double(ownedIDs.count) / Double(store.cards.count)
    }

    func nextEvent(in store: LocalVaultStore) -> VaultEvent? {
        store.events.sorted { $0.date < $1.date }.first
    }

    func highlightCards(in store: LocalVaultStore) -> [Card] {
        store.collectionItems
            .sorted { $0.card.marketValue > $1.card.marketValue }
            .prefix(4)
            .map(\.card)
    }

    func recentActivity(in store: LocalVaultStore) -> [DashboardActivity] {
        var activities = store.recentlyAdded.prefix(3).map { item in
            DashboardActivity(
                title: item.card.name + " added",
                subtitle: "\(item.quantity) owned · \(item.variant.displayName)",
                systemImage: "plus.circle.fill"
            )
        }

        if let firstWant = store.friendWants.first {
            activities.append(
                DashboardActivity(
                    title: firstWant.friend.displayName + " wants " + firstWant.card.name,
                    subtitle: firstWant.priority.displayName + " priority",
                    systemImage: "person.2.fill"
                )
            )
        }

        return activities
    }
}
