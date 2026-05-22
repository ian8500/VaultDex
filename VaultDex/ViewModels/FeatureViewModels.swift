import Foundation

struct ParsedImportRow: Identifiable, Hashable {
    let id = UUID()
    let rowNumber: Int
    let name: String
    let set: String
    let number: String
    let quantity: Int
    let condition: CardCondition
    let variant: CardVariant
    let language: String
    let matchedCard: Card?

    var isMatched: Bool {
        matchedCard != nil
    }
}

struct ImportResultSummary: Equatable {
    var addedCards = 0
    var updatedCards = 0
    var unmatchedRows = 0
}

@MainActor
final class ImportCollectionViewModel: ObservableObject {
    @Published var importText = ""
    @Published private(set) var matchedRows: [ParsedImportRow] = []
    @Published private(set) var unmatchedRows: [ParsedImportRow] = []
    @Published private(set) var summary = ImportResultSummary()
    @Published var errorMessage: String?
    @Published var exportText = ""

    var totalRows: Int {
        matchedRows.count + unmatchedRows.count
    }

    var matchedCopies: Int {
        matchedRows.reduce(0) { $0 + $1.quantity }
    }

    var estimatedMatchedValue: Double {
        matchedRows.reduce(0) { total, row in
            total + ((row.matchedCard?.marketValue ?? 0) * Double(row.quantity))
        }
    }

    var canConfirmImport: Bool {
        !matchedRows.isEmpty
    }

    func loadSampleCSV() {
        importText = """
        Name,Set,Number,Quantity,Condition,Variant,Language
        Astra Prime,Nebula Crown,001,1,Mint,Full Art,English
        Prism Courier,NBC,121,4,Near Mint,Normal,English
        Frostbound Crown,Radiant Archive,166,1,Mint,Secret Rare,Japanese
        Unknown Prototype,Nebula Crown,999,2,Played,Holo,English
        """
    }

    func parseImportText(in store: LocalVaultStore) {
        let trimmed = importText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            resetRows()
            errorMessage = "Paste CSV or JSON before reviewing."
            return
        }

