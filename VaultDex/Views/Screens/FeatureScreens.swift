import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct ImportCollectionView: View {
    @EnvironmentObject private var store: LocalVaultStore
    @StateObject private var viewModel = ImportCollectionViewModel()
    @State private var isFileImporterPresented = false

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    pasteInput
                    reviewSummary
                    matchedRows
                    unmatchedRows
                    exportTools
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("Import Collection")
        .navigationBarTitleDisplayMode(.large)
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [.commaSeparatedText, .json, .plainText],
            allowsMultipleSelection: false
        ) { result in
            loadFile(result)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Import Collection")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.vdTextPrimary)

                    Text("Paste or upload collection data, review matches, then import only confirmed cards.")
                        .font(.subheadline)
                        .foregroundStyle(Color.vdTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "square.and.arrow.down.on.square.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Color.vdEmerald)
            }

            HStack(spacing: 12) {
                MetricPill(title: "Matched", value: "\(viewModel.matchedRows.count)")
                MetricPill(title: "Unmatched", value: "\(viewModel.unmatchedRows.count)")
                MetricPill(title: "Value", value: viewModel.estimatedMatchedValue.compactVaultCurrency)
            }

            HStack(spacing: 10) {
                compactAction(title: "Template", systemImage: "doc.text.fill", tint: .vdViolet) {
                    viewModel.loadCSVTemplate()
                }

                compactAction(title: "Upload CSV", systemImage: "folder.fill", tint: .vdEmerald) {
                    isFileImporterPresented = true
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

    private var pasteInput: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Paste CSV or JSON", subtitle: "CSV columns: Name, Set, Number, Quantity, Condition, Variant, Language")

            TextEditor(text: $viewModel.importText)
                .font(.callout.monospaced())
                .foregroundStyle(Color.vdTextPrimary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 190)
                .padding(12)
                .background(Color.vdPanel.opacity(0.86), in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.vdStroke.opacity(0.78), lineWidth: 1)
                )

            if let errorMessage = viewModel.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.vdCoral)
            }

            PrimaryButton(title: "Review Import", systemImage: "checklist") {
                viewModel.parseImportText(in: store)
            }
        }
    }

    private var reviewSummary: some View {
        VStack(alignment: .leading, spacing: 14) {
            VaultSectionHeader(title: "Import Summary", subtitle: "Nothing is added until you confirm")

            HStack(spacing: 12) {
                MetricPill(title: "Added", value: "\(viewModel.summary.addedCards)")
                MetricPill(title: "Updated", value: "\(viewModel.summary.updatedCards)")
                MetricPill(title: "Unmatched", value: "\(viewModel.summary.unmatchedRows)")
            }

            PrimaryButton(title: "Confirm Matched Import", systemImage: "tray.and.arrow.down.fill") {
                viewModel.confirmImport(into: store)
            }
            .disabled(!viewModel.canConfirmImport)
        }
        .padding(18)
        .background(Color.vdPanel.opacity(0.84), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.78), lineWidth: 1)
        )
    }

    private var matchedRows: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Matched Rows", subtitle: "\(viewModel.matchedRows.count) rows ready to import")

            if viewModel.matchedRows.isEmpty {
                EmptyStateView(
                    systemImage: "checkmark.seal",
                    title: "No matches yet",
                    message: "Paste data and review it to see matched catalogue cards."
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.matchedRows) { row in
                        ImportReviewRow(row: row, isMatched: true)
                    }
                }
            }
        }
    }

    private var unmatchedRows: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Unmatched Rows", subtitle: "These will never import silently")

            if viewModel.unmatchedRows.isEmpty {
                EmptyStateView(
                    systemImage: "shield.checkered",
                    title: "No unmatched rows",
                    message: "Rows that fail catalogue matching will appear here for manual cleanup."
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.unmatchedRows) { row in
                        ImportReviewRow(row: row, isMatched: false)
                    }
                }
            }
        }
    }

    private var exportTools: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Export", subtitle: "Generate local CSV snapshots")

            HStack(spacing: 10) {
                compactAction(title: "Collection CSV", systemImage: "square.and.arrow.up", tint: .vdGold) {
                    viewModel.exportCollectionCSV(from: store)
                }

                compactAction(title: "Wants CSV", systemImage: "star.fill", tint: .vdViolet) {
                    viewModel.exportWishlistCSV(from: store)
                }
            }

            if !viewModel.exportText.isEmpty {
                ExportCSVPanel(csvText: viewModel.exportText)
            }
        }
    }

    private func loadFile(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            let didAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            viewModel.importText = try String(contentsOf: url, encoding: .utf8)
            viewModel.parseImportText(in: store)
        } catch {
            viewModel.errorMessage = "Could not read file: \(error.localizedDescription)"
        }
    }

    private func compactAction(
        title: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(tint.opacity(0.38), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct WishlistView: View {
    @EnvironmentObject private var store: LocalVaultStore
    @StateObject private var viewModel = WishlistViewModel()

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    chaseStrip
                    allItems
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("Wants")
        .navigationBarTitleDisplayMode(.large)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Wants")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.vdTextPrimary)

                    Text(store.runtimeMode == .supabase ? "Find your next grail. Wants sync to Supabase when you are signed in." : "Find your next grail. Offline targets stay available locally.")
                        .font(.subheadline)
                        .foregroundStyle(Color.vdTextSecondary)
                }

                Spacer()

                StatusPill(title: "\(store.wishlistItems.count) Cards", tint: .vdGold)
            }

            HStack(spacing: 12) {
                MetricPill(title: "Target Total", value: viewModel.targetValue(in: store).compactVaultCurrency)
                MetricPill(title: "High Priority", value: "\(viewModel.highPriorityItems(in: store).count)")
            }

            wishlistSyncStatus
        }
        .padding(18)
        .background(Color.vdPanel.opacity(0.84), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.78), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var wishlistSyncStatus: some View {
        if store.lastSyncError?.contains("Wants") == true, let error = store.lastSyncError {
            Label(error, systemImage: "exclamationmark.triangle.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.vdCoral)
                .fixedSize(horizontal: false, vertical: true)
        } else if store.runtimeMode == .supabase {
            Label("Wants are syncing to Supabase", systemImage: "icloud.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.vdSky)
        } else if store.runtimeMode == .offline {
            Label("Showing offline cached wants", systemImage: "wifi.slash")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.vdGold)
        }
    }

    @ViewBuilder
    private var chaseStrip: some View {
        if !viewModel.highPriorityItems(in: store).isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                VaultSectionHeader(title: "Grail Board", subtitle: "Find your next grail")

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(viewModel.highPriorityItems(in: store)) { item in
                            NavigationLink {
                                CardDetailView(card: item.card)
                            } label: {
                                CardTile(card: item.card, style: .compact)
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

    private var allItems: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "All Wants", subtitle: "Priority, target price, and notes")

            if store.wishlistItems.isEmpty {
                EmptyStateView(
                    systemImage: "star.circle.fill",
                    title: "Track cards you want",
                    message: "Add cards from Search or card detail to build a focused wants list with priority, budget, and notes."
                )
            } else {
                VStack(spacing: 12) {
                    matchPlaceholders

                    ForEach(store.wishlistItems) { item in
                        NavigationLink {
                            CardDetailView(card: item.card)
                        } label: {
                            WishlistRow(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var matchPlaceholders: some View {
        HStack(spacing: 12) {
            WishlistMatchCard(title: "Friend Matches", subtitle: "Cards friends may own", systemImage: "person.2.fill", tint: .vdSky)
            WishlistMatchCard(title: "Market Matches", subtitle: "Saved listing alerts soon", systemImage: "storefront.fill", tint: .vdLeaf)
        }
    }
}

struct FriendsView: View {
    @EnvironmentObject private var store: LocalVaultStore
    @StateObject private var viewModel = FriendsViewModel()

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    addFriendCard
                    requestList
                    tradeMatches
                    friendsList
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("Friends")
        .navigationBarTitleDisplayMode(.large)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Friends")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.vdTextPrimary)

                    Text(store.runtimeMode == .supabase ? "Cloud friends, visible collections, wants, and trade matches." : "Offline friends, collections, wants, and local trade matches.")
                        .font(.subheadline)
                        .foregroundStyle(Color.vdTextSecondary)
                }

                Spacer()

                NavigationLink {
                    InviteFriendsView()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color(hex: 0x111318))
                        .frame(width: 42, height: 42)
                        .background(Color.vdGold, in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 12) {
                MetricPill(title: "Friends", value: "\(store.friends.count)")
                MetricPill(title: "Online", value: "\(viewModel.onlineFriends(in: store).count)")
                MetricPill(title: "Requests", value: "\(store.friendRequests.count)")
            }

            if let error = store.lastSyncError, error.contains("Friend") || error.contains("friend") {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.vdCoral)
                    .fixedSize(horizontal: false, vertical: true)
            } else if store.runtimeMode == .supabase {
                Label("Friends sync through Supabase", systemImage: "icloud.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.vdSky)
            }
        }
        .padding(18)
        .background(Color.vdPanel.opacity(0.84), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.78), lineWidth: 1)
        )
    }

    private var addFriendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Add Friend", subtitle: "Search by VaultDex username")

            HStack(spacing: 10) {
                TextField("@username or email", text: $viewModel.addFriendText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundStyle(Color.vdTextPrimary)
                    .padding(14)
                    .background(Color.vdPanelRaised.opacity(0.82), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.vdStroke.opacity(0.8), lineWidth: 1)
                    )

                Button {
                    viewModel.addFriend(in: store)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.vdBackground)
                        .frame(width: 46, height: 46)
                        .background(Color.vdGold, in: RoundedRectangle(cornerRadius: 8))
                }
                .disabled(viewModel.addFriendText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(viewModel.addFriendText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
                .accessibilityLabel("Send friend request")
            }

            if store.isSearchingFriends {
                Label("Searching collectors...", systemImage: "magnifyingglass")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.vdTextSecondary)
            }

            if !store.friendSearchResults.isEmpty {
                VStack(spacing: 8) {
                    ForEach(store.friendSearchResults) { profile in
                        Button {
                            viewModel.addFriendText = profile.username
                            viewModel.addFriend(in: store)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "person.crop.circle.badge.plus")
                                    .foregroundStyle(Color.vdGold)
                                    .frame(width: 32, height: 32)
                                    .background(Color.vdGold.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(profile.displayName)
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(Color.vdTextPrimary)
                                    Text("@\(profile.username)")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Color.vdTextSecondary)
                                }

                                Spacer()

                                Text("Request")
                                    .font(.caption.weight(.black))
                                    .foregroundStyle(Color.vdNavy)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.vdGold, in: Capsule())
                            }
                            .padding(10)
                            .background(Color.vdPanelRaised.opacity(0.7), in: RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
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
        .onChange(of: viewModel.addFriendText) {
            viewModel.searchUsers(in: store)
        }
    }

    private var requestList: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Friend Requests", subtitle: "\(viewModel.incomingRequests(in: store).count) incoming · \(viewModel.outgoingRequests(in: store).count) pending")

            if store.friendRequests.isEmpty {
                EmptyStateView(systemImage: "person.crop.circle.badge.checkmark", title: "Add collectors to trade safely", message: "Search by username to send a request. Incoming and pending requests will appear here.")
            } else {
                VStack(spacing: 10) {
                    ForEach(store.friendRequests) { request in
                        FriendRequestRow(request: request) {
                            store.acceptFriendRequest(request)
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        } onReject: {
                            store.rejectFriendRequest(request)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                }
            }
        }
    }

    private var tradeMatches: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Suggested Trades", subtitle: "Wants overlap from local friend data")

            let opportunities = store.tradeOpportunities()
            if opportunities.isEmpty {
                EmptyStateView(systemImage: "arrow.left.arrow.right.circle.fill", title: "Add collectors to trade safely", message: "Once friends share wants and collections, VaultDex will suggest fair trade opportunities.")
            } else {
                VStack(spacing: 10) {
                    ForEach(opportunities) { opportunity in
                        NavigationLink {
                            FriendProfileView(friend: opportunity.friend)
                        } label: {
                            TradeOpportunityRow(opportunity: opportunity)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var friendsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "My Friends", subtitle: "Public and friends-visible profiles")

            if store.friends.isEmpty {
                EmptyStateView(
                    systemImage: "person.2.badge.plus",
                    title: "Add collectors to trade safely",
                    message: "Start with a username search, then compare wants, visible vault cards, and reputation before trading."
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.topCollectors(in: store)) { friend in
                        NavigationLink {
                            FriendProfileView(friend: friend)
                        } label: {
                            FriendRow(friend: friend)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

struct BinderDesignerView: View {
    @EnvironmentObject private var store: LocalVaultStore
    @StateObject private var viewModel = BinderDesignerViewModel()
    @State private var selectedPageID: BinderPage.ID?
    @State private var selectedSlot: BinderSlot?
    @State private var pageToDelete: BinderPage?
    @State private var pageToRename: BinderPage?
    @State private var renameText = ""
    @State private var isPreviewPresented = false

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header

                    if let page = selectedPage {
                        pageList
                        pageControls(page)
                        pageGrid(page)
                        selectedSlotTools(page)
                    } else {
                        EmptyStateView(
                            systemImage: "rectangle.grid.3x2",
                            title: "No binder pages",
                            message: "Build your dream binder with a 3 by 3 card album page."
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("My Binder")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedSlot) { slot in
            if let page = selectedPage {
                BinderCardPickerView(slot: slot, page: page) { card in
                    applySlotChange(page: page, slot: slot, card: card)
                }
                .environmentObject(store)
            }
        }
        .fullScreenCover(isPresented: $isPreviewPresented) {
            if let page = selectedPage {
                BinderPreviewView(page: page)
            }
        }
        .alert("Rename Page", isPresented: Binding(
            get: { pageToRename != nil },
            set: { if !$0 { pageToRename = nil } }
        )) {
            TextField("Page name", text: $renameText)
            Button("Cancel", role: .cancel) { pageToRename = nil }
            Button("Save") {
                guard let pageToRename else { return }
                viewModel.recordChange(before: pageToRename)
                store.renameBinderPage(pageToRename.id, title: renameText)
                selectedPageID = pageToRename.id
                self.pageToRename = nil
                notify(.light)
            }
        } message: {
            Text("Choose a name that helps you recognize this binder page.")
        }
        .confirmationDialog("Delete this binder page?", isPresented: Binding(
            get: { pageToDelete != nil },
            set: { if !$0 { pageToDelete = nil } }
        ), titleVisibility: .visible) {
            Button("Delete Page", role: .destructive) {
                guard let pageToDelete else { return }
                viewModel.recordChange(before: pageToDelete)
                store.deleteBinderPage(pageToDelete.id)
                selectedPageID = store.binderPages.first?.id
                self.pageToDelete = nil
                notify(.medium)
            }
            Button("Cancel", role: .cancel) { pageToDelete = nil }
        } message: {
            Text("Cards are not removed from your collection. Only this page layout is deleted.")
        }
    }

    private var selectedPage: BinderPage? {
        guard let firstPage = store.binderPages.first else { return nil }
        guard let selectedPageID else { return firstPage }
        return store.binderPages.first { $0.id == selectedPageID } ?? firstPage
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("My Binder")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.vdTextPrimary)

                    Text("Build your dream binder with polished 3 by 3 album pages.")
                        .font(.subheadline)
                        .foregroundStyle(Color.vdTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "rectangle.grid.3x2.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.vdNavy)
                    .frame(width: 56, height: 56)
                    .background(Color.vdGold, in: RoundedRectangle(cornerRadius: 18))
                    .shadow(color: Color.vdGold.opacity(0.26), radius: 14, x: 0, y: 6)
            }

            HStack(spacing: 12) {
                MetricPill(title: "Pages", value: "\(store.binderPages.count)")
                MetricPill(title: "Filled", value: "\(viewModel.filledSlots(in: store))/\(viewModel.totalSlots(in: store))")
            }

            HStack(spacing: 8) {
                Image(systemName: viewModel.hasUnsavedChanges ? "icloud.and.arrow.up" : "checkmark.seal.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(viewModel.hasUnsavedChanges ? Color.vdGold : Color.vdEmerald)

                Text(viewModel.hasUnsavedChanges ? "Unsaved page changes" : "All changes saved")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.vdTextSecondary)

                Spacer()

                Button {
                    createPage()
                } label: {
                    Image(systemName: "plus")
                        .font(.caption.weight(.black))
                        .foregroundStyle(Color.vdBackground)
                        .frame(width: 30, height: 30)
                        .background(Color.vdGold, in: Circle())
                }
                .accessibilityLabel("Create binder page")
            }
        }
        .padding(18)
        .background {
            ZStack {
                binderTexture
                LinearGradient(
                    colors: [Color.vdGold.opacity(0.12), Color.clear, Color.vdViolet.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.vdGold.opacity(0.32), lineWidth: 1)
        )
    }

    private var binderTexture: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x201713), Color.vdPanel.opacity(0.92), Color(hex: 0x3A2515).opacity(0.72)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            ForEach(0..<7, id: \.self) { index in
                Rectangle()
                    .fill(Color.white.opacity(0.035))
                    .frame(height: 1)
                    .rotationEffect(.degrees(-12))
                    .offset(y: CGFloat(index * 18 - 54))
            }
        }
    }

    private var pageList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(store.binderPages) { page in
                    Button {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                            selectedPageID = page.id
                            selectedSlot = nil
                        }
                        notify(.light)
                    } label: {
                        BinderPageListCard(
                            page: page,
                            completionText: viewModel.completionText(for: page),
                            isSelected: selectedPage?.id == page.id
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func pageControls(_ page: BinderPage) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(page.title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.vdTextPrimary)

                    Text("\(viewModel.completionText(for: page)) complete · \(page.theme)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.vdTextSecondary)
                }

                Spacer()

                Button {
                    isPreviewPresented = true
                    notify(.light)
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.vdTextPrimary)
                        .frame(width: 36, height: 36)
                        .background(Color.vdPanelRaised, in: Circle())
                }
                .accessibilityLabel("Preview fullscreen")
            }

            ProgressView(value: viewModel.completion(for: page))
                .tint(Color.vdGold)
                .background(Color.vdStroke.opacity(0.55), in: Capsule())

            Picker("Visibility", selection: Binding(
                get: { page.visibility },
                set: { visibility in
                    viewModel.recordChange(before: page)
                    store.updateBinderVisibility(page.id, visibility: visibility)
                    notify(.light)
                }
            )) {
                ForEach(BinderVisibility.allCases) { visibility in
                    Label(visibility.displayName, systemImage: visibility.systemImage).tag(visibility)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 10) {
                PrimaryButton(title: "Save Page", systemImage: "checkmark.circle.fill") {
                    viewModel.markSaved()
                    notify(.medium)
                }

                Button {
                    viewModel.undoLastChange(in: store, selectedPageID: &selectedPageID)
                    notify(.medium)
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(viewModel.canUndo ? Color.vdTextPrimary : Color.vdTextSecondary.opacity(0.45))
                        .frame(width: 44, height: 44)
                        .background(Color.vdPanelRaised.opacity(0.9), in: RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.vdStroke.opacity(0.65), lineWidth: 1)
                        )
                }
                .disabled(!viewModel.canUndo)
                .accessibilityLabel("Undo last binder change")

                Menu {
                    Button("Rename Page") {
                        pageToRename = page
                        renameText = page.title
                    }
                    Button("Delete Page", role: .destructive) {
                        pageToDelete = page
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.vdTextPrimary)
                        .frame(width: 44, height: 44)
                        .background(Color.vdPanelRaised.opacity(0.9), in: RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.vdStroke.opacity(0.65), lineWidth: 1)
                        )
                }
            }
        }
        .padding(16)
        .background(Color.vdPanel.opacity(0.86), in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.vdGold.opacity(0.22), lineWidth: 1)
        )
    }

    private func pageGrid(_ page: BinderPage) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VaultSectionHeader(title: "3x3 Page Layout", subtitle: "Tap a slot to add, replace, or remove a card")

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(page.slots) { slot in
                    Button {
                        selectedSlot = slot
                        notify(.light)
                    } label: {
                        BinderSlotCell(slot: slot, isSelected: selectedSlot?.id == slot.id)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .background {
            ZStack {
                binderPageTexture
                LinearGradient(
                    colors: [Color.vdGold.opacity(0.08), Color.clear, Color.black.opacity(0.24)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 22))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.vdGold.opacity(0.26), lineWidth: 1)
        )
        .shadow(color: Color.vdGold.opacity(0.10), radius: 18, x: 0, y: 8)
    }

    private var binderPageTexture: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x1B130F), Color(hex: 0x2A1B12), Color(hex: 0x120E0B)], startPoint: .topLeading, endPoint: .bottomTrailing)
            ForEach(0..<10, id: \.self) { index in
                Rectangle()
                    .fill(index.isMultiple(of: 2) ? Color.white.opacity(0.025) : Color.black.opacity(0.045))
                    .frame(height: 1)
                    .offset(y: CGFloat(index * 18 - 82))
            }
        }
    }

    @ViewBuilder
    private func selectedSlotTools(_ page: BinderPage) -> some View {
        if let selectedSlot = selectedSlot, page.slots.contains(where: { $0.id == selectedSlot.id }) {
            VStack(alignment: .leading, spacing: 12) {
                VaultSectionHeader(title: "Selected Slot #\(selectedSlot.index)", subtitle: selectedSlot.card?.name ?? "Ready for a card")

                HStack(spacing: 10) {
                    PrimaryButton(title: selectedSlot.card == nil ? "Add Card" : "Replace Card", systemImage: "rectangle.stack.badge.plus") {
                        self.selectedSlot = selectedSlot
                        notify(.light)
                    }

                    Button {
                        applySlotChange(page: page, slot: selectedSlot, card: nil)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(selectedSlot.card == nil ? Color.vdTextSecondary.opacity(0.45) : Color.vdCoral)
                            .frame(width: 44, height: 44)
                            .background(Color.vdPanelRaised.opacity(0.9), in: RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.vdStroke.opacity(0.65), lineWidth: 1)
                            )
                    }
                    .disabled(selectedSlot.card == nil)
                    .accessibilityLabel("Remove card from slot")
                }
            }
        }
    }

    private func createPage() {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
            let page = store.createBinderPage()
            selectedPageID = page.id
            selectedSlot = nil
        }
        viewModel.markChanged()
        notify(.medium)
    }

    private func applySlotChange(page: BinderPage, slot: BinderSlot, card: Card?) {
        viewModel.recordChange(before: page)
        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
            store.updateBinderSlot(pageID: page.id, slotID: slot.id, card: card)
            selectedSlot = store.binderPages
                .first { $0.id == page.id }?
                .slots
                .first { $0.id == slot.id }
        }
        notify(.medium)
    }

    private func notify(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

struct CompletionTrackerView: View {
    @EnvironmentObject private var store: LocalVaultStore
    @StateObject private var viewModel = CompletionTrackerViewModel()

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    filters
                    setRows
                    cardResults
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("Completion")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $viewModel.searchText, prompt: "Search card, set, or number")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Completion Tracker")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.vdTextPrimary)

                    Text("Track owned, missing, wants, and set completion from your local VaultDex catalogue.")
                        .font(.subheadline)
                        .foregroundStyle(Color.vdTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Text(viewModel.overallFraction(in: store).formatted(.percent.precision(.fractionLength(0))))
                    .font(.system(.title2, design: .rounded, weight: .black))
                    .foregroundStyle(Color.vdGold)
            }

            ProgressView(value: viewModel.overallFraction(in: store))
                .tint(Color.vdGold)
                .background(Color.vdStroke.opacity(0.55), in: Capsule())

            HStack(spacing: 10) {
                MetricPill(title: "Tracked", value: "\(viewModel.totalTracked(in: store))")
                MetricPill(title: "Caught", value: "\(viewModel.ownedCount(in: store))")
                MetricPill(title: "Missing", value: "\(viewModel.missingCount(in: store))")
            }
        }
        .padding(18)
        .background(Color.vdPanel.opacity(0.84), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.78), lineWidth: 1)
        )
    }

    private var filters: some View {
        VStack(alignment: .leading, spacing: 14) {
            VaultSectionHeader(title: "Filters", subtitle: "Focus by caught state, generation, type, or rarity")

            Picker("Caught filter", selection: $viewModel.ownershipFilter) {
                ForEach(CompletionTrackerViewModel.OwnershipFilter.allCases) { filter in
                    Text(filter.displayName).tag(filter)
                }
            }
            .pickerStyle(.segmented)

            VStack(spacing: 10) {
                Picker("Generation", selection: $viewModel.selectedGeneration) {
                    Text("All generations").tag(Int?.none)
                    ForEach(viewModel.generations(in: store), id: \.self) { generation in
                        Text("Gen \(generation)").tag(Int?.some(generation))
                    }
                }

                Picker("Type", selection: $viewModel.selectedType) {
                    Text("All types").tag(CardType?.none)
                    ForEach(CardType.allCases) { type in
                        Text(type.displayName).tag(CardType?.some(type))
                    }
                }

                Picker("Rarity", selection: $viewModel.selectedRarity) {
                    Text("All rarities").tag(CardRarity?.none)
                    ForEach(CardRarity.allCases) { rarity in
                        Text(rarity.displayName).tag(CardRarity?.some(rarity))
                    }
                }
            }
            .pickerStyle(.menu)
            .tint(Color.vdGold)
        }
    }

    private var setRows: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Set Completion", subtitle: "Owned unique cards in your catalogue")

            VStack(spacing: 12) {
                ForEach(viewModel.setProgress(in: store)) { progress in
                    CompletionProgressRow(progress: progress)
                }
            }
        }
    }

    @ViewBuilder
    private var cardResults: some View {
        let cards = viewModel.filteredCards(in: store)

        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Card Entries", subtitle: "\(cards.count) cards match the current filters")

            if cards.isEmpty {
                EmptyStateView(
                    systemImage: "line.3.horizontal.decrease.circle.fill",
                    title: "No matching entries",
                    message: "Loosen the filters to see more of your card catalogue."
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(cards) { card in
                        PokedexEntryRow(
                            card: card,
                            isOwned: viewModel.isOwned(card, in: store),
                            isWishlisted: viewModel.isWishlisted(card, in: store)
                        ) {
                            store.addMissingCardToWishlist(card)
                        }
                    }
                }
            }
        }
    }
}

