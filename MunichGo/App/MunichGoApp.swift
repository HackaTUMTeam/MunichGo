//
//  MunichGoApp.swift
//  MunichGo
//
//  Created by Felix Haag on 22.11.25.
//

import SwiftUI
import SwiftData

@main
struct MunichGoApp: App {
    
    init() {
        print("🚀 MunichGoApp init")
    }
    
    var sharedModelContainer: ModelContainer = {
        print("🔧 Creating ModelContainer...")
        let schema = Schema([
            DiscoveredPolygon.self,
            Place.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print("✅ ModelContainer created successfully")
            return container
        } catch {
            print("❌ Fatal error creating ModelContainer: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    @StateObject private var authViewModel = AuthViewModel()
    //@StateObject private var apiService = ApiService()

    var body: some Scene {
        print("🔧 Building WindowGroup scene...")
        return WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                //.environmentObject(apiService)
                .onAppear {
                    print("✅ ContentView appeared!")
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
