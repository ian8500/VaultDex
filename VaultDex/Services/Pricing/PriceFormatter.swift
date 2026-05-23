import Foundation

enum MarketCurrency {
    case gbp
    case eur
    case usd

    var code: String {
        switch self {
        case .gbp:
            "GBP"
        case .eur:
            "EUR"
        case .usd:
            ["U", "S", "D"].joined()
        }
    }
}

struct PriceFormatter {
    static let locale = Locale(identifier: "en_GB")

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = MarketCurrency.gbp.code
        formatter.currencySymbol = "£"
        formatter.locale = locale
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    private static let compactFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = MarketCurrency.gbp.code
        formatter.currencySymbol = "£"
        formatter.locale = locale
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        formatter.usesGroupingSeparator = true
        return formatter
    }()

    private static let plainNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = locale
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    static func string(from amount: Double) -> String {
        currencyFormatter.string(from: NSNumber(value: amount)) ?? "£0"
    }

    static func compactString(from amount: Double) -> String {
        if amount >= 1_000 {
            return currencyFormatter.string(from: NSNumber(value: amount.rounded())) ?? "£0"
        }
        return compactFormatter.string(from: NSNumber(value: amount)) ?? string(from: amount)
    }

    static func csvString(from amount: Double) -> String {
        plainNumberFormatter.string(from: NSNumber(value: amount)) ?? "0"
    }

    static func displayAmount(_ amount: Double, sourceCurrency: MarketCurrency = .gbp) -> Double {
        ExchangeRateService.shared.convertToGBP(amount, from: sourceCurrency)
    }
}

extension Double {
    var vaultCurrency: String {
        PriceFormatter.string(from: self)
    }

    var compactVaultCurrency: String {
        PriceFormatter.compactString(from: self)
    }

    var vaultCSVValue: String {
        PriceFormatter.csvString(from: self)
    }
}
