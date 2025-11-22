//
//  ContentView.swift
//  MunichGo
//
//  Created by Felix Haag on 22.11.25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var store: DiscoveredPolygonsStore? = nil
    @State private var isInitialized = false
    
    init() {
        print("🔧 ContentView init")
    }
    
    var body: some View {
        print("🔧 ContentView body - isAuthenticated: \(authViewModel.isAuthenticated), isInitialized: \(isInitialized)")
        
        return Group {
            if authViewModel.isAuthenticated {
                if isInitialized {
                    MainTabView()
                        .environment(\.discoveredPolygonStore, store)
                } else {
                    ProgressView("Initializing...")
                        .onAppear {
                            print("✅ Starting initialization...")
                            initializeStore()
                        }
                }
            } else {
                LoginView()
                    .onAppear {
                        print("✅ LoginView appeared!")
                        print("🛑 User logged out, stopping location tracking")
                        BackgroundLocationManager.shared.stopTracking()
                        store = nil
                        isInitialized = false
                    }
            }
        }
    }
    
    private func initializeStore() {
        guard !isInitialized else { return }
        
        print("🔧 Initializing DiscoveredPolygonsStore...")
        let s = DiscoveredPolygonsStore(context: modelContext)
        store = s
        
        print("🔧 Configuring BackgroundLocationManager...")
        BackgroundLocationManager.shared.configure(store: s)
        BackgroundLocationManager.shared.startTracking()
        print("✅ Location tracking started")
        
        isInitialized = true
        print("✅ Initialization complete!")
    }
}
