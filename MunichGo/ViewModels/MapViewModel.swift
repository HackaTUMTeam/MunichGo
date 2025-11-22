//
//  MapViewModel.swift
//  MunichGo
//
//  Created by Felix Haag on 22.11.25.
//

import Foundation
import SwiftUI
import MapKit

@Observable
final class MapViewModel {
    let munichCenter = CLLocationCoordinate2D(latitude: Constants.MUNICH_LAT, longitude: Constants.MUNICH_LON)
    
    let defaultZoom = MKCoordinateSpan(latitudeDelta: Constants.ZOOM_LAT, longitudeDelta: Constants.ZOOM_LON)
    
    let closeZoom = MKCoordinateSpan(latitudeDelta: Constants.CLOSE_ZOOM_LAT, longitudeDelta: Constants.CLOSE_ZOOM_LON)
    let broadZoom = MKCoordinateSpan(latitudeDelta: Constants.BROAD_ZOOM_LAT, longitudeDelta: Constants.BROAD_ZOOM_LON)

    var position: MapCameraPosition
    var selection: MapSelection<MKMapItem>? = nil
    
    var discoveredPolygons: [MKPolygon] = []
    var worldOverlay: MKPolygon = MKPolygon()
    
    var selectedMapItem: MKMapItem? = nil
    var isSheetPresented: Bool = false
    var sheetDetent: PresentationDetent = .height(180)
    
    var cityExploration: Int = 0
    var greenScore: Int = 0
    
    var isZoomedOut = false

    init() {
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
        
        // Test
        discoveredPolygons.append(polygonPromCell(from: h3FromPos(lat: Constants.MUNICH_LAT, lng: Constants.MUNICH_LON)!))
        
        rebuildOverlay(withHoles: discoveredPolygons)
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
    
    func rebuildOverlay(withHoles holes: [MKPolygon]) {
        // großer Kasten um München (gross genug, dass man nie raus scrollt)
        // du kannst die Zahlen ruhig anpassen/erweitern
        let paddingLat: CLLocationDegrees = 25
        let paddingLon: CLLocationDegrees = 90

        let north = munichCenter.latitude + paddingLat
        let south = munichCenter.latitude - paddingLat * 4
        let east  = munichCenter.longitude + paddingLon
        let west  = munichCenter.longitude - paddingLon

        let coords = [
            CLLocationCoordinate2D(latitude: north, longitude: west),
            CLLocationCoordinate2D(latitude: north, longitude: east),
            CLLocationCoordinate2D(latitude: south, longitude: east),
            CLLocationCoordinate2D(latitude: south, longitude: west),
        ]

        worldOverlay = MKPolygon(
            coordinates: coords,
            count: coords.count,
            interiorPolygons: holes
        )
    }
    
    var region: MKCoordinateRegion {
        get {
            if let r = position.region {
                return r
            }
            // fallback
            return MKCoordinateRegion(
                center: munichCenter,
                span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
            )
        }
        set {
            position = .region(newValue)
        }
    }
    
    let pointsOfInterest: [MKPointOfInterestCategory] = [
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
}
