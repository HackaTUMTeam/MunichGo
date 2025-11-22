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

protocol POIProgressServicing {
    var allPOIs: [MKMapItem] { get }
    var unseenPOIs: [MKMapItem] { get }
    var coveragePercent: Double { get }

    func refreshPOIs(region: MKCoordinateRegion,
                     categories: Set<MKPointOfInterestCategory>) async

    func save(_ item: MKMapItem,
              as listType: PlaceListType,
              modelContext: ModelContext)

    func recomputeStats(modelContext: ModelContext)
    
    func savedMKMapItems(modelContext: ModelContext) -> [MKMapItem]
}

@Observable
final class POIProgressService: POIProgressServicing {
    static let shared = POIProgressService()
    private init() {}
    
    private(set) var allPOIs: [MKMapItem] = []
    private(set) var unseenPOIs: [MKMapItem] = []
    private(set) var coveragePercent: Double = 0

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

    func recomputeStats(modelContext: ModelContext) {
        let saved = (try? modelContext.fetch(FetchDescriptor<Place>())) ?? []
        let savedKeys = Set(saved.map(\.key))

        unseenPOIs = allPOIs.filter { !savedKeys.contains(placeKey(for: $0)) }

        let total = allPOIs.count
        let seen = total - unseenPOIs.count
        coveragePercent = total == 0 ? 0 : Double(seen) / Double(total) * 100.0
    }
}

extension POIProgressService {

    func scanRegionForPOIs(region: MKCoordinateRegion,
                           categories: Set<MKPointOfInterestCategory>) async -> [MKMapItem] {

        let tiles = split(region: region, rows: 6, cols: 6)

        var collected: [String: MKMapItem] = [:]

        for tile in tiles {
            for cat in categories {
                if let results = await searchPOIs(in: tile, category: cat) {
                    for item in results {
                        collected[placeKey(for: item)] = item
                    }
                }
            }
        }

        return Array(collected.values)
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

