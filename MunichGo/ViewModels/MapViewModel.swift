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

    var position: MapCameraPosition
    var selection: MapSelection<MKMapItem>? = nil
    
    var selectedMapItem: MKMapItem? = nil
    var isSheetPresented: Bool = false
    var sheetDetent: PresentationDetent = .height(180)

    init() {
        self.position = .region(
            MKCoordinateRegion(
                center: munichCenter,
                span: MKCoordinateSpan(latitudeDelta: Constants.ZOOM_LAT, longitudeDelta: Constants.ZOOM_LON)
            )
        )
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
