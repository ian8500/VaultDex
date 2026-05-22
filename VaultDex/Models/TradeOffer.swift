import Foundation

enum TradeStatus: String, CaseIterable, Identifiable, Hashable {
    case pending
    case accepted
    case countered
    case declined

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pending: "Pending"
        case .accepted: "Accepted"
        case .countered: "Countered"
        case .declined: "Declined"
        }
    }
}

struct TradeOffer: Identifiable, Hashable {
    let id: UUID
    let partnerName: String
    let partnerHandle: String
    let offeredCards: [Card]
    let requestedCards: [Card]
    let status: TradeStatus
    let createdAt: Date
    let expiresInDays: Int
    let note: String

    init(
        id: UUID = UUID(),
        partnerName: String,
        partnerHandle: String,
        offeredCards: [Card],
        requestedCards: [Card],
        status: TradeStatus,
        createdAt: Date = .now,
        expiresInDays: Int,
        note: String
    ) {
        self.id = id
        self.partnerName = partnerName
        self.partnerHandle = partnerHandle
        self.offeredCards = offeredCards
        self.requestedCards = requestedCards
        self.status = status
        self.createdAt = createdAt
        self.expiresInDays = expiresInDays
        self.note = note
    }
}
