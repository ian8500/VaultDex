import SwiftUI
import UIKit

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder

    @State private var uiImage: UIImage?
    @State private var isLoading = false

    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let uiImage {
                content(Image(uiImage: uiImage))
            } else {
                placeholder()
                    .task(id: url) {
                        await loadImage()
                    }
            }
        }
    }

    private func loadImage() async {
        guard let url, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        if let cached = await CardCacheService.shared.image(for: url) {
            await MainActor.run {
                uiImage = cached
            }
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  200..<300 ~= httpResponse.statusCode,
                  let image = UIImage(data: data)
            else { return }

            await CardCacheService.shared.saveImageData(data, for: url)
            await MainActor.run {
                uiImage = image
            }
        } catch {
            return
        }
    }
}
