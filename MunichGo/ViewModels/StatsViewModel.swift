//
//  MapViewModel.swift
//  MunichGo
//
//  Created by Felix Haag on 22.11.25.
//

import Foundation
import SwiftUI
import MapKit
import SwiftyH3
import SwiftData

@Observable
final class StatsViewModel {
    let munichCenter = CLLocationCoordinate2D(latitude: Constants.MUNICH_LAT, longitude: Constants.MUNICH_LON)
    
    let store: DiscoveredPolygonsStore
    let poiService: POIProgressServicing
    let transportDetection: TransportDetector
    let districtDetector: DistrictDetector
    
    var cityExploration: Double = 0
    var locationCount: Int = 0
    var locationPercentage: Double = 0
    var greenScore: Double = 0
    var categoryStats: [CategoryStats] = []
    
    let region: MKCoordinateRegion
    let categories: Set<MKPointOfInterestCategory>
    
    var savedItems: [MKMapItem] = []
    
    // 1. Define the grid layout: 4 columns
    let columns = Array(repeating: GridItem(.flexible(), spacing: 20), count: 4)
    
    let modelContext: ModelContext
    
    // Mock badges
    let badges: [Badge] = [
        Badge(name: "Explorer", icon: "map.fill", description: "Explore 10% of the city.", unlocked: true, level: 2, maxLevel: 5),
        Badge(name: "Green Thumb", icon: "leaf.fill", description: "Achieve a green score of 50.", unlocked: true, level: 3, maxLevel: 5),
        Badge(name: "Night Owl", icon: "moon.fill", description: "Explore at night.", unlocked: false, level: 0, maxLevel: 3),
        Badge(name: "Early Bird", icon: "sun.max.fill", description: "Explore in the morning.", unlocked: false, level: 1, maxLevel: 3),
        // Added a few duplicates just so you can see the grid effect in Preview
        Badge(name: "Walker", icon: "figure.walk", description: "Walk 10km", unlocked: true, level: 4, maxLevel: 10),
        Badge(name: "Cyclist", icon: "bicycle", description: "Ride 20km", unlocked: false, level: 0, maxLevel: 10)
    ]

    init(store: DiscoveredPolygonsStore, poiService: POIProgressServicing = POIProgressService.shared, transportDetection: TransportDetector = TransportDetector.shared, districtDetector: DistrictDetector = DistrictDetector.shared, modelContext: ModelContext) {
        self.store = store
        self.transportDetection = transportDetection
        self.districtDetector = districtDetector
        self.modelContext = modelContext
        
        self.region = MKCoordinateRegion(center: munichCenter, span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08))
        self.categories = MKPointOfInterestCategory.trackedCategories
        self.poiService = poiService
                
        Task { @MainActor in
            await self.poiService.refreshPOIs(region: region, categories: categories)
            self.poiService.recomputeStats(modelContext: modelContext)
            
            cityExploration = store.percentageDiscovered()
            greenScore = transportDetection.getSustainabilityScore()
            locationCount = poiService.seenLocationsCount
            locationPercentage = poiService.coveragePercent
            categoryStats = poiService.categoryStats
        }
    }
    
    func reloadStats() {
        self.poiService.recomputeStats(modelContext: modelContext)
        
        cityExploration = store.percentageDiscovered()
        greenScore = transportDetection.getSustainabilityScore()
        locationCount = poiService.seenLocationsCount
        locationPercentage = poiService.coveragePercent
        categoryStats = poiService.categoryStats
    }
}