struct EventsView: View {
    @EnvironmentObject private var store: LocalVaultStore
    @StateObject private var viewModel = EventsViewModel()
    @State private var isEditorPresented = false
    @State private var eventPendingDelete: VaultEvent?

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    calendarStrip
                    visibilityFilters
                    eventList
                    sharedPlaceholder
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("Events")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.resetDraft(featuredSet: store.sets.first)
                    isEditorPresented = true
                } label: {
                    Image(systemName: "plus")
                }
                .tint(Color.vdGold)
            }
        }
        .sheet(isPresented: $isEditorPresented) {
            EventEditorSheet(
                draft: $viewModel.eventDraft,
                sets: store.sets,
                onCancel: { isEditorPresented = false },
                onSave: {
                    let event = viewModel.makeEvent()
                    if viewModel.eventDraft.id == nil {
                        store.addEvent(event)
                    } else {
                        store.updateEvent(event)
                    }
                    isEditorPresented = false
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .confirmationDialog(
            "Delete this event?",
            isPresented: Binding(
                get: { eventPendingDelete != nil },
                set: { if !$0 { eventPendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete Event", role: .destructive) {
                if let eventPendingDelete {
                    store.deleteEvent(eventPendingDelete)
                }
                eventPendingDelete = nil
            }

            Button("Cancel", role: .cancel) {
                eventPendingDelete = nil
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Events")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.vdTextPrimary)

                    Text("Track trade nights, release events, and community goals.")
                        .font(.subheadline)
                        .foregroundStyle(Color.vdTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Button {
                    viewModel.resetDraft(featuredSet: store.sets.first)
                    isEditorPresented = true
                } label: {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Color.vdGold)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 10) {
                MetricPill(title: "Upcoming", value: "\(viewModel.upcomingEvents(in: store).count)")
                MetricPill(title: "Shared", value: "Soon")
                MetricPill(title: "Local", value: "\(store.events.count)")
            }
        }
        .padding(18)
        .background(Color.vdPanel.opacity(0.84), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.78), lineWidth: 1)
        )
    }

    private var calendarStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.filteredEvents(in: store)) { event in
                    VStack(spacing: 8) {
                        Text(event.emojiMarker)
                            .font(.title2)

                        Text(event.date.formatted(.dateTime.month(.abbreviated)))
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color.vdTextSecondary)

                        Text(event.date.formatted(.dateTime.day()))
                            .font(.title3.weight(.black))
                            .foregroundStyle(Color.vdTextPrimary)
                    }
                    .frame(width: 78, height: 104)
                    .background(Color.vdPanelRaised.opacity(0.88), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(event.visibility == .public ? Color.vdGold.opacity(0.72) : Color.vdStroke.opacity(0.72), lineWidth: 1)
                    )
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var visibilityFilters: some View {
        HStack(spacing: 10) {
            Button("All") {
                viewModel.selectedVisibility = nil
            }
            .buttonStyle(FilterChipStyle(isSelected: viewModel.selectedVisibility == nil))

            ForEach(BinderVisibility.allCases) { visibility in
                Button(visibility.displayName) {
                    viewModel.selectedVisibility = visibility
                }
                .buttonStyle(FilterChipStyle(isSelected: viewModel.selectedVisibility == visibility))
            }
        }
    }

    private var eventList: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Calendar", subtitle: "Offline event schedule")

            if viewModel.filteredEvents(in: store).isEmpty {
                EmptyStateView(
                    systemImage: "calendar.badge.exclamationmark",
                    title: "No events yet",
                    message: "Add your next trade night, release event, or collector meetup."
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.filteredEvents(in: store)) { event in
                        VaultEventRow(
                            event: event,
                            onEdit: {
                                viewModel.editDraft(from: event)
                                isEditorPresented = true
                            },
                            onDelete: {
                                eventPendingDelete = event
                            }
                        )
                    }
                }
            }
        }
    }

    private var sharedPlaceholder: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.2.wave.2.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.vdViolet)
                .frame(width: 46, height: 46)
                .background(Color.vdViolet.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text("Shared Friend Events")
                    .font(.headline)
                    .foregroundStyle(Color.vdTextPrimary)

                Text("Friend RSVPs and shared event calendars will connect here once sync is added.")
                    .font(.subheadline)
                    .foregroundStyle(Color.vdTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(Color.vdPanel.opacity(0.82), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.72), lineWidth: 1)
        )
    }
}

