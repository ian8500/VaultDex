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
                compactAction(title: "Sample", systemImage: "doc.text.fill", tint: .vdViolet) {
                    viewModel.loadSampleCSV()
                    viewModel.parseImportText(in: store)
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

                compactAction(title: "Wishlist CSV", systemImage: "star.fill", tint: .vdViolet) {
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
        .navigationTitle("Wishlist")
        .navigationBarTitleDisplayMode(.large)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Wishlist")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.vdTextPrimary)

                    Text("Chase targets and price notes stay local for now.")
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
        }
        .padding(18)
        .background(Color.vdPanel.opacity(0.84), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.78), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var chaseStrip: some View {
        if !viewModel.highPriorityItems(in: store).isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                VaultSectionHeader(title: "Chase Board", subtitle: "The cards to watch first")

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
            VaultSectionHeader(title: "All Wishlist Items", subtitle: "Priority, target price, and notes")

            if store.wishlistItems.isEmpty {
                EmptyStateView(
                    systemImage: "star",
                    title: "Wishlist is empty",
                    message: "Add cards from search or card detail to start tracking targets."
                )
            } else {
                VStack(spacing: 12) {
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
}

struct FriendsView: View {
    @StateObject private var viewModel = FriendsViewModel()

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header
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

                    Text("Compare completion, favorite cards, and trade history.")
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
                MetricPill(title: "Friends", value: "\(viewModel.friends.count)")
                MetricPill(title: "Online", value: "\(viewModel.onlineFriends.count)")
            }
        }
        .padding(18)
        .background(Color.vdPanel.opacity(0.84), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.78), lineWidth: 1)
        )
    }

    private var friendsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Collectors", subtitle: "Sorted by collector score")

            VStack(spacing: 12) {
                ForEach(viewModel.topCollectors) { friend in
                    FriendRow(friend: friend)
                }
            }
        }
    }
}

struct BinderDesignerView: View {
    @StateObject private var viewModel = BinderDesignerViewModel()
    @State private var selectedPageID: BinderPage.ID?

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header

                    if let page = selectedPage {
                        pagePicker
                        pageGrid(page)
                    } else {
                        EmptyStateView(
                            systemImage: "rectangle.grid.3x2",
                            title: "No binder pages",
                            message: "Demo binder pages will appear here once created."
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("Binder")
        .navigationBarTitleDisplayMode(.large)
    }

    private var selectedPage: BinderPage? {
        guard let firstPage = viewModel.pages.first else { return nil }
        guard let selectedPageID else { return firstPage }
        return viewModel.pages.first { $0.id == selectedPageID } ?? firstPage
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Binder Designer")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.vdTextPrimary)

                    Text("Plan native binder pages before sync, sharing, or printing exists.")
                        .font(.subheadline)
                        .foregroundStyle(Color.vdTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "rectangle.grid.3x2.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.vdViolet)
            }

            HStack(spacing: 12) {
                MetricPill(title: "Pages", value: "\(viewModel.pages.count)")
                MetricPill(title: "Filled", value: "\(viewModel.filledSlots)/\(viewModel.totalSlots)")
            }
        }
        .padding(18)
        .background(Color.vdPanel.opacity(0.84), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.78), lineWidth: 1)
        )
    }

    private var pagePicker: some View {
        Picker("Binder Page", selection: Binding(
            get: { selectedPageID ?? viewModel.pages.first?.id },
            set: { selectedPageID = $0 }
        )) {
            ForEach(viewModel.pages) { page in
                Text(page.title).tag(Optional(page.id))
            }
        }
        .pickerStyle(.segmented)
    }

    private func pageGrid(_ page: BinderPage) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: page.title, subtitle: page.theme)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(page.slots) { slot in
                    BinderSlotCell(slot: slot)
                }
            }
        }
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
                    setRows
                    missingCards
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("Pokedex")
        .navigationBarTitleDisplayMode(.large)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Completion Tracker")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.vdTextPrimary)

                    Text("Demo catalog coverage by set, ready to become a synced dex later.")
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
        }
        .padding(18)
        .background(Color.vdPanel.opacity(0.84), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.78), lineWidth: 1)
        )
    }

    private var setRows: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Set Progress", subtitle: "Owned unique cards in the demo catalog")

            VStack(spacing: 12) {
                ForEach(viewModel.setProgress(in: store)) { progress in
                    CompletionProgressRow(progress: progress)
                }
            }
        }
    }

    private var missingCards: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Missing Cards", subtitle: "Targets for wishlist, import, and trade")

            if viewModel.missingCards(in: store).isEmpty {
                EmptyStateView(
                    systemImage: "checkmark.seal.fill",
                    title: "Demo catalog complete",
                    message: "Every local card is already in your vault."
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(viewModel.missingCards(in: store)) { card in
                            NavigationLink {
                                CardDetailView(card: card)
                            } label: {
                                CardTile(card: card, style: .compact)
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
}

struct EventsView: View {
    @StateObject private var viewModel = EventsViewModel()

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    eventList
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("Events")
        .navigationBarTitleDisplayMode(.large)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Events")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.vdTextPrimary)

                    Text("Track local demo tournaments, trade nights, and community goals.")
                        .font(.subheadline)
                        .foregroundStyle(Color.vdTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "calendar")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.vdGold)
            }

            MetricPill(title: "Upcoming", value: "\(viewModel.upcomingEvents.count)")
        }
        .padding(18)
        .background(Color.vdPanel.opacity(0.84), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.78), lineWidth: 1)
        )
    }

    private var eventList: some View {
        VStack(alignment: .leading, spacing: 12) {
            VaultSectionHeader(title: "Calendar", subtitle: "Offline event schedule")

            VStack(spacing: 12) {
                ForEach(viewModel.upcomingEvents) { event in
                    VaultEventRow(event: event)
                }
            }
        }
    }
}

