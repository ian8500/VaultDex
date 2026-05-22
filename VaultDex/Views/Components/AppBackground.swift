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

            Circle()
                .fill(Color.vdGold.opacity(colorScheme == .dark ? 0.18 : 0.28))
                .blur(radius: 70)
                .frame(width: 220, height: 220)
                .offset(x: -120, y: -270)

            Circle()
                .fill(Color.vdSky.opacity(colorScheme == .dark ? 0.12 : 0.18))
                .blur(radius: 80)
                .frame(width: 260, height: 260)
                .offset(x: 150, y: 120)

            diagonalFoil
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
                Color.white.opacity(colorScheme == .dark ? 0.04 : 0.32),
                Color.clear,
                Color.vdGold.opacity(colorScheme == .dark ? 0.08 : 0.18),
                Color.clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .blendMode(colorScheme == .dark ? .screen : .normal)
    }
}