struct InviteFriendsView: View {
    @StateObject private var viewModel = InviteFriendsViewModel()
    @State private var didCopyInvite = false

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    inviteCard
                    contactList
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("Invite")
        .navigationBarTitleDisplayMode(.large)
    }

    private var inviteCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Invite Friends")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.vdTextPrimary)

                    Text("A local sharing flow today; real invites can plug into backend auth later.")
                        .font(.subheadline)
                        .foregroundStyle(Color.vdTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "paperplane.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.vdViolet)
            }

            Text(viewModel.inviteCode)
                .font(.system(.title, design: .monospaced, weight: .black))
                .foregroundStyle(Color.vdGold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.vdPanelRaised.opacity(0.82), in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.vdGold.opacity(0.3), lineWidth: 1)
                )

            PrimaryButton(title: "Send Invites", systemImage: "paperplane.fill") {}

            HStack(spacing: 10) {
                ShareLink(item: viewModel.inviteMessage) {
                    Label("Share Invite", systemImage: "square.and.arrow.up")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.vdBackground)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(Color.vdGold, in: RoundedRectangle(cornerRadius: 8))
                }

                Button {
                    UIPasteboard.general.string = viewModel.inviteMessage
                    didCopyInvite = true
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Label(didCopyInvite ? "Copied" : "Copy", systemImage: didCopyInvite ? "checkmark" : "doc.on.doc")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.vdTextPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(Color.vdPanelRaised.opacity(0.9), in: RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.vdStroke.opacity(0.68), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .background(Color.vdPanel.opacity(0.84), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.78), lineWidth: 1)
        )
    }

    private var contactList: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Suggested Contacts", subtitle: "\(viewModel.pendingContacts.count) still pending")

            VStack(spacing: 12) {
                ForEach(viewModel.contacts) { contact in
                    InviteContactRow(contact: contact)
                }
            }
        }
    }
}

