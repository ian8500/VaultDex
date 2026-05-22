import Foundation

struct DashboardActivity: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let systemImage: String
}

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published private(set) var collectionItems: [CollectionItem]
    @Published private(set) var tradeOffers: [TradeOffer]
    @Published private(set) var profile: UserProfile

    let recentActivity: [DashboardActivity]

    init(repository: DemoVaultRepository = .shared) {
        collectionItems = repository.collectionItems
        tradeOffers = repository.tradeOffers
        profile = repository.profile
        recentActivity = [
            DashboardActivity(title: "Astra Prime secured", subtitle: "Mint pull from Nebula Crown", systemImage: "sparkles"),
            DashboardActivity(title: "Trade counter received", subtitle: "Theo Vale adjusted a bundle", systemImage: "arrow.left.arrow.right"),
            DashboardActivity(title: "Vault value moved", subtitle: "Radiant Archive climbed 6%", systemImage: "chart.line.uptrend.xyaxis")
        ]
    }

    var totalCopies: Int {
        collectionItems.reduce(0) { $0 + $1.quantity }
    }

    var uniqueCards: Int {
        collectionItems.count
    }

    var vaultValue: Double {
        collectionItems.reduce(0) { $0 + ($1.card.marketValue * Double($1.quantity)) }
    }

    var pendingTrades: Int {
        tradeOffers.filter { $0.status == .pending || $0.status == .countered }.count
    }

    var highlightCards: [Card] {
        collectionItems
            .sorted { $0.card.marketValue > $1.card.marketValue }
            .prefix(4)
            .map(\.card)
    }
}
