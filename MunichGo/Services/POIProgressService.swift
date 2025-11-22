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
            name: item.name ?? "Unknown",
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
        // Hole alle besuchten Orte
        let visitedDescriptor = FetchDescriptor<Place>(
            predicate: #Predicate<Place> { place in
                place.listTypeRaw == "visited"
            }
        )
        let savedVisited = (try? modelContext.fetch(visitedDescriptor)) ?? []
        let savedKeys = Set(savedVisited.map(\.key))
        
        unseenPOIs = allPOIs.filter { !savedKeys.contains(placeKey(for: $0)) }

        let total = allPOIs.count
        seenLocationsCount = savedVisited.count
        coveragePercent = total == 0 ? 0 : Double(seenLocationsCount) / Double(total) * 100.0
                
        // Berechne Statistiken pro Kategorie
        var categoryStatsDict: [String: (total: Int, seen: Int)] = [:]
        
        // Initialisiere alle Kategorien mit 0
        for category in MKPointOfInterestCategory.trackedCategories {
            let categoryKey = category.rawValue
            categoryStatsDict[categoryKey] = (total: 0, seen: 0)
        }
        
        // Zähle POIs aus allPOIs
        for poi in allPOIs {
            let categoryKey = poi.pointOfInterestCategory?.rawValue ?? "unknown"
            let isSeen = savedKeys.contains(placeKey(for: poi))
            
            if categoryStatsDict[categoryKey] == nil {
                categoryStatsDict[categoryKey] = (total: 0, seen: 0)
            }
            
            categoryStatsDict[categoryKey]?.total += 1
            if isSeen {
                categoryStatsDict[categoryKey]?.seen += 1
            }
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
        
        // WICHTIG: Viel größere Suchregion - MapKit findet in kleinen Regionen oft nichts
        // Wir filtern später auf maxDistance
        let searchRadius: CLLocationDistance = 1000 // 1km Suchradius
        let searchRegion = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: searchRadius,
            longitudinalMeters: searchRadius
        )
        
        print("🔍 Searching POIs in \(Int(searchRadius))m radius around (\(String(format: "%.4f", coordinate.latitude)), \(String(format: "%.4f", coordinate.longitude)))")
        print("📍 Categories: \(categories.map { $0.rawValue }.joined(separator: ", "))")
        
        // Verbesserte POI-Suche mit breiterem Filter
        let results = await searchNearbyPOIs(in: searchRegion, categories: categories)
        
        if results.isEmpty {
            print("❌ No POIs found in search radius")
            return nil
        }
        
        print("✅ Found \(results.count) total POIs, filtering to \(Int(maxDistance))m...")
        
        // Filtere nach tatsächlicher Entfernung und sortiere
        let nearbyPOIs = results.compactMap { item -> (item: MKMapItem, distance: CLLocationDistance)? in
            let distance = userLocation.distance(from: item.location)
            guard distance <= maxDistance else { return nil }
            return (item: item, distance: distance)
        }
        .sorted { $0.distance < $1.distance }
        
        if nearbyPOIs.isEmpty {
            print("ℹ️ Found \(results.count) POIs in search area, but none within \(Int(maxDistance))m")
            // Debug: Zeige die nächsten 3 POIs
            let nearest = results.map { item -> String in
                let dist = userLocation.distance(from: item.location)
                return "\(item.name ?? "Unknown"): \(Int(dist))m"
            }.prefix(3)
            print("   Nearest POIs: \(nearest.joined(separator: ", "))")
            return nil
        }
        
        let closest = nearbyPOIs.first!
        print("✅ Nearest place: '\(closest.item.name ?? "Unknown")' at \(Int(closest.distance))m")
        
        return closest.item
    }
    
    /// Erweiterte POI-Suche die mehrere Kategorien gleichzeitig berücksichtigt
    private func searchNearbyPOIs(in region: MKCoordinateRegion,
                                  categories: Set<MKPointOfInterestCategory>) async -> [MKMapItem] {
        
        // STRATEGIE 1: Versuche OHNE Kategoriefilter (findet mehr POIs)
        print("🔍 Searching all POIs in region...")
        var results = await performPOISearch(region: region, categories: nil)
        
        if !results.isEmpty {
            // Filtere STRIKT nach trackedCategories
            let filtered = results.filter { item in
                guard let category = item.pointOfInterestCategory else { return false }
                return categories.contains(category)
            }
            
            if !filtered.isEmpty {
                print("✅ Found \(filtered.count) POIs matching tracked categories (from \(results.count) total)")
                return filtered
            } else {
                print("⚠️ Found \(results.count) POIs but none match tracked categories")
                
                // Debug: Zeige welche Kategorien gefunden wurden
                let foundCategories = Set(results.compactMap { $0.pointOfInterestCategory?.rawValue })
                print("   Found categories: \(foundCategories.joined(separator: ", "))")
                print("   Wanted categories: \(categories.map { $0.rawValue }.joined(separator: ", "))")
                
                // WICHTIG: Gib LEERES Array zurück, nicht alle POIs
                // Wir wollen nur POIs aus trackedCategories
                return []
            }
        }
        
        // STRATEGIE 2: Versuche mit naturalLanguageQuery
        print("🔍 No POIs found, trying with natural language query...")
        results = await performPOISearchWithQuery(region: region, query: "places")
        
        if !results.isEmpty {
            // Auch hier: Filtere nach trackedCategories
            let filtered = results.filter { item in
                guard let category = item.pointOfInterestCategory else { return false }
                return categories.contains(category)
            }
            
            if !filtered.isEmpty {
                print("✅ Found \(filtered.count) POIs via natural language query (matching tracked categories)")
                return filtered
            } else {
                print("⚠️ Natural language query found \(results.count) POIs but none match tracked categories")
                return []
            }
        }
        
        print("❌ No POIs found with any strategy")
        return []
    }
    
    /// Alternative Suchmethode mit Natural Language Query
    private func performPOISearchWithQuery(region: MKCoordinateRegion, query: String) async -> [MKMapItem] {
        await withCheckedContinuation { continuation in
            let request = MKLocalSearch.Request()
            request.region = region
            request.naturalLanguageQuery = query
            // Nicht .pointOfInterest spezifizieren - lässt MapKit mehr finden
            
            print("   Trying natural language query: '\(query)'")
            
            MKLocalSearch(request: request).start { response, error in
                if let error = error {
                    print("   ℹ️ Query search failed: \(error.localizedDescription)")
                    continuation.resume(returning: [])
                    return
                }
                
                let items = response?.mapItems ?? []
                print("   📍 Query returned \(items.count) results")
                continuation.resume(returning: items)
            }
        }
    }
    
    private func performPOISearch(region: MKCoordinateRegion,
                                  categories: Set<MKPointOfInterestCategory>?) async -> [MKMapItem] {
        
        await withCheckedContinuation { continuation in
            let request = MKLocalSearch.Request()
            request.region = region
            request.resultTypes = .pointOfInterest
            
            if let categories = categories, !categories.isEmpty {
                // Verwende Filter mit allen Kategorien
                request.pointOfInterestFilter = MKPointOfInterestFilter(including: Array(categories))
                print("   Using category filter: \(categories.map { $0.rawValue }.joined(separator: ", "))")
            } else {
                // KEIN Filter = alle POIs
                print("   No category filter - searching all POIs")
            }
            
            MKLocalSearch(request: request).start { response, error in
                if let error = error as? MKError {
                    switch error.code {
                    case .loadingThrottled:
                        print("   ⚠️ MapKit rate limit exceeded")
                    case .placemarkNotFound:
                        print("   ℹ️ No placemarks in region (this is normal if area has no POIs)")
                    case .serverFailure:
                        print("   ⚠️ MapKit server error")
                    default:
                        print("   ⚠️ MapKit error: \(error.localizedDescription)")
                    }
                    continuation.resume(returning: [])
                    return
                }
                
                let items = response?.mapItems ?? []
                print("   📍 MapKit returned \(items.count) POIs")
                
                // Debug: Zeige erste paar Ergebnisse
                if items.count > 0 && items.count <= 5 {
                    for item in items {
                        let cat = item.pointOfInterestCategory?.rawValue ?? "uncategorized"
                        print("      - \(item.name ?? "Unknown") [\(cat)]")
                    }
                }
                
                continuation.resume(returning: items)
            }
        }
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
                print(resp?.mapItems.count)
                
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

