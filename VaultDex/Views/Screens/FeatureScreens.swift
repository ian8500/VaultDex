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
                .bottomDockSpacing()
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
                MetricPill(title: "Estimate", value: viewModel.estimatedMatchedValue.compactVaultCurrency)
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
            viewModel.errorMessage = "Could not read that file. Please check the format and try again."
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
    @State private var selectedPriority: WishlistPriority?
    @State private var searchText = ""
    @State private var editingItem: WishlistItem?

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    searchAndActions
                    friendsHuntingSection
                    prioritySections
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .bottomDockSpacing()
            }
        }
        .navigationTitle("Wants")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $editingItem) { item in
            WishlistEditSheet(item: item)
                .environmentObject(store)
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Wants")
                    .font(.system(.largeTitle, design: .rounded, weight: .black))
                    .foregroundStyle(Color.vdTextPrimary)
                    .lineLimit(1)

                Text("Cards you’re hunting for")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.vdTextSecondary)
                    .lineLimit(1)
            }

            Spacer()

            NavigationLink {
                SearchView()
            } label: {
                Image(systemName: "plus")
                    .font(.headline.weight(.black))
                    .foregroundStyle(Color.vdNavy)
                    .frame(width: 44, height: 44)
                    .background(Color.vdGold, in: RoundedRectangle(cornerRadius: 15))
                    .accessibilityLabel("Add Want")
            }
            .buttonStyle(.plain)
        }
    }

    private var searchAndActions: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.vdTextSecondary)

                TextField("Search your wants", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundStyle(Color.vdTextPrimary)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.vdTextSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14)
            .background(Color.vdPanel.opacity(0.70), in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08), lineWidth: 1))

            HStack(spacing: 10) {
                priorityFilter

                NavigationLink {
                    SearchView()
                } label: {
                    Label("Add Want", systemImage: "star.fill")
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(Color.vdNavy)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.vdGold, in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var friendsHuntingSection: some View {
        NavigationLink {
            FriendsWantsView()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "person.2.fill")
                    .font(.headline.weight(.black))
                    .foregroundStyle(Color.vdNavy)
                    .frame(width: 44, height: 44)
                    .background(Color.vdSky, in: RoundedRectangle(cornerRadius: 15))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Friends are hunting")
                        .font(.headline.weight(.black))
                        .foregroundStyle(Color.vdTextPrimary)
                    Text("View friends’ wants")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.vdTextSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.black))
                    .foregroundStyle(Color.vdTextSecondary)
            }
            .padding(14)
            .background(Color.vdPanel.opacity(0.62), in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.07), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var prioritySections: some View {
        VStack(alignment: .leading, spacing: 18) {
            if store.wishlistItems.isEmpty {
                EmptyStateView(
                    systemImage: "star.circle.fill",
                    title: "No wants yet",
                    message: "Add cards you’re hunting for so friends can spot them."
                )
            } else if filteredItems.isEmpty {
                EmptyStateView(
                    systemImage: "line.3.horizontal.decrease.circle",
                    title: "No wants found",
                    message: "Clear the filter or choose another priority."
                )
            } else {
                ForEach(priorityOrder, id: \.self) { priority in
                    let items = filteredItems.filter { $0.priority == priority }
                    if !items.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            VaultSectionHeader(title: priority.displayName, subtitle: "\(items.count)")

                            VStack(spacing: 10) {
                                ForEach(items) { item in
                                    NavigationLink {
                                        CardDetailView(card: item.card)
                                    } label: {
                                        WishlistRow(item: item)
                                    }
                                    .contextMenu {
                                        Button("Edit Want", systemImage: "slider.horizontal.3") {
                                            editingItem = item
                                        }
                                        Button("Remove from Wants", systemImage: "star.slash", role: .destructive) {
                                            store.removeFromWishlist(item.card)
                                        }
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            store.removeFromWishlist(item.card)
                                        } label: {
                                            Label("Remove", systemImage: "star.slash")
                                        }

                                        Button {
                                            editingItem = item
                                        } label: {
                                            Label("Edit", systemImage: "slider.horizontal.3")
                                        }
                                        .tint(.vdGold)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
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

    private var priorityFilter: some View {
        Menu {
            Button("All Priorities") {
                selectedPriority = nil
            }
            ForEach(WishlistPriority.allCases) { priority in
                Button(priority.displayName) {
                    selectedPriority = priority
                }
            }
        } label: {
            Label(selectedPriority?.displayName ?? "Filter", systemImage: selectedPriority == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.vdGold)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.vdGold.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.vdGold.opacity(0.28), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var filteredItems: [WishlistItem] {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let items = store.wishlistItems.filter { item in
            guard !trimmedSearch.isEmpty else { return true }
            return item.card.name.lowercased().contains(trimmedSearch)
                || item.card.set.name.lowercased().contains(trimmedSearch)
                || item.card.set.code.lowercased().contains(trimmedSearch)
                || item.card.rarity.displayName.lowercased().contains(trimmedSearch)
        }
        .sorted { first, second in
            if first.priority.sortRank != second.priority.sortRank {
                return first.priority.sortRank > second.priority.sortRank
            }
            return first.addedAt > second.addedAt
        }
        guard let selectedPriority else { return items }
        return items.filter { $0.priority == selectedPriority }
    }

    private var priorityOrder: [WishlistPriority] {
        [.grail, .high, .medium, .low]
    }
}

private struct WishlistEditSheet: View {
    @EnvironmentObject private var store: LocalVaultStore
    @Environment(\.dismiss) private var dismiss

    let item: WishlistItem

    @State private var priority: WishlistPriority
    @State private var preferredCondition: CardCondition
    @State private var budget: Double
    @State private var notes: String

    init(item: WishlistItem) {
        self.item = item
        _priority = State(initialValue: item.priority)
        _preferredCondition = State(initialValue: item.preferredCondition)
        _budget = State(initialValue: item.budget)
        _notes = State(initialValue: item.notes)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        CardTile(card: item.card, variant: priority == .grail ? .secretRare : nil, style: .compact)
                            .frame(maxWidth: .infinity)

                        Picker("Priority", selection: $priority) {
                            ForEach(WishlistPriority.allCases) { priority in
                                Text(priority.displayName).tag(priority)
                            }
                        }
                        .pickerStyle(.segmented)

                        Picker("Preferred Condition", selection: $preferredCondition) {
                            ForEach(CardCondition.allCases) { condition in
                                Text(condition.displayName).tag(condition)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(Color.vdGold)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Max Value")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color.vdTextSecondary)

                            TextField("Max value", value: $budget, format: .number.precision(.fractionLength(0...2)))
                                .keyboardType(.decimalPad)
                                .foregroundStyle(Color.vdTextPrimary)
                                .padding(14)
                                .background(Color.vdPanelRaised.opacity(0.84), in: RoundedRectangle(cornerRadius: 8))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color.vdTextSecondary)

                            TextField("Notes", text: $notes, axis: .vertical)
                                .lineLimit(3...6)
                                .foregroundStyle(Color.vdTextPrimary)
                                .padding(14)
                                .background(Color.vdPanelRaised.opacity(0.84), in: RoundedRectangle(cornerRadius: 8))
                        }

                        if store.lastSyncError?.contains("Wants") == true, let error = store.lastSyncError {
                            Label(error, systemImage: "exclamationmark.triangle.fill")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color.vdCoral)
                        }

                        PrimaryButton(title: "Save Want", systemImage: "checkmark.circle.fill") {
                            store.updateWishlist(for: item.card, priority: priority, preferredCondition: preferredCondition, budget: budget, notes: notes)
                            dismiss()
                        }

                        secondaryRemoveButton
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Edit Want")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var secondaryRemoveButton: some View {
        Button {
            store.removeFromWishlist(item.card)
            dismiss()
        } label: {
            Label("Remove from Wants", systemImage: "star.slash.fill")
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.vdCoral)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.vdCoral.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.vdCoral.opacity(0.38), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct FriendsView: View {
    @EnvironmentObject private var store: LocalVaultStore
    @StateObject private var viewModel = FriendsViewModel()
    @FocusState private var isAddFriendFocused: Bool

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    friendsWantsShortcut
                    addFriendCard
                    if !store.friendRequests.isEmpty {
                        requestList
                    }
                    friendsList
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .bottomDockSpacing()
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

                    Text("Add trusted collectors and find fair trades.")
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

        }
        .padding(18)
        .background(Color.vdPanel.opacity(0.84), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.78), lineWidth: 1)
        )
    }

    private var friendsWantsShortcut: some View {
        NavigationLink {
            FriendsWantsView()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "star.bubble.fill")
                    .font(.system(size: 21, weight: .black))
                    .foregroundStyle(Color.vdNavy)
                    .frame(width: 52, height: 52)
                    .background(Color.vdGold, in: RoundedRectangle(cornerRadius: 17))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Friends’ Wants")
                        .font(.headline.weight(.black))
                        .foregroundStyle(Color.vdTextPrimary)
                    Text("Quickly check what friends are hunting for.")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.vdTextSecondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.black))
                    .foregroundStyle(Color.vdTextSecondary)
            }
            .padding(15)
            .background(Color.vdPanel.opacity(0.70), in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.08), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var addFriendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Add friend", subtitle: nil)

            HStack(spacing: 10) {
                TextField("@username or email", text: $viewModel.addFriendText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($isAddFriendFocused)
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
                            store.sendFriendRequest(to: profile)
                            viewModel.addFriendText = ""
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "person.crop.circle.badge.plus")
                                    .foregroundStyle(Color.vdGold)
                                    .frame(width: 32, height: 32)
                                    .background(Color.vdGold.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(profile.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? profile.username : profile.displayName)
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

    private var friendsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "My friends", subtitle: nil)

            if store.friends.isEmpty {
                noFriendsState
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.topCollectors(in: store)) { friend in
                        FriendSummaryCard(friend: friend)
                    }
                }
            }
        }
    }

    private var noFriendsState: some View {
        VStack(spacing: 16) {
            EmptyStateView(
                systemImage: "person.2.badge.plus",
                title: "No friends yet",
                message: "Add collectors to compare wants, view collections and start fair trades."
            )

            PrimaryButton(title: "Add friend", systemImage: "person.badge.plus") {
                isAddFriendFocused = true
            }
        }
    }
}

