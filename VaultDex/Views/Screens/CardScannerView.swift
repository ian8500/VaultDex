import SwiftUI
import UIKit
import Vision
import AVFoundation

struct CardScannerView: View {
    @EnvironmentObject private var store: LocalVaultStore
    @State private var isCameraPresented = false
    @State private var cameraPermission: ScannerCameraPermission = .unknown
    @State private var isSearching = false
    @State private var detectedText = ""
    @State private var manualSearchText = ""
    @State private var matches: [Card] = []
    @State private var selectedCard: Card?
    @State private var message: String?
    @State private var successMessage: String?
    @State private var scanOverlayMessage = "Place card inside the frame"

    private let apiService = CardAPIService()

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    scanPanel
                    manualSearch
                    resultsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .bottomDockSpacing()
            }

            if let successMessage {
                VStack {
                    Spacer()
                    SuccessToast(message: successMessage)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 18)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationTitle("Scan Card")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            refreshCameraPermission()
        }
        .sheet(isPresented: $isCameraPresented) {
            CardCameraPicker { image in
                isCameraPresented = false
                handleCapturedImage(image)
            } onCancel: {
                isCameraPresented = false
                if cameraPermission != .denied {
                    scanOverlayMessage = "Place card inside the frame"
                    message = "Search manually if the camera is unavailable."
                }
            }
            .ignoresSafeArea()
        }
        .sheet(item: $selectedCard) { card in
            ScanCardConfirmationView(card: card) {
                store.addCard(card)
                showSuccess("Added to My Vault")
                selectedCard = nil
            } addToWants: {
                store.addToWishlist(card, priority: .medium, budget: card.marketValue)
                showSuccess("Added to Wants")
                selectedCard = nil
            } retry: {
                selectedCard = nil
                startScan()
            }
            .environmentObject(store)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Scan a card")
                .font(.system(.largeTitle, design: .rounded, weight: .black))
                .foregroundStyle(Color.vdTextPrimary)
                .lineLimit(1)

            Text("Capture the card name or number, then confirm the match.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.vdTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var scanPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [Color.vdGold.opacity(0.16), Color.vdPanel.opacity(0.78), Color.vdPanelRaised.opacity(0.86)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(spacing: 14) {
                    Image(systemName: "viewfinder.circle.fill")
                        .font(.system(size: 42, weight: .black))
                        .foregroundStyle(Color.vdGold)

                    Text(scanOverlayMessage)
                        .font(.headline.weight(.black))
                        .foregroundStyle(Color.vdTextPrimary)
                        .multilineTextAlignment(.center)

                    Text("Good light helps.")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.vdTextSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(22)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 190)
            .overlay(ScannerFrameOverlay().stroke(Color.vdGold.opacity(0.72), lineWidth: 2).padding(28))

            PrimaryButton(title: "Scan Card", systemImage: "camera.viewfinder") {
                startScan()
            }

            SecondaryButton(title: "Search manually", systemImage: "magnifyingglass") {
                scanOverlayMessage = "Place card inside the frame"
                message = "Use manual search below to find the card."
            }

            if cameraPermission == .denied {
                cameraPermissionPanel
            }

            if !detectedText.isEmpty {
                Text("Detected: \(detectedText)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.vdTextSecondary)
                    .lineLimit(2)
            }

            if let message {
                Label(message, systemImage: "info.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.vdTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(Color.vdPanel.opacity(0.70), in: RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    private var cameraPermissionPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Camera access is needed to scan cards.", systemImage: "camera.badge.ellipsis")
                .font(.subheadline.weight(.black))
                .foregroundStyle(Color.vdTextPrimary)

            Text("You can still search manually, or enable camera access in Settings.")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.vdTextSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                Button {
                    openSettings()
                } label: {
                    Label("Open Settings", systemImage: "gearshape.fill")
                        .font(.caption.weight(.black))
                        .foregroundStyle(Color.vdNavy)
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .background(Color.vdGold, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)

                Button {
                    message = "Use manual search below to find the card."
                } label: {
                    Label("Search manually", systemImage: "magnifyingglass")
                        .font(.caption.weight(.black))
                        .foregroundStyle(Color.vdTextPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .background(Color.vdPanelRaised.opacity(0.82), in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(Color.vdCoral.opacity(0.10), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.vdCoral.opacity(0.22), lineWidth: 1))
    }

    private var manualSearch: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Manual confirmation")
                .font(.headline.weight(.black))
                .foregroundStyle(Color.vdTextPrimary)

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.vdTextSecondary)

                TextField("Card name or number", text: $manualSearchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundStyle(Color.vdTextPrimary)

                Button {
                    Task { await searchCards(using: manualSearchText) }
                } label: {
                    Text("Search")
                        .font(.caption.weight(.black))
                        .foregroundStyle(Color.vdNavy)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color.vdGold, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(manualSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(manualSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
            }
            .padding(14)
            .background(Color.vdPanelRaised.opacity(0.72), in: RoundedRectangle(cornerRadius: 16))
        }
    }

    @ViewBuilder
    private var resultsSection: some View {
        if isSearching {
            VStack(spacing: 12) {
                ProgressView()
                    .tint(Color.vdGold)
                Text(message ?? "Finding matches...")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.vdTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(Color.vdPanel.opacity(0.68), in: RoundedRectangle(cornerRadius: 20))
        } else if matches.isEmpty {
            EmptyStateView(
                systemImage: "rectangle.stack.badge.plus",
                title: "No scan results yet",
                message: "Scan a card or search manually to add it to VaultDex."
            )
        } else {
            VStack(alignment: .leading, spacing: 12) {
                VaultSectionHeader(title: "Possible matches", subtitle: "\(matches.count)")

                VStack(spacing: 10) {
                    ForEach(matches) { card in
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            selectedCard = card
                        } label: {
                            ScanMatchRow(card: card)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func startScan() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        scanOverlayMessage = "Hold steady"
        guard ScannerCameraViewController.hasUsableCamera else {
            cameraPermission = .unavailable
            message = "Camera is not available here. Use manual search instead."
            return
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraPermission = .granted
            message = nil
            isCameraPresented = true
        case .notDetermined:
            message = "Checking camera access..."
            AVCaptureDevice.requestAccess(for: .video) { granted in
                Task { @MainActor in
                    cameraPermission = granted ? .granted : .denied
                    message = granted ? nil : nil
                    isCameraPresented = granted
                }
            }
        case .denied, .restricted:
            cameraPermission = .denied
            message = nil
        @unknown default:
            cameraPermission = .denied
            message = nil
        }
    }

    private func refreshCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraPermission = .granted
        case .notDetermined:
            cameraPermission = .unknown
        case .denied, .restricted:
            cameraPermission = .denied
        @unknown default:
            cameraPermission = .denied
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func handleCapturedImage(_ image: UIImage) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        isSearching = true
        scanOverlayMessage = "Scanning..."
        message = "Reading card..."
        Task {
            let recognition = await recognizeCardText(in: image)
            await MainActor.run {
                detectedText = recognition.displayText
                manualSearchText = recognition.primaryQuery
                message = "Finding matches..."
            }
            await searchCards(using: recognition)
        }
    }

    private func recognizeCardText(in image: UIImage) async -> ScanRecognitionResult {
        await Task.detached(priority: .userInitiated) {
            let croppedImage = image.croppedToScannerCardFrame()
            guard let cgImage = croppedImage.cgImage else { return .empty }
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.minimumTextHeight = 0.018
            request.recognitionLanguages = ["en-US"]
            request.customWords = [
                "Pikachu", "Charizard", "Eevee", "Mew", "Snorlax",
                "Bulbasaur", "Charmander", "Squirtle", "Dragonite",
                "Mewtwo", "Gengar", "Lucario"
            ]

            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: CGImagePropertyOrientation(croppedImage.imageOrientation))
            do {
                try handler.perform([request])
                let observations = request.results ?? []
                let candidates = observations.compactMap { observation -> ScanTextCandidate? in
                    guard let candidate = observation.topCandidates(1).first else { return nil }
                    let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !text.isEmpty else { return nil }
                    return ScanTextCandidate(text: text, confidence: candidate.confidence, boundingBox: observation.boundingBox)
                }
                return ScanRecognitionResult(candidates: candidates)
            } catch {
                return .empty
            }
        }
        .value
    }

    private func searchCards(using text: String) async {
        await searchCards(using: ScanRecognitionResult(manualText: text))
    }

    private func searchCards(using recognition: ScanRecognitionResult) async {
        guard let query = recognition.scanNameQuery else {
            await MainActor.run {
                isSearching = false
                matches = []
                message = "We couldn’t identify this card. Try again or search manually."
                scanOverlayMessage = "Place card inside the frame"
            }
            return
        }

        await MainActor.run {
            isSearching = true
            scanOverlayMessage = "Scanning..."
            message = nil
        }

        do {
            do {
                let supabaseCards = try await SupabaseCardRepository(repository: store.repositories.cards).searchCardsByName(
                    query,
                    limit: 5
                )
                if !supabaseCards.isEmpty {
                    await MainActor.run {
                        matches = rankScannedMatches(supabaseCards, recognition: recognition)
                        isSearching = false
                        message = recognition.isLowConfidence ? "We found a few possible matches" : "Choose the correct card"
                        scanOverlayMessage = "Hold steady"
                    }
                    return
                }
            } catch {
                // Fall back to the external provider if the card cache is unavailable.
            }

            await ExchangeRateService.shared.refreshRatesIfNeeded()
            let response = try await apiService.searchCardsForScan(name: query, pageSize: 5)
            let uniqueCards = response.data

            await apiService.cache(cards: uniqueCards, using: store.repositories.clientProvider)
            await MainActor.run {
                matches = rankScannedMatches(uniqueCards.map(\.localCard), recognition: recognition)
                isSearching = false
                if matches.isEmpty {
                    message = "We couldn’t identify this card. Try again or search manually."
                    scanOverlayMessage = "Place card inside the frame"
                } else {
                    message = recognition.isLowConfidence ? "We found a few possible matches" : "Choose the correct card"
                    scanOverlayMessage = "Hold steady"
                }
            }
        } catch {
            await MainActor.run {
                matches = []
                isSearching = false
                message = Self.isTimeout(error) ? "Card search took too long. Try again or search manually." : "Couldn’t search right now. Try again or use manual search."
                scanOverlayMessage = "Place card inside the frame"
            }
        }
    }

    private func rankScannedMatches(_ cards: [Card], recognition: ScanRecognitionResult) -> [Card] {
        let tokens = Set(recognition.searchQueries.flatMap { $0.lowercased().split(separator: " ").map(String.init) })
        return cards
            .sorted { left, right in
                score(card: left, tokens: tokens, recognition: recognition) > score(card: right, tokens: tokens, recognition: recognition)
            }
            .prefix(5)
            .map { $0 }
    }

    private func score(card: Card, tokens: Set<String>, recognition: ScanRecognitionResult) -> Int {
        let name = card.name.lowercased()
        let number = card.number.lowercased()
        var score = 0
        for token in tokens where token.count >= 2 {
            if name.contains(token) { score += 6 }
            if number.contains(token) { score += 4 }
            if card.set.name.lowercased().contains(token) { score += 2 }
        }
        if recognition.cardNumber?.lowercased() == number {
            score += 10
        }
        if let cardNumberPrefix = recognition.cardNumber?.split(separator: "/").first?.lowercased(), cardNumberPrefix == number {
            score += 8
        }
        return score
    }

    private static func isTimeout(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorTimedOut
    }

    private func showSuccess(_ text: String) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
            successMessage = text
        }
        Task {
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    if successMessage == text {
                        successMessage = nil
                    }
                }
            }
        }
    }
}

private struct ScanTextCandidate {
    let text: String
    let confidence: Float
    let boundingBox: CGRect
}

private struct ScanRecognitionResult {
    let lines: [ScanTextCandidate]
    let likelyName: String?
    let cardNumber: String?
    let setNumber: String?
    let averageConfidence: Float

    static let empty = ScanRecognitionResult(candidates: [])

    init(manualText: String) {
        let trimmed = Self.cleanOCRLine(manualText)
        lines = trimmed.isEmpty ? [] : [ScanTextCandidate(text: trimmed, confidence: 1, boundingBox: .zero)]
        likelyName = Self.isLikelyAppUIText(trimmed) ? nil : trimmed
        cardNumber = Self.extractCardNumber(from: trimmed)
        setNumber = Self.extractSetNumber(from: trimmed)
        averageConfidence = trimmed.isEmpty ? 0 : 1
    }

    init(candidates: [ScanTextCandidate]) {
        let cleaned = candidates
            .map { candidate in
                ScanTextCandidate(
                    text: Self.cleanOCRLine(candidate.text),
                    confidence: candidate.confidence,
                    boundingBox: candidate.boundingBox
                )
            }
            .filter { !$0.text.isEmpty }
            .filter { !Self.isLikelyAppUIText($0.text) }

        lines = cleaned
        averageConfidence = cleaned.isEmpty ? 0 : cleaned.reduce(Float(0)) { $0 + $1.confidence } / Float(cleaned.count)
        cardNumber = cleaned.compactMap { Self.extractCardNumber(from: $0.text) }.first
        setNumber = cleaned.compactMap { Self.extractSetNumber(from: $0.text) }.first
        likelyName = Self.extractLikelyName(from: cleaned)
    }

    var primaryQuery: String {
        searchQueries.first ?? ""
    }

    var displayText: String {
        let text = [likelyName, cardNumber, setNumber]
            .compactMap { $0 }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.isEmpty { return text }
        return lines.prefix(4).map(\.text).joined(separator: " ")
    }

    var isLowConfidence: Bool {
        averageConfidence < 0.62 || likelyName == nil
    }

    var scanNameQuery: String? {
        guard let likelyName else { return nil }
        let cleaned = Self.cleanOCRLine(likelyName)
        guard Self.isValidScanName(cleaned) else { return nil }
        return cleaned
    }

    var searchQueries: [String] {
        var queries: [String] = []

        if let likelyName {
            queries.append(likelyName)
        }
        if let cardNumber {
            queries.append(cardNumber)
        }
        if let setNumber {
            queries.append(setNumber)
        }

        for line in lines.prefix(6).map(\.text) where line.count >= 3 {
            queries.append(line)
        }

        var seen = Set<String>()
        return queries
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && seen.insert($0.lowercased()).inserted }
    }

    private static func extractLikelyName(from lines: [ScanTextCandidate]) -> String? {
        let noise = [
            "pokemon", "trainer", "stage", "basic", "evolves", "weakness", "resistance",
            "retreat", "illustrated", "illus", "copyright", "switch", "during", "damage",
            "attach", "energy", "opponent", "bench", "active", "discard", "shuffle",
            "card trading", "trading app", "manual search", "possible matches"
        ]

        return lines
            .filter { candidate in
                let lower = candidate.text.lowercased()
                return candidate.text.count >= 3
                    && candidate.text.count <= 34
                    && candidate.text.rangeOfCharacter(from: .letters) != nil
                    && candidate.text.range(of: #"^\d+(/\d+)?$"#, options: .regularExpression) == nil
                    && !noise.contains { lower.contains($0) }
                    && !Self.isLikelyAppUIText(candidate.text)
            }
            .sorted { left, right in
                let leftScore = nameScore(left)
                let rightScore = nameScore(right)
                if leftScore != rightScore { return leftScore > rightScore }
                return left.boundingBox.maxY > right.boundingBox.maxY
            }
            .first?
            .text
    }

    private static func nameScore(_ candidate: ScanTextCandidate) -> Float {
        var score = candidate.confidence * 10
        if candidate.boundingBox.maxY > 0.62 { score += 5 }
        if candidate.boundingBox.width > 0.18 { score += 2 }
        if candidate.text.split(separator: " ").count <= 4 { score += 2 }
        if candidate.text.count > 22 { score -= 4 }
        if candidate.text.range(of: #"\d"#, options: .regularExpression) != nil { score -= 3 }
        return score
    }

    private static func extractCardNumber(from text: String) -> String? {
        if let range = text.range(of: #"\b\d{1,4}/\d{1,4}\b"#, options: .regularExpression) {
            return String(text[range])
        }
        if let range = text.range(of: #"\b[A-Z]{1,4}\d{1,4}\b"#, options: .regularExpression) {
            return String(text[range])
        }
        return nil
    }

    private static func extractSetNumber(from text: String) -> String? {
        if let range = text.range(of: #"\b\d{1,4}\b"#, options: .regularExpression) {
            return String(text[range])
        }
        return nil
    }

    private static func cleanOCRLine(_ line: String) -> String {
        let cleaned = line
            .replacingOccurrences(of: #"[^A-Za-z0-9éÉ'’.\- /]"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return isLikelyAppUIText(cleaned) ? "" : cleaned
    }

    private static func isValidScanName(_ text: String) -> Bool {
        let words = text.split(separator: " ")
        return text.count >= 3
            && text.count <= 28
            && words.count <= 4
            && text.rangeOfCharacter(from: .letters) != nil
            && !isLikelyAppUIText(text)
            && text.range(of: #"^\d+(/\d+)?$"#, options: .regularExpression) == nil
    }

    private static func isLikelyAppUIText(_ text: String) -> Bool {
        let lower = text.lowercased()
        let blockedPhrases = [
            "vaultdex",
            "card trading app",
            "card trading",
            "trading app",
            "place card",
            "inside the frame",
            "inside frame",
            "hold steady",
            "good light",
            "capture",
            "cancel",
            "scan",
            "scanning",
            "scan card",
            "find card",
            "add to vault",
            "add to wants",
            "manual confirmation",
            "manual search",
            "search manually",
            "possible matches",
            "no scan results",
            "home",
            "search",
            "trade",
            "friends",
            "wants",
            "profile"
        ]
        return blockedPhrases.contains { lower.contains($0) }
    }
}

private enum ScannerCameraPermission {
    case unknown
    case granted
    case denied
    case unavailable
}

private struct ScanMatchRow: View {
    let card: Card

    var body: some View {
        HStack(spacing: 13) {
            ScanCardThumbnail(card: card)
                .frame(width: 68, height: 94)

            VStack(alignment: .leading, spacing: 8) {
                Text(card.name)
                    .font(.headline.weight(.black))
                    .foregroundStyle(Color.vdTextPrimary)
                    .lineLimit(2)

                HStack(spacing: 7) {
                    StatusPill(title: "\(card.set.code) #\(card.number)", tint: .vdSky)
                    StatusPill(title: card.rarity.displayName, tint: .vdGold)
                }

                Text(card.marketValue.vaultEstimatedCurrency)
                    .font(.caption.weight(.black))
                    .foregroundStyle(Color.vdTextSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.black))
                .foregroundStyle(Color.vdTextSecondary)
        }
        .padding(12)
        .background(Color.vdPanel.opacity(0.72), in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.07), lineWidth: 1))
    }
}

private struct ScanCardThumbnail: View {
    let card: Card

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.vdPanelRaised.opacity(0.82))

            if let url = card.smallImageURL ?? card.largeImageURL {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image(systemName: "rectangle.portrait.fill")
                        .foregroundStyle(Color.vdGold)
                }
            } else {
                Image(systemName: "rectangle.portrait.fill")
                    .foregroundStyle(Color.vdGold)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.vdGold.opacity(0.20), lineWidth: 1))
    }
}

