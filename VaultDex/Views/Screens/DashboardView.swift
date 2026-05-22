import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()

    private let statColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    statsGrid
                    featuredCards
                    activityFeed
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Text("Demo")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.vdGold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.vdGold.opacity(0.14), in: Capsule())
            }
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: viewModel.profile.avatarSymbol)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Color.vdGold)
                .frame(width: 56, height: 56)
                .background(Color.vdPanelRaised, in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.vdStroke, lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome back")
                    .font(.subheadline)
                    .foregroundStyle(Color.vdTextSecondary)

                Text(viewModel.profile.displayName)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.vdTextPrimary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.vdPanel.opacity(0.72), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vdStroke.opacity(0.7), lineWidth: 1)
        )
    }

    private var statsGrid: some View {
        LazyVGrid(columns: statColumns, spacing: 12) {
            DashboardStatCard(
                title: "Total Cards",
                value: "\(viewModel.totalCopies)",
                caption: "\(viewModel.uniqueCards) unique",
                systemImage: "rectangle.stack.fill",
                tint: .vdEmerald
            )

            DashboardStatCard(
                title: "Vault Value",
                value: viewModel.vaultValue.compactVaultCurrency,
                caption: "Offline estimate",
                systemImage: "chart.line.uptrend.xyaxis",
                tint: .vdGold
            )

            DashboardStatCard(
                title: "Collector Score",
                value: "\(viewModel.profile.collectorScore)",
                caption: viewModel.profile.favoriteSet.code + " favorite",
                systemImage: "crown.fill",
                tint: .vdViolet
            )

            DashboardStatCard(
                title: "Open Trades",
                value: "\(viewModel.pendingTrades)",
                caption: "Awaiting action",
                systemImage: "arrow.left.arrow.right",
                tint: .vdCoral
            )
        }
    }

    private var featuredCards: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Featured Vault", subtitle: "Highest value demo cards")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(viewModel.highlightCards) { card in
                        CardTile(card: card, style: .compact)
                            .frame(width: 220)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
        }
    }

    private var activityFeed: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Recent Activity", subtitle: "Local demo events")

            VStack(spacing: 10) {
                ForEach(viewModel.recentActivity) { activity in
                    HStack(spacing: 12) {
                        Image(systemName: activity.systemImage)
                            .foregroundStyle(Color.vdGold)
                            .frame(width: 34, height: 34)
                            .background(Color.vdGold.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

                        VStack(alignment: .leading, spacing: 3) {
                            Text(activity.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.vdTextPrimary)

                            Text(activity.subtitle)
                                .font(.caption)
                                .foregroundStyle(Color.vdTextSecondary)
                        }

                        Spacer()
                    }
                    .padding(12)
                    .background(Color.vdPanel.opacity(0.78), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.vdStroke.opacity(0.65), lineWidth: 1)
                    )
                }
            }
        }
    }

    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.vdTextPrimary)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(Color.vdTextSecondary)
        }
    }
}
