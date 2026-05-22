import SwiftUI

struct DashboardStatCard: View {
    let title: String
    let value: String
    let caption: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: systemImage)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(tint)
                    .frame(width: 38, height: 38)
                    .background(tint.opacity(0.16), in: RoundedRectangle(cornerRadius: 13))

                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(.title2, design: .rounded, weight: .black))
                    .foregroundStyle(Color.vdTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(title)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.vdTextPrimary.opacity(0.78))

                Text(caption)
                    .font(.caption)
                    .foregroundStyle(Color.vdTextSecondary)
                    .lineLimit(1)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.vdPanelRaised.opacity(0.96), Color.vdPanel.opacity(0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 16)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(tint.opacity(0.34), lineWidth: 1)
        )
        .overlay(
            LinearGradient(colors: [Color.white.opacity(0.16), Color.clear], startPoint: .top, endPoint: .center)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        )
        .shadow(color: tint.opacity(0.12), radius: 12, x: 0, y: 6)
    }
}