        do {
            let rows: [ParsedImportRow]
            if trimmed.first == "[" || trimmed.first == "{" {
                rows = try parseJSON(trimmed, store: store)
            } else {
                rows = try parseCSV(trimmed, store: store)
            }

            matchedRows = rows.filter(\.isMatched)
            unmatchedRows = rows.filter { !$0.isMatched }
            summary = ImportResultSummary(unmatchedRows: unmatchedRows.count)
            exportText = ""
            errorMessage = nil
        } catch {
            resetRows()
            errorMessage = error.localizedDescription
        }
    }

    func confirmImport(into store: LocalVaultStore) {
        guard !matchedRows.isEmpty else { return }

        var added = 0
        var updated = 0

        for row in matchedRows {
            guard let card = row.matchedCard else { continue }

            if store.collectionItem(for: card) == nil {
                added += 1
            } else {
                updated += 1
            }

            store.addCard(
                card,
                quantity: row.quantity,
                condition: row.condition,
                variant: row.variant
            )
        }

        summary = ImportResultSummary(
            addedCards: added,
            updatedCards: updated,
            unmatchedRows: unmatchedRows.count
        )
    }

    func exportCollectionCSV(from store: LocalVaultStore) {
        let rows = store.collectionItems.map { item in
            [
                item.card.name,
                item.card.set.name,
                item.card.number,
                "\(item.quantity)",
                item.condition.displayName,
                item.variant.displayName,
                "English"
            ]
        }

        exportText = csvString(
            headers: ["Name", "Set", "Number", "Quantity", "Condition", "Variant", "Language"],
            rows: rows
        )
    }

    func exportWishlistCSV(from store: LocalVaultStore) {
        let rows = store.wishlistItems.map { item in
            [
                item.card.name,
                item.card.set.name,
                item.card.number,
                item.priority.displayName,
                item.budget.vaultCSVValue,
                item.notes
            ]
        }

        exportText = csvString(
            headers: ["Name", "Set", "Number", "Priority", "Budget", "Notes"],
            rows: rows
        )
    }

    private func resetRows() {
        matchedRows = []
        unmatchedRows = []
        summary = ImportResultSummary()
    }

    private func parseCSV(_ text: String, store: LocalVaultStore) throws -> [ParsedImportRow] {
        let records = csvRecords(from: text).filter { record in
            record.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        }

        guard let header = records.first else {
            throw ImportParseError.emptyInput
        }

        let columns = Dictionary(uniqueKeysWithValues: header.enumerated().map { index, value in
            (Self.normalizedHeader(value), index)
        })

        guard columns["name"] != nil else {
            throw ImportParseError.missingNameColumn
        }

        return records.dropFirst().enumerated().map { offset, record in
            makeRow(rowNumber: offset + 2, valueFor: { key in
                guard let index = columns[key], record.indices.contains(index) else { return "" }
                return record[index]
            }, store: store)
        }
    }

    private func parseJSON(_ text: String, store: LocalVaultStore) throws -> [ParsedImportRow] {
        guard let data = text.data(using: .utf8) else {
            throw ImportParseError.emptyInput
        }

        let object = try JSONSerialization.jsonObject(with: data)
        let rawRows: [[String: Any]]

        if let array = object as? [[String: Any]] {
            rawRows = array
        } else if
            let dictionary = object as? [String: Any],
            let array = dictionary["cards"] as? [[String: Any]]
        {
            rawRows = array
        } else {
            throw ImportParseError.invalidJSON
        }

        return rawRows.enumerated().map { offset, dictionary in
            let normalized = Dictionary(uniqueKeysWithValues: dictionary.map { key, value in
                (Self.normalizedHeader(key), String(describing: value))
            })

            return makeRow(rowNumber: offset + 1, valueFor: { key in
                normalized[key] ?? ""
            }, store: store)
        }
    }

    private func makeRow(
        rowNumber: Int,
        valueFor: (String) -> String,
        store: LocalVaultStore
    ) -> ParsedImportRow {
        let name = clean(valueFor("name"))
        let set = clean(valueFor("set"))
        let number = clean(valueFor("number"))
        let quantity = max(Int(clean(valueFor("quantity"))) ?? 1, 1)
        let condition = Self.cardCondition(from: valueFor("condition"))
        let variant = Self.cardVariant(from: valueFor("variant"))
        let language = clean(valueFor("language")).isEmpty ? "English" : clean(valueFor("language"))
        let card = matchCard(name: name, set: set, number: number, in: store)

        return ParsedImportRow(
            rowNumber: rowNumber,
            name: name,
            set: set,
            number: number,
            quantity: quantity,
            condition: condition,
            variant: variant,
            language: language,
            matchedCard: card
        )
    }

    private func matchCard(name: String, set: String, number: String, in store: LocalVaultStore) -> Card? {
        let normalizedName = Self.normalizedValue(name)
        let normalizedSet = Self.normalizedValue(set)
        let normalizedNumber = Self.normalizedValue(number)

        return store.cards.first { card in
            guard Self.normalizedValue(card.name) == normalizedName else { return false }

            let setMatches = normalizedSet.isEmpty
                || Self.normalizedValue(card.set.name) == normalizedSet
                || Self.normalizedValue(card.set.code) == normalizedSet

            let numberMatches = normalizedNumber.isEmpty
                || Self.normalizedValue(card.number) == normalizedNumber

            return setMatches && numberMatches
        }
    }

    private func csvRecords(from text: String) -> [[String]] {
        var records: [[String]] = []
        var record: [String] = []
        var field = ""
        var isQuoted = false
        var iterator = text.makeIterator()

        while let character = iterator.next() {
            if character == "\"" {
                if isQuoted, let next = iterator.next() {
                    if next == "\"" {
                        field.append("\"")
                    } else {
                        isQuoted = false
                        if next == "," {
                            record.append(field)
                            field = ""
                        } else if next == "\n" {
                            record.append(field)
                            records.append(record)
                            record = []
                            field = ""
                        } else if next != "\r" {
                            field.append(next)
                        }
                    }
                } else {
                    isQuoted.toggle()
                }
            } else if character == "," && !isQuoted {
                record.append(field)
                field = ""
            } else if character == "\n" && !isQuoted {
                record.append(field)
                records.append(record)
                record = []
                field = ""
            } else if character != "\r" {
                field.append(character)
            }
        }

        record.append(field)
        records.append(record)
        return records
    }

    private func csvString(headers: [String], rows: [[String]]) -> String {
        ([headers] + rows)
            .map { row in row.map(Self.escapeCSV).joined(separator: ",") }
            .joined(separator: "\n")
    }

    private func clean(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func normalizedHeader(_ value: String) -> String {
        normalizedValue(value)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "_", with: "")
    }

    private static func normalizedValue(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private static func cardCondition(from value: String) -> CardCondition {
        switch normalizedHeader(value) {
        case "mint", "m": .mint
        case "nearmint", "nm": .nearMint
        case "excellent", "ex": .excellent
        case "played", "pl": .played
        default: .nearMint
        }
    }

    private static func cardVariant(from value: String) -> CardVariant {
        switch normalizedHeader(value) {
        case "holo", "holographic": .holo
        case "reverseholo", "reverse": .reverseHolo
        case "fullart": .fullArt
        case "secretrare", "secret": .secretRare
        case "promo": .promo
        default: .normal
        }
    }

    private static func escapeCSV(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        if escaped.contains(",") || escaped.contains("\n") || escaped.contains("\"") {
            return "\"" + escaped + "\""
        }
        return escaped
    }
}

