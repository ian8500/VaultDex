import Foundation

final class DemoVaultRepository {
    static let shared = DemoVaultRepository()

    let sets: [CardSet]
    let cards: [Card]
    let collectionItems: [CollectionItem]
    let profile: UserProfile
    let tradeOffers: [TradeOffer]
    let wishlistItems: [WishlistItem]
    let friends: [Friend]
    let binderPages: [BinderPage]
    let tradeListings: [TradeListing]
    let events: [VaultEvent]
    let importPreviewItems: [ImportPreviewItem]
    let inviteContacts: [InviteContact]

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

        wishlistItems = [
            WishlistItem(
                card: cards[11],
                priority: .chase,
                targetPrice: 340,
                note: "Wait for a clean mint listing below the current market."
            ),
            WishlistItem(
                card: cards[6],
                priority: .high,
                targetPrice: 10,
                note: "Need two more for a complete Nebula Crown binder page."
            ),
            WishlistItem(
                card: cards[9],
                priority: .medium,
                targetPrice: 2,
                note: "Low-cost filler for demo catalog completion."
            ),
            WishlistItem(
                card: cards[3],
                priority: .watch,
                targetPrice: 48,
                note: "Good trade sweetener when Obsidian Keys dips."
            )
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

        friends = [
            Friend(
                displayName: "Mara Quinn",
                handle: "@maraquinn",
                avatarSymbol: "moon.stars.fill",
                collectorScore: 9180,
                favoriteCard: cards[11],
                completionPercent: 0.84,
                mutualTrades: 7,
                isOnline: true
            ),
            Friend(
                displayName: "Theo Vale",
                handle: "@theovale",
                avatarSymbol: "bolt.fill",
                collectorScore: 6735,
                favoriteCard: cards[10],
                completionPercent: 0.68,
                mutualTrades: 3,
                isOnline: true
            ),
            Friend(
                displayName: "Lena Cross",
                handle: "@lenacross",
                avatarSymbol: "leaf.fill",
                collectorScore: 7420,
                favoriteCard: cards[4],
                completionPercent: 0.73,
                mutualTrades: 5,
                isOnline: false
            ),
            Friend(
                displayName: "Owen Pike",
                handle: "@owenpike",
                avatarSymbol: "flame.fill",
                collectorScore: 5025,
                favoriteCard: cards[5],
                completionPercent: 0.51,
                mutualTrades: 1,
                isOnline: false
            )
        ]

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

        binderPages = [
            BinderPage(
                title: "Mythic Front Page",
                theme: "Gold foil showcase",
                slots: [
                    BinderSlot(index: 1, card: cards[0], note: "Anchor"),
                    BinderSlot(index: 2, card: cards[11], note: "Wishlist proxy"),
                    BinderSlot(index: 3, card: cards[1]),
                    BinderSlot(index: 4, card: cards[4]),
                    BinderSlot(index: 5, card: nil, note: "Reserved"),
                    BinderSlot(index: 6, card: cards[2]),
                    BinderSlot(index: 7, card: cards[5]),
                    BinderSlot(index: 8, card: cards[3]),
                    BinderSlot(index: 9, card: nil, note: "Incoming trade")
                ],
                updatedAt: .now.addingTimeInterval(-3600 * 5)
            ),
            BinderPage(
                title: "Nebula Crown Run",
                theme: "Set completion",
                slots: [
                    BinderSlot(index: 1, card: cards[0]),
                    BinderSlot(index: 2, card: cards[3]),
                    BinderSlot(index: 3, card: cards[6]),
                    BinderSlot(index: 4, card: cards[9]),
                    BinderSlot(index: 5, card: nil, note: "Need #041"),
                    BinderSlot(index: 6, card: nil, note: "Need #057"),
                    BinderSlot(index: 7, card: nil, note: "Need #088"),
                    BinderSlot(index: 8, card: nil, note: "Need #119"),
                    BinderSlot(index: 9, card: nil, note: "Need #144")
                ],
                updatedAt: .now.addingTimeInterval(-86400 * 2)
            )
        ]

        tradeListings = [
            TradeListing(
                ownerName: "Mara Quinn",
                ownerHandle: "@maraquinn",
                card: cards[11],
                askingFor: "Astra Prime or premium Nebula Crown bundle",
                listedAt: .now.addingTimeInterval(-3600 * 3),
                locationLabel: "Online",
                isFeatured: true
            ),
            TradeListing(
                ownerName: "Theo Vale",
                ownerHandle: "@theovale",
                card: cards[6],
                askingFor: "Low-rarity Radiant Archive needs",
                listedAt: .now.addingTimeInterval(-3600 * 10),
                locationLabel: "2 mi",
                isFeatured: false
            ),
            TradeListing(
                ownerName: "Lena Cross",
                ownerHandle: "@lenacross",
                card: cards[7],
                askingFor: "Vesper Blade or mint rares",
                listedAt: .now.addingTimeInterval(-86400),
                locationLabel: "Club night",
                isFeatured: false
            )
        ]

        events = [
            VaultEvent(
                title: "Nebula Crown Launch League",
                venue: "Arcade Tabletop Club",
                date: .now.addingTimeInterval(86400 * 2),
                kind: .tournament,
                prize: "Foil promo pack",
                attendingFriends: 3,
                featuredSet: nebula
            ),
            VaultEvent(
                title: "Friday Trade Night",
                venue: "VaultDex Community Hall",
                date: .now.addingTimeInterval(86400 * 5),
                kind: .tradeNight,
                prize: "Swap table access",
                attendingFriends: 6,
                featuredSet: obsidian
            ),
            VaultEvent(
                title: "Radiant Archive Completion Sprint",
                venue: "Online",
                date: .now.addingTimeInterval(86400 * 12),
                kind: .community,
                prize: "Collector badge",
                attendingFriends: 2,
                featuredSet: radiant
            )
        ]

        importPreviewItems = [
            ImportPreviewItem(sourceName: "Camera Scan", card: cards[2], quantity: 1, condition: .excellent, confidence: 0.96),
            ImportPreviewItem(sourceName: "CSV Upload", card: cards[6], quantity: 2, condition: .nearMint, confidence: 0.91),
            ImportPreviewItem(sourceName: "Camera Scan", card: cards[9], quantity: 5, condition: .mint, confidence: 0.88),
            ImportPreviewItem(sourceName: "Manual Entry", card: cards[11], quantity: 1, condition: .nearMint, confidence: 0.78)
        ]

        inviteContacts = [
            InviteContact(name: "Avery Stone", handleHint: "@averystone", channel: "Messages", isInvited: true),
            InviteContact(name: "Nina Park", handleHint: "@ninapark", channel: "Email", isInvited: false),
            InviteContact(name: "Samir Hart", handleHint: "@samirhart", channel: "Messages", isInvited: false)
        ]
    }
}
