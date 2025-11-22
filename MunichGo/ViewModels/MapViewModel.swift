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

struct FadingPolygon: Identifiable {
    let id = UUID()
    let polygon: MKPolygon
    var opacity: Double = 0.7
}

let trackedCategories: Set<MKPointOfInterestCategory> = [
    // Essen & Trinken
    .bakery,
    .restaurant,
    .cafe,
    .foodMarket,

    // Kultur & Freizeit
    .amusementPark,
    .aquarium,
    .zoo,
    .museum,
    .theater,
    .stadium,
    .nightlife,

    // Natur & Outdoor
    .park,
    .beach,
    
    // Sightseeing / Tourismus
    .landmark,

    // Sport & Aktivitäten
    .fitnessCenter,

    // Shopping
    .store,

    // Verkehr & Mobilität
    .publicTransport,
    .airport,

    // Öffentliche Einrichtungen
    .library,
    .school,
    .university,

    // Gesundheit
    .hospital,
    .pharmacy
]

@Observable
final class MapViewModel {
    let munichCenter = CLLocationCoordinate2D(latitude: Constants.MUNICH_LAT, longitude: Constants.MUNICH_LON)
    let defaultZoom = MKCoordinateSpan(latitudeDelta: Constants.ZOOM_LAT, longitudeDelta: Constants.ZOOM_LON)
    let closeZoom = MKCoordinateSpan(latitudeDelta: Constants.CLOSE_ZOOM_LAT, longitudeDelta: Constants.CLOSE_ZOOM_LON)
    let broadZoom = MKCoordinateSpan(latitudeDelta: Constants.BROAD_ZOOM_LAT, longitudeDelta: Constants.BROAD_ZOOM_LON)

    var position: MapCameraPosition
    var selection: MapSelection<MKMapItem>? = nil
    
    let store: DiscoveredPolygonsStore
    
    var fogOverlay: MKPolygon = MKPolygon()
    var fogOverlayVersion: UUID = UUID()
    
    var worldOverlay: MKPolygon = MKPolygon()
    private var _munichPolygons: [MKPolygon]? = nil
    private var munichPolygons: [MKPolygon] {
        if _munichPolygons == nil {
            print("🔨 Generating Munich polygons (first access)...")
            _munichPolygons = PolygonsMunich.map { polygonPromCell(from: H3Cell($0)) }
            print("✅ Munich polygons generated: \(_munichPolygons!.count) polygons")
        }
        return _munichPolygons!
    }
    private(set) var discoveredPolygons: [MKPolygon] = []
    
    var fadingPolygons: [FadingPolygon] = []
    
    var selectedMapItem: MKMapItem? = nil
    var isSheetPresented: Bool = false
    var sheetDetent: PresentationDetent = .medium
    
    var cityExploration: Int = 0
    var greenScore: Int = 0
    
    var isZoomedOut = false
    var showSaved = false
    
    let poiService: POIProgressServicing
    let region: MKCoordinateRegion
    let categories: Set<MKPointOfInterestCategory>
    
    var savedItems: [MKMapItem] = []

    init(store: DiscoveredPolygonsStore, poiService: POIProgressServicing = POIProgressService.shared) {
        self.store = store
        
        self.region = MKCoordinateRegion(center: munichCenter, span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08))
        self.categories = trackedCategories
        self.poiService = poiService
        self.position = .region(region)
        
        self.position = .region(
            MKCoordinateRegion(
                center: munichCenter,
                span: defaultZoom
            )
        )
                
        Task { @MainActor in
            cityExploration = Int.random(in: 0..<101)
            greenScore = Int.random(in: 0..<101)
        }
        
        // munichPolygons wird jetzt lazy geladen - erst beim ersten Zugriff
                        
