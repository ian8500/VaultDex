import SwiftUI

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color.vdGold.opacity(0.18), Color.vdPanelRaised.opacity(0.72)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 76, height: 76)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.vdGold.opacity(isAnimating ? 0.36 : 0.20), lineWidth: 1)
                    )
                    .shadow(color: Color.vdGold.opacity(isAnimating ? 0.18 : 0.10), radius: isAnimating ? 16 : 10, x: 0, y: 7)

                Image(systemName: systemImage)
                    .font(.system(size: 31, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.vdGold)
                    .offset(y: isAnimating ? -2 : 2)
            }

            VStack(spacing: 6) {
                Text(title)
                    .font(.headline.weight(.black))
                    .foregroundStyle(Color.vdTextPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.84)

                Text(message)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.vdTextSecondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let actionTitle, let action {
                PrimaryButton(title: actionTitle, systemImage: "arrow.right", action: action)
                    .frame(maxWidth: 220)
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.vdPanelRaised.opacity(0.88), Color.vdPanel.opacity(0.78)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 20)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.vdGold.opacity(0.20), lineWidth: 1)
        )
        .shadow(color: Color.vdGold.opacity(0.09), radius: 16, x: 0, y: 8)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}
