import SwiftUI

struct VaultDexLogo: View {
    let size: CGFloat

    init(size: CGFloat = 64) {
        self.size = size
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0xFFF3A6), Color.vdGold, Color.vdGoldDeep],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.vdGold.opacity(0.32), radius: size * 0.18, x: 0, y: size * 0.08)
                .overlay(
                    LinearGradient(
                        colors: [Color.white.opacity(0.48), Color.clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
                )

            ShieldMark()
                .fill(
                    LinearGradient(
                        colors: [Color.vdNavy, Color.vdMidnight],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(size * 0.12)

            RoundedRectangle(cornerRadius: size * 0.07, style: .continuous)
                .fill(Color.vdPanelRaised.opacity(0.96))
                .frame(width: size * 0.36, height: size * 0.48)
                .rotationEffect(.degrees(-7))
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.07, style: .continuous)
                        .stroke(Color.vdGold.opacity(0.9), lineWidth: max(1.5, size * 0.035))
                        .rotationEffect(.degrees(-7))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.03, style: .continuous)
                        .fill(Color.vdGold.opacity(0.22))
                        .frame(width: size * 0.21, height: size * 0.05)
                        .rotationEffect(.degrees(-7))
                        .offset(y: size * 0.10)
                )

            LightningSpark()
                .fill(Color.vdGold)
                .frame(width: size * 0.24, height: size * 0.30)
                .offset(x: size * 0.19, y: -size * 0.16)
                .shadow(color: Color.vdGold.opacity(0.42), radius: size * 0.08, x: 0, y: 0)
        }
        .frame(width: size, height: size)
        .accessibilityLabel("VaultDex")
    }
}

private struct ShieldMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midX = rect.midX
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.16, y: rect.minY + rect.height * 0.18))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - rect.width * 0.16, y: rect.minY + rect.height * 0.18), control: CGPoint(x: midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.12, y: rect.minY + rect.height * 0.58))
        path.addQuadCurve(to: CGPoint(x: midX, y: rect.maxY - rect.height * 0.06), control: CGPoint(x: rect.maxX - rect.width * 0.20, y: rect.maxY - rect.height * 0.02))
        path.addQuadCurve(to: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.minY + rect.height * 0.58), control: CGPoint(x: rect.minX + rect.width * 0.20, y: rect.maxY - rect.height * 0.02))
        path.closeSubpath()
        return path
    }
}

private struct LightningSpark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX + rect.width * 0.08, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.22, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX - rect.width * 0.08, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.18, y: rect.midY - rect.height * 0.08))
        path.addLine(to: CGPoint(x: rect.midX + rect.width * 0.18, y: rect.midY - rect.height * 0.08))
        path.closeSubpath()
        return path
    }
}

#Preview {
    ZStack {
        AppBackground()
        VaultDexLogo(size: 96)
    }
}