struct AccountDeletionView: View {
    @EnvironmentObject private var store: LocalVaultStore
    @StateObject private var viewModel = AccountDeletionViewModel()
    @State private var isDeleteConfirmationPresented = false
    @State private var didResetLocalState = false

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    warning
                    checklist
                    confirmation
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("Delete Account")
        .navigationBarTitleDisplayMode(.large)
        .confirmationDialog(
            "Delete local test account data?",
            isPresented: $isDeleteConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("Delete and Reset Local State", role: .destructive) {
                store.resetDemoUserState()
                viewModel.confirmationText = ""
                didResetLocalState = true
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This deletes collection, wants, binder, trade, and profile data in local mode, then returns VaultDex to an empty local state.")
        }
    }

    private var warning: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.vdCoral)

            Text("Account Deletion")
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.vdTextPrimary)

            Text("Deleting an account removes collection, wants, binder, trade, and profile data. In local mode this resets VaultDex back to an empty local state.")
                .font(.subheadline)
                .foregroundStyle(Color.vdTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(Color.vdPanel.opacity(0.84), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdCoral.opacity(0.36), lineWidth: 1)
        )
    }

    private var checklist: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Deletion Plan", subtitle: "Steps this app will need before launch")

            VStack(spacing: 10) {
                ForEach(viewModel.checklist, id: \.self) { item in
                    DeletionChecklistRow(title: item)
                }
            }
        }
    }

    private var confirmation: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Type DELETE to confirm.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.vdTextPrimary)

            TextField("DELETE", text: $viewModel.confirmationText)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .foregroundStyle(Color.vdTextPrimary)
                .padding(14)
                .background(Color.vdPanelRaised.opacity(0.82), in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.vdStroke.opacity(0.8), lineWidth: 1)
                )

            PrimaryButton(title: "Delete Account", systemImage: "trash.fill") {
                isDeleteConfirmationPresented = true
            }
                .disabled(!viewModel.canRequestDeletion)

            if didResetLocalState {
                Label("Local test state reset", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.vdEmerald)
            }
        }
        .padding(18)
        .background(Color.vdPanel.opacity(0.84), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.78), lineWidth: 1)
        )
    }
}

