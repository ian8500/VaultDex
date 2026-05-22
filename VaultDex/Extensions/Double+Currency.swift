import Foundation

extension Double {
    var vaultCurrency: String {
        formatted(.currency(code: "USD").precision(.fractionLength(0...2)))
    }

    var compactVaultCurrency: String {
        formatted(.currency(code: "USD").notation(.compactName))
    }

    var vaultCSVValue: String {
        formatted(.number.precision(.fractionLength(0...2)))
    }
}
