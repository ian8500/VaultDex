import SwiftUI

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Color.vdGold)
                .frame(width: 72, height: 72)
                .background(Color.vdGold.opacity(0.16), in: RoundedRectangle(cornerRadius: 18))
                .shadow(color: Color.vdGold.opacity(0.28), radius: 16, x: 0, y: 6)

            VStack(spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.vdTextPrimary)

                Text(message)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.vdTextSecondary)
            }

            if let actionTitle, let action {
                PrimaryButton(title: actionTitle, systemImage: "arrow.right", action: action)
                    .frame(maxWidth: 220)
                    .padding(.top, 4)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.vdPanel.opacity(0.9), in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.vdGold.opacity(0.22), lineWidth: 1)
        )
        .shadow(color: Color.vdGold.opacity(0.09), radius: 16, x: 0, y: 8)
    }
}
