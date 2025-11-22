//
//  MunichGoApp.swift
//  MunichGo
//
//  Created by Felix Haag on 22.11.25.
//

import SwiftUI
import SwiftData
import MapKit

@main
struct MunichGoApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Hexagon.self,
        ])
        //////////////////////////////////////////////////////////
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let pos = CLLocationCoordinate2D(latitude: Constants.MUNICH_LAT, longitude: Constants.MUNICH_LON)
        let dman = DistrictManager()
        if let districtId = DistrictManager.getDistrictID(for: pos) {
            print("✅ User is in district: \(districtId)")
        } else {
            print("❌ User is outside the city districts.")
        }
        //////////////////////////////////////////////////////////

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    @StateObject private var authViewModel = AuthViewModel()
    @State var mapViewModel = MapViewModel()
    //@StateObject private var apiService = ApiService()
    
    init() {
        BackgroundLocationManager.shared.startTracking()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environment(mapViewModel)
                //.environmentObject(apiService)
        }
        .modelContainer(sharedModelContainer)
    }
}
