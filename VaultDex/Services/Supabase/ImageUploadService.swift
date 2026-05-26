import Foundation

#if canImport(UIKit)
import UIKit
#endif

enum CardPhotoSide: String, CaseIterable, Identifiable, Hashable {
    case front
    case back

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .front: "Front"
        case .back: "Back"
        }
    }
}

enum ImageUploadError: LocalizedError {
    case unsupportedPlatform
    case unreadableImage
    case compressionFailed
    case missingSession

    var errorDescription: String? {
        switch self {
        case .unsupportedPlatform:
            "Image upload is only available on iOS."
        case .unreadableImage:
            "VaultDex could not read that image. Try a different photo."
        case .compressionFailed:
            "VaultDex could not prepare that image for upload."
        case .missingSession:
            "Sign in before uploading images."
        }
    }
}

struct ImageUploadService {
    private let storage: VaultStorageRepository

    init(storage: VaultStorageRepository) {
        self.storage = storage
    }

    func uploadAvatar(userID: UUID, imageData: Data) async throws -> String {
        guard !imageData.isEmpty else { throw ImageUploadError.compressionFailed }
        return try await storage.uploadAvatar(userID: userID, data: imageData, contentType: "image/jpeg")
    }

    func uploadCardPhoto(userID: UUID, collectionItemID: UUID, side: CardPhotoSide, imageData: Data) async throws -> String {
        let compressed = try Self.compressedJPEGData(from: imageData, maxPixelDimension: 1_800, quality: 0.76)
        return try await storage.uploadCardPhoto(
            userID: userID,
            collectionItemID: collectionItemID,
            side: side,
            data: compressed,
            contentType: "image/jpeg"
        )
    }

    static func compressedJPEGData(from data: Data, maxPixelDimension: CGFloat, quality: CGFloat) throws -> Data {
        #if canImport(UIKit)
        guard let image = UIImage(data: data) else { throw ImageUploadError.unreadableImage }
        let fittedImage = image.resizedToFit(maxPixelDimension: maxPixelDimension)
        guard let jpegData = fittedImage.jpegData(compressionQuality: quality), !jpegData.isEmpty else {
            throw ImageUploadError.compressionFailed
        }
        return jpegData
        #else
        throw ImageUploadError.unsupportedPlatform
        #endif
    }
}

#if canImport(UIKit)
private extension UIImage {
    func resizedToFit(maxPixelDimension: CGFloat) -> UIImage {
        let largestSide = max(size.width, size.height)
        guard largestSide > maxPixelDimension else { return self }

        let scale = maxPixelDimension / largestSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
#endif