enum ImportParseError: LocalizedError {
    case emptyInput
    case missingNameColumn
    case invalidJSON

    var errorDescription: String? {
        switch self {
        case .emptyInput: "No import rows were found."
        case .missingNameColumn: "CSV must include a Name column."
        case .invalidJSON: "JSON must be an array of cards or an object with a cards array."
        }
    }
}

@MainActor
final class WishlistViewModel: ObservableObject {
    func highPriorityItems(in store: LocalVaultStore) -> [WishlistItem] {
        store.wishlistItems.filter { $0.priority == .grail || $0.priority == .high }
    }

    func targetValue(in store: LocalVaultStore) -> Double {
        store.wishlistItems.reduce(0) { $0 + $1.budget }
    }
}

@MainActor
final class FriendsViewModel: ObservableObject {
    @Published var addFriendText = ""

    func onlineFriends(in store: LocalVaultStore) -> [Friend] {
        store.friends.filter(\.isOnline)
    }

    func topCollectors(in store: LocalVaultStore) -> [Friend] {
        store.friends.sorted { $0.collectorScore > $1.collectorScore }
    }

    func incomingRequests(in store: LocalVaultStore) -> [FriendRequest] {
        store.friendRequests.filter { $0.direction == .incoming }
    }

    func outgoingRequests(in store: LocalVaultStore) -> [FriendRequest] {
        store.friendRequests.filter { $0.direction == .outgoing }
    }

    func addFriend(in store: LocalVaultStore) {
        store.sendFriendRequest(to: addFriendText)
        addFriendText = ""
    }
}

@MainActor
final class BinderDesignerViewModel: ObservableObject {
    @Published private(set) var hasUnsavedChanges = false
    @Published private(set) var lastSavedAt: Date = .now
    private var history: [BinderPage] = []

    func filledSlots(in store: LocalVaultStore) -> Int {
        store.binderPages.flatMap(\.slots).filter { $0.card != nil }.count
    }

    func totalSlots(in store: LocalVaultStore) -> Int {
        store.binderPages.flatMap(\.slots).count
    }

