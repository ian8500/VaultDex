import Foundation

enum CurrencyFormatter {
    static func gbp(_ amount: Double?) -> String {
        guard let amount, amount.isFinite, amount > 0 else {
            return "Value unavailable"
        }
        return PriceFormatter.string(from: amount)
    }

    static func compactGBP(_ amount: Double?) -> String {
        guard let amount, amount.isFinite, amount > 0 else {
            return "Value unavailable"
        }
        return PriceFormatter.compactString(from: amount)
    }
}

enum PriceService {
    static let eurToGBP = 0.86
    static let usdToGBP = 0.79

    static func gbpAmount(_ amount: Double?, sourceCurrency: MarketCurrency) -> Double? {
        guard let amount, amount.isFinite, amount > 0 else { return nil }
        switch sourceCurrency {
        case .gbp:
            return amount
        case .eur:
            return amount * eurToGBP
        case .usd:
            return amount * usdToGBP
        }
    }

    static func estimatedGBP(cardmarket: PokemonCardmarket?, tcgplayer: PokemonTCGPlayer?) -> Double? {
        if let price = cardmarket?.prices?.preferredPrice {
            return gbpAmount(price, sourceCurrency: .eur)
        }

        if let price = tcgplayer?.preferredPrice {
            return gbpAmount(price, sourceCurrency: .usd)
        }

        return nil
    }

    static func conditionMultiplier(_ condition: CardCondition) -> Double {
        switch condition {
        case .mint:
            1.10
        case .nearMint:
            1.00
        case .excellent:
            0.85
        case .played:
            0.50
        }
    }

    static func collectionValue(cardValue: Double, quantity: Int, condition: CardCondition) -> Double {
        guard cardValue.isFinite, cardValue > 0 else { return 0 }
        return cardValue * Double(max(quantity, 0)) * conditionMultiplier(condition)
    }
}
