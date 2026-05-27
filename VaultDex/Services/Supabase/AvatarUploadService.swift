import Foundation

#if canImport(UIKit)
import UIKit
#endif

#if canImport(UIKit)
struct AvatarUploadService {
    private let storage: VaultStorageRepository
    private let clientProvider: SupabaseClientProvider
    private let statusHandler: @MainActor (String) -> Void

    init(
        storage: VaultStorageRepository,
        clientProvider: SupabaseClientProvider,
        statusHandler: @escaping @MainActor (String) -> Void = { _ in }
    ) {
        self.storage = storage
        self.clientProvider = clientProvider
        self.statusHandler = statusHandler
    }

    func saveAvatar(image: UIImage, userId: UUID) async throws -> String {
        let jpegData = try ImageUploadService.compressedJPEGData(
            from: image,
            maxPixelDimension: 512,
            quality: 0.75
        )
        guard !jpegData.isEmpty else { throw ImageUploadError.compressionFailed }
        await statusHandler("JPEG prepared")

        await statusHandler("Uploading")
        let publicURLString = try await storage.uploadAvatar(
            userID: userId,
            data: jpegData,
            contentType: "image/jpeg"
        )
        await statusHandler("Uploaded")

        let data = try JSONSerialization.data(withJSONObject: [
            "avatar_url": publicURLString,
            "avatar_path": "\(userId.uuidString)/profile.jpg"
        ])
        let request = try clientProvider.restRequest(
            table: "profiles",
            method: .patch,
            queryItems: [URLQueryItem(name: "id", value: "eq.\(userId.uuidString)")],
            body: data,
            prefer: "return=minimal"
        )
        try await clientProvider.send(request)
        await statusHandler("Profile updated")

        return publicURLString
    }
}
#endif
