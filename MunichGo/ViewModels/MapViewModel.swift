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

@Observable
final class MapViewModel {
    let munichCenter = CLLocationCoordinate2D(latitude: Constants.MUNICH_LAT, longitude: Constants.MUNICH_LON)
    let defaultZoom = MKCoordinateSpan(latitudeDelta: Constants.ZOOM_LAT, longitudeDelta: Constants.ZOOM_LON)
    let closeZoom = MKCoordinateSpan(latitudeDelta: Constants.CLOSE_ZOOM_LAT, longitudeDelta: Constants.CLOSE_ZOOM_LON)
    let broadZoom = MKCoordinateSpan(latitudeDelta: Constants.BROAD_ZOOM_LAT, longitudeDelta: Constants.BROAD_ZOOM_LON)

    var position: MapCameraPosition
    var selection: MapSelection<MKMapItem>? = nil
    var markerSelection: MKMapItem? = nil
    
    let store: DiscoveredPolygonsStore
    let transportDetection: TransportDetector
    
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
    
    // New: Dex sheet presentation flag
    var isDexPresented: Bool = false
    
    var cityExploration: Int = 0
    var greenScore: Int = 0
    
    var isZoomedOut = false
    var showSaved = true
    
    let poiService: POIProgressServicing
    let region: MKCoordinateRegion
    let categories: Set<MKPointOfInterestCategory>
    
    var savedItems: [MKMapItem] = []
    
    // MARK: - Live Location Tracking
    private var currentLocation: CLLocationCoordinate2D?
    var nearbyPlace: MKMapItem? = nil
    var isTrackingLocation = false

    init(store: DiscoveredPolygonsStore, poiService: POIProgressServicing = POIProgressService.shared, transportDetection: TransportDetector = TransportDetector.shared) {
        self.store = store
        self.transportDetection = transportDetection
        
        self.region = MKCoordinateRegion(center: munichCenter, span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08))
        self.categories = MKPointOfInterestCategory.trackedCategories
        self.poiService = poiService
        self.position = .region(region)
                
        Task { @MainActor in
            cityExploration = Int(store.percentageDiscovered() * 100)
            greenScore = Int(transportDetection.getSustainabilityScore() * 100)
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
        
        cityExploration = Int(store.percentageDiscovered() * 100)
        greenScore = Int(transportDetection.getSustainabilityScore() * 100)
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
    }
    
    func handleSelection(_ selection: MapSelection<MKMapItem>?) {
        guard let selection else {
            clearSelection()
            return
        }
        
        // Wenn ein MapFeature vorhanden ist, wurde ein POI geklickt
        if let feature = selection.feature {
            handleFeatureSelection(feature)
        } else if let mapItem = selection.value {
            selectedMapItem = mapItem
            isSheetPresented = true
        }
    }
    
    func clearSelection() {
        selection = nil
        markerSelection = nil
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
    
    func setDiscoveredMock() {
//        store.add(cells: Array(generateMunichH3Tiles()))
//        print(discoveredPolygons.count)
    }
    
    // MARK: - Live Location Tracking
    
    func startLocationTracking() {
        isTrackingLocation = true
        Task {
            await trackLocationUpdates()
        }
    }
    
    func stopLocationTracking() {
        isTrackingLocation = false
        nearbyPlace = nil
    }
    
    private func trackLocationUpdates() async {
        // Initiale Suche
        await refreshNearbyPlace()
        
        // Kontinuierliche Updates - reduziert auf 30 Sekunden um Rate Limits zu vermeiden
        while isTrackingLocation && !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 Sekunden
            greenScore = Int(transportDetection.getSustainabilityScore() * 100)
            await refreshNearbyPlace()
        }
    }
    
    func refreshNearbyPlace() async {
        // Hole aktuelle Location vom BackgroundLocationManager
        guard let location = BackgroundLocationManager.shared.manager.location?.coordinate else {
            currentLocation = nil
            return
        }
        
        // Prüfe ob sich die Position signifikant geändert hat (>30m)
        if let lastLocation = currentLocation {
            let distance = CLLocation(latitude: lastLocation.latitude, longitude: lastLocation.longitude)
                .distance(from: CLLocation(latitude: location.latitude, longitude: location.longitude))
            
            // Keine Update wenn Bewegung < 30m
            if distance < 30 {
                return
            }
        }
        
        currentLocation = location
                
        // Suche nahegelegene POIs (50m Radius)
        if let place = await poiService.suggestNearbyPlace(
            coordinate: location,
            categories: categories,
            maxDistance: 50
        ) {            
            // Prüfe ob es ein neuer Ort ist
            let isSamePlace = nearbyPlace?.name == place.name
            
            // Hole Status vom Context (muss auf MainActor sein)
            await MainActor.run {
                // Zeige nur an, wenn noch nicht besucht oder auf Wishlist
                // Status wird später in der View gecheckt
                if !isSamePlace {
                    nearbyPlace = place
                }
            }
        } else {
            // Kein Ort gefunden
            await MainActor.run {
                nearbyPlace = nil
            }
        }
    }
    
    func dismissNearbyPlace() {
        nearbyPlace = nil
    }
    
    func generateMunichH3Tiles() -> Set<H3Cell> {
        let center = CLLocationCoordinate2D(latitude: 48.137154, longitude: 11.576124)

        // 10 × 10 Tiles = 100 Zellen
        let rows = 30
        let cols = 30

        // In Grad (~6 km × 6 km)
        let totalLatDelta = 0.9
        let totalLonDelta = 0.12

        let tileLat = totalLatDelta / Double(rows)
        let tileLon = totalLonDelta / Double(cols)

        var result: Set<H3Cell> = []

        for r in 0..<rows {
            for c in 0..<cols {

                // Offset vom Zentrum
                let latOffset = (Double(r) - Double(rows)/2 + 0.5) * tileLat
                let lonOffset = (Double(c) - Double(cols)/2 + 0.5) * tileLon

                // Zentrum des Tiles
                let tileCenter = CLLocationCoordinate2D(
                    latitude: center.latitude + latOffset,
                    longitude: center.longitude + lonOffset
                )

                // H3 Cell berechnen
                if let cells = adjacentH3FromPos(lat: tileCenter.latitude, lng: tileCenter.longitude) {
                    result.formUnion(cells)
                }
            }
        }

        return result
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