private struct ScanCardConfirmationView: View {
    let card: Card
    let addToVault: () -> Void
    let addToWants: () -> Void
    let retry: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                VStack(alignment: .leading, spacing: 18) {
                    CardDetailSummary(card: card)

                    PrimaryButton(title: "Add to My Vault", systemImage: "plus.circle.fill", action: addToVault)
                    SecondaryButton(title: "Add to Wants", systemImage: "star.fill", action: addToWants)

                    Button(action: retry) {
                        Label("Retry scan", systemImage: "camera.viewfinder")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Color.vdGold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.vdGold.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Confirm Card")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

private struct CardDetailSummary: View {
    let card: Card

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let imageURL = card.largeImageURL ?? card.smallImageURL {
                CachedAsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .scaledToFit()
                } placeholder: {
                    CardTile(card: card)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 300)
            } else {
                CardTile(card: card)
                    .frame(maxWidth: .infinity)
            }

            Text(card.name)
                .font(.title2.weight(.black))
                .foregroundStyle(Color.vdTextPrimary)

            HStack(spacing: 8) {
                StatusPill(title: "\(card.set.code) #\(card.number)", tint: .vdSky)
                StatusPill(title: card.rarity.displayName, tint: .vdGold)
                StatusPill(title: card.marketValue.vaultEstimatedCurrency, tint: .vdEmerald)
            }
        }
        .padding(16)
        .background(Color.vdPanel.opacity(0.74), in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
}

private struct ScannerFrameOverlay: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let length = min(rect.width, rect.height) * 0.20
        let corners = [
            (CGPoint(x: rect.minX, y: rect.minY), CGPoint(x: rect.minX + length, y: rect.minY), CGPoint(x: rect.minX, y: rect.minY + length)),
            (CGPoint(x: rect.maxX, y: rect.minY), CGPoint(x: rect.maxX - length, y: rect.minY), CGPoint(x: rect.maxX, y: rect.minY + length)),
            (CGPoint(x: rect.minX, y: rect.maxY), CGPoint(x: rect.minX + length, y: rect.maxY), CGPoint(x: rect.minX, y: rect.maxY - length)),
            (CGPoint(x: rect.maxX, y: rect.maxY), CGPoint(x: rect.maxX - length, y: rect.maxY), CGPoint(x: rect.maxX, y: rect.maxY - length))
        ]
        for corner in corners {
            path.move(to: corner.1)
            path.addLine(to: corner.0)
            path.addLine(to: corner.2)
        }
        return path
    }
}

