import SwiftUI

struct TradeView: View {
    @EnvironmentObject private var store: LocalVaultStore
    @StateObject private var viewModel = TradeViewModel()
    @State private var listingCard: CollectionItem?
    @State private var offerListing: TradeListing?
    @State private var detailListing: TradeListing?
    @State private var isFriendTradePresented = false
    @State private var selectedTab: TradeListTab = .active

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    safetyNote
                    createTradeAction
                    tradeTabs
                    tradesSection
                    listMyCardSection
                    myListingsSection
                    marketplaceSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .bottomDockSpacing()
            }
        }
        .navigationTitle("Trade")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $listingCard) { item in
            ListCardSheet(item: item, viewModel: viewModel) {
                store.listCardForTrade(
                    item,
                    listingKind: viewModel.listingKind,
                    askingCredits: viewModel.listingKind == .trade ? nil : viewModel.listingAskingCredits,
                    description: viewModel.listingDescription,
                    askingFor: viewModel.listingAsk,
                    usesSafeTrade: viewModel.listingUsesSafeTrade
                )
                listingCard = nil
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        }
        .sheet(item: $offerListing) { listing in
            TradeOfferComposer(listing: listing, viewModel: viewModel) {
                let offered = viewModel.selectedOfferCards(in: store)
                let requested = viewModel.requestedCards(from: listing)
                store.sendTradeOffer(
                    to: listing,
                    offeredCards: offered,
                    requestedCards: requested,
                    internalCredits: viewModel.internalCredits,
                    message: viewModel.offerMessage,
                    usesSafeTrade: viewModel.offerUsesSafeTrade
                )
                offerListing = nil
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
            .environmentObject(store)
            .onAppear {
                viewModel.resetOffer(for: listing)
            }
        }
        .sheet(item: $detailListing) { listing in
            TradeListingDetailView(listing: listing) {
                detailListing = nil
                offerListing = listing
            }
            .environmentObject(store)
        }
        .sheet(isPresented: $isFriendTradePresented) {
            FriendTradeComposer(viewModel: viewModel) {
                guard let friend = viewModel.selectedFriend(in: store) else { return }
                let offeredItems = viewModel.selectedOfferItems(in: store)
                let requestedItems = viewModel.requestedItems(from: friend)
                store.sendTradeOffer(
                    to: friend,
                    offeredItems: offeredItems,
                    requestedItems: requestedItems,
                    internalCredits: viewModel.internalCredits,
                    message: viewModel.offerMessage,
                    usesSafeTrade: viewModel.offerUsesSafeTrade
                )
                isFriendTradePresented = false
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
            .environmentObject(store)
            .onAppear {
                viewModel.resetFriendOffer(in: store)
            }
        }
    }

    private var safetyNote: some View {
        Label("Only trade with people you trust", systemImage: "shield.lefthalf.filled")
            .font(.subheadline.weight(.black))
            .foregroundStyle(Color.vdGold)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color.vdGold.opacity(0.10), in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.vdGold.opacity(0.20), lineWidth: 1))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Trade")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.vdTextPrimary)

                    Text("Trades I’m involved in.")
                        .font(.subheadline)
                        .foregroundStyle(Color.vdTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(Color.vdNavy)
                    .frame(width: 58, height: 58)
                    .background(
                        LinearGradient(colors: [Color(hex: 0xFFF06A), Color.vdGold], startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 18)
                    )
                    .shadow(color: Color.vdGold.opacity(0.26), radius: 14, x: 0, y: 6)
            }
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [Color.vdPanelRaised.opacity(0.94), Color.vdPanel.opacity(0.78)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.vdGold.opacity(0.28), lineWidth: 1)
        )
        .shadow(color: Color.vdGold.opacity(0.10), radius: 18, x: 0, y: 8)
    }

    @ViewBuilder
    private var createTradeAction: some View {
        if !store.friends.isEmpty, !store.collectionItems.isEmpty {
            PrimaryButton(title: "Create Trade", systemImage: "plus.circle.fill") {
                viewModel.resetFriendOffer(in: store)
                isFriendTradePresented = true
            }
        } else {
            NavigationLink {
                SearchView()
            } label: {
                Label("Create Trade", systemImage: "plus.circle.fill")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.vdNavy)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.vdGold, in: RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.vdGold.opacity(0.22), radius: 16, x: 0, y: 8)
            }
            .buttonStyle(.plain)
        }
    }

    private var tradeTabs: some View {
        Picker("Trades", selection: $selectedTab) {
            ForEach(TradeListTab.allCases) { tab in
                Text(tab.title).tag(tab)
            }
        }
        .pickerStyle(.segmented)
    }

    private var tradesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Trades I’m involved in", subtitle: nil)

            let offers = selectedTab == .active ? activeOffers : completedOffers
            if offers.isEmpty {
                tradeEmptyState
            } else {
                VStack(spacing: 12) {
                    ForEach(offers) { offer in
                        TradeOfferRow(offer: offer) { status in
                            store.updateTradeOfferStatus(offer, status: status)
                        }
                    }
                }
            }
        }
    }

    private var activeOffers: [TradeOffer] {
        store.tradeOffers.filter { offer in
            offer.status == .pending || offer.status == .accepted || offer.status == .disputed
        }
    }

    private var completedOffers: [TradeOffer] {
        store.tradeOffers.filter { offer in
            offer.status == .completed || offer.status == .rejected || offer.status == .canceled
        }
    }

    private var tradeEmptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.left.arrow.right.circle.fill")
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(Color.vdGold)
                .frame(width: 72, height: 72)
                .background(Color.vdGold.opacity(0.14), in: RoundedRectangle(cornerRadius: 24))

            VStack(spacing: 6) {
                Text("No trades yet")
                    .font(.title3.weight(.black))
                    .foregroundStyle(Color.vdTextPrimary)

                Text("Add cards to your vault and connect with collectors to start trading.")
                    .font(.subheadline)
                    .foregroundStyle(Color.vdTextSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 10) {
                NavigationLink {
                    SearchView()
                } label: {
                    Label("Find cards", systemImage: "magnifyingglass")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.vdNavy)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.vdGold, in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)

                NavigationLink {
                    InviteFriendsView()
                } label: {
                    Label("Invite a friend", systemImage: "person.badge.plus")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.vdGold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.vdPanelRaised.opacity(0.78), in: RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.vdGold.opacity(0.28), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.vdPanel.opacity(0.82), in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.vdGold.opacity(0.20), lineWidth: 1))
    }

    private var listMyCardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "List a Card", subtitle: nil)

            if store.collectionItems.isEmpty {
                EmptyStateView(systemImage: "arrow.left.arrow.right.circle.fill", title: "No cards to list", message: "Add cards to your vault before listing in Card Market.")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(store.collectionItems) { item in
                            Button {
                                viewModel.listingAsk = ""
                                viewModel.listingDescription = ""
                                viewModel.listingKind = .both
                                viewModel.listingAskingCredits = item.askingCredits ?? max(Int(item.card.marketValue.rounded()), 0)
                                viewModel.listingUsesSafeTrade = true
                                listingCard = item
                            } label: {
                                CardTile(
                                    card: item.card,
                                    quantity: item.quantity,
                                    condition: item.condition,
                                    variant: item.variant,
                                    isAvailableForTrade: item.isAvailableForTrade,
                                    style: .compact
                                )
                                .frame(width: 220)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
            }
        }
    }

    private var myListingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "My Listings", subtitle: nil)

            if viewModel.myListings(in: store).isEmpty {
                EmptyStateView(systemImage: "tag.circle.fill", title: "No active trades yet", message: "List a trade-ready card when you are ready to receive friend offers.")
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.myListings(in: store)) { listing in
                        TradeListingRow(listing: listing, isMine: true) {
                            store.removeTradeListing(listing)
                        } onOffer: {} onDetails: {
                            detailListing = listing
                        }
                    }
                }
            }
        }
    }

    private var marketplaceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Card Market", subtitle: nil)
            filters

            let listings = viewModel.filteredListings(in: store)
            if listings.isEmpty {
                EmptyStateView(systemImage: "magnifyingglass.circle.fill", title: "No listings found", message: "Try changing filters, or check back after collectors list cards for trade.")
            } else {
                VStack(spacing: 12) {
                    ForEach(listings) { listing in
                        TradeListingRow(listing: listing, isMine: false) {
                            store.toggleSavedListing(listing)
                        } onOffer: {
                            offerListing = listing
                        } onDetails: {
                            detailListing = listing
                        }
                    }
                }
            }
        }
    }

    private var filters: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Search listings", text: $viewModel.searchText)
                .textInputAutocapitalization(.never)
                .foregroundStyle(Color.vdTextPrimary)
                .padding(14)
                .background(Color.vdPanelRaised.opacity(0.82), in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.vdGold.opacity(0.22), lineWidth: 1))

            HStack(spacing: 10) {
                Picker("Rarity", selection: $viewModel.selectedRarity) {
                    Text("Any Rarity").tag(Optional<CardRarity>.none)
                    ForEach(CardRarity.allCases) { rarity in
                        Text(rarity.displayName).tag(Optional(rarity))
                    }
                }
                .pickerStyle(.menu)

                Picker("Condition", selection: $viewModel.selectedCondition) {
                    Text("Any Condition").tag(Optional<CardCondition>.none)
                    ForEach(CardCondition.allCases) { condition in
                        Text(condition.displayName).tag(Optional(condition))
                    }
                }
                .pickerStyle(.menu)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Max market estimate \(viewModel.maximumValue.vaultCurrency)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.vdTextSecondary)
                Slider(value: $viewModel.maximumValue, in: 10...250, step: 5)
                    .tint(Color.vdGold)
            }

            Stepper(value: $viewModel.minimumReputation, in: 0...100, step: 5) {
                editorLine(title: "Seller reputation", value: "\(viewModel.minimumReputation)+")
            }
        }
        .padding(14)
        .background(Color.vdPanel.opacity(0.76), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.vdGold.opacity(0.20), lineWidth: 1))
    }

    private var receivedOffersSection: some View {
        offerSection(
            title: "Offers Received",
            subtitle: "\(viewModel.receivedOffers(in: store).count) offers",
            offers: viewModel.receivedOffers(in: store)
        )
    }

    private var sentOffersSection: some View {
        offerSection(
            title: "Offers Sent",
            subtitle: "\(viewModel.sentOffers(in: store).count) outbound",
            offers: viewModel.sentOffers(in: store)
        )
    }

    private func offerSection(title: String, subtitle: String, offers: [TradeOffer]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: title, subtitle: subtitle)

            if offers.isEmpty {
                EmptyStateView(systemImage: "tray.circle.fill", title: "No active trades yet", message: "Sent and received offers will appear here once you start trading with collectors.")
            } else {
                VStack(spacing: 12) {
                    ForEach(offers) { offer in
                        TradeOfferRow(offer: offer) { status in
                            store.updateTradeOfferStatus(offer, status: status)
                        }
                    }
                }
            }
        }
    }

    private func editorLine(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(Color.vdTextPrimary)
            Spacer()
            Text(value)
                .font(.headline)
                .foregroundStyle(Color.vdGold)
        }
    }
}

