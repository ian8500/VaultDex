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
    let friendWants: [FriendWant]
    let friendRequests: [FriendRequest]

    private init() {
        let nebula = CardSet(name: "Nebula Crown", code: "NBC", releaseYear: 2026, totalCards: 182)
        let obsidian = CardSet(name: "Obsidian Keys", code: "OSK", releaseYear: 2025, totalCards: 144)
        let radiant = CardSet(name: "Radiant Archive", code: "RDA", releaseYear: 2024, totalCards: 210)

        sets = [nebula, obsidian, radiant]

        cards = [
            Card(
                name: "Astra Prime",
                set: nebula,
                number: "001",
                rarity: .mythic,
                cardType: .psychic,
                typeLine: "Celestial Vanguard",
                power: 98,
                condition: .mint,
                marketValue: 420,
                accent: .aurora
            ),
            Card(
                name: "Gilded Revenant",
                set: obsidian,
                number: "017",
                rarity: .legendary,
                cardType: .dark,
                typeLine: "Relic Warden",
                power: 91,
                condition: .nearMint,
                marketValue: 235,
                accent: .void
            ),
            Card(
                name: "Solaris Wyrm",
                set: radiant,
                number: "024",
                rarity: .epic,
                cardType: .dragon,
                typeLine: "Dragon Aspect",
                power: 86,
                condition: .excellent,
                marketValue: 118,
                accent: .solar
            ),
            Card(
                name: "Vesper Blade",
                set: nebula,
                number: "042",
                rarity: .rare,
                cardType: .dark,
                typeLine: "Shadow Artifact",
                power: 74,
                condition: .nearMint,
                marketValue: 62,
                accent: .void
            ),
            Card(
                name: "Emerald Oracle",
                set: radiant,
                number: "058",
                rarity: .legendary,
                cardType: .grass,
                typeLine: "Verdant Seer",
                power: 89,
                condition: .mint,
                marketValue: 196,
                accent: .venom
            ),
            Card(
                name: "Cinder Paladin",
                set: obsidian,
                number: "063",
                rarity: .epic,
                cardType: .fire,
                typeLine: "Flame Knight",
                power: 82,
                condition: .excellent,
                marketValue: 94,
                accent: .ember
            ),
            Card(
                name: "Glasswing Scout",
                set: nebula,
                number: "077",
                rarity: .uncommon,
                cardType: .colorless,
                typeLine: "Aerial Scout",
                power: 43,
                condition: .nearMint,
                marketValue: 14,
                accent: .frost
            ),
            Card(
                name: "Moonlit Vault",
                set: obsidian,
                number: "088",
                rarity: .rare,
                cardType: .psychic,
                typeLine: "Hidden Location",
                power: 68,
                condition: .mint,
                marketValue: 49,
                accent: .aurora
            ),
            Card(
                name: "Ironroot Sentinel",
                set: radiant,
                number: "104",
                rarity: .uncommon,
                cardType: .metal,
                typeLine: "Ancient Guardian",
                power: 55,
                condition: .played,
                marketValue: 9,
                accent: .venom
            ),
            Card(
                name: "Prism Courier",
                set: nebula,
                number: "121",
                rarity: .common,
                cardType: .electric,
                typeLine: "Arcane Runner",
                power: 28,
                condition: .nearMint,
                marketValue: 3,
                accent: .aurora
            ),
            Card(
                name: "Ashen Contract",
                set: obsidian,
                number: "132",
                rarity: .rare,
                cardType: .fire,
                typeLine: "Forbidden Pact",
                power: 71,
                condition: .excellent,
                marketValue: 58,
                accent: .ember
            ),
            Card(
                name: "Frostbound Crown",
                set: radiant,
                number: "166",
                rarity: .mythic,
                cardType: .water,
                typeLine: "Royal Relic",
                power: 96,
                condition: .mint,
                marketValue: 380,
                accent: .frost
            )
        ]

        collectionItems = [
            CollectionItem(card: cards[0], quantity: 1, variant: .fullArt, isAvailableForTrade: false, isFavorite: true, acquiredAt: .now.addingTimeInterval(-86400 * 5), notes: "Launch pull"),
            CollectionItem(card: cards[1], quantity: 1, variant: .holo, isAvailableForTrade: false, isFavorite: true, acquiredAt: .now.addingTimeInterval(-86400 * 12)),
            CollectionItem(card: cards[2], quantity: 2, condition: .excellent, variant: .reverseHolo, isAvailableForTrade: true, acquiredAt: .now.addingTimeInterval(-86400 * 21)),
            CollectionItem(card: cards[3], quantity: 1, variant: .normal, isAvailableForTrade: true, acquiredAt: .now.addingTimeInterval(-86400 * 3)),
            CollectionItem(card: cards[4], quantity: 1, variant: .secretRare, isFavorite: true, acquiredAt: .now.addingTimeInterval(-86400 * 8)),
            CollectionItem(card: cards[5], quantity: 3, condition: .excellent, variant: .holo, isAvailableForTrade: true, acquiredAt: .now.addingTimeInterval(-86400 * 30)),
            CollectionItem(card: cards[7], quantity: 1, variant: .promo, acquiredAt: .now.addingTimeInterval(-86400 * 2)),
            CollectionItem(card: cards[8], quantity: 4, condition: .played, variant: .normal, isAvailableForTrade: true, acquiredAt: .now.addingTimeInterval(-86400 * 42)),
            CollectionItem(card: cards[10], quantity: 2, condition: .excellent, variant: .reverseHolo, acquiredAt: .now.addingTimeInterval(-86400 * 16))
        ]

        wishlistItems = [
            WishlistItem(
                card: cards[11],
                priority: .grail,
                budget: 340,
                notes: "Wait for a clean mint listing below the current market."
            ),
            WishlistItem(
                card: cards[6],
                priority: .high,
                budget: 10,
                notes: "Need two more for a complete Nebula Crown binder page."
            ),
            WishlistItem(
                card: cards[9],
                priority: .medium,
                budget: 2,
                notes: "Low-cost filler for demo catalog completion."
            ),
            WishlistItem(
                card: cards[3],
                priority: .low,
                budget: 48,
                notes: "Good trade sweetener when Obsidian Keys dips."
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

        let maraCollection = [
            CollectionItem(card: cards[11], quantity: 1, variant: .secretRare, isAvailableForTrade: true, acquiredAt: .now.addingTimeInterval(-86400 * 6)),
            CollectionItem(card: cards[6], quantity: 2, variant: .holo, isAvailableForTrade: true, acquiredAt: .now.addingTimeInterval(-86400 * 14)),
            CollectionItem(card: cards[7], quantity: 1, variant: .promo, acquiredAt: .now.addingTimeInterval(-86400 * 21))
        ]
        let maraWishlist = [
            WishlistItem(card: cards[2], priority: .high, budget: 92, notes: "Clean copy for Radiant Archive front page."),
            WishlistItem(card: cards[8], priority: .medium, budget: 22, notes: "Need one more durable trade copy.")
        ]
        let theoCollection = [
            CollectionItem(card: cards[10], quantity: 3, variant: .reverseHolo, isAvailableForTrade: true, acquiredAt: .now.addingTimeInterval(-86400 * 10)),
            CollectionItem(card: cards[9], quantity: 1, variant: .normal, isAvailableForTrade: true, acquiredAt: .now.addingTimeInterval(-86400 * 19)),
            CollectionItem(card: cards[3], quantity: 1, variant: .normal, acquiredAt: .now.addingTimeInterval(-86400 * 24))
        ]
        let theoWishlist = [
            WishlistItem(card: cards[5], priority: .medium, budget: 38, notes: "Building a Fire page."),
            WishlistItem(card: cards[0], priority: .grail, budget: 180, notes: "Would bundle several cards for this.")
        ]
        let lenaCollection = [
            CollectionItem(card: cards[4], quantity: 1, variant: .secretRare, isAvailableForTrade: false, acquiredAt: .now.addingTimeInterval(-86400 * 9)),
            CollectionItem(card: cards[2], quantity: 1, variant: .holo, isAvailableForTrade: true, acquiredAt: .now.addingTimeInterval(-86400 * 32)),
            CollectionItem(card: cards[1], quantity: 2, variant: .holo, acquiredAt: .now.addingTimeInterval(-86400 * 40))
        ]
        let lenaWishlist = [
            WishlistItem(card: cards[7], priority: .grail, budget: 140, notes: "Promo variant only."),
            WishlistItem(card: cards[10], priority: .low, budget: 16, notes: "Binder filler.")
        ]
        let owenCollection = [
            CollectionItem(card: cards[5], quantity: 2, variant: .holo, isAvailableForTrade: true, acquiredAt: .now.addingTimeInterval(-86400 * 18)),
            CollectionItem(card: cards[8], quantity: 1, variant: .normal, isAvailableForTrade: true, acquiredAt: .now.addingTimeInterval(-86400 * 28))
        ]
        let owenWishlist = [
            WishlistItem(card: cards[3], priority: .high, budget: 45, notes: "Needs near mint."),
            WishlistItem(card: cards[6], priority: .medium, budget: 24, notes: "Any variant.")
        ]

        friends = [
            Friend(
                displayName: "Mara Quinn",
                handle: "@maraquinn",
                email: "mara@vaultdex.demo",
                avatarSymbol: "moon.stars.fill",
                collectorScore: 9180,
                favoriteCard: cards[11],
                completionPercent: 0.84,
                mutualTrades: 7,
                isOnline: true,
                visibleCollection: maraCollection,
                wishlist: maraWishlist
            ),
            Friend(
                displayName: "Theo Vale",
                handle: "@theovale",
                email: "theo@vaultdex.demo",
                avatarSymbol: "bolt.fill",
                collectorScore: 6735,
                favoriteCard: cards[10],
                completionPercent: 0.68,
                mutualTrades: 3,
                isOnline: true,
                visibleCollection: theoCollection,
                wishlist: theoWishlist
            ),
            Friend(
                displayName: "Lena Cross",
                handle: "@lenacross",
                email: "lena@vaultdex.demo",
                avatarSymbol: "leaf.fill",
                collectorScore: 7420,
                favoriteCard: cards[4],
                completionPercent: 0.73,
                mutualTrades: 5,
                isOnline: false,
                collectionVisibility: .public,
                visibleCollection: lenaCollection,
                wishlist: lenaWishlist
            ),
            Friend(
                displayName: "Owen Pike",
                handle: "@owenpike",
                email: "owen@vaultdex.demo",
                avatarSymbol: "flame.fill",
                collectorScore: 5025,
                favoriteCard: cards[5],
                completionPercent: 0.51,
                mutualTrades: 1,
                isOnline: false,
                visibleCollection: owenCollection,
                wishlist: owenWishlist
            )
        ]

        friendRequests = [
            FriendRequest(displayName: "Nina Park", handleOrEmail: "@ninapark", avatarSymbol: "sparkle.magnifyingglass", direction: .incoming, requestedAt: .now.addingTimeInterval(-3600 * 6), previewCard: cards[1]),
            FriendRequest(displayName: "Avery Stone", handleOrEmail: "avery@vaultdex.demo", avatarSymbol: "person.crop.circle.badge.plus", direction: .incoming, requestedAt: .now.addingTimeInterval(-86400), previewCard: cards[4]),
            FriendRequest(displayName: "Samir Hart", handleOrEmail: "@samirhart", avatarSymbol: "paperplane.fill", direction: .outgoing, requestedAt: .now.addingTimeInterval(-3600 * 30), previewCard: cards[9])
        ]

        friendWants = [
            FriendWant(friend: friends[0], card: cards[2], priority: .high, note: "Mara needs a clean Solaris Wyrm for Radiant Archive."),
            FriendWant(friend: friends[1], card: cards[10], priority: .medium, note: "Theo is bundling for Ashen Contract copies."),
            FriendWant(friend: friends[2], card: cards[7], priority: .grail, note: "Lena wants the Moonlit Vault promo variant.")
        ]

        tradeOffers = [
            TradeOffer(
                partnerName: "Mara Quinn",
                partnerHandle: "@maraquinn",
                offeredCards: [cards[11], cards[6]],
                requestedCards: [cards[2]],
                status: .pending,
                direction: .received,
                internalCredits: 40,
                expiresInDays: 2,
                note: "Looking to complete Radiant Archive mythics.",
                usesSafeTrade: true
            ),
            TradeOffer(
                partnerName: "Theo Vale",
                partnerHandle: "@theovale",
                offeredCards: [cards[6], cards[9], cards[8]],
                requestedCards: [cards[10]],
                status: .pending,
                direction: .sent,
                internalCredits: 15,
                expiresInDays: 5,
                note: "Bundle offer for Theo's Ashen Contract copies."
            ),
            TradeOffer(
                partnerName: "Lena Cross",
                partnerHandle: "@lenacross",
                offeredCards: [cards[3]],
                requestedCards: [cards[7]],
                status: .completed,
                direction: .sent,
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
                visibility: .friends,
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
                visibility: .private,
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
                sellerReputation: 98,
                isFeatured: true,
                isSaved: true,
                usesSafeTrade: true
            ),
            TradeListing(
                ownerName: "Theo Vale",
                ownerHandle: "@theovale",
                card: cards[6],
                askingFor: "Low-rarity Radiant Archive needs",
                listedAt: .now.addingTimeInterval(-3600 * 10),
                locationLabel: "2 mi",
                sellerReputation: 86,
                isFeatured: false
            ),
            TradeListing(
                ownerName: "Lena Cross",
                ownerHandle: "@lenacross",
                card: cards[7],
                askingFor: "Vesper Blade or mint rares",
                listedAt: .now.addingTimeInterval(-86400),
                locationLabel: "Club night",
                sellerReputation: 93,
                isFeatured: false,
                usesSafeTrade: true
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