private struct ImportReviewRow: View {
    let row: ParsedImportRow
    let isMatched: Bool

    var body: some View {
        HStack(spacing: 12) {
            if let card = row.matchedCard {
                CardTile(
                    card: card,
                    quantity: row.quantity,
                    condition: row.condition,
                    variant: row.variant,
                    style: .compact
                )
                .frame(width: 150)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Image(systemName: "questionmark.square.dashed")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Color.vdCoral)

                    Text(row.name.isEmpty ? "Missing name" : row.name)
                        .font(.headline)
                        .foregroundStyle(Color.vdTextPrimary)
                        .lineLimit(2)

                    Text(row.set.isEmpty ? "No set supplied" : row.set)
                        .font(.caption)
                        .foregroundStyle(Color.vdTextSecondary)
                        .lineLimit(2)
                }
                .frame(width: 150, alignment: .topLeading)
                .frame(minHeight: 190, alignment: .topLeading)
                .padding(12)
                .background(Color.vdPanelRaised.opacity(0.74), in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.vdCoral.opacity(0.45), lineWidth: 1)
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                StatusPill(title: isMatched ? "Matched" : "Needs Review", tint: isMatched ? .vdEmerald : .vdCoral)

                Text(row.name.isEmpty ? "Unnamed row" : row.name)
                    .font(.headline)
                    .foregroundStyle(Color.vdTextPrimary)
                    .lineLimit(2)

                Text(importDetails)
                    .font(.caption)
                    .foregroundStyle(Color.vdTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let card = row.matchedCard {
                    Text(card.set.name + " #" + card.number)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.vdGold)
                } else {
                    Text("This row will be skipped until its name, set, or number matches the local catalogue.")
                        .font(.caption)
                        .foregroundStyle(Color.vdTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(12)
        .background(Color.vdPanel.opacity(0.86), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke((isMatched ? Color.vdStroke : Color.vdCoral.opacity(0.5)), lineWidth: 1)
        )
    }

    private var importDetails: String {
        [
            "Row \(row.rowNumber)",
            row.set.isEmpty ? nil : row.set,
            row.number.isEmpty ? nil : "#" + row.number,
            "\(row.quantity)x",
            row.condition.displayName,
            row.variant.displayName,
            row.language
        ]
        .compactMap { $0 }
        .joined(separator: " · ")
    }
}

private struct ExportCSVPanel: View {
    let csvText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("CSV Preview", systemImage: "doc.plaintext.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.vdTextPrimary)

                Spacer()

                Button {
                    UIPasteboard.general.string = csvText
                } label: {
                    Label("Copy", systemImage: "doc.on.doc.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.vdGold)
                }
                .buttonStyle(.plain)
            }

            Text(csvText)
                .font(.caption.monospaced())
                .foregroundStyle(Color.vdTextPrimary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color.vdPanelRaised.opacity(0.78), in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.vdStroke.opacity(0.72), lineWidth: 1)
                )
        }
        .padding(14)
        .background(Color.vdPanel.opacity(0.86), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.72), lineWidth: 1)
        )
    }
}

private struct WishlistRow: View {
    let item: WishlistItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            CardTile(card: item.card, variant: item.priority == .grail ? .secretRare : nil, style: .compact)
                .frame(width: 150)

            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    StatusPill(title: item.priority == .grail ? "Grail" : item.priority.displayName, tint: priorityTint)
                    Spacer()
                    tradeValueChip(item.budget.vaultCurrency, tint: .vdGold)
                }

                Text(item.card.name)
                    .font(.headline)
                    .foregroundStyle(Color.vdTextPrimary)
                    .lineLimit(2)

                Text("Preferred: \(item.preferredCondition.displayName)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.vdSky)

                Text(item.notes)
                    .font(.subheadline)
                    .foregroundStyle(Color.vdTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .background(
            LinearGradient(
                colors: item.priority == .grail
                ? [Color.vdGold.opacity(0.20), Color.vdPanel.opacity(0.92), Color.vdCoral.opacity(0.12)]
                : [Color.vdPanelRaised.opacity(0.92), Color.vdPanel.opacity(0.86)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke((item.priority == .grail ? Color.vdGold : Color.vdStroke).opacity(item.priority == .grail ? 0.58 : 0.72), lineWidth: 1.1)
        )
        .shadow(color: (item.priority == .grail ? Color.vdGold : Color.clear).opacity(0.18), radius: 18, x: 0, y: 8)
    }

    private func tradeValueChip(_ value: String, tint: Color) -> some View {
        Label(value, systemImage: "seal.fill")
            .font(.caption.weight(.black))
            .foregroundStyle(Color.vdNavy)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(tint.opacity(0.92), in: Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.34), lineWidth: 1))
    }

    private var priorityTint: Color {
        switch item.priority {
        case .grail: .vdCoral
        case .high: .vdGold
        case .medium: .vdViolet
        case .low: .vdTextSecondary
        }
    }
}

private struct WishlistMatchCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.headline.weight(.black))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.black))
                    .foregroundStyle(Color.vdTextPrimary)

                Text(subtitle)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.vdTextSecondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.vdPanelRaised.opacity(0.72), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(tint.opacity(0.24), lineWidth: 1)
        )
    }
}

private struct FriendProfileView: View {
    @EnvironmentObject private var store: LocalVaultStore
    @Environment(\.dismiss) private var dismiss
    let friend: Friend
    @State private var isRemoveConfirmationPresented = false
    @State private var actionMessage: String?

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    profileHeader
                    matchSummary
                    visibleCollection
                    wishlist
                    safetyActions
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle(friend.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Remove friend?", isPresented: $isRemoveConfirmationPresented, titleVisibility: .visible) {
            Button("Remove Friend", role: .destructive) {
                store.removeFriend(friend)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the local friendship and hides their collection, wants, and trade matches.")
        }
    }

    private var profileHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                Image(systemName: friend.avatarSymbol)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(friend.isOnline ? Color.vdEmerald : Color.vdGold)
                    .frame(width: 68, height: 68)
                    .background(Color.vdPanelRaised.opacity(0.86), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke((friend.isOnline ? Color.vdEmerald : Color.vdGold).opacity(0.35), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(friend.displayName)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.vdTextPrimary)

                    Text(friend.handle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.vdGold)

                    Text(friend.email.isEmpty ? "VaultDex collector" : friend.email)
                        .font(.caption)
                        .foregroundStyle(Color.vdTextSecondary)
                }