struct InviteFriendsView: View {
    @StateObject private var viewModel = InviteFriendsViewModel()

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

            PrimaryButton(title: "Send Demo Invites", systemImage: "paperplane.fill") {}
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
    @StateObject private var viewModel = AccountDeletionViewModel()

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
    }

    private var warning: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.vdCoral)

            Text("Account Deletion")
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.vdTextPrimary)

            Text("This is a local dry-run screen. When backend accounts exist, this flow can request export, revoke sessions, and permanently delete server records.")
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
            Text("Type DELETE to enable the demo request.")
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

            PrimaryButton(title: "Request Demo Deletion", systemImage: "trash.fill") {}
                .disabled(!viewModel.canRequestDeletion)
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
            CardTile(card: item.card, style: .compact)
                .frame(width: 150)

            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    StatusPill(title: item.priority.displayName, tint: priorityTint)
                    Spacer()
                    Text(item.budget.vaultCurrency)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.vdGold)
                }

                Text(item.card.name)
                    .font(.headline)
                    .foregroundStyle(Color.vdTextPrimary)
                    .lineLimit(2)

                Text(item.notes)
                    .font(.subheadline)
                    .foregroundStyle(Color.vdTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .background(Color.vdPanel.opacity(0.86), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.72), lineWidth: 1)
        )
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

private struct BinderSlotCell: View {
    let slot: BinderSlot

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.vdPanelRaised.opacity(0.9))

                if let card = slot.card {
                    VStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Color.vdGold)

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
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Color.vdTextSecondary)

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
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(slot.card == nil ? Color.vdStroke.opacity(0.8) : Color.vdGold.opacity(0.32), lineWidth: 1)
            )

            Text("#\(slot.index)")
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.vdTextSecondary)
        }
    }
}

private struct CompletionProgressRow: View {
    let progress: SetProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(progress.cardSet.name)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.vdTextPrimary)

                    Text(progress.cardSet.code + " · " + "\(progress.cardSet.releaseYear)")
                        .font(.caption)
                        .foregroundStyle(Color.vdTextSecondary)
                }

                Spacer()

                Text("\(progress.owned)/\(progress.total)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.vdGold)
            }

            ProgressView(value: progress.fraction)
                .tint(Color.vdGold)
                .background(Color.vdStroke.opacity(0.55), in: Capsule())
        }
        .padding(14)
        .background(Color.vdPanel.opacity(0.84), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.72), lineWidth: 1)
        )
    }
}

private struct VaultEventRow: View {
    let event: VaultEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: eventIcon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.vdGold)
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

                StatusPill(title: event.kind.displayName, tint: .vdViolet)
            }

            HStack(spacing: 12) {
                Label(event.date.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
                Label("\(event.attendingFriends) friends", systemImage: "person.2.fill")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.vdTextSecondary)

            Text(event.prize + " · " + event.featuredSet.name)
                .font(.subheadline)
                .foregroundStyle(Color.vdTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Color.vdPanel.opacity(0.86), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.72), lineWidth: 1)
        )
    }

    private var eventIcon: String {
        switch event.kind {
        case .tournament: "trophy.fill"
        case .tradeNight: "arrow.left.arrow.right"
        case .release: "shippingbox.fill"
        case .community: "person.3.fill"
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
