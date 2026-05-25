import SwiftUI

struct AppBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            base

            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            diagonalFoil
            cardTexture
        }
        .ignoresSafeArea()
    }

    private var base: Color {
        colorScheme == .dark ? Color.vdNavy : Color.vdCream
    }

    private var gradientColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(hex: 0x142747),
                Color.vdNavy,
                Color(hex: 0x091526),
                Color(hex: 0x211B2C)
            ]
        }

        return [
            Color(hex: 0xFFF7D7),
            Color(hex: 0xFFEAA3),
            Color(hex: 0xF6FAFF),
            Color(hex: 0xFFFDF4)
        ]
    }

    private var diagonalFoil: some View {
        LinearGradient(
            colors: [
                Color.white.opacity(colorScheme == .dark ? 0.035 : 0.30),
                Color.clear,
                Color.vdGold.opacity(colorScheme == .dark ? 0.07 : 0.16),
                Color.clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .blendMode(colorScheme == .dark ? .screen : .normal)
    }

    private var cardTexture: some View {
        GeometryReader { proxy in
            let spacing: CGFloat = 54
            Path { path in
                var x: CGFloat = -spacing
                while x < proxy.size.width + spacing {
                    path.move(to: CGPoint(x: x, y: -spacing))
                    path.addLine(to: CGPoint(x: x + proxy.size.height + spacing, y: proxy.size.height + spacing))
                    x += spacing
                }
            }
            .stroke(Color.vdGold.opacity(colorScheme == .dark ? 0.025 : 0.06), lineWidth: 1)
            .blendMode(colorScheme == .dark ? .screen : .multiply)
        }
        .allowsHitTesting(false)
    }
}
