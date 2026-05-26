import Foundation

enum TradeStatus: String, CaseIterable, Identifiable, Hashable {
    case pending
    case accepted
    case rejected
    case canceled
    case completed
    case disputed

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pending: "Pending"
        case .accepted: "Accepted"
        case .rejected: "Rejected"
        case .canceled: "Canceled"
        case .completed: "Completed"
        case .disputed: "Disputed"
        }
    }
}

enum TradeOfferDirection: String, CaseIterable, Identifiable, Hashable {
    case sent
    case received

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sent: "Sent"
        case .received: "Received"
        }
    }
}

struct TradeOffer: Identifiable, Hashable {
    let id: UUID
    let senderID: UUID?
    let receiverID: UUID?
    let partnerName: String
    let partnerHandle: String
    let offeredCards: [Card]
    let requestedCards: [Card]
    var status: TradeStatus
    let direction: TradeOfferDirection
    let internalCredits: Int
    let createdAt: Date
    let expiresInDays: Int
    let note: String
    let usesSafeTrade: Bool

    init(
        id: UUID = UUID(),
        senderID: UUID? = nil,
        receiverID: UUID? = nil,
        partnerName: String,
        partnerHandle: String,
        offeredCards: [Card],
        requestedCards: [Card],
        status: TradeStatus,
        direction: TradeOfferDirection = .received,
        internalCredits: Int = 0,
        createdAt: Date = .now,
        expiresInDays: Int,
        note: String,
        usesSafeTrade: Bool = false
    ) {
        self.id = id
        self.senderID = senderID
        self.receiverID = receiverID
        self.partnerName = partnerName
        self.partnerHandle = partnerHandle
        self.offeredCards = offeredCards
        self.requestedCards = requestedCards
        self.status = status
        self.direction = direction
        self.internalCredits = internalCredits
        self.createdAt = createdAt
        self.expiresInDays = expiresInDays
        self.note = note
        self.usesSafeTrade = usesSafeTrade
    }

    var offeredValue: Double {
        offeredCards.reduce(0) { $0 + $1.marketValue } + Double(internalCredits)
    }

    var requestedValue: Double {
        requestedCards.reduce(0) { $0 + $1.marketValue }
    }

    var valueDelta: Double {
        offeredValue - requestedValue
    }

    var fairnessScore: Double {
        let larger = max(offeredValue, requestedValue)
        guard larger > 0 else { return 1 }
        return max(0, 1 - abs(valueDelta) / larger)
    }

    var fairnessLabel: String {
        switch fairnessScore {
        case 0.86...: "Fair"
        case 0.65..<0.86: "Slightly uneven"
        default: "Review carefully"
        }
    }
}
