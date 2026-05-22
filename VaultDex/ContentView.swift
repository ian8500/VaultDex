//
//  ContentView.swift
//  VaultDex
//
//  Created by Ian Dickson on 22/05/2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Label("Dashboard", systemImage: "gauge.with.dots.needle.67percent")
            }

            NavigationStack {
                SearchView()
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }

            NavigationStack {
                VaultView()
            }
            .tabItem {
                Label("Vault", systemImage: "lock.shield")
            }

            NavigationStack {
                TradeView()
            }
            .tabItem {
                Label("Trade", systemImage: "arrow.left.arrow.right")
            }

            NavigationStack {
                SocialProfileView()
            }
            .tabItem {
                Label("Social", systemImage: "person.crop.circle")
            }
        }
        .tint(.vdGold)
        .preferredColorScheme(.dark)
        .background(AppBackground())
        .toolbarBackground(Color.vdBackground.opacity(0.95), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
    }
}

#Preview {
    ContentView()
}
