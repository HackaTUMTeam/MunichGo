//
//  location.swift
//  MunichGo
//
//  Created by Dominik on 22.11.25.
//

import CoreLocation

class BackgroundLocationManager: NSObject, CLLocationManagerDelegate {
    
    static let shared = BackgroundLocationManager()
    private let manager = CLLocationManager()
    
    override init() {
        super.init()
        manager.delegate = self
        
        // 1. Configure Accuracy (Lower accuracy = Less Battery Drain)
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 20 // Only update if moved 50 meters
        
    }
    
    func startTracking() {
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
        // 4. Request "Always" permission
        manager.requestAlwaysAuthorization()
        manager.startUpdatingLocation()
    }
    
    func stopTracking() {
        manager.stopUpdatingLocation()
    }
    
    // MARK: - Delegate Methods
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // This code runs even if the app is in the background/locked!
        print("Background Location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        updateCells(lat: location.coordinate.latitude, lng: location.coordinate.longitude)
        
        print("\(Cells.count) Cells visited")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways:
            print("✅ Permission: Always - Background updates will work silently.")
        case .authorizedWhenInUse:
            print("⚠️ Permission: When In Use - Background updates only work if Blue Bar is active.")
        case .denied, .restricted:
            print("❌ Permission: Denied - No updates.")
        case .notDetermined:
            print("❓ Permission: Not Determined yet.")
        @unknown default:
            break
        }
    }
}