                Spacer()
            }

            HStack(spacing: 10) {
                MetricPill(title: "Score", value: "\(friend.collectorScore)")
                MetricPill(title: "Trades", value: "\(friend.mutualTrades)")
                MetricPill(title: "Complete", value: friend.completionPercent.formatted(.percent.precision(.fractionLength(0))))
            }
        }
        .padding(18)
        .background(Color.vdPanel.opacity(0.86), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.72), lineWidth: 1)
        )
    }

    private var matchSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Trade Match", subtitle: "Wants overlap between both collections")

            VStack(spacing: 10) {
                FriendMatchCard(
                    title: "I want, \(friend.displayName) owns",
                    items: store.cardsIWantThatFriendOwns(friend),
                    tint: .vdGold
                )

                FriendMatchCard(
                    title: "\(friend.displayName) wants, I own",
                    items: store.cardsFriendWantsThatIOwn(friend),
                    tint: .vdEmerald
                )
            }
        }
    }

    private var visibleCollection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(
                title: "Visible Collection",
                subtitle: "\(friend.collectionVisibility.displayName) · \(friend.visibleCollection.count) cards"
            )

            if friend.visibleCollection.isEmpty {
                EmptyStateView(systemImage: "lock.rectangle.stack", title: "No visible cards", message: "This friend has not shared collection cards yet.")
            } else {
                VStack(spacing: 10) {
                    ForEach(friend.visibleCollection) { item in
                        NavigationLink {
                            CardDetailView(card: item.card)
                        } label: {
                            FriendCardRow(item: item, badge: store.isWishlisted(item.card) ? "You want" : nil)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var wishlist: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(
                title: "Wants",
                subtitle: "\(friend.wishlistVisibility.displayName) · \(friend.wishlist.count) targets"
            )

            if friend.wishlist.isEmpty {
                EmptyStateView(systemImage: "star.slash", title: "No visible wants", message: "Wanted cards will appear here when shared.")
            } else {
                VStack(spacing: 10) {
                    ForEach(friend.wishlist) { item in
                        NavigationLink {
                            CardDetailView(card: item.card)
                        } label: {
                            FriendWishlistRow(item: item, youOwn: store.collectionItem(for: item.card) != nil)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var safetyActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Friend Controls", subtitle: "Trust and safety actions")

            PrimaryButton(title: "Remove Friend", systemImage: "person.fill.xmark") {
                isRemoveConfirmationPresented = true
            }

            HStack(spacing: 10) {
                PlaceholderActionButton(title: "Block", systemImage: "hand.raised.fill", tint: .vdCoral) {
                    actionMessage = "Block flow will be available when moderation is enabled."
                }
                PlaceholderActionButton(title: "Report", systemImage: "exclamationmark.bubble.fill", tint: .vdGold) {
                    actionMessage = "Report flow will be available when moderation is enabled."
                }
            }

            if let actionMessage {
                Text(actionMessage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.vdTextSecondary)
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

private struct FriendRequestRow: View {
    let request: FriendRequest
    let onAccept: () -> Void
    let onReject: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: request.avatarSymbol)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(request.direction == .incoming ? Color.vdEmerald : Color.vdGold)
                .frame(width: 46, height: 46)
                .background(Color.vdPanelRaised.opacity(0.82), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(request.displayName)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.vdTextPrimary)

                Text("\(request.direction.displayName) · \(request.handleOrEmail)")
                    .font(.caption)
                    .foregroundStyle(Color.vdTextSecondary)
            }

            Spacer()

            if request.direction == .incoming {
                Button(action: onAccept) {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.black))
                        .foregroundStyle(Color.vdBackground)
                        .frame(width: 34, height: 34)
                        .background(Color.vdEmerald, in: Circle())
                }
                .accessibilityLabel("Accept friend request")

                Button(action: onReject) {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.black))
                        .foregroundStyle(Color.vdCoral)
                        .frame(width: 34, height: 34)
                        .background(Color.vdCoral.opacity(0.12), in: Circle())
                }
                .accessibilityLabel("Reject friend request")
            } else {
                StatusPill(title: "Pending", tint: .vdGold)
            }
        }
        .padding(14)
        .background(Color.vdPanel.opacity(0.82), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.68), lineWidth: 1)
        )
    }
}

private struct TradeOpportunityRow: View {
    let opportunity: FriendTradeOpportunity

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(opportunity.friend.displayName, systemImage: opportunity.friend.avatarSymbol)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.vdTextPrimary)

                Spacer()

                StatusPill(title: "\(opportunity.score) matches", tint: .vdGold)
            }

            HStack(spacing: 10) {
                MetricPill(title: "They Own", value: "\(opportunity.theyOwn.count)")
                MetricPill(title: "You Own", value: "\(opportunity.youOwn.count)")
            }

            Text(previewText)
                .font(.caption)
                .foregroundStyle(Color.vdTextSecondary)
                .lineLimit(2)
        }
        .padding(14)
        .background(Color.vdPanel.opacity(0.84), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdGold.opacity(0.18), lineWidth: 1)
        )
    }

    private var previewText: String {
        let theirCard = opportunity.theyOwn.first?.card.name
        let yourCard = opportunity.youOwn.first?.card.name
        return switch (theirCard, yourCard) {
        case let (.some(theirCard), .some(yourCard)):
            "\(theirCard) could match with \(yourCard)."
        case let (.some(theirCard), .none):
            "They own \(theirCard), one of your wanted cards."
        case let (.none, .some(yourCard)):
            "They want \(yourCard), which is in your collection."
        default:
            "Open profile for details."
        }
    }
}

private struct FriendMatchCard: View {
    let title: String
    let items: [CollectionItem]
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.vdTextSecondary)

                Spacer()

                Text("\(items.count)")
                    .font(.caption.weight(.black))
                    .foregroundStyle(tint)
            }

            if items.isEmpty {
                Text("No overlap yet")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.vdTextPrimary)
            } else {
                Text(items.map { $0.card.name }.joined(separator: ", "))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.vdTextPrimary)
                    .lineLimit(2)
            }
        }
        .padding(14)
        .background(Color.vdPanel.opacity(0.82), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(tint.opacity(0.22), lineWidth: 1)
        )
    }
}

private struct FriendCardRow: View {
    let item: CollectionItem
    let badge: String?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "rectangle.stack.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.vdGold)
                .frame(width: 46, height: 46)
                .background(Color.vdPanelRaised.opacity(0.82), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(item.card.name)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.vdTextPrimary)

                Text("\(item.card.set.code) #\(item.card.number) · \(item.variant.displayName)")
                    .font(.caption)
                    .foregroundStyle(Color.vdTextSecondary)
            }

            Spacer()

            if let badge {
                StatusPill(title: badge, tint: .vdGold)
            } else {
                Text("x\(item.quantity)")
                    .font(.caption.weight(.black))
                    .foregroundStyle(Color.vdTextSecondary)
            }
        }
        .padding(14)
        .background(Color.vdPanel.opacity(0.82), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.68), lineWidth: 1)
        )
    }
}

private struct FriendWishlistRow: View {
    let item: WishlistItem
    let youOwn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: youOwn ? "checkmark.seal.fill" : "star.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(youOwn ? Color.vdEmerald : Color.vdGold)
                .frame(width: 46, height: 46)
                .background(Color.vdPanelRaised.opacity(0.82), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(item.card.name)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.vdTextPrimary)

                Text("\(item.priority.displayName) · \(item.budget.vaultCurrency)")
                    .font(.caption)
                    .foregroundStyle(Color.vdTextSecondary)
            }

            Spacer()

            StatusPill(title: youOwn ? "You own" : "Wanted", tint: youOwn ? .vdEmerald : .vdGold)
        }
        .padding(14)
        .background(Color.vdPanel.opacity(0.82), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.68), lineWidth: 1)
        )
    }
}

private struct PlaceholderActionButton: View {
    let title: String
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(tint)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(tint.opacity(0.35), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct FriendRow: View {
    let friend: Friend

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: friend.avatarSymbol)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(friend.isOnline ? Color.vdEmerald : Color.vdTextSecondary)
                    .frame(width: 50, height: 50)
                    .background(Color.vdPanelRaised.opacity(0.82), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke((friend.isOnline ? Color.vdEmerald : Color.vdStroke).opacity(0.5), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(friend.displayName)
                        .font(.headline)
                        .foregroundStyle(Color.vdTextPrimary)

                    Text(friend.handle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.vdGold)
                }

                Spacer()

                StatusPill(title: friend.isOnline ? "Online" : "Away", tint: friend.isOnline ? .vdEmerald : .vdTextSecondary)
            }

            HStack(spacing: 12) {
                MetricPill(title: "Score", value: "\(friend.collectorScore)")
                MetricPill(title: "Trades", value: "\(friend.mutualTrades)")
                MetricPill(title: "Complete", value: friend.completionPercent.formatted(.percent.precision(.fractionLength(0))))
            }

            HStack(spacing: 10) {
                Text("Favorite")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.vdTextSecondary)

                Text(friend.favoriteCard.name)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.vdTextPrimary)
                    .lineLimit(1)

                Spacer()

                RarityBadge(rarity: friend.favoriteCard.rarity)
            }
        }
        .padding(16)
        .background(Color.vdPanel.opacity(0.86), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.72), lineWidth: 1)
        )
    }
}

