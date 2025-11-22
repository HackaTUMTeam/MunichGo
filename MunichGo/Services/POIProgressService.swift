//
//  POIProgressService.swift
//  MunichGo
//
//  Created by Felix Haag on 22.11.25.
//

import Foundation
import MapKit
import SwiftData
import SwiftUI

struct CategoryStats: Identifiable {
    let id = UUID()
    let category: MKPointOfInterestCategory
    let totalCount: Int
    let seenCount: Int
    let coveragePercent: Double
}

struct NearbySuggestion: Identifiable {
    let id = UUID()
    let item: MKMapItem
    let distance: CLLocationDistance
    let isAlreadyVisited: Bool
    
    var distanceText: String {
        if distance < 1000 {
            return String(format: "%.0f m", distance)
        } else {
            return String(format: "%.1f km", distance / 1000)
        }
    }
}

protocol POIProgressServicing {
    var allPOIs: [MKMapItem] { get }
    var unseenPOIs: [MKMapItem] { get }
    var coveragePercent: Double { get }
    var seenLocationsCount: Int { get }
    var categoryStats: [CategoryStats] { get }

    func refreshPOIs(region: MKCoordinateRegion,
                     categories: Set<MKPointOfInterestCategory>) async

    func save(_ item: MKMapItem,
              as listType: PlaceListType,
              modelContext: ModelContext)
    
    func updateListType(for item: MKMapItem,
                        to newListType: PlaceListType,
                        modelContext: ModelContext) -> Bool

    func recomputeStats(modelContext: ModelContext)
    
    func savedMKMapItems(modelContext: ModelContext) -> [MKMapItem]
    
    func status(for item: MKMapItem, modelContext: ModelContext) -> PlaceListType?
    
    func suggestNearbyPlace(coordinate: CLLocationCoordinate2D,
                           categories: Set<MKPointOfInterestCategory>,
                           maxDistance: CLLocationDistance) async -> MKMapItem?
}

@Observable
final class POIProgressService: POIProgressServicing {
    static let shared = POIProgressService()
    private init() {}
    
    private(set) var allPOIs: [MKMapItem] = []
    private(set) var unseenPOIs: [MKMapItem] = []
    private(set) var coveragePercent: Double = 0
    private(set) var seenLocationsCount: Int = 0
    private(set) var categoryStats: [CategoryStats] = []
    
    // Rate limiting properties
    private var requestCount = 0
    private var lastRequestResetTime = Date()
    private let maxRequestsPerMinute = 45
    private let requestWindow: TimeInterval = 60

    // optional: last scan cache key
    private var lastScanKey: String? = nil

    // MARK: - Public

    func refreshPOIs(region: MKCoordinateRegion,
                     categories: Set<MKPointOfInterestCategory>) async {

        let scanKey = "\(region.center.latitude)|\(region.center.longitude)|\(region.span.latitudeDelta)|\(region.span.longitudeDelta)|\(categories.map{$0.rawValue}.sorted())"

        // simpler cache: if same scanKey, skip
        if scanKey == lastScanKey, !allPOIs.isEmpty { return }
        lastScanKey = scanKey

        let items = await scanRegionForPOIs(region: region, categories: categories)

        await MainActor.run {
            self.allPOIs = items
        }
    }

    func save(_ item: MKMapItem,
              as listType: PlaceListType,
              modelContext: ModelContext) {

        let key = placeKey(for: item)
        let descriptor = FetchDescriptor<Place>(
            predicate: #Predicate { $0.key == key }
        )

        if let existing = try? modelContext.fetch(descriptor).first {
            existing.listType = listType
            return
        }

        let coord = item.location.coordinate
        let cat = item.pointOfInterestCategory?.rawValue ?? "unknown"

        let sp = Place(
            key: key,
            name: item.name ?? "Unbekannt",
            latitude: coord.latitude,
            longitude: coord.longitude,
            categoryRaw: cat,
            listType: listType
        )
        modelContext.insert(sp)
    }
    
    func updateListType(for item: MKMapItem,
                        to newListType: PlaceListType,
                        modelContext: ModelContext) -> Bool {
        
        let key = placeKey(for: item)
        let descriptor = FetchDescriptor<Place>(
            predicate: #Predicate { $0.key == key }
        )
        
        guard let existing = try? modelContext.fetch(descriptor).first else {
            return false
        }
        
        existing.listType = newListType
        return true
    }

    func recomputeStats(modelContext: ModelContext) {
        let saved = (try? modelContext.fetch(FetchDescriptor<Place>())) ?? []
        let savedKeys = Set(saved.map(\.key))
        
        unseenPOIs = allPOIs.filter { !savedKeys.contains(placeKey(for: $0)) }

        let total = allPOIs.count
        seenLocationsCount = saved.count
        coveragePercent = total == 0 ? 0 : Double(seenLocationsCount) / Double(total) * 100.0
                
        // Berechne Statistiken pro Kategorie
        var categoryStatsDict: [String: (total: Int, seen: Int)] = [:]
        
//        for poi in allPOIs {
//            let categoryKey = poi.pointOfInterestCategory?.rawValue ?? "unknown"
//            let isSeen = savedKeys.contains(placeKey(for: poi))
//            
//            if categoryStatsDict[categoryKey] == nil {
//                categoryStatsDict[categoryKey] = (total: 0, seen: 0)
//            }
//            
//            categoryStatsDict[categoryKey]?.total += 1
//            if isSeen {
//                categoryStatsDict[categoryKey]?.seen += 1
//            }
//        }
        
        for category in MKPointOfInterestCategory.trackedCategories {
            let categoryKey = category.rawValue
            categoryStatsDict[categoryKey] = (total: 0, seen: 0)
        }
                
        categoryStats = categoryStatsDict.map { (key, value) in
            let coverage = value.total == 0 ? 0 : Double(value.seen) / Double(value.total) * 100.0
            return CategoryStats(
                category: MKPointOfInterestCategory(rawValue: key),
                totalCount: value.total,
                seenCount: value.seen,
                coveragePercent: coverage
            )
        }.sorted { $0.category.rawValue < $1.category.rawValue }
    }
    
