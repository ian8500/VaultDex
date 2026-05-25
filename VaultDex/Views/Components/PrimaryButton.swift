import SwiftUI
import UIKit

struct PrimaryButton: View {
    let title: String
    var systemImage: String?
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 15, weight: .bold))
                }

                Text(title)
                    .font(.headline.weight(.black))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .foregroundStyle(Color.vdNavy)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 54)
            .padding(.vertical, 2)
            .background(
                LinearGradient(
                    colors: isEnabled ? [Color(hex: 0xFFF06A), Color.vdGold, Color.vdGoldDeep] : [Color.vdTextSecondary.opacity(0.5)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 14)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.48), lineWidth: 1)
            )
            .overlay(
                LinearGradient(
                    colors: [Color.white.opacity(0.52), Color.clear],
                    startPoint: .top,
                    endPoint: .center
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            )
            .shadow(color: Color.vdGold.opacity(isEnabled ? 0.34 : 0), radius: 14, x: 0, y: 6)
        }
        .simultaneousGesture(TapGesture().onEnded {
            guard isEnabled else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        })
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.55)
        .accessibilityHint("Activates \(title)")
    }
}

struct SecondaryButton: View {
    let title: String
    var systemImage: String?
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 15, weight: .bold))
                }

                Text(title)
                    .font(.subheadline.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .foregroundStyle(Color.vdTextPrimary)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 50)
            .padding(.vertical, 2)
            .background(Color.vdPanelRaised.opacity(0.86), in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.vdGold.opacity(0.38), lineWidth: 1)
            )
            .shadow(color: Color.vdGold.opacity(isEnabled ? 0.12 : 0), radius: 10, x: 0, y: 4)
        }
        .simultaneousGesture(TapGesture().onEnded {
            guard isEnabled else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        })
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.55)
        .accessibilityHint("Activates \(title)")
    }
}
