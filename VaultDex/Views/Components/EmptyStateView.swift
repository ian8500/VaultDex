import SwiftUI

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(
                        LinearGradient(
                            colors: [Color.vdGold.opacity(0.22), Color.vdGold.opacity(0.08), Color.vdSky.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 82, height: 82)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color.vdGold.opacity(isAnimating ? 0.44 : 0.22), lineWidth: 1)
                    )
                    .shadow(color: Color.vdGold.opacity(isAnimating ? 0.24 : 0.12), radius: isAnimating ? 18 : 10, x: 0, y: 8)

                Image(systemName: systemImage)
                    .font(.system(size: 34, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.vdGold)
                    .offset(y: isAnimating ? -2 : 2)
            }

            VStack(spacing: 6) {
                Text(title)
                    .font(.headline.weight(.black))
                    .foregroundStyle(Color.vdTextPrimary)
                    .multilineTextAlignment(.center)

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
        .padding(.horizontal, 24)
        .padding(.vertical, 26)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.vdPanelRaised.opacity(0.92), Color.vdPanel.opacity(0.88)],
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