    func status(for item: MKMapItem, modelContext: ModelContext) -> PlaceListType? {
        let key = placeKey(for: item)

        let descriptor = FetchDescriptor<Place>(
            predicate: #Predicate { $0.key == key }
        )

        guard let saved = try? modelContext.fetch(descriptor).first else {
            return nil
        }

        switch saved.listType {
        case .visited:  return .visited
        case .wishlist: return .wishlist
        }
    }
    
    func suggestNearbyPlace(coordinate: CLLocationCoordinate2D,
                           categories: Set<MKPointOfInterestCategory>,
                           maxDistance: CLLocationDistance = 50) async -> MKMapItem? {
        
        let userLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        // Erstelle eine kleine Region um die User-Position
        let searchRegion = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: maxDistance * 2,
            longitudinalMeters: maxDistance * 2
        )
        
        // Live-Suche nach POIs in der Nähe
        var nearbyPOIs: [(item: MKMapItem, distance: CLLocationDistance)] = []
                
        for category in categories {
            if let results = await searchPOIs(in: searchRegion, category: category) {
                for poi in results {
                    let distance = userLocation.distance(from: poi.location)
                    if distance <= maxDistance {
                        nearbyPOIs.append((item: poi, distance: distance))
                    }
                }
            }
        }
        
        // Sortiere nach Entfernung und gib den nächsten zurück
        return nearbyPOIs
            .sorted { $0.distance < $1.distance }
            .first?.item
    }
}

extension POIProgressService {
    
    /// Manages rate limiting for MapKit requests
    private func throttleRequest() async {
        let now = Date()
        let timeSinceReset = now.timeIntervalSince(lastRequestResetTime)
        
        // Reset counter if window has passed
        if timeSinceReset >= requestWindow {
            requestCount = 0
            lastRequestResetTime = now
        }
        
        // If we've hit the limit, wait until reset
        if requestCount >= maxRequestsPerMinute {
            let waitTime = requestWindow - timeSinceReset
            if waitTime > 0 {
                try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
                requestCount = 0
                lastRequestResetTime = Date()
            }
        }
        
        requestCount += 1
    }

    func scanRegionForPOIs(region: MKCoordinateRegion,
                           categories: Set<MKPointOfInterestCategory>) async -> [MKMapItem] {

//        let tiles = split(region: region, rows: 3, cols: 3)
//
//        var collected: [String: MKMapItem] = [:]
//        var requestCount = 0
//        let maxRequestsPerMinute = 45 // Stay under 50 limit with buffer
//        let delayNanoseconds: UInt64 = 1_200_000_000 // 1.2 seconds between requests
//
//        for tile in tiles {
//            for cat in categories {
//                // Rate limiting: add delay after every request
//                if requestCount > 0 {
//                    try? await Task.sleep(nanoseconds: delayNanoseconds)
//                }
//                
//                if let results = await searchPOIs(in: tile, category: cat) {
//                    for item in results {
//                        collected[placeKey(for: item)] = item
//                    }
//                }
//                
//                requestCount += 1
//                
//                // Reset counter after 60 seconds worth of requests
//                if requestCount >= maxRequestsPerMinute {
//                    try? await Task.sleep(nanoseconds: 60_000_000_000) // Wait 60 seconds
//                    requestCount = 0
//                }
//            }
//        }
//
//        return Array(collected.values)
        
        return []
    }

    func searchPOIs(in region: MKCoordinateRegion,
                    category: MKPointOfInterestCategory) async -> [MKMapItem]? {

        await withCheckedContinuation { continuation in
            let req = MKLocalSearch.Request()
            req.region = region
            req.resultTypes = .pointOfInterest
            req.pointOfInterestFilter = MKPointOfInterestFilter(including: [category])
            
            MKLocalSearch(request: req).start { resp, err in
                if err != nil { continuation.resume(returning: nil); return }
                continuation.resume(returning: resp?.mapItems ?? [])
            }
        }
    }

    func split(region: MKCoordinateRegion, rows: Int, cols: Int) -> [MKCoordinateRegion] {
        let latDelta = region.span.latitudeDelta / Double(rows)
        let lonDelta = region.span.longitudeDelta / Double(cols)

        var tiles: [MKCoordinateRegion] = []
        for r in 0..<rows {
            for c in 0..<cols {
                let latOffset = (Double(r) - Double(rows)/2 + 0.5) * latDelta
                let lonOffset = (Double(c) - Double(cols)/2 + 0.5) * lonDelta

                let center = CLLocationCoordinate2D(
                    latitude: region.center.latitude + latOffset,
                    longitude: region.center.longitude + lonOffset
                )

                tiles.append(
                    MKCoordinateRegion(
                        center: center,
                        span: MKCoordinateSpan(latitudeDelta: latDelta,
                                               longitudeDelta: lonDelta)
                    )
                )
            }
        }
        return tiles
    }
    
    func savedMKMapItems(modelContext: ModelContext) -> [MKMapItem] {
        let saved = (try? modelContext.fetch(FetchDescriptor<Place>())) ?? []

        return saved.compactMap { place in
            let coord = CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
            
            let location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)

            let item = MKMapItem(location: location, address: nil)
            item.name = place.name
            item.pointOfInterestCategory = MKPointOfInterestCategory(rawValue: place.categoryRaw)
            return item
        }
    }
}

