//
//  MainTabView.swift
//  HackaTUM_25_App
//
//  Created by Felix Haag on 21.11.25.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.discoveredPolygonStore) private var store
    @Environment(\.modelContext) private var modelContext

    @State private var mapViewModel: MapViewModel? = nil
    @State private var selection: TabType = .map

    enum TabType: Hashable {
        case map, explore, stats, search
    }

    var body: some View {
        TabView(selection: $selection) {

            Tab("Map", systemImage: "map", value: TabType.map) {
                NavigationStack {
                    Group {
                        if let mapViewModel {
                            MapView(viewModel: mapViewModel)
                        } else {
                            ProgressView("Loading map...")
                        }
                    }
                    .onAppear {
                        if mapViewModel == nil, let store {
                            mapViewModel = MapViewModel(store: store)
                        }
                    }
                }
            }
            
            Tab("Explore", systemImage: "location", value: TabType.explore) {
                NavigationStack {
                    ExploreView()
                }
            }

            Tab("Stats", systemImage: "chart.pie", value: TabType.stats) {
                NavigationStack {
                    if let store {
                        StatsView(viewModel: StatsViewModel(store: store, modelContext: modelContext))
                    } else {
                        ProgressView("Loading stats...")
                    }
                }
            }
            
            Tab("Search", systemImage: "magnifyingglass", value: TabType.search, role: .search) {
                VStack {
                    
                }
            }
        }
        .modifier(BottomAccessoryIfNeeded(
            show: selection == .map && mapViewModel != nil,
            mapViewModel: mapViewModel,
            modelContext: modelContext
        ))
    }
}

private struct BottomAccessoryIfNeeded: ViewModifier {
    let show: Bool
    let mapViewModel: MapViewModel?
    let modelContext: ModelContext

    @ViewBuilder
    func body(content: Content) -> some View {
        if show, let mapViewModel {
            content
                .tabViewBottomAccessory {
                    LiveLocationBar(
                        viewModel: mapViewModel,
                        modelContext: modelContext // falls global erreichbar; sonst reinreichen
                    )
                }
        } else {
            content   // ← KEIN tabViewBottomAccessory modifier -> kein leerer Container
        }
    }
}