struct FriendsWantsView: View {
    @EnvironmentObject private var store: LocalVaultStore
    @State private var searchText = ""
    @State private var selectedFriendID: UUID?
    @State private var selectedRarity: CardRarity?
    @State private var selectedPriority: WishlistPriority?
    @State private var selectedSetCode: String?
    @State private var isShowModeEnabled = false
    @State private var spottedDraft: FriendWantSpotDraft?
    @State private var spots: [FriendWantSpot] = []

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    searchBar
                    filterRow
                    showModeToggle
                    wantsList
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .bottomDockSpacing()
            }
        }
        .navigationTitle("Friends’ Wants")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $spottedDraft) { draft in
            FriendWantSpotSheet(draft: draft) { note in
                spots.append(
                    FriendWantSpot(
                        friendID: draft.row.friend.id,
                        cardID: draft.row.item.card.id,
                        note: note
                    )
                )
                spottedDraft = nil
            } onCancel: {
                spottedDraft = nil
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Friends’ Wants")
                .font(.system(.largeTitle, design: .rounded, weight: .black))
                .foregroundStyle(Color.vdTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            Text("Scan what trusted collectors are hunting for.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.vdTextSecondary)
                .lineLimit(2)
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.vdTextSecondary)

            TextField("Search cards, friends or sets", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundStyle(Color.vdTextPrimary)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.vdTextSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(Color.vdPanel.opacity(0.70), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                filterMenu(
                    title: selectedFriendName ?? "Friend",
                    icon: "person.fill",
                    isActive: selectedFriendID != nil
                ) {
                    Button("All friends") { selectedFriendID = nil }
                    ForEach(store.friends) { friend in
                        Button(friend.displayName) { selectedFriendID = friend.id }
                    }
                }

                filterMenu(
                    title: selectedPriority?.displayName ?? "Priority",
                    icon: "star.fill",
                    isActive: selectedPriority != nil
                ) {
                    Button("All priorities") { selectedPriority = nil }
                    ForEach(WishlistPriority.allCases.reversed()) { priority in
                        Button(priority.displayName) { selectedPriority = priority }
                    }
                }

                filterMenu(
                    title: selectedRarity?.displayName ?? "Rarity",
                    icon: "sparkles",
                    isActive: selectedRarity != nil
                ) {
                    Button("All rarities") { selectedRarity = nil }
                    ForEach(CardRarity.allCases) { rarity in
                        Button(rarity.displayName) { selectedRarity = rarity }
                    }
                }

                filterMenu(
                    title: selectedSetCode ?? "Set",
                    icon: "rectangle.3.group.fill",
                    isActive: selectedSetCode != nil
                ) {
                    Button("All sets") { selectedSetCode = nil }
                    ForEach(availableSetCodes, id: \.self) { code in
                        Button(code) { selectedSetCode = code }
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func filterMenu<Content: View>(title: String, icon: String, isActive: Bool, @ViewBuilder content: () -> Content) -> some View {
        Menu {
            content()
        } label: {
            Label(title, systemImage: icon)
                .font(.caption.weight(.black))
                .foregroundStyle(isActive ? Color.vdNavy : Color.vdGold)
                .lineLimit(1)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(isActive ? Color.vdGold : Color.vdGold.opacity(0.12), in: Capsule())
                .overlay(Capsule().stroke(Color.vdGold.opacity(0.28), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var showModeToggle: some View {
        Toggle(isOn: $isShowModeEnabled) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Show mode")
                    .font(.headline.weight(.black))
                    .foregroundStyle(Color.vdTextPrimary)
                Text("Bigger cards and quick spotting for card shows.")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.vdTextSecondary)
                    .lineLimit(2)
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: Color.vdGold))
        .padding(14)
        .background(Color.vdPanel.opacity(0.62), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.07), lineWidth: 1))
    }

    @ViewBuilder
    private var wantsList: some View {
        if store.friends.isEmpty {
            EmptyStateView(
                systemImage: "person.2.badge.plus",
                title: "No friends yet",
                message: "Add collectors to compare wants, view collections and start fair trades."
            )
        } else if allRows.isEmpty {
            EmptyStateView(
                systemImage: "star.slash",
                title: "No shared wants yet",
                message: "Friends’ visible wants will appear here."
            )
        } else if filteredRows.isEmpty {
            EmptyStateView(
                systemImage: "line.3.horizontal.decrease.circle",
                title: "No wants found",
                message: "Try another search or filter."
            )
        } else {
            VStack(alignment: .leading, spacing: 18) {
                ForEach(groupedRows, id: \.friend.id) { group in
                    VStack(alignment: .leading, spacing: 10) {
                        VaultSectionHeader(title: group.friend.displayName, subtitle: "\(group.rows.count)")

                        VStack(spacing: 10) {
                            ForEach(group.rows) { row in
                                FriendWantDiscoveryRow(
                                    row: row,
                                    showMode: isShowModeEnabled,
                                    youOwn: store.collectionItem(for: row.item.card) != nil,
                                    isSpotted: spots.contains { $0.friendID == row.friend.id && $0.cardID == row.item.card.id }
                                ) {
                                    spottedDraft = FriendWantSpotDraft(row: row)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var allRows: [FriendWantDiscoveryRowModel] {
        store.friends.filter { $0.wishlistVisibility != .private }.flatMap { friend in
            friend.wishlist.map { item in
                FriendWantDiscoveryRowModel(friend: friend, item: item)
            }
        }
    }

    private var filteredRows: [FriendWantDiscoveryRowModel] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return allRows.filter { row in
            let matchesSearch = trimmed.isEmpty
                || row.friend.displayName.lowercased().contains(trimmed)
                || row.friend.handle.lowercased().contains(trimmed)
                || row.item.card.name.lowercased().contains(trimmed)
                || row.item.card.set.name.lowercased().contains(trimmed)
                || row.item.card.set.code.lowercased().contains(trimmed)

            let matchesFriend = selectedFriendID == nil || row.friend.id == selectedFriendID
            let matchesPriority = selectedPriority == nil || row.item.priority == selectedPriority
            let matchesRarity = selectedRarity == nil || row.item.card.rarity == selectedRarity
            let matchesSet = selectedSetCode == nil || row.item.card.set.code == selectedSetCode

            return matchesSearch && matchesFriend && matchesPriority && matchesRarity && matchesSet
        }
        .sorted {
            if $0.friend.displayName != $1.friend.displayName {
                return $0.friend.displayName < $1.friend.displayName
            }
            if $0.item.priority.sortRank != $1.item.priority.sortRank {
                return $0.item.priority.sortRank > $1.item.priority.sortRank
            }
            return $0.item.card.name < $1.item.card.name
        }
    }

    private var groupedRows: [(friend: Friend, rows: [FriendWantDiscoveryRowModel])] {
        store.friends.compactMap { friend in
            let rows = filteredRows.filter { $0.friend.id == friend.id }
            guard !rows.isEmpty else { return nil }
            return (friend, rows)
        }
    }

    private var selectedFriendName: String? {
        guard let selectedFriendID else { return nil }
        return store.friends.first { $0.id == selectedFriendID }?.displayName
    }

    private var availableSetCodes: [String] {
        Array(Set(allRows.map { $0.item.card.set.code })).sorted()
    }
}

private struct FriendWantDiscoveryRowModel: Identifiable, Hashable {
    let friend: Friend
    let item: WishlistItem

    var id: String {
        friend.id.uuidString + "-" + item.id.uuidString
    }
}

private struct FriendWantDiscoveryRow: View {
    let row: FriendWantDiscoveryRowModel
    let showMode: Bool
    let youOwn: Bool
    let isSpotted: Bool
    let onSpot: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            cardImage
                .frame(width: showMode ? 86 : 58, height: showMode ? 120 : 80)

            VStack(alignment: .leading, spacing: showMode ? 8 : 5) {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(row.item.card.name)
                            .font(showMode ? .headline.weight(.black) : .subheadline.weight(.black))
                            .foregroundStyle(Color.vdTextPrimary)
                            .lineLimit(showMode ? 2 : 1)
                            .minimumScaleFactor(0.84)

                        Text("\(row.item.card.set.name) #\(row.item.card.number)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.vdTextSecondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)

                    StatusPill(title: row.item.priority.displayName, tint: row.item.priority == .grail ? .vdGold : .vdSky)
                }

                HStack(spacing: 8) {
                    Image(systemName: row.friend.avatarSymbol)
                        .font(.caption.weight(.black))
                        .foregroundStyle(Color.vdGold)
                        .frame(width: 26, height: 26)
                        .background(Color.vdGold.opacity(0.12), in: Circle())

                    Text(row.friend.displayName)
                        .font((showMode ? Font.subheadline : Font.caption).weight(.bold))
                        .foregroundStyle(Color.vdTextPrimary)
                        .lineLimit(1)

                    Spacer(minLength: 6)
                }

                HStack(spacing: 7) {
                    FriendWantMetaChip(text: row.item.card.rarity.displayName, systemImage: "sparkles", tint: rarityTint)
                    FriendWantMetaChip(text: row.item.budget.vaultEstimatedCurrency, systemImage: "seal.fill", tint: .vdGold, isFilled: true)
                }

                if !row.item.notes.isEmpty {
                    Text(row.item.notes)
                        .font(.caption)
                        .foregroundStyle(Color.vdTextSecondary)
                        .lineLimit(showMode ? 1 : 2)
                }

                actionRow
            }
        }
        .padding(12)
        .background(Color.vdPanel.opacity(0.78), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(row.item.priority == .grail ? Color.vdGold.opacity(0.35) : Color.white.opacity(0.07), lineWidth: 1))
        .shadow(color: row.item.priority == .grail ? Color.vdGold.opacity(0.10) : Color.black.opacity(0.10), radius: 12, x: 0, y: 7)
    }

    private var cardImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.vdPanelRaised.opacity(0.78))

            if let imageURL = row.item.card.smallImageURL ?? row.item.card.largeImageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        Image(systemName: "rectangle.stack.fill")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Color.vdGold)
                    }
                }
            } else {
                Image(systemName: "rectangle.stack.fill")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.vdGold)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var actionRow: some View {
        HStack(spacing: 8) {
            if youOwn {
                StatusPill(title: "You have this", tint: .vdEmerald)

                NavigationLink {
                    TradeView()
                } label: {
                    Text("Suggest trade")
                        .font(.caption.weight(.black))
                        .foregroundStyle(Color.vdNavy)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color.vdGold, in: Capsule())
                }
                .buttonStyle(.plain)
            }

            if showMode {
                Button(action: onSpot) {
                    Label(isSpotted ? "Spotted" : "Spotted", systemImage: isSpotted ? "checkmark.circle.fill" : "eye.fill")
                        .font(.caption.weight(.black))
                        .foregroundStyle(isSpotted ? Color.vdEmerald : Color.vdGold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background((isSpotted ? Color.vdEmerald : Color.vdGold).opacity(0.12), in: Capsule())
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 0)
        }
    }

    private var rarityTint: Color {
        switch row.item.card.rarity {
        case .common: .vdTextSecondary
        case .uncommon: .vdLeaf
        case .rare: .vdSky
        case .epic: .vdViolet
        case .legendary, .mythic: .vdGold
        }
    }
}

private struct FriendWantMetaChip: View {
    let text: String
    let systemImage: String
    let tint: Color
    var isFilled = false

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption2.weight(.black))
            .foregroundStyle(isFilled ? Color.vdNavy : tint)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(isFilled ? tint : tint.opacity(0.13), in: Capsule())
            .overlay(Capsule().stroke(isFilled ? Color.white.opacity(0.24) : tint.opacity(0.24), lineWidth: 1))
    }
}

private struct FriendWantSpotDraft: Identifiable {
    let id = UUID()
    let row: FriendWantDiscoveryRowModel
}

private struct FriendWantSpotSheet: View {
    let draft: FriendWantSpotDraft
    let onSave: (String) -> Void
    let onCancel: () -> Void
    @State private var note = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                VStack(alignment: .leading, spacing: 18) {
                    Text(draft.row.item.card.name)
                        .font(.title3.weight(.black))
                        .foregroundStyle(Color.vdTextPrimary)

                    Text("Where did you see it?")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.vdTextSecondary)

                    TextField("Found at stall/table", text: $note, axis: .vertical)
                        .lineLimit(3...5)
                        .foregroundStyle(Color.vdTextPrimary)
                        .padding(14)
                        .background(Color.vdPanelRaised.opacity(0.82), in: RoundedRectangle(cornerRadius: 14))

                    PrimaryButton(title: "Save Spotted", systemImage: "checkmark.circle.fill") {
                        onSave(note.trimmingCharacters(in: .whitespacesAndNewlines))
                    }

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Spotted")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
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
                .bottomDockSpacing()
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
                .bottomDockSpacing()
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
                .bottomDockSpacing()
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

                Text("See shared plans from trusted collectors.")
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
                .bottomDockSpacing()
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

                    Text("Share VaultDex with trusted collectors.")
                        .font(.subheadline)
                        .foregroundStyle(Color.vdTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "paperplane.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.vdViolet)
            }

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
            VaultSectionHeader(title: "Invite History", subtitle: nil)

            if viewModel.contacts.isEmpty {
                EmptyStateView(
                    systemImage: "person.crop.circle.badge.plus",
                    title: "No invites yet",
                    message: "Share your invite with trusted collectors when you are ready."
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.contacts) { contact in
                        InviteContactRow(contact: contact)
                    }
                }
            }
        }
    }
}

struct AccountDeletionView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var store: LocalVaultStore
    @StateObject private var viewModel = AccountDeletionViewModel()
    @State private var isDeleteConfirmationPresented = false
    @State private var message = ""
    @State private var isDeleting = false

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
                .bottomDockSpacing()
            }
        }
        .navigationTitle("Delete Account")
        .navigationBarTitleDisplayMode(.large)
        .confirmationDialog(
            "Delete account data?",
            isPresented: $isDeleteConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("Delete and Reset", role: .destructive) {
                Task { await deleteAccountData() }
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This deletes your VaultDex app data and signs you out.")
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

            Text("Deleting your account removes your VaultDex profile, collection, wants, binder, and trade data from this app.")
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
            VaultSectionHeader(title: "Deletion Plan", subtitle: "Review what will be removed.")

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
            .disabled(!viewModel.canRequestDeletion || isDeleting)

            if isDeleting {
                Label("Deleting account data...", systemImage: "trash")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.vdGold)
            }

            if !message.isEmpty {
                Label(message, systemImage: "exclamationmark.circle.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.vdCoral)
            }
        }
        .padding(18)
        .background(Color.vdPanel.opacity(0.84), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.78), lineWidth: 1)
            )
    }

    private func deleteAccountData() async {
        isDeleting = true
        message = ""
        defer { isDeleting = false }

        do {
            try await store.deleteSignedInAccountData()
            try? await authService.signOut()
            viewModel.confirmationText = ""
        } catch {
            message = "Unable to delete account data right now. Please try again."
        }
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
                    tradeValueChip(item.budget.vaultEstimatedCurrency, tint: .vdGold)
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

private enum FriendProfileTab: String, CaseIterable, Identifiable {
    case collection
    case wants
    case tradeMatch

    var id: String { rawValue }

    var title: String {
        switch self {
        case .collection: "Collection"
        case .wants: "Wants"
        case .tradeMatch: "Trade Match"
        }
    }
}

private struct FriendProfileView: View {
    @EnvironmentObject private var store: LocalVaultStore
    @Environment(\.dismiss) private var dismiss
    let friend: Friend
    @State private var selectedTab: FriendProfileTab
    @State private var isRemoveConfirmationPresented = false
    @State private var actionMessage: String?
    @State private var friendWantsSearch = ""

    init(friend: Friend, initialTab: FriendProfileTab = .collection) {
        self.friend = friend
        _selectedTab = State(initialValue: initialTab)
    }

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    profileHeader
                    profileTabs
                    tabContent
                    safetyActions
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .bottomDockSpacing()
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

    private var profileTabs: some View {
        Picker("Friend profile section", selection: $selectedTab) {
            ForEach(FriendProfileTab.allCases) { tab in
                Text(tab.title).tag(tab)
            }
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .collection:
            visibleCollection
        case .wants:
            wishlist
        case .tradeMatch:
            tradeMatch
        }
    }

    private var visibleCollection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(
                title: "Collection",
                subtitle: "\(friend.visibleCollection.count) cards"
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
                subtitle: "\(friend.wishlist.count) cards"
            )

            if !friend.wishlist.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.vdTextSecondary)

                    TextField("Search wants", text: $friendWantsSearch)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .foregroundStyle(Color.vdTextPrimary)

                    if !friendWantsSearch.isEmpty {
                        Button {
                            friendWantsSearch = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Color.vdTextSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(13)
                .background(Color.vdPanel.opacity(0.68), in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.07), lineWidth: 1))
            }

            if friend.wishlist.isEmpty {
                EmptyStateView(systemImage: "star.slash", title: "No visible wants", message: "Wanted cards will appear here when shared.")
            } else if filteredFriendWishlist.isEmpty {
                EmptyStateView(systemImage: "line.3.horizontal.decrease.circle", title: "No wants found", message: "Try another search.")
            } else {
                VStack(spacing: 10) {
                    ForEach(filteredFriendWishlist) { item in
                        FriendWishlistActionRow(
                            item: item,
                            youOwn: store.collectionItem(for: item.card) != nil
                        ) {
                            actionMessage = "Trade suggestion started for \(item.card.name)."
                        }
                    }
                }
            }
        }
    }

    private var tradeMatch: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Trade Match", subtitle: nil)

            VStack(spacing: 10) {
                FriendMatchCard(
                    title: "Cards I want that they own",
                    items: store.cardsIWantThatFriendOwns(friend),
                    tint: .vdGold
                )

                FriendMatchCard(
                    title: "Cards they want that I own",
                    items: store.cardsFriendWantsThatIOwn(friend),
                    tint: .vdEmerald
                )
            }

            PrimaryButton(title: "Suggest Trade", systemImage: "arrow.left.arrow.right.circle.fill") {
                actionMessage = "Trade suggestions will appear when both collectors have matching cards."
            }
        }
    }

    private var filteredFriendWishlist: [WishlistItem] {
        let trimmed = friendWantsSearch.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return friend.wishlist.filter { item in
            guard !trimmed.isEmpty else { return true }
            return item.card.name.lowercased().contains(trimmed)
                || item.card.set.name.lowercased().contains(trimmed)
                || item.card.set.code.lowercased().contains(trimmed)
                || item.card.rarity.displayName.lowercased().contains(trimmed)
        }
        .sorted {
            if $0.priority.sortRank != $1.priority.sortRank {
                return $0.priority.sortRank > $1.priority.sortRank
            }
            return $0.card.name < $1.card.name
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

                Text("\(item.priority.displayName) · \(item.budget.vaultEstimatedCurrency)")
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

private struct FriendWishlistActionRow: View {
    let item: WishlistItem
    let youOwn: Bool
    let onSuggestTrade: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            NavigationLink {
                CardDetailView(card: item.card)
            } label: {
                FriendWishlistRow(item: item, youOwn: youOwn)
            }
            .buttonStyle(.plain)

            HStack(spacing: 10) {
                if youOwn {
                    StatusPill(title: "I have this", tint: .vdEmerald)
                }

                Button(action: onSuggestTrade) {
                    Label(youOwn ? "Suggest trade" : "Offer trade", systemImage: "arrow.left.arrow.right.circle.fill")
                        .font(.caption.weight(.black))
                        .foregroundStyle(Color.vdNavy)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.vdGold, in: Capsule())
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 2)
        }
        .padding(10)
        .background(Color.vdPanel.opacity(0.52), in: RoundedRectangle(cornerRadius: 18))
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

private struct FriendSummaryCard: View {
    let friend: Friend

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: friend.avatarSymbol)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.vdGold)
                    .frame(width: 52, height: 52)
                    .background(Color.vdPanelRaised.opacity(0.82), in: RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.vdGold.opacity(0.26), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(friend.displayName)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.vdTextPrimary)

                    Text(friend.handle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.vdGold)
                }

                Spacer()

                StatusPill(title: "Trust \(friend.collectorScore)", tint: .vdEmerald)
            }

            HStack(spacing: 10) {
                friendAction(title: "Collection", icon: "rectangle.stack.fill", tab: .collection)
                friendAction(title: "Wants", icon: "star.fill", tab: .wants)
                friendAction(title: "Trade", icon: "arrow.left.arrow.right.circle.fill", tab: .tradeMatch)
            }
        }
        .padding(16)
        .background(Color.vdPanel.opacity(0.86), in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.vdGold.opacity(0.20), lineWidth: 1)
        )
    }

    private func friendAction(title: String, icon: String, tab: FriendProfileTab) -> some View {
        NavigationLink {
            FriendProfileView(friend: friend, initialTab: tab)
        } label: {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.caption.weight(.black))

                Text(title)
                    .font(.caption.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(Color.vdGold)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.vdGold.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.vdGold.opacity(0.28), lineWidth: 1))
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

            if let favoriteCard = friend.favoriteCard {
                HStack(spacing: 10) {
                    Text("Featured")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.vdTextSecondary)

                    Text(favoriteCard.name)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.vdTextPrimary)
                        .lineLimit(1)

                    Spacer()

                    RarityBadge(rarity: favoriteCard.rarity)
                }
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
                    .bottomDockSpacing()
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