        Task { @MainActor in
            buildWorldOverlay()
            updateFromCells(store.cells, animateDiffVs: [])
        }
    }
    
    func updateFromCells(_ newCells: Set<H3Cell>) {
        updateFromCells(newCells, animateDiffVs: Array(store.lastCellsSnapshot))
        store.lastCellsSnapshot = newCells
    }
    
    func reloadSaved(modelContext: ModelContext) {
        savedItems = poiService.savedMKMapItems(modelContext: modelContext)
    }

    func mark(item: MKMapItem, as type: PlaceListType, modelContext: ModelContext) {
        poiService.save(item, as: type, modelContext: modelContext)
        reloadSaved(modelContext: modelContext)
    }
    
    private func updateFromCells(_ newCells: Set<H3Cell>, animateDiffVs oldCellsArray: [H3Cell]) {
        let oldCells = Set(oldCellsArray)
        let newlyFound = newCells.subtracting(oldCells)

        // 1) Discovered -> Polygone
        discoveredPolygons = newCells.map { polygonPromCell(from: $0) }

        // 2) Fog neu bauen
        buildFogOverlay()

        // 3) Map refresh erzwingen
        fogOverlayVersion = UUID()

        // 4) Fade-Overlays für neue Zellen
        for cell in newlyFound {
            let poly = polygonPromCell(from: cell)
            let fading = FadingPolygon(polygon: poly)
            fadingPolygons.append(fading)
            
            Task { @MainActor in
                // Fade out animation - 3 Sekunden, 30 Frames = 100ms pro Frame
                let duration: Double = 3.0 // Sekunden
                let steps = 30
                let delayNanoseconds = UInt64(duration * 1_000_000_000 / Double(steps))
                
                for i in 0...steps {
                    let progress = Double(i) / Double(steps)
                    let opacity = 0.7 * (1.0 - progress) // Von 0.7 bis 0.0
                    
                    if let index = fadingPolygons.firstIndex(where: { $0.id == fading.id }) {
                        fadingPolygons[index].opacity = opacity
                    }
                    
                    if i < steps {
                        try? await Task.sleep(nanoseconds: delayNanoseconds)
                    }
                }
                fadingPolygons.removeAll { $0.id == fading.id }
            }
        }
    }
    
    private func buildWorldOverlay() {
        let coords = worldCoords()

        worldOverlay = MKPolygon(
            coordinates: coords,
            count: coords.count,
            interiorPolygons: munichPolygons
        )
    }
    
    private func buildFogOverlay() {
        let coords = worldCoords()
        
        fogOverlay = MKPolygon(
            coordinates: coords,
            count: coords.count,
            interiorPolygons: discoveredPolygons
        )
    }
    
    @MainActor
    func rebuildFog(from cells: Set<H3Cell>) {
        discoveredPolygons = cells.map { polygonPromCell(from: $0) }
        buildFogOverlay()
        fogOverlayVersion = UUID()
    }
    
    private func worldCoords() -> [CLLocationCoordinate2D] {
        let paddingLat: CLLocationDegrees = 25
        let paddingLon: CLLocationDegrees = 90

        let north = munichCenter.latitude + paddingLat
        let south = munichCenter.latitude - paddingLat * 4
        let east  = munichCenter.longitude + paddingLon
        let west  = munichCenter.longitude - paddingLon

        let coords = [
            CLLocationCoordinate2D(latitude: north, longitude: west),
            CLLocationCoordinate2D(latitude: south, longitude: west), // Go South first
            CLLocationCoordinate2D(latitude: south, longitude: east), // Then East
            CLLocationCoordinate2D(latitude: north, longitude: east)  // Then North
        ]
        
        return coords
    }
    
    func handleFeatureSelection(_ feature: MapFeature?) {
        guard let feature else {
            clearSelection()
            return
        }

        Task { @MainActor in
            let request = MKMapItemRequest(feature: feature)
            do {
                let item = try await request.mapItem
                self.selectedMapItem = item
                self.isSheetPresented = true
            } catch {
                self.clearSelection()
            }
        }

        isSheetPresented = true
        sheetDetent = .height(180)
    }
    
    func clearSelection() {
        selection = nil
        selectedMapItem = nil
        isSheetPresented = false
    }
    
    func handleSavedMarkerTap(_ item: MKMapItem) {
        selectedMapItem = item
        isSheetPresented = true
        sheetDetent = .medium
    }

    func resetToMunich() {
        position = .region(
            MKCoordinateRegion(
                center: munichCenter,
                span: MKCoordinateSpan(latitudeDelta: Constants.ZOOM_LAT, longitudeDelta: Constants.ZOOM_LON)
            )
        )
    }
    
    func changeZoom() {
        if isZoomedOut {
            position = .region(
                MKCoordinateRegion(
                    center: position.camera?.centerCoordinate ?? munichCenter,
                    span: closeZoom
                )
            )
        } else {
            position = .region(
                MKCoordinateRegion(
                    center: munichCenter,
                    span: broadZoom
                )
            )
        }
        
        isZoomedOut.toggle()
    }
}

extension MKPolygon {
    /// Schwerpunkt (rough) vom Polygon, gut genug zum Zugehörigkeits-Test
    var centroid: CLLocationCoordinate2D {
        let pts = points()
        var x: Double = 0
        var y: Double = 0
        for i in 0..<pointCount {
            x += pts[i].x
            y += pts[i].y
        }
        let centerPoint = MKMapPoint(x: x / Double(pointCount),
                                     y: y / Double(pointCount))
        return centerPoint.coordinate
    }
    
    func containsCoordinate(_ coord: CLLocationCoordinate2D) -> Bool {
        let renderer = MKPolygonRenderer(polygon: self)
        let mapPoint = MKMapPoint(coord)
        let point = renderer.point(for: mapPoint)
        return renderer.path.contains(point)
    }
}