    func completion(for page: BinderPage) -> Double {
        guard !page.slots.isEmpty else { return 0 }
        let filled = page.slots.filter { $0.card != nil }.count
        return Double(filled) / Double(page.slots.count)
    }

    func completionText(for page: BinderPage) -> String {
        "\(Int((completion(for: page) * 100).rounded()))%"
    }

    func markSaved() {
        hasUnsavedChanges = false
        lastSavedAt = .now
    }

    func markChanged() {
        hasUnsavedChanges = true
    }

    func recordChange(before page: BinderPage?) {
        guard let page else { return }
        history.append(page)
        if history.count > 20 {
            history.removeFirst()
        }
        hasUnsavedChanges = true
    }

    func undoLastChange(in store: LocalVaultStore, selectedPageID: inout BinderPage.ID?) {
        guard let previous = history.popLast() else { return }
        if store.binderPages.contains(where: { $0.id == previous.id }) {
            store.updateBinderPage(previous)
        } else {
            store.binderPages.insert(previous, at: 0)
        }
        selectedPageID = previous.id
        hasUnsavedChanges = true
    }

    var canUndo: Bool {
        !history.isEmpty
    }
}

@MainActor
final class CompletionTrackerViewModel: ObservableObject {
    enum OwnershipFilter: String, CaseIterable, Identifiable {
        case all
        case caught
        case missing

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .all: "All"
            case .caught: "Caught"
            case .missing: "Missing"
            }
        }
    }

    @Published var ownershipFilter: OwnershipFilter = .all
    @Published var selectedGeneration: Int?
    @Published var selectedType: CardType?
    @Published var selectedRarity: CardRarity?
    @Published var searchText = ""

    func generations(in store: LocalVaultStore) -> [Int] {
        Array(Set(store.sets.map(Self.generation(for:)))).sorted()
    }

    func totalTracked(in store: LocalVaultStore) -> Int {
        store.cards.count
    }

    func ownedCount(in store: LocalVaultStore) -> Int {
        Set(store.collectionItems.map(\.card.id)).count
    }

    func missingCount(in store: LocalVaultStore) -> Int {
        max(totalTracked(in: store) - ownedCount(in: store), 0)
    }

    func setProgress(in store: LocalVaultStore) -> [SetProgress] {
        store.sets.map { set in
            let owned = Set(store.collectionItems.filter { $0.card.set == set }.map(\.card.id)).count
            let total = store.cards.filter { $0.set == set }.count
            return SetProgress(cardSet: set, owned: owned, total: max(total, 1))
        }
    }

    func overallFraction(in store: LocalVaultStore) -> Double {
        guard !store.cards.isEmpty else { return 0 }
        return Double(ownedCount(in: store)) / Double(store.cards.count)
    }

    func missingCards(in store: LocalVaultStore) -> [Card] {
        let ownedIDs = Set(store.collectionItems.map(\.card.id))
        return store.cards.filter { !ownedIDs.contains($0.id) }
    }

    func filteredCards(in store: LocalVaultStore) -> [Card] {
        let ownedIDs = Set(store.collectionItems.map(\.card.id))
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return store.cards.filter { card in
            switch ownershipFilter {
            case .all:
                break
            case .caught:
                guard ownedIDs.contains(card.id) else { return false }
            case .missing:
                guard !ownedIDs.contains(card.id) else { return false }
            }

            if let selectedGeneration, Self.generation(for: card.set) != selectedGeneration { return false }
            if let selectedType, card.cardType != selectedType { return false }
            if let selectedRarity, card.rarity != selectedRarity { return false }

            guard !query.isEmpty else { return true }
            return card.name.lowercased().contains(query)
                || card.set.name.lowercased().contains(query)
                || card.number.lowercased().contains(query)
        }
        .sorted { lhs, rhs in
            if lhs.set.releaseYear != rhs.set.releaseYear { return lhs.set.releaseYear < rhs.set.releaseYear }
            return lhs.name < rhs.name
        }
    }

    func isOwned(_ card: Card, in store: LocalVaultStore) -> Bool {
        store.collectionItem(for: card) != nil
    }

    func isWishlisted(_ card: Card, in store: LocalVaultStore) -> Bool {
        store.isWishlisted(card)
    }

    static func generation(for set: CardSet) -> Int {
        switch set.releaseYear {
        case ..<2020: 1
        case 2020...2022: 2
        case 2023...2024: 3
        default: 4
        }
    }
}