private struct BinderPageListCard: View {
    let page: BinderPage
    let completionText: String
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: page.visibility.systemImage)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.vdGold)

                Spacer()

                Text(completionText)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(Color.vdBackground)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.vdGold, in: Capsule())
            }

            Text(page.title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.vdTextPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Text(page.visibility.displayName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.vdTextSecondary)
        }
        .frame(width: 150, alignment: .leading)
        .padding(14)
        .background {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: 0x2A1B12).opacity(0.88), Color.vdPanelRaised.opacity(0.88)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                LinearGradient(
                    colors: [Color.vdGold.opacity(isSelected ? 0.16 : 0.06), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color.vdGold.opacity(0.88) : Color.vdStroke.opacity(0.68), lineWidth: isSelected ? 1.4 : 1)
        )
        .shadow(color: isSelected ? Color.vdGold.opacity(0.16) : Color.clear, radius: 12, x: 0, y: 6)
    }
}

private struct BinderCardPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: LocalVaultStore
    let slot: BinderSlot
    let page: BinderPage
    let onSelect: (Card?) -> Void
    @State private var query = ""

    private var filteredCards: [Card] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return store.cards }
        return store.cards.filter { card in
            card.name.lowercased().contains(trimmed) ||
            card.set.name.lowercased().contains(trimmed) ||
            card.set.code.lowercased().contains(trimmed) ||
            card.rarity.displayName.lowercased().contains(trimmed)
        }
    }

    private var ownedCards: [Card] {
        store.collectionItems.map(\.card)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        slotHeader

                        if !ownedCards.isEmpty && query.isEmpty {
                            cardSection(title: "My Collection", cards: ownedCards)
                        }

                        cardSection(title: query.isEmpty ? "All Cards" : "Search Results", cards: filteredCards)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("Slot #\(slot.index)")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Search cards, sets, rarity")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if slot.card != nil {
                        Button("Remove", role: .destructive) {
                            onSelect(nil)
                            dismiss()
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var slotHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(page.title)
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.vdTextPrimary)

            Text(slot.card == nil ? "Choose a card for this empty album slot." : "Replace or remove \(slot.card?.name ?? "this card").")
                .font(.subheadline)
                .foregroundStyle(Color.vdTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.vdPanel.opacity(0.88), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.72), lineWidth: 1)
        )
    }

    private func cardSection(title: String, cards: [Card]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: title, subtitle: "\(cards.count) available")

            if cards.isEmpty {
                EmptyStateView(systemImage: "magnifyingglass", title: "No cards found", message: "Try another name, set, or rarity.")
            } else {
                VStack(spacing: 10) {
                    ForEach(cards) { card in
                        Button {
                            onSelect(card)
                            dismiss()
                        } label: {
                            BinderPickerCardRow(card: card, isOwned: store.collectionItem(for: card) != nil)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct BinderPickerCardRow: View {
    let card: Card
    let isOwned: Bool

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(cardGradient)
                .frame(width: 48, height: 62)
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.82))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(card.name)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.vdTextPrimary)
                    .lineLimit(1)

                Text("\(card.set.code) #\(card.number) · \(card.cardType.displayName)")
                    .font(.caption)
                    .foregroundStyle(Color.vdTextSecondary)
            }

            Spacer()

            if isOwned {
                Image(systemName: "checkmark.seal.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.vdEmerald)
            }

            RarityBadge(rarity: card.rarity)
        }
        .padding(12)
        .background(Color.vdPanel.opacity(0.84), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.62), lineWidth: 1)
        )
    }

    private var cardGradient: LinearGradient {
        switch card.accent {
        case .aurora:
            LinearGradient(colors: [Color.vdViolet, Color.vdEmerald], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .ember:
            LinearGradient(colors: [Color.vdCoral, Color.vdGold], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .frost:
            LinearGradient(colors: [Color.cyan, Color.vdViolet], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .solar:
            LinearGradient(colors: [Color.vdGold, Color.orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .venom:
            LinearGradient(colors: [Color.green, Color.vdViolet], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .void:
            LinearGradient(colors: [Color.vdPanelRaised, Color.vdViolet], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

private struct BinderPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    let page: BinderPage

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(page.title)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color.vdTextPrimary)

                        Text(page.visibility.displayName)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.vdGold)
                    }

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color.vdTextPrimary)
                            .frame(width: 40, height: 40)
                            .background(Color.vdPanelRaised.opacity(0.9), in: Circle())
                    }
                    .accessibilityLabel("Close preview")
                }

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(page.slots) { slot in
                        BinderSlotCell(slot: slot, isSelected: false)
                            .scaleEffect(1.03)
                    }
                }
                .padding(14)
                .background(
                    LinearGradient(colors: [Color(hex: 0x2A1B12), Color(hex: 0x120E0B)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 22)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.vdGold.opacity(0.24), lineWidth: 1)
                )

                Spacer(minLength: 0)
            }
            .padding(20)
        }
    }
}

private struct BinderSlotCell: View {
    let slot: BinderSlot
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(slotBackground)
                    .overlay(texture)

                if let card = slot.card {
                    VStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(card.rarity.slotTint)

                        Text(card.name)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.vdTextPrimary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.75)

