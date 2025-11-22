//
//  location.swift
//  MunichGo
//
//  Created by Dominik on 22.11.25.
//

import CoreLocation
import Observation
import SwiftyH3

@Observable
final class BackgroundLocationManager: NSObject, CLLocationManagerDelegate {

    static let shared = BackgroundLocationManager()
    private let manager = CLLocationManager()

    private var store: DiscoveredPolygonsStore?

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 20
        manager.pausesLocationUpdatesAutomatically = false
    }

    /// Einmal beim App-Start/Login aufrufen
    func configure(store: DiscoveredPolygonsStore) {
        self.store = store
    }

    func startTracking() {
        manager.requestAlwaysAuthorization()
        // Start erst nach Auth-Callback (sauber)
    }

    private func startLocationPipelines() {
        manager.allowsBackgroundLocationUpdates = true
        manager.startUpdatingLocation()

        // Fallback für lange Background-Laufzeiten
        manager.startMonitoringSignificantLocationChanges()
        manager.startMonitoringVisits()
    }

    func stopTracking() {
        manager.stopUpdatingLocation()
        manager.stopMonitoringSignificantLocationChanges()
        manager.stopMonitoringVisits()
    }

    // MARK: - Delegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways:
            startLocationPipelines()
        case .authorizedWhenInUse:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            stopTracking()
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        insertCell(for: loc)
    }

    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        guard visit.departureDate != .distantFuture else { return }
        let loc = CLLocation(latitude: visit.coordinate.latitude,
                             longitude: visit.coordinate.longitude)
        insertCell(for: loc)
    }

    private func insertCell(for loc: CLLocation) {
//        guard let store else { return }   // falls configure vergessen wurde
//        guard let cell = h3FromPos(lat: loc.coordinate.latitude,
//                                    lng: loc.coordinate.longitude)
//        else { return }
//
//        // Direkt aufrufen, kein MainActor nötig
//        store.add(cell: cell)
        if checkIfInMunich(for: loc) {
            insertCells(for: loc)
            print("In Munich")
        } else {
            print("Not in Munich")
        }
    }
    
    private func checkIfInMunich(for loc: CLLocation) -> Bool {
        return loc.coordinate.latitude < Constants.MUNICH_LAT + 15 && loc.coordinate.latitude > Constants.MUNICH_LAT - 15 && loc.coordinate.longitude < Constants.MUNICH_LON + 15 && loc.coordinate.longitude > Constants.MUNICH_LON - 15
    }
    
    private func insertCells(for loc: CLLocation) {
        guard let store else { return }   // falls configure vergessen wurde
        guard let cells = adjacentH3FromPos(lat: loc.coordinate.latitude,
                                    lng: loc.coordinate.longitude)
        else { return }

        // Direkt aufrufen, kein MainActor nötig
        store.add(cells: Array(cells))
    }
}