@MainActor
final class EventsViewModel: ObservableObject {
    @Published var selectedVisibility: BinderVisibility?
    @Published var eventDraft = EventDraft()

    func upcomingEvents(in store: LocalVaultStore) -> [VaultEvent] {
        filteredEvents(in: store).filter { $0.date >= .now }
    }

    func filteredEvents(in store: LocalVaultStore) -> [VaultEvent] {
        store.events
            .filter { selectedVisibility == nil || $0.visibility == selectedVisibility }
            .sorted { $0.date < $1.date }
    }

    func resetDraft(featuredSet: CardSet?) {
        eventDraft = EventDraft(featuredSet: featuredSet)
    }

    func editDraft(from event: VaultEvent) {
        eventDraft = EventDraft(event: event)
    }

    func makeEvent() -> VaultEvent {
        eventDraft.makeEvent()
    }
}

struct EventDraft {
    var id: UUID?
    var title: String
    var venue: String
    var date: Date
    var emojiMarker: String
    var notes: String
    var visibility: BinderVisibility
    var kind: VaultEventKind
    var prize: String
    var attendingFriends: Int
    var featuredSet: CardSet?

    init(featuredSet: CardSet? = nil) {
        self.id = nil
        self.title = ""
        self.venue = ""
        self.date = .now.addingTimeInterval(86400)
        self.emojiMarker = "📅"
        self.notes = ""
        self.visibility = .private
        self.kind = .community
        self.prize = "Collector meetup"
        self.attendingFriends = 0
        self.featuredSet = featuredSet
    }

    init(event: VaultEvent) {
        self.id = event.id
        self.title = event.title
        self.venue = event.venue
        self.date = event.date
        self.emojiMarker = event.emojiMarker
        self.notes = event.notes
        self.visibility = event.visibility
        self.kind = event.kind
        self.prize = event.prize
        self.attendingFriends = event.attendingFriends
        self.featuredSet = event.featuredSet
    }

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !venue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && featuredSet != nil
    }

    func makeEvent() -> VaultEvent {
        VaultEvent(
            id: id ?? UUID(),
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            venue: venue.trimmingCharacters(in: .whitespacesAndNewlines),
            date: date,
            kind: kind,
            prize: prize.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Collector meetup" : prize,
            attendingFriends: max(attendingFriends, 0),
            featuredSet: featuredSet ?? DemoVaultRepository.shared.sets[0],
            emojiMarker: emojiMarker.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "📅" : emojiMarker,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            visibility: visibility
        )
    }
}

@MainActor
final class InviteFriendsViewModel: ObservableObject {
    @Published private(set) var contacts: [InviteContact]
    let inviteCode = "VAULT-8420"

    init(repository: DemoVaultRepository = .shared) {
        contacts = repository.inviteContacts
    }

    var pendingContacts: [InviteContact] {
        contacts.filter { !$0.isInvited }
    }

    var inviteMessage: String {
        "Join me on VaultDex. Use invite code \(inviteCode) to compare collections, wishlists, and trade matches."
    }
}

@MainActor
final class AccountDeletionViewModel: ObservableObject {
    @Published var confirmationText = ""

    let checklist = [
        "Export collection history",
        "Close active trade offers",
        "Remove social profile",
        "Delete local demo data"
    ]

    var canRequestDeletion: Bool {
        confirmationText == "DELETE"
    }
}