private enum TradeListTab: String, CaseIterable, Identifiable {
    case active
    case completed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .active: "Active"
        case .completed: "Completed"
        }
    }
}

private struct ListCardSheet: View {
    let item: CollectionItem
    @ObservedObject var viewModel: TradeViewModel
    let onConfirm: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                VStack(alignment: .leading, spacing: 18) {
                    CardTile(card: item.card, quantity: item.quantity, condition: item.condition, variant: item.variant, isAvailableForTrade: true)

                    Picker("Listing type", selection: $viewModel.listingKind) {
                        ForEach(TradeListingKind.allCases) { kind in
                            Text(kind.displayName).tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)

                    if viewModel.listingKind != .trade {
                        Stepper(value: $viewModel.listingAskingCredits, in: 0...5000, step: 5) {
                            HStack {
                                Text("Asking credits")
                                    .foregroundStyle(Color.vdTextPrimary)
                                Spacer()
                                Text("\(viewModel.listingAskingCredits)")
                                    .font(.headline)
                                    .foregroundStyle(Color.vdGold)
                            }
                        }
                    }

                    TextField("Description", text: $viewModel.listingDescription, axis: .vertical)
                        .lineLimit(3...5)
                        .foregroundStyle(Color.vdTextPrimary)
                        .padding(14)
                        .background(Color.vdPanelRaised.opacity(0.82), in: RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.vdStroke.opacity(0.72), lineWidth: 1))

                    TextField("What would you like?", text: $viewModel.listingAsk, axis: .vertical)
                        .lineLimit(3...5)
                        .foregroundStyle(Color.vdTextPrimary)
                        .padding(14)
                        .background(Color.vdPanelRaised.opacity(0.82), in: RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.vdStroke.opacity(0.72), lineWidth: 1))

