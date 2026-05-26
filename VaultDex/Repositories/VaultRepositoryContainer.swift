import Foundation

struct VaultRepositoryContainer {
    let config: SupabaseConfig
    let clientProvider: SupabaseClientProvider
    let auth: AuthRepository
    let profiles: ProfileRepository
    let verification: VerificationRepository
    let cards: CardCatalogRepository
    let collection: CollectionRepository
    let wishlist: WishlistRepository
    let friends: FriendsRepository
    let binder: BinderRepository
    let trades: TradeRepository
    let marketplace: MarketplaceRepository
    let events: EventsRepository
    let reputation: ReputationRepository
    let storage: VaultStorageRepository

    static func live(config: SupabaseConfig = .current) -> VaultRepositoryContainer {
        let client = SupabaseClientProvider(config: config)
        return VaultRepositoryContainer(
            config: config,
            clientProvider: client,
            auth: SupabaseAuthRepository(client: client),
            profiles: SupabaseProfileRepository(client: client),
            verification: SupabaseVerificationRepository(client: client),
            cards: SupabaseCardCatalogRepository(client: client),
            collection: SupabaseCollectionRepository(client: client),
            wishlist: SupabaseWishlistRepository(client: client),
            friends: SupabaseFriendsRepository(client: client),
            binder: SupabaseBinderRepository(client: client),
            trades: SupabaseTradeRepository(client: client),
            marketplace: SupabaseMarketplaceRepository(client: client),
            events: SupabaseEventsRepository(client: client),
            reputation: SupabaseReputationRepository(client: client),
            storage: SupabaseStorageRepository(client: client)
        )
    }
}
