import Foundation

final class DemoVaultRepository {
    static let shared = DemoVaultRepository()

    let sets: [CardSet]
    let cards: [Card]
    let collectionItems: [CollectionItem]
    let profile: UserProfile
    let tradeOffers: [TradeOffer]

    private init() {
        let nebula = CardSet(name: "Nebula Crown", code: "NBC", releaseYear: 2026, totalCards: 182)
        let obsidian = CardSet(name: "Obsidian Keys", code: "OSK", releaseYear: 2025, totalCards: 144)
        let radiant = CardSet(name: "Radiant Archive", code: "RDA", releaseYear: 2024, totalCards: 210)

        sets = [nebula, obsidian, radiant]

        cards = [
            Card(
                name: "Astra Prime",
                set: nebula,
                rarity: .mythic,
                typeLine: "Celestial Vanguard",
                power: 98,
                condition: .mint,
                marketValue: 420,
                accent: .aurora
            ),
            Card(
                name: "Gilded Revenant",
                set: obsidian,
                rarity: .legendary,
                typeLine: "Relic Warden",
                power: 91,
                condition: .nearMint,
                marketValue: 235,
                accent: .void
            ),
            Card(
                name: "Solaris Wyrm",
                set: radiant,
                rarity: .epic,
                typeLine: "Dragon Aspect",
                power: 86,
                condition: .excellent,
                marketValue: 118,
                accent: .solar
            ),
            Card(
                name: "Vesper Blade",
                set: nebula,
                rarity: .rare,
                typeLine: "Shadow Artifact",
                power: 74,
                condition: .nearMint,
                marketValue: 62,
                accent: .void
            ),
            Card(
                name: "Emerald Oracle",
                set: radiant,
                rarity: .legendary,
                typeLine: "Verdant Seer",
                power: 89,
                condition: .mint,
                marketValue: 196,
                accent: .venom
            ),
            Card(
                name: "Cinder Paladin",
                set: obsidian,
                rarity: .epic,
                typeLine: "Flame Knight",
                power: 82,
                condition: .excellent,
                marketValue: 94,
                accent: .ember
            ),
            Card(
                name: "Glasswing Scout",
                set: nebula,
                rarity: .uncommon,
                typeLine: "Aerial Scout",
                power: 43,
                condition: .nearMint,
                marketValue: 14,
                accent: .frost
            ),
            Card(
                name: "Moonlit Vault",
                set: obsidian,
                rarity: .rare,
                typeLine: "Hidden Location",
                power: 68,
                condition: .mint,
                marketValue: 49,
                accent: .aurora
            ),
            Card(
                name: "Ironroot Sentinel",
                set: radiant,
                rarity: .uncommon,
                typeLine: "Ancient Guardian",
                power: 55,
                condition: .played,
                marketValue: 9,
                accent: .venom
            ),
            Card(
                name: "Prism Courier",
                set: nebula,
                rarity: .common,
                typeLine: "Arcane Runner",
                power: 28,
                condition: .nearMint,
                marketValue: 3,
                accent: .aurora
            ),
            Card(
                name: "Ashen Contract",
                set: obsidian,
                rarity: .rare,
                typeLine: "Forbidden Pact",
                power: 71,
                condition: .excellent,
                marketValue: 58,
                accent: .ember
            ),
            Card(
                name: "Frostbound Crown",
                set: radiant,
                rarity: .mythic,
                typeLine: "Royal Relic",
                power: 96,
                condition: .mint,
                marketValue: 380,
                accent: .frost
            )
        ]

        collectionItems = [
            CollectionItem(card: cards[0], quantity: 1, isFavorite: true, acquiredAt: .now.addingTimeInterval(-86400 * 5), notes: "Launch pull"),
            CollectionItem(card: cards[1], quantity: 1, isFavorite: true, acquiredAt: .now.addingTimeInterval(-86400 * 12)),
            CollectionItem(card: cards[2], quantity: 2, acquiredAt: .now.addingTimeInterval(-86400 * 21)),
            CollectionItem(card: cards[3], quantity: 1, acquiredAt: .now.addingTimeInterval(-86400 * 3)),
            CollectionItem(card: cards[4], quantity: 1, isFavorite: true, acquiredAt: .now.addingTimeInterval(-86400 * 8)),
            CollectionItem(card: cards[5], quantity: 3, acquiredAt: .now.addingTimeInterval(-86400 * 30)),
            CollectionItem(card: cards[7], quantity: 1, acquiredAt: .now.addingTimeInterval(-86400 * 2)),
            CollectionItem(card: cards[8], quantity: 4, acquiredAt: .now.addingTimeInterval(-86400 * 42)),
            CollectionItem(card: cards[10], quantity: 2, acquiredAt: .now.addingTimeInterval(-86400 * 16))
        ]

        profile = UserProfile(
            displayName: "Ian Vaultwright",
            handle: "@vaultdexian",
            bio: "Building a pristine digital vault, one mythic chase card at a time.",
            avatarSymbol: "sparkles",
            collectorScore: 8420,
            favoriteSet: nebula,
            joinedDate: .now.addingTimeInterval(-86400 * 320),
            followers: 1284,
            following: 212
        )

        tradeOffers = [
            TradeOffer(
                partnerName: "Mara Quinn",
                partnerHandle: "@maraquinn",
                offeredCards: [cards[11], cards[6]],
                requestedCards: [cards[2]],
                status: .pending,
                expiresInDays: 2,
                note: "Looking to complete Radiant Archive mythics."
            ),
            TradeOffer(
                partnerName: "Theo Vale",
                partnerHandle: "@theovale",
                offeredCards: [cards[6], cards[9], cards[8]],
                requestedCards: [cards[10]],
                status: .countered,
                expiresInDays: 5,
                note: "Countered with a lower value bundle."
            ),
            TradeOffer(
                partnerName: "Lena Cross",
                partnerHandle: "@lenacross",
                offeredCards: [cards[3]],
                requestedCards: [cards[7]],
                status: .accepted,
                expiresInDays: 0,
                note: "Ready for final confirmation."
            )
        ]
    }
}