private struct CardCameraPicker: UIViewControllerRepresentable {
    let onImage: (UIImage) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> ScannerCameraViewController {
        ScannerCameraViewController(onImage: onImage, onCancel: onCancel)
    }

    func updateUIViewController(_ uiViewController: ScannerCameraViewController, context: Context) {}
}

private final class ScannerCameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    static var hasUsableCamera: Bool {
        preferredCameraDevice() != nil
    }

    private let onImage: (UIImage) -> Void
    private let onCancel: () -> Void
    private let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "VaultDex.Scanner.Session")
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var didConfigureSession = false
    private var isViewVisible = false
    private var isCapturingPhoto = false

    init(onImage: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
        self.onImage = onImage
        self.onCancel = onCancel
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configurePreview()
        configureOverlayControls()

        sessionQueue.async { [weak self] in
            self?.configureSession()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isViewVisible = true
        sessionQueue.async { [weak self] in
            self?.startSessionIfReady()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isViewVisible = false
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
        if let connection = previewLayer?.connection, connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }
    }

    private func configurePreview() {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(layer)
        previewLayer = layer
    }

    private func configureSession() {
        guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized,
              let device = Self.preferredCameraDevice()
        else {
            DispatchQueue.main.async { [weak self] in self?.onCancel() }
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            session.beginConfiguration()
            session.sessionPreset = .photo
            guard session.canAddInput(input), session.canAddOutput(photoOutput) else {
                session.commitConfiguration()
                DispatchQueue.main.async { [weak self] in self?.onCancel() }
                return
            }
            session.addInput(input)
            session.addOutput(photoOutput)
            session.commitConfiguration()
            didConfigureSession = true
            startSessionIfReady()
        } catch {
            DispatchQueue.main.async { [weak self] in self?.onCancel() }
        }
    }

    private func startSessionIfReady() {
        guard didConfigureSession, isViewVisible, !session.isRunning else { return }
        session.startRunning()
    }

    private static func preferredCameraDevice() -> AVCaptureDevice? {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
    }

    private func configureOverlayControls() {
        let overlay = UIView()
        overlay.backgroundColor = .clear
        overlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlay)

        let label = UILabel()
        label.text = "Place card inside the frame\nGood light helps"
        label.textColor = .white
        label.font = .systemFont(ofSize: 17, weight: .bold)
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false

        let frameView = UIView()
        frameView.layer.borderColor = UIColor(red: 1.0, green: 0.78, blue: 0.12, alpha: 0.92).cgColor
        frameView.layer.borderWidth = 3
        frameView.layer.cornerRadius = 18
        frameView.backgroundColor = UIColor.clear
        frameView.translatesAutoresizingMaskIntoConstraints = false

        let shutterButton = UIButton(type: .system)
        shutterButton.setImage(UIImage(systemName: "camera.circle.fill"), for: .normal)
        shutterButton.tintColor = UIColor(red: 1.0, green: 0.78, blue: 0.12, alpha: 1)
        shutterButton.translatesAutoresizingMaskIntoConstraints = false
        shutterButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)

        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        cancelButton.tintColor = .white
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)

        overlay.addSubview(frameView)
        overlay.addSubview(label)
        overlay.addSubview(shutterButton)
        overlay.addSubview(cancelButton)

        NSLayoutConstraint.activate([
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            frameView.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            frameView.centerYAnchor.constraint(equalTo: overlay.centerYAnchor, constant: -18),
            frameView.widthAnchor.constraint(equalTo: overlay.widthAnchor, multiplier: 0.78),
            frameView.heightAnchor.constraint(equalTo: frameView.widthAnchor, multiplier: 1.38),
            label.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            label.topAnchor.constraint(equalTo: frameView.bottomAnchor, constant: 18),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: overlay.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(lessThanOrEqualTo: overlay.trailingAnchor, constant: -24),

            shutterButton.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            shutterButton.bottomAnchor.constraint(equalTo: overlay.safeAreaLayoutGuide.bottomAnchor, constant: -26),
            shutterButton.widthAnchor.constraint(equalToConstant: 74),
            shutterButton.heightAnchor.constraint(equalToConstant: 74),

            cancelButton.leadingAnchor.constraint(equalTo: overlay.leadingAnchor, constant: 20),
            cancelButton.topAnchor.constraint(equalTo: overlay.safeAreaLayoutGuide.topAnchor, constant: 16)
        ])
    }

    @objc private func capturePhoto() {
        guard !isCapturingPhoto else { return }
        guard didConfigureSession, session.isRunning else {
            onCancel()
            return
        }
        isCapturingPhoto = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let settings = AVCapturePhotoSettings()
        if let connection = photoOutput.connection(with: .video), connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    @objc private func cancel() {
        onCancel()
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        isCapturingPhoto = false
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data)
        else {
            onCancel()
            return
        }
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
        onImage(image)
    }
}

private extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}

private extension UIImage {
    func croppedToScannerCardFrame() -> UIImage {
        let normalized = normalizedForScannerCrop()
        guard let cgImage = normalized.cgImage else { return normalized }

        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)
        let cardAspect: CGFloat = 1.38
        var cropWidth = imageWidth * 0.78
        var cropHeight = cropWidth * cardAspect

        if cropHeight > imageHeight * 0.84 {
            cropHeight = imageHeight * 0.84
            cropWidth = cropHeight / cardAspect
        }

        let cropX = max((imageWidth - cropWidth) / 2, 0)
        let verticalOffset = imageHeight * -0.035
        let cropY = max((imageHeight - cropHeight) / 2 + verticalOffset, 0)
        let cropRect = CGRect(
            x: cropX,
            y: min(cropY, imageHeight - cropHeight),
            width: min(cropWidth, imageWidth),
            height: min(cropHeight, imageHeight)
        ).integral

        guard let cropped = cgImage.cropping(to: cropRect) else { return normalized }
        return UIImage(cgImage: cropped, scale: normalized.scale, orientation: .up)
    }

    private func normalizedForScannerCrop() -> UIImage {
        guard imageOrientation != .up else { return self }
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