                    Toggle("Safe intermediary option", isOn: $viewModel.listingUsesSafeTrade)
                        .tint(Color.vdGold)
                        .foregroundStyle(Color.vdTextPrimary)

                    PrimaryButton(title: "List in Card Market", systemImage: "tag.fill", action: onConfirm)
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("New Listing")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

private struct FriendTradeComposer: View {
    @EnvironmentObject private var store: LocalVaultStore
    @ObservedObject var viewModel: TradeViewModel
    let onSend: () -> Void

    private var selectedFriend: Friend? {
        viewModel.selectedFriend(in: store)
    }

    private var offeredItems: [CollectionItem] {
        viewModel.selectedOfferItems(in: store)
    }

    private var requestedItems: [CollectionItem] {
        viewModel.requestedItems(from: selectedFriend)
    }

    private var offeredCards: [Card] {
        offeredItems.map(\.card)
    }

    private var requestedCards: [Card] {
        requestedItems.map(\.card)
    }

    private var fairScore: Double {
        viewModel.fairnessScore(offeredCards: offeredCards, requestedCards: requestedCards, credits: viewModel.internalCredits)
    }

    private var canSend: Bool {
        selectedFriend != nil && (!offeredItems.isEmpty || viewModel.internalCredits > 0) && !requestedItems.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        friendPicker
                        ownCardPicker
                        friendCardPicker
                        creditsAndMessage
                        fairTradeMeter

                        PrimaryButton(title: "Send Offer", systemImage: "paperplane.fill", action: onSend)
                            .disabled(!canSend)
                            .opacity(canSend ? 1 : 0.45)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Create Trade")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var friendPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Collector", subtitle: "Choose a friend to trade with")

