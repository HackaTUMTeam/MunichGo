//
//  MainTabView.swift
//  HackaTUM_25_App
//
//  Created by Felix Haag on 21.11.25.
//

import SwiftUI

struct MainTabView: View {
    @Environment(\.discoveredPolygonStore) private var store
    
    var body: some View {
        print("🔧 MainTabView body - store exists: \(store != nil)")
        
        return TabView {
            NavigationStack {
                if let store = store {
                    MapView(viewModel: MapViewModel(store: store))
                } else {
                    ProgressView("Loading map...")
                        .onAppear {
                            print("⚠️ MapView waiting for store...")
                        }
                }
            }
            .tabItem {
                Label("Map", systemImage: "map")
            }
            
            NavigationStack {
                ExploreView()
            }
            .tabItem {
                Label("Explore", systemImage: "location")
            }
            
            NavigationStack {
                StatsView()
            }
            .tabItem {
                Label("Stats", systemImage: "chart.pie")
            }
            NavigationStack{
                AccountView()
            }
            .tabItem {
                Label("Account", systemImage: "person")
            }
        }
    }
}

