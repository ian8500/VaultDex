import SwiftUI

struct AppBackground: View {
    var body: some View {
        ZStack {
            Color.vdBackground

            LinearGradient(
                colors: [
                    Color(hex: 0x1D2430).opacity(0.86),
                    Color.vdBackground,
                    Color(hex: 0x120F18).opacity(0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            LinearGradient(
                colors: [
                    Color.vdGold.opacity(0.13),
                    Color.clear,
                    Color.vdEmerald.opacity(0.09)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}