            Picker("Collector", selection: $viewModel.selectedFriendID) {
                ForEach(store.friends) { friend in
                    Text(friend.displayName).tag(Optional(friend.id))
                }
            }
            .pickerStyle(.menu)
            .tint(Color.vdGold)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.vdPanel.opacity(0.78), in: RoundedRectangle(cornerRadius: 8))
            .onChange(of: viewModel.selectedFriendID) {
                viewModel.requestedFriendCollectionItemIDs = []
            }

            if let selectedFriend {
                Label(selectedFriend.handle, systemImage: "person.2.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.vdTextSecondary)
            }
        }
    }

    private var ownCardPicker: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let selectedFriend {
                let wantedItems = store.cardsFriendWantsThatIOwn(selectedFriend)
                if !wantedItems.isEmpty {
                    collectionPicker(
                        title: "They Want From You",
                        subtitle: "\(wantedItems.filter { viewModel.selectedOfferCardIDs.contains($0.card.id) }.count) selected",
                        items: wantedItems,
                        selectedIDs: selectedOfferItemIDs(for: wantedItems)
                    )
                }
            }

            collectionPicker(
                title: "Offer My Cards",
                subtitle: "\(offeredItems.count) selected",
                items: store.collectionItems,
                selectedIDs: selectedOfferItemIDs(for: store.collectionItems)
            )
        }
    }

    @ViewBuilder
    private var friendCardPicker: some View {
        if let selectedFriend {
            if selectedFriend.visibleCollection.isEmpty {
                EmptyStateView(
                    systemImage: "lock.rectangle.stack",
                    title: "No shared cards",
                    message: "This friend has not shared tradeable collection cards yet."
                )
            } else {
                collectionPicker(
                    title: "Request Their Cards",
                    subtitle: "\(requestedItems.count) selected",
                    items: selectedFriend.visibleCollection,
                    selectedIDs: $viewModel.requestedFriendCollectionItemIDs
                )
            }
        } else {
            EmptyStateView(
                systemImage: "person.2.slash",
                title: "Choose a friend",
                message: "Add a friend first, then build a fair trade offer."
            )
        }
    }

    private func collectionPicker(
        title: String,
        subtitle: String,
        items: [CollectionItem],
        selectedIDs: Binding<Set<CollectionItem.ID>>
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: title, subtitle: subtitle)

            VStack(spacing: 8) {
                ForEach(items) { item in
                    Toggle(isOn: Binding(
                        get: { selectedIDs.wrappedValue.contains(item.id) },
                        set: { isOn in
                            if isOn {
                                selectedIDs.wrappedValue.insert(item.id)
                            } else {
                                selectedIDs.wrappedValue.remove(item.id)
                            }
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.card.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.vdTextPrimary)
                            Text(item.card.marketValue.vaultEstimatedCurrency)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color.vdTextSecondary)
                        }
                    }
                    .tint(Color.vdGold)
                    .padding(12)
                    .background(Color.vdPanel.opacity(0.78), in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    private func selectedOfferItemIDs(for items: [CollectionItem]) -> Binding<Set<CollectionItem.ID>> {
        Binding(
            get: { Set(items.filter { viewModel.selectedOfferCardIDs.contains($0.card.id) }.map(\.id)) },
            set: { ids in
                var selectedCardIDs = viewModel.selectedOfferCardIDs
                for item in items {
                    if ids.contains(item.id) {
                        selectedCardIDs.insert(item.card.id)
                    } else {
                        selectedCardIDs.remove(item.card.id)
                    }
                }
                viewModel.selectedOfferCardIDs = selectedCardIDs
            }
        )
    }

    private var creditsAndMessage: some View {
        VStack(alignment: .leading, spacing: 12) {
            Stepper(value: $viewModel.internalCredits, in: 0...500, step: 5) {
                HStack {
                    Text("Internal credits")
                        .foregroundStyle(Color.vdTextPrimary)
                    Spacer()
                    Text("\(viewModel.internalCredits)")
                        .font(.headline)
                        .foregroundStyle(Color.vdGold)
                }
            }

            TextField("Message", text: $viewModel.offerMessage, axis: .vertical)
                .lineLimit(3...5)
                .foregroundStyle(Color.vdTextPrimary)
                .padding(14)
                .background(Color.vdPanelRaised.opacity(0.82), in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.vdStroke.opacity(0.72), lineWidth: 1))

            Toggle("Safe trade review", isOn: $viewModel.offerUsesSafeTrade)
                .tint(Color.vdGold)
                .foregroundStyle(Color.vdTextPrimary)

            Label("Only trade with people you trust", systemImage: "shield.lefthalf.filled")
                .font(.caption.weight(.black))
                .foregroundStyle(Color.vdGold)
        }
        .padding(14)
        .background(Color.vdPanel.opacity(0.78), in: RoundedRectangle(cornerRadius: 8))
    }

    private var fairTradeMeter: some View {
        let balance = viewModel.valueBalance(offeredCards: offeredCards, requestedCards: requestedCards, credits: viewModel.internalCredits)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Fair trade meter")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.vdTextSecondary)
                Spacer()
                Text(viewModel.fairnessLabel(score: fairScore))
                    .font(.caption.weight(.black))
                    .foregroundStyle(fairScore > 0.85 ? Color.vdEmerald : Color.vdGold)
            }
            ProgressView(value: fairScore)
                .tint(fairScore > 0.85 ? Color.vdEmerald : Color.vdGold)
            Text("Estimated value balance: \(balance.vaultCurrency)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.vdTextPrimary)
        }
        .padding(14)
        .background(Color.vdPanel.opacity(0.78), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct TradeOfferComposer: View {
    @EnvironmentObject private var store: LocalVaultStore
    let listing: TradeListing
    @ObservedObject var viewModel: TradeViewModel
    let onSend: () -> Void

    private var offeredCards: [Card] {
        viewModel.selectedOfferCards(in: store)
    }

    private var requestedCards: [Card] {
        viewModel.requestedCards(from: listing)
    }

    private var fairScore: Double {
        viewModel.fairnessScore(offeredCards: offeredCards, requestedCards: requestedCards, credits: viewModel.internalCredits)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        TradeListingRow(listing: listing, isMine: false) {} onOffer: {} onDetails: {}
                            .allowsHitTesting(false)

                        cardPicker(title: "Offer My Cards", items: store.collectionItems, selectedIDs: $viewModel.selectedOfferCardIDs)
                        requestPicker
                        creditsAndMessage
                        fairTradeMeter

                        PrimaryButton(title: "Send Offer", systemImage: "paperplane.fill", action: onSend)
                            .disabled(offeredCards.isEmpty && viewModel.internalCredits <= 0)
                            .opacity((offeredCards.isEmpty && viewModel.internalCredits <= 0) ? 0.45 : 1)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Create Offer")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func cardPicker(title: String, items: [CollectionItem], selectedIDs: Binding<Set<Card.ID>>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: title, subtitle: "\(selectedIDs.wrappedValue.count) selected")
            VStack(spacing: 8) {
                ForEach(items) { item in
                    Toggle(isOn: Binding(
                        get: { selectedIDs.wrappedValue.contains(item.card.id) },
                        set: { isOn in
                            if isOn {
                                selectedIDs.wrappedValue.insert(item.card.id)
                            } else {
                                selectedIDs.wrappedValue.remove(item.card.id)
                            }
                        }
                    )) {
                        Text(item.card.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.vdTextPrimary)
                    }
                    .tint(Color.vdGold)
                    .padding(12)
                    .background(Color.vdPanel.opacity(0.78), in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    private var requestPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Request Their Cards", subtitle: "Listing card selected")
            Toggle(isOn: Binding(
                get: { viewModel.requestedCardIDs.contains(listing.card.id) },
                set: { isOn in
                    if isOn {
                        viewModel.requestedCardIDs.insert(listing.card.id)
                    } else {
                        viewModel.requestedCardIDs.remove(listing.card.id)
                    }
                }
            )) {
                Text(listing.card.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.vdTextPrimary)
            }
            .tint(Color.vdGold)
            .padding(12)
            .background(Color.vdPanel.opacity(0.78), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private var creditsAndMessage: some View {
        VStack(alignment: .leading, spacing: 12) {
            Stepper(value: $viewModel.internalCredits, in: 0...500, step: 5) {
                HStack {
                    Text("Internal credits")
                        .foregroundStyle(Color.vdTextPrimary)
                    Spacer()
                    Text("\(viewModel.internalCredits)")
                        .font(.headline)
                        .foregroundStyle(Color.vdGold)
                }
            }

            TextField("Message", text: $viewModel.offerMessage, axis: .vertical)
                .lineLimit(3...5)
                .foregroundStyle(Color.vdTextPrimary)
                .padding(14)
                .background(Color.vdPanelRaised.opacity(0.82), in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.vdStroke.opacity(0.72), lineWidth: 1))

            Toggle("Safe trade review", isOn: $viewModel.offerUsesSafeTrade)
                .tint(Color.vdGold)
                .foregroundStyle(Color.vdTextPrimary)

            Label("Only trade with people you trust", systemImage: "shield.lefthalf.filled")
                .font(.caption.weight(.black))
                .foregroundStyle(Color.vdGold)
        }
        .padding(14)
        .background(Color.vdPanel.opacity(0.78), in: RoundedRectangle(cornerRadius: 8))
    }

    private var fairTradeMeter: some View {
        let balance = viewModel.valueBalance(offeredCards: offeredCards, requestedCards: requestedCards, credits: viewModel.internalCredits)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Fair trade meter")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.vdTextSecondary)
                Spacer()
                Text(viewModel.fairnessLabel(score: fairScore))
                    .font(.caption.weight(.black))
                    .foregroundStyle(fairScore > 0.85 ? Color.vdEmerald : Color.vdGold)
            }
            ProgressView(value: fairScore)
                .tint(fairScore > 0.85 ? Color.vdEmerald : Color.vdGold)
            Text("Estimated value balance: \(balance.vaultCurrency)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.vdTextPrimary)
        }
        .padding(14)
        .background(Color.vdPanel.opacity(0.78), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct TradeListingRow: View {
    let listing: TradeListing
    let isMine: Bool
    let onSaveOrRemove: () -> Void
    let onOffer: () -> Void
    let onDetails: () -> Void
    @State private var reportMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                CardTile(card: listing.card, condition: listing.condition, variant: listing.variant, style: .compact)
                    .frame(width: 138)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(listing.ownerName)
                                .font(.headline)
                                .foregroundStyle(Color.vdTextPrimary)

                            Text(listing.ownerHandle + " · " + listing.locationLabel)
                                .font(.caption)
                                .foregroundStyle(Color.vdTextSecondary)
                        }
                        Spacer()
                        if listing.isFeatured {
                            StatusPill(title: "Featured", tint: .vdGold)
                        }
                    }

                    Text(listing.askingFor)
                        .font(.subheadline)
                        .foregroundStyle(Color.vdTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 8) {
                        RarityBadge(rarity: listing.card.rarity)
                        TradeValueChip(value: listing.estimatedValue.vaultEstimatedCurrency, tint: .vdLeaf)
                        StatusPill(title: listing.listingKind.displayName, tint: .vdGold)
                        if let askingCredits = listing.askingCredits, listing.listingKind != .trade {
                            StatusPill(title: "\(askingCredits) credits", tint: .vdSky)
                        }
                    }

                    HStack(spacing: 8) {
                        Label("\(listing.sellerReputation)% rep", systemImage: "checkmark.seal.fill")
                        if listing.usesSafeTrade {
                            Label("Safe trade", systemImage: "shield.fill")
                        }
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.vdTextSecondary)
                }
            }

            HStack(spacing: 10) {
                if isMine {
                    miniButton(title: "Details", systemImage: "info.circle", tint: .vdGold, action: onDetails)
                    miniButton(title: "Remove", systemImage: "trash", tint: .vdCoral, action: onSaveOrRemove)
                } else {
                    miniButton(title: "Details", systemImage: "info.circle", tint: .vdSky, action: onDetails)
                    miniButton(title: listing.isSaved ? "Saved" : "Save", systemImage: listing.isSaved ? "bookmark.fill" : "bookmark", tint: .vdGold, action: onSaveOrRemove)
                    miniButton(title: "Offer", systemImage: "arrow.left.arrow.right", tint: .vdEmerald, action: onOffer)
                    miniButton(title: "Report", systemImage: "exclamationmark.bubble", tint: .vdCoral) {
                        reportMessage = "Report listing flow will be available when moderation is enabled."
                    }
                }
            }

            if let reportMessage {
                Text(reportMessage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.vdTextSecondary)
            }
        }
        .padding(12)
        .background(
            LinearGradient(
                colors: [Color.vdPanelRaised.opacity(0.94), Color.vdPanel.opacity(0.84)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18)
        )
        .overlay(
            LinearGradient(colors: [Color.white.opacity(0.16), Color.clear, Color.vdGold.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .clipShape(RoundedRectangle(cornerRadius: 18))
        )
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.vdGold.opacity(listing.isFeatured ? 0.42 : 0.22), lineWidth: 1.1))
        .shadow(color: Color.vdGold.opacity(listing.isFeatured ? 0.16 : 0.08), radius: 16, x: 0, y: 8)
    }

    private func miniButton(title: String, systemImage: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(tint.opacity(0.13), in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(tint.opacity(0.32), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

private struct TradeListingDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let listing: TradeListing
    let onOffer: () -> Void
    @State private var reportMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        CardTile(card: listing.card, condition: listing.condition, variant: listing.variant)
                            .frame(maxWidth: .infinity)

                        VStack(alignment: .leading, spacing: 12) {
                            Text(listing.card.name)
                                .font(.title2.weight(.black))
                                .foregroundStyle(Color.vdTextPrimary)

                            Text(listing.ownerName + " · " + listing.ownerHandle)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.vdGold)

                            if !listing.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text(listing.description)
                                    .font(.body)
                                    .foregroundStyle(Color.vdTextSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Text(listing.askingFor)
                                .font(.subheadline)
                                .foregroundStyle(Color.vdTextSecondary)
                                .fixedSize(horizontal: false, vertical: true)

                            HStack(spacing: 8) {
                                RarityBadge(rarity: listing.card.rarity)
                                TradeValueChip(value: listing.estimatedValue.vaultEstimatedCurrency, tint: .vdLeaf)
                                StatusPill(title: listing.listingKind.displayName, tint: .vdGold)
                            }

                            if let askingCredits = listing.askingCredits, listing.listingKind != .trade {
                                Label("\(askingCredits) internal credits", systemImage: "seal.fill")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Color.vdSky)
                            }

                            if listing.usesSafeTrade {
                                Label("Safe intermediary requested", systemImage: "shield.fill")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Color.vdTextSecondary)
                            }
                        }
                        .padding(16)
                        .background(Color.vdPanel.opacity(0.84), in: RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.vdStroke.opacity(0.72), lineWidth: 1))

                        if !listing.isMine {
                            PrimaryButton(title: "Make Offer", systemImage: "arrow.left.arrow.right.circle.fill") {
                                dismiss()
                                onOffer()
                            }

                            Button {
                                reportMessage = "Report listing flow will be available when moderation is enabled."
                            } label: {
                                Label("Report Listing", systemImage: "exclamationmark.bubble.fill")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(Color.vdCoral)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .background(Color.vdCoral.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.vdCoral.opacity(0.32), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }

                        if let reportMessage {
                            Text(reportMessage)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.vdTextSecondary)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Listing")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

private struct TradeValueChip: View {
    let value: String
    let tint: Color

    var body: some View {
        Label(value, systemImage: "seal.fill")
            .font(.caption.weight(.black))
            .foregroundStyle(Color.vdNavy)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(
                LinearGradient(colors: [tint, Color.vdGold], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: Capsule()
            )
            .overlay(Capsule().stroke(Color.white.opacity(0.34), lineWidth: 1))
            .shadow(color: tint.opacity(0.20), radius: 8, x: 0, y: 3)
    }
}

private struct TradeOfferRow: View {
    let offer: TradeOffer
    let onStatus: (TradeStatus) -> Void
    @State private var disputeMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(offer.partnerName)
                        .font(.headline)
                        .foregroundStyle(Color.vdTextPrimary)

                    Text(offer.partnerHandle + " · " + offer.direction.displayName)
                        .font(.caption)
                        .foregroundStyle(Color.vdTextSecondary)
                }

                Spacer()
                statusBadge
            }

            Text(offer.note)
                .font(.subheadline)
                .foregroundStyle(Color.vdTextSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .top, spacing: 12) {
                cardStack(title: "Offering", cards: offer.offeredCards)
                Image(systemName: "arrow.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.vdGold)
                    .padding(.top, 28)
                cardStack(title: "Requesting", cards: offer.requestedCards)
            }

            VStack(alignment: .leading, spacing: 8) {
                ProgressView(value: offer.fairnessScore)
                    .tint(offer.fairnessScore > 0.85 ? Color.vdEmerald : Color.vdGold)
                HStack {
                    Text("\(offer.fairnessLabel) · balance \(offer.valueDelta.vaultCurrency)")
                    Spacer()
                    Text("\(offer.internalCredits) credits")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.vdTextSecondary)
            }

            HStack(spacing: 8) {
                if offer.status == .pending {
                    if offer.direction == .received {
                        actionButton("Accept", "checkmark", .vdEmerald) { onStatus(.accepted) }
                        actionButton("Reject", "xmark", .vdCoral) { onStatus(.rejected) }
                    } else {
                        actionButton("Cancel", "xmark", .vdCoral) { onStatus(.canceled) }
                    }
                }

                if offer.status == .accepted {
                    actionButton("Complete", "checkmark.seal.fill", .vdEmerald) { onStatus(.completed) }
                }

                actionButton("Dispute", "exclamationmark.triangle.fill", .vdGold) {
                    disputeMessage = "Dispute flow will be available when moderation is enabled."
                    onStatus(.disputed)
                }
            }

            if let disputeMessage {
                Text(disputeMessage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.vdTextSecondary)
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color.vdPanelRaised.opacity(0.92), Color.vdPanel.opacity(0.82)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18)
        )
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.vdGold.opacity(0.20), lineWidth: 1))
        .shadow(color: Color.vdGold.opacity(0.08), radius: 14, x: 0, y: 7)
    }

    private var statusBadge: some View {
        Text(offer.status.displayName)
            .font(.caption.weight(.bold))
            .foregroundStyle(statusTint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(statusTint.opacity(0.14), in: Capsule())
            .overlay(Capsule().stroke(statusTint.opacity(0.35), lineWidth: 1))
    }

    private var statusTint: Color {
        switch offer.status {
        case .pending: .vdGold
        case .accepted, .completed: .vdEmerald
        case .rejected, .canceled, .disputed: .vdCoral
        }
    }

    private func actionButton(_ title: String, _ systemImage: String, _ tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(tint.opacity(0.32), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func cardStack(title: String, cards: [Card]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.vdTextSecondary)

            VStack(spacing: 6) {
                ForEach(cards.prefix(3)) { card in
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.caption)
                            .foregroundStyle(Color.vdGold)
                            .frame(width: 24, height: 24)
                            .background(Color.vdGold.opacity(0.11), in: RoundedRectangle(cornerRadius: 6))

                        Text(card.name)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.vdTextPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(Color.vdPanelRaised.opacity(0.72), in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
