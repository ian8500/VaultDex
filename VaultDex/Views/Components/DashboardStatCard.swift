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
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 34, height: 34)
                    .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))

                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(.vdTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(title)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.vdTextPrimary.opacity(0.78))

                Text(caption)
                    .font(.caption)
                    .foregroundStyle(.vdTextSecondary)
                    .lineLimit(1)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.vdPanel.opacity(0.9), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.8), lineWidth: 1)
        )
    }
}

#Preview {
    DashboardStatCard(
        title: "Vault Value",
        value: "$1.4K",
        caption: "Demo portfolio",
        systemImage: "chart.line.uptrend.xyaxis",
        tint: .vdGold
    )
    .padding()
    .background(AppBackground())
}
