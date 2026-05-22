import SwiftUI

struct CardDetailView: View {
    @EnvironmentObject private var store: LocalVaultStore

    let card: Card

    @State private var ownedQuantity = 1
    @State private var selectedCondition: CardCondition
    @State private var selectedVariant = CardVariant.normal
    @State private var isAvailableForTrade = false
    @State private var wishlistPriority = WishlistPriority.medium
    @State private var wishlistBudget: Double
    @State private var wishlistNotes = ""

    init(card: Card) {
        self.card = card
        _selectedCondition = State(initialValue: card.condition)
        _wishlistBudget = State(initialValue: card.marketValue)
    }

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    hero
                    friendWishlistBadges
                    collectionEditor
                    wishlistEditor
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle(card.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: syncState)
    }

    private var ownedItem: CollectionItem? {
        store.collectionItem(for: card)
    }

    private var savedWishlistItem: WishlistItem? {
        store.wishlistItem(for: card)
    }

    private var friendsWantingCard: [Friend] {
        store.friendsWanting(card)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 14) {
            CardTile(
                card: card,
                quantity: ownedItem?.quantity,
                condition: ownedItem?.condition,
                variant: ownedItem?.variant,
                isAvailableForTrade: ownedItem?.isAvailableForTrade ?? false
            )

            HStack(spacing: 10) {
                StatusPill(title: card.cardType.displayName, tint: .vdEmerald)
                RarityBadge(rarity: card.rarity)
                StatusPill(title: card.marketValue.vaultCurrency, tint: .vdGold)
            }

            Text(card.set.name + " · " + card.typeLine)
                .font(.subheadline)
                .foregroundStyle(Color.vdTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var friendWishlistBadges: some View {
        if !friendsWantingCard.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                VaultSectionHeader(title: "Friend Wishlist", subtitle: "Friends who want this card")

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(friendsWantingCard) { friend in
                            HStack(spacing: 8) {
                                Image(systemName: friend.avatarSymbol)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Color.vdGold)

                                Text(friend.displayName)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Color.vdTextPrimary)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(Color.vdGold.opacity(0.12), in: Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.vdGold.opacity(0.28), lineWidth: 1)
                            )
                        }
                    }
                }
            }
            .padding(16)
            .background(Color.vdPanel.opacity(0.84), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.vdStroke.opacity(0.72), lineWidth: 1)
            )
        }
    }

    private var collectionEditor: some View {
        VStack(alignment: .leading, spacing: 16) {
            VaultSectionHeader(
                title: "Collection",
                subtitle: ownedItem == nil ? "Add this card to your local vault" : "Edit owned quantity, condition, variant, and trade status"
            )

            Stepper(value: $ownedQuantity, in: 1...99) {
                editorLabel(title: "Quantity", value: "\(ownedQuantity)")
            }

            Picker("Condition", selection: $selectedCondition) {
                ForEach(CardCondition.allCases) { condition in
                    Text(condition.displayName).tag(condition)
                }
            }
            .pickerStyle(.menu)

            Picker("Variant", selection: $selectedVariant) {
                ForEach(CardVariant.allCases) { variant in
                    Text(variant.displayName).tag(variant)
                }
            }
            .pickerStyle(.menu)

            Toggle("Available for trade", isOn: $isAvailableForTrade)
                .tint(Color.vdEmerald)

            if ownedItem == nil {
                PrimaryButton(title: "Add to Collection", systemImage: "plus.circle.fill") {
                    store.addCard(card, quantity: ownedQuantity, condition: selectedCondition, variant: selectedVariant)
                    store.updateTradeAvailability(for: card, isAvailable: isAvailableForTrade)
                    syncState()
                }
            } else {
                PrimaryButton(title: "Save Collection Changes", systemImage: "checkmark.circle.fill") {
                    store.updateQuantity(for: card, quantity: ownedQuantity)
                    store.updateCondition(for: card, condition: selectedCondition)
                    store.updateVariant(for: card, variant: selectedVariant)
                    store.updateTradeAvailability(for: card, isAvailable: isAvailableForTrade)
                    syncState()
                }

                secondaryButton(title: "Remove from Collection", systemImage: "minus.circle.fill", tint: .vdCoral) {
                    store.removeCard(card)
                    syncState()
                }
            }
        }
        .padding(18)
        .background(Color.vdPanel.opacity(0.84), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.78), lineWidth: 1)
        )
    }

    private var wishlistEditor: some View {
        VStack(alignment: .leading, spacing: 16) {
            VaultSectionHeader(
                title: "Wishlist",
                subtitle: savedWishlistItem == nil ? "Track budget, priority, and notes" : "Edit this wishlist target"
            )

            Picker("Priority", selection: $wishlistPriority) {
                ForEach(WishlistPriority.allCases) { priority in
                    Text(priority.displayName).tag(priority)
                }
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 8) {
                Text("Budget / Value")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.vdTextSecondary)

                TextField("Budget", value: $wishlistBudget, format: .number.precision(.fractionLength(0...2)))
                    .keyboardType(.decimalPad)
                    .foregroundStyle(Color.vdTextPrimary)
                    .padding(14)
                    .background(Color.vdPanelRaised.opacity(0.82), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.vdStroke.opacity(0.8), lineWidth: 1)
                    )
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Notes")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.vdTextSecondary)

                TextField("Wishlist notes", text: $wishlistNotes, axis: .vertical)
                    .lineLimit(3...5)
                    .foregroundStyle(Color.vdTextPrimary)
                    .padding(14)
                    .background(Color.vdPanelRaised.opacity(0.82), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.vdStroke.opacity(0.8), lineWidth: 1)
                    )
            }

            if savedWishlistItem == nil {
                PrimaryButton(title: "Add to Wishlist", systemImage: "star.fill") {
                    store.addToWishlist(card, priority: wishlistPriority, budget: wishlistBudget, notes: wishlistNotes)
                    syncState()
                }
            } else {
                PrimaryButton(title: "Save Wishlist", systemImage: "checkmark.circle.fill") {
                    store.updateWishlist(for: card, priority: wishlistPriority, budget: wishlistBudget, notes: wishlistNotes)
                    syncState()
                }

                secondaryButton(title: "Remove from Wishlist", systemImage: "star.slash.fill", tint: .vdCoral) {
                    store.removeFromWishlist(card)
                    syncState()
                }
            }
        }
        .padding(18)
        .background(Color.vdPanel.opacity(0.84), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.78), lineWidth: 1)
        )
    }

    private func editorLabel(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(Color.vdTextPrimary)

            Spacer()

            Text(value)
                .font(.headline)
                .foregroundStyle(Color.vdGold)
        }
    }

    private func secondaryButton(
        title: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .bold))

                Text(title)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(tint.opacity(0.45), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func syncState() {
        if let ownedItem {
            ownedQuantity = ownedItem.quantity
            selectedCondition = ownedItem.condition
            selectedVariant = ownedItem.variant
            isAvailableForTrade = ownedItem.isAvailableForTrade
        } else {
            ownedQuantity = 1
            selectedCondition = card.condition
            selectedVariant = .normal
            isAvailableForTrade = false
        }

        if let savedWishlistItem {
            wishlistPriority = savedWishlistItem.priority
            wishlistBudget = savedWishlistItem.budget
            wishlistNotes = savedWishlistItem.notes
        } else {
            wishlistPriority = .medium
            wishlistBudget = card.marketValue
            wishlistNotes = ""
        }
    }
}
