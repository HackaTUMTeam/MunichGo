//
//  MainTabView.swift
//  HackaTUM_25_App
//
//  Created by Felix Haag on 21.11.25.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            MapView()
                .tabItem {
                    Label("Map", systemImage: "map")
                }
            
            ExploreView()
                .tabItem {
                    Label("Explore", systemImage: "location")
                }
            
            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.pie")
                }
        }
    }
}

