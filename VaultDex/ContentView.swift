//
//  ContentView.swift
//  VaultDex
//
//  Created by Ian Dickson on 22/05/2026.
//

import SwiftUI
import UIKit

struct ContentView: View {
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor { traits in
            traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.05, green: 0.10, blue: 0.18, alpha: 0.97)
            : UIColor(red: 1.00, green: 0.96, blue: 0.80, alpha: 0.97)
        }
        appearance.shadowColor = UIColor(red: 1.00, green: 0.85, blue: 0.30, alpha: 0.26)

        let selectedColor = UIColor(red: 1.00, green: 0.78, blue: 0.12, alpha: 1)
        let normalColor = UIColor.secondaryLabel
        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]
        appearance.stackedLayoutAppearance.normal.iconColor = normalColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: normalColor]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView {
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
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
                Label("My Vault", systemImage: "lock.shield")
            }

            NavigationStack {
                TradeView()
            }
            .tabItem {
                Label("Trade Hub", systemImage: "arrow.left.arrow.right")
            }

            NavigationStack {
                SocialProfileView()
            }
            .tabItem {
                Label("Collector", systemImage: "person.crop.circle")
            }
        }
        .tint(Color.vdGold)
        .background(AppBackground())
        .toolbarBackground(Color.vdPanel.opacity(0.95), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