                        RarityBadge(rarity: card.rarity)
                    }
                    .padding(8)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "rectangle.dashed")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Color.vdGold.opacity(0.72))

                        Text(slot.note.isEmpty ? "Empty" : slot.note)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.vdTextSecondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.75)
                    }
                    .padding(8)
                }
            }
            .frame(height: 138)
            .shadow(color: glowColor, radius: glowRadius, x: 0, y: 0)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.vdGold : borderColor, lineWidth: isSelected ? 1.6 : 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.white.opacity(slot.card == nil ? 0.06 : 0.18), lineWidth: 0.7)
                    .padding(5)
            )

            Text("#\(slot.index)")
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.vdTextSecondary)
        }
    }

    private var slotBackground: LinearGradient {
        if let card = slot.card {
            switch card.accent {
            case .aurora:
                return LinearGradient(colors: [Color.vdViolet.opacity(0.88), Color.vdEmerald.opacity(0.58)], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .ember:
                return LinearGradient(colors: [Color.vdCoral.opacity(0.9), Color.vdGold.opacity(0.54)], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .frost:
                return LinearGradient(colors: [Color.cyan.opacity(0.62), Color.vdViolet.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .solar:
                return LinearGradient(colors: [Color.vdGold.opacity(0.85), Color.orange.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .venom:
                return LinearGradient(colors: [Color.green.opacity(0.66), Color.vdViolet.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .void:
                return LinearGradient(colors: [Color.vdPanelRaised.opacity(0.95), Color.vdViolet.opacity(0.58)], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }

        return LinearGradient(colors: [Color(hex: 0x2B221B), Color(hex: 0x120F0C)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var texture: some View {
        ZStack {
            LinearGradient(
                colors: [Color.white.opacity(0.06), Color.clear, Color.black.opacity(0.18)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.white.opacity(slot.card == nil ? 0.05 : 0.12), lineWidth: 0.5)
                .padding(5)

            if slot.card != nil {
                LinearGradient(
                    colors: [Color.white.opacity(0.20), Color.clear, Color.vdGold.opacity(0.10), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .blendMode(.screen)
            }
        }
    }

    private var borderColor: Color {
        slot.card == nil ? Color.vdGold.opacity(0.18) : Color.vdGold.opacity(0.34)
    }

    private var glowColor: Color {
        guard let rarity = slot.card?.rarity else { return Color.clear }
        switch rarity {
        case .legendary, .mythic:
            return Color.vdGold.opacity(0.34)
        case .epic:
            return Color.vdViolet.opacity(0.24)
        default:
            return Color.clear
        }
    }

    private var glowRadius: CGFloat {
        guard let rarity = slot.card?.rarity else { return 0 }
        return switch rarity {
        case .legendary, .mythic: 12
        case .epic: 8
        default: 0
        }
    }
}

private struct CompletionProgressRow: View {
    let progress: SetProgress

    var body: some View {
        HStack(spacing: 14) {
            SetProgressRing(fraction: progress.fraction)

            VStack(alignment: .leading, spacing: 9) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(progress.cardSet.name)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.vdTextPrimary)

                    Text(progress.cardSet.code + " · " + "\(progress.cardSet.releaseYear)")
                        .font(.caption)
                        .foregroundStyle(Color.vdTextSecondary)
                }

                HStack {
                    ProgressView(value: progress.fraction)
                        .tint(Color.vdGold)
                        .background(Color.vdStroke.opacity(0.55), in: Capsule())

                    Text("\(progress.owned)/\(progress.total)")
                        .font(.caption.weight(.black))
                        .foregroundStyle(Color.vdGold)
                }
            }
        }
        .padding(14)
        .background(Color.vdPanel.opacity(0.84), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.vdGold.opacity(0.22), lineWidth: 1)
        )
    }
}

private struct SetProgressRing: View {
    let fraction: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.vdStroke.opacity(0.45), lineWidth: 7)
            Circle()
                .trim(from: 0, to: min(max(fraction, 0), 1))
                .stroke(
                    LinearGradient(colors: [Color.vdGold, Color.vdLeaf, Color.vdSky], startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: 7, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            Text(fraction.formatted(.percent.precision(.fractionLength(0))))
                .font(.caption2.weight(.black))
                .foregroundStyle(Color.vdTextPrimary)
        }
        .frame(width: 50, height: 50)
        .shadow(color: Color.vdGold.opacity(0.16), radius: 8, x: 0, y: 4)
    }
}

private struct PokedexEntryRow: View {
    let card: Card
    let isOwned: Bool
    let isWishlisted: Bool
    let onWishlist: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            CardTile(card: card, style: .compact)
                .frame(width: 86, height: 118)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    StatusPill(title: isOwned ? "Caught" : "Missing", tint: isOwned ? .vdEmerald : .vdCoral)
                    RarityBadge(rarity: card.rarity)
                }

                Text(card.name)
                    .font(.headline)
                    .foregroundStyle(Color.vdTextPrimary)
                    .lineLimit(1)

                Text("\(card.set.name) · #\(card.number) · \(card.cardType.displayName)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.vdTextSecondary)
                    .lineLimit(2)

                ProgressView(value: min(Double(card.power) / 100, 1))
                    .tint(isOwned ? Color.vdEmerald : Color.vdGold)
                    .background(Color.vdStroke.opacity(0.45), in: Capsule())
            }

            Spacer()

            VStack(spacing: 10) {
                NavigationLink {
                    CardDetailView(card: card)
                } label: {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color.vdGold)
                }
                .buttonStyle(.plain)

                if !isOwned {
                    Button {
                        onWishlist()
                    } label: {
                        Image(systemName: isWishlisted ? "star.fill" : "star")
                            .font(.system(size: 19, weight: .bold))
                            .foregroundStyle(isWishlisted ? Color.vdGold : Color.vdTextSecondary)
                    }
                    .buttonStyle(.plain)
                    .disabled(isWishlisted)
                    .accessibilityLabel(isWishlisted ? "Already in wants" : "Add missing card to wants")
                }
            }
        }
        .padding(14)
        .background(Color.vdPanel.opacity(0.86), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isOwned ? Color.vdEmerald.opacity(0.34) : Color.vdStroke.opacity(0.72), lineWidth: 1)
        )
    }
}

private struct FilterChipStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.bold))
            .foregroundStyle(isSelected ? Color.vdBackground : Color.vdTextSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(isSelected ? Color.vdGold : Color.vdPanelRaised.opacity(0.82), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.vdGold.opacity(0.2) : Color.vdStroke.opacity(0.72), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

private extension CardRarity {
    var slotTint: Color {
        switch self {
        case .common: Color.white.opacity(0.72)
        case .uncommon: .vdLeaf
        case .rare: .vdSky
        case .epic: .vdViolet
        case .legendary: .vdGold
        case .mythic: .vdCoral
        }
    }
}

private struct VaultEventRow: View {
    let event: VaultEvent
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Text(event.emojiMarker)
                    .font(.system(size: 26))
                    .frame(width: 44, height: 44)
                    .background(Color.vdGold.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.headline)
                        .foregroundStyle(Color.vdTextPrimary)
                        .lineLimit(2)

                    Text(event.venue)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.vdTextSecondary)
                }

                Spacer()

                Menu {
                    Button("Edit", systemImage: "pencil") {
                        onEdit()
                    }

                    Button("Delete", systemImage: "trash", role: .destructive) {
                        onDelete()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color.vdTextSecondary)
                }
            }

            HStack(spacing: 12) {
                Label(event.date.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
                Label(event.visibility.displayName, systemImage: event.visibility.systemImage)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.vdTextSecondary)

            HStack(spacing: 8) {
                StatusPill(title: event.kind.displayName, tint: .vdViolet)
                StatusPill(title: "\(event.attendingFriends) friends", tint: .vdEmerald)
            }

            Text(event.prize + " · " + event.featuredSet.name)
                .font(.subheadline)
                .foregroundStyle(Color.vdTextSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if !event.notes.isEmpty {
                Text(event.notes)
                    .font(.caption)
                    .foregroundStyle(Color.vdTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
        }
        .padding(16)
        .background(Color.vdPanel.opacity(0.86), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.72), lineWidth: 1)
        )
    }
}

private struct EventEditorSheet: View {
    @Binding var draft: EventDraft
    let sets: [CardSet]
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(alignment: .center, spacing: 12) {
                            TextField("📅", text: $draft.emojiMarker)
                                .font(.system(size: 34))
                                .multilineTextAlignment(.center)
                                .frame(width: 68, height: 68)
                                .background(Color.vdPanelRaised.opacity(0.88), in: RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.vdStroke.opacity(0.72), lineWidth: 1)
                                )

                            VStack(alignment: .leading, spacing: 8) {
                                TextField("Event name", text: $draft.title)
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(Color.vdTextPrimary)

                                TextField("Location", text: $draft.venue)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.vdTextSecondary)
                            }
                            .textFieldStyle(.plain)
                        }

                        DatePicker("Date", selection: $draft.date)
                            .foregroundStyle(Color.vdTextPrimary)
                            .tint(Color.vdGold)

                        Picker("Event type", selection: $draft.kind) {
                            ForEach(VaultEventKind.allCases) { kind in
                                Text(kind.displayName).tag(kind)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(Color.vdGold)

                        Picker("Visibility", selection: $draft.visibility) {
                            ForEach(BinderVisibility.allCases) { visibility in
                                Label(visibility.displayName, systemImage: visibility.systemImage).tag(visibility)
                            }
                        }
                        .pickerStyle(.segmented)

                        Picker("Featured set", selection: $draft.featuredSet) {
                            ForEach(sets) { set in
                                Text(set.name).tag(CardSet?.some(set))
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(Color.vdGold)

                        TextField("Prize or event focus", text: $draft.prize)
                            .textFieldStyle(.roundedBorder)

                        Stepper("Friends attending: \(draft.attendingFriends)", value: $draft.attendingFriends, in: 0...99)
                            .foregroundStyle(Color.vdTextPrimary)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color.vdTextSecondary)

                            TextEditor(text: $draft.notes)
                                .frame(minHeight: 110)
                                .scrollContentBackground(.hidden)
                                .padding(8)
                                .background(Color.vdPanelRaised.opacity(0.88), in: RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.vdStroke.opacity(0.72), lineWidth: 1)
                                )
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle(draft.id == nil ? "Add Event" : "Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .tint(Color.vdTextSecondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                    }
                    .disabled(!draft.isValid)
                    .tint(Color.vdGold)
                }
            }
        }
    }
}

private struct InviteContactRow: View {
    let contact: InviteContact

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: contact.isInvited ? "checkmark.circle.fill" : "person.crop.circle.badge.plus")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(contact.isInvited ? Color.vdEmerald : Color.vdGold)
                .frame(width: 42, height: 42)
                .background(Color.vdPanelRaised.opacity(0.82), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(contact.name)
                    .font(.headline)
                    .foregroundStyle(Color.vdTextPrimary)

                Text(contact.handleHint + " · " + contact.channel)
                    .font(.caption)
                    .foregroundStyle(Color.vdTextSecondary)
            }

            Spacer()

            StatusPill(title: contact.isInvited ? "Sent" : "Ready", tint: contact.isInvited ? .vdEmerald : .vdGold)
        }
        .padding(14)
        .background(Color.vdPanel.opacity(0.86), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.72), lineWidth: 1)
        )
    }
}

private struct DeletionChecklistRow: View {
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.vdCoral)
                .frame(width: 34, height: 34)
                .background(Color.vdCoral.opacity(0.13), in: RoundedRectangle(cornerRadius: 8))

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.vdTextPrimary)

            Spacer()
        }
        .padding(12)
        .background(Color.vdPanel.opacity(0.82), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.7), lineWidth: 1)
        )
    }
}
