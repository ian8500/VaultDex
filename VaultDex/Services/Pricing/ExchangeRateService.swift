import Foundation

final class ExchangeRateService {
    static let shared = ExchangeRateService()

    private let userDefaults: UserDefaults
    private let urlSession: URLSession
    private let cacheTimestampKey = "VaultDexExchangeRatesCachedAt"
    private let cacheDuration: TimeInterval = 12 * 60 * 60
    private let fallbackRates: [MarketCurrency: Double] = [
        .gbp: 1.0,
        .eur: 0.86,
        .usd: 0.79
    ]

    init(userDefaults: UserDefaults = .standard, urlSession: URLSession = .shared) {
        self.userDefaults = userDefaults
        self.urlSession = urlSession
    }

    func convertToGBP(_ amount: Double, from sourceCurrency: MarketCurrency) -> Double {
        guard amount.isFinite else { return 0 }
        guard sourceCurrency != .gbp else { return amount }
        let rate = cachedRate(for: sourceCurrency)
        guard rate.isFinite, rate > 0 else { return amount }
        return amount * rate
    }

    func refreshRatesIfNeeded() async {
        let cachedAt = userDefaults.object(forKey: cacheTimestampKey) as? Date ?? .distantPast
        guard Date().timeIntervalSince(cachedAt) > cacheDuration else { return }

        do {
            let url = URL(string: "https://open.er-api.com/v6/latest/GBP")!
            let (data, response) = try await urlSession.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else { return }
            let payload = try JSONDecoder().decode(ExchangeRateResponse.self, from: data)
            cacheRate(fromGBPResponse: payload.rates[MarketCurrency.eur.code], for: .eur)
            cacheRate(fromGBPResponse: payload.rates[MarketCurrency.usd.code], for: .usd)
            userDefaults.set(Date(), forKey: cacheTimestampKey)
        } catch {
            return
        }
    }

    private func cachedRate(for sourceCurrency: MarketCurrency) -> Double {
        if sourceCurrency == .gbp { return 1 }
        let key = cacheKey(for: sourceCurrency)
        let cached = userDefaults.double(forKey: key)
        if cached > 0 { return cached }
        return fallbackRates[sourceCurrency] ?? 1
    }

    private func cacheRate(fromGBPResponse responseRate: Double?, for sourceCurrency: MarketCurrency) {
        guard let responseRate, responseRate.isFinite, responseRate > 0 else { return }
        userDefaults.set(1 / responseRate, forKey: cacheKey(for: sourceCurrency))
    }

    private func cacheKey(for sourceCurrency: MarketCurrency) -> String {
        "VaultDexExchangeRateToGBP.\(sourceCurrency.code)"
    }
}

private struct ExchangeRateResponse: Decodable {
    let rates: [String: Double]
}
