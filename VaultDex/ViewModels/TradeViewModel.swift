import Foundation

@MainActor
final class TradeViewModel: ObservableObject {
    @Published private(set) var offers: [TradeOffer]
    @Published private(set) var listings: [TradeListing]

    init(repository: DemoVaultRepository = .shared) {
        offers = repository.tradeOffers
        listings = repository.tradeListings
    }

    var activeOffers: [TradeOffer] {
        offers.filter { $0.status == .pending || $0.status == .countered }
    }

    var completedOffers: [TradeOffer] {
        offers.filter { $0.status == .accepted || $0.status == .declined }
    }

    var featuredListings: [TradeListing] {
        listings.filter(\.isFeatured)
    }
}
