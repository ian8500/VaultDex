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
                .padding(.bottom, 30)
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

                    Text("Line up the card name and number")
                        .font(.headline.weight(.black))
                        .foregroundStyle(Color.vdTextPrimary)
                        .multilineTextAlignment(.center)

                    Text("OCR may need confirmation, especially with shiny cards or busy artwork.")
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
                Text("Finding possible matches...")
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
        message = "Reading card text..."
        Task {
            let text = await recognizeText(in: image)
            await MainActor.run {
                detectedText = text
                manualSearchText = text
            }
            await searchCards(using: text)
        }
    }

    private func recognizeText(in image: UIImage) async -> String {
        await Task.detached(priority: .userInitiated) {
            guard let cgImage = image.cgImage else { return "" }
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.minimumTextHeight = 0.018

            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: CGImagePropertyOrientation(image.imageOrientation))
            do {
                try handler.perform([request])
                let lines = request.results?
                    .compactMap { $0.topCandidates(1).first?.string }
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty } ?? []
                return scanBestSearchText(from: lines)
            } catch {
                return ""
            }
        }
        .value
    }

    private func searchCards(using text: String) async {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else {
            await MainActor.run {
                isSearching = false
                matches = []
                message = "We couldn’t read enough text. Try manual search."
            }
            return
        }

        await MainActor.run {
            isSearching = true
            message = nil
        }

        do {
            await ExchangeRateService.shared.refreshRatesIfNeeded()
            let response = try await apiService.searchCards(query: cleaned, page: 1, pageSize: 12)
            await apiService.cache(cards: response.data, using: store.repositories.clientProvider)
            await MainActor.run {
                matches = response.data.map(\.localCard)
                isSearching = false
                message = matches.isEmpty ? "No matches found. Try a simpler card name or number." : nil
            }
        } catch {
            await MainActor.run {
                matches = []
                isSearching = false
                message = "Couldn’t search right now. Try again or use manual search."
            }
        }
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

private func scanBestSearchText(from lines: [String]) -> String {
    let noise = ["pokemon", "trainer", "stage", "basic", "evolves", "weakness", "resistance", "retreat", "illustrated"]
    let numberLine = lines.first { $0.range(of: #"^\s*\d{1,3}/\d{1,3}\s*$"#, options: .regularExpression) != nil }
    let nameLine = lines.first { line in
        let lower = line.lowercased()
        return line.count >= 3
            && line.count <= 34
            && line.rangeOfCharacter(from: .letters) != nil
            && !noise.contains { lower.contains($0) }
    }
    return [nameLine, numberLine]
        .compactMap { $0 }
        .joined(separator: " ")
        .trimmingCharacters(in: .whitespacesAndNewlines)
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

                Text(card.marketValue.vaultCurrency)
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
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        Image(systemName: "rectangle.portrait.fill")
                            .foregroundStyle(Color.vdGold)
                    }
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
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    default:
                        CardTile(card: card)
                    }
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
                StatusPill(title: card.marketValue.vaultCurrency, tint: .vdEmerald)
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
        sessionQueue.async { [weak self] in
            guard let self, self.didConfigureSession, !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
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
            if session.canAddInput(input) {
                session.addInput(input)
            }
            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
            }
            session.commitConfiguration()
            didConfigureSession = true
        } catch {
            DispatchQueue.main.async { [weak self] in self?.onCancel() }
        }
    }

    private static func preferredCameraDevice() -> AVCaptureDevice? {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
            ?? AVCaptureDevice.default(for: .video)
    }

    private func configureOverlayControls() {
        let overlay = UIView()
        overlay.backgroundColor = .clear
        overlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlay)

        let label = UILabel()
        label.text = "Align card name and number"
        label.textColor = .white
        label.font = .systemFont(ofSize: 17, weight: .bold)
        label.textAlignment = .center
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
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data)
        else {
            onCancel()
            return
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
