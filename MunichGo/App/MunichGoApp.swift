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
    // Add this init method
        init() {
            BackgroundLocationManager.shared.startTracking()
        }
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Hexagon.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var apiService = ApiService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(apiService)
        }
        .modelContainer(sharedModelContainer)
    }
}
