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
                .foregroundStyle(.vdGold)
                .frame(width: 72, height: 72)
                .background(Color.vdGold.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))

            VStack(spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.vdTextPrimary)

                Text(message)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.vdTextSecondary)
            }

            if let actionTitle, let action {
                PrimaryButton(title: actionTitle, systemImage: "arrow.right", action: action)
                    .frame(maxWidth: 220)
                    .padding(.top, 4)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.vdPanel.opacity(0.88), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.8), lineWidth: 1)
        )
    }
}

#Preview {
    EmptyStateView(
        systemImage: "tray",
        title: "Nothing here yet",
        message: "Your demo vault is ready for the next batch."
    )
    .padding()
    .background(AppBackground())
}
