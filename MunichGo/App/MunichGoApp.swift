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
    
    init() {
        print("🚀 MunichGoApp init")
    }
    
    var sharedModelContainer: ModelContainer = {
        print("🔧 Creating ModelContainer...")
        let schema = Schema([
            DiscoveredPolygon.self,
            Place.self
        ])

//        TransportDetector.shared.startDetection()
//        //////////////////////////////////////////////////////////

        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
//        //////////////////////////////////////////////////////////
//        let pos = CLLocationCoordinate2D(latitude: Constants.MUNICH_LAT, longitude: Constants.MUNICH_LON)
//        let dman = DistrictManager()
//        if let districtId = DistrictManager.getDistrictID(for: pos) {
//            print("✅ User is in district: \(districtId)")
//        } else {
//            print("❌ User is outside the city districts.")
//        }
//        //////////////////////////////////////////////////////////

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
    //@State var mapViewModel = MapViewModel()
    //@StateObject private var apiService = ApiService()

    var body: some Scene {
        print("🔧 Building WindowGroup scene...")
        return WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                //.environment(mapViewModel)
                //.environmentObject(apiService)
                .onAppear {
                    print("✅ ContentView appeared!")
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
