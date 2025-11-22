//
//  DistrictManager.swift
//  MunichGo
//
//  Created by Dominik on 22.11.25.
//


import Foundation
import MapKit

// MARK: - District Manager
class DistrictManager {
    
    // 1. Cache the polygons once on startup
    // Creating MKPolygons is expensive, so we do it only once here.
    private static let cachedPolygons: [(id: String, polygon: MKPolygon)] = {
        return DistrictData.allDistricts.map { district in
            let polygon = MKPolygon(coordinates: district.coordinates, count: district.coordinates.count)
            return (district.id, polygon)
        }
    }()
    
    /// Checks which district contains the given coordinate.
    /// - Parameter coordinate: The user's location
    /// - Returns: The District ID (e.g. "vablock_stadtbezirke_opendata.1") or nil if outside Munich.
    static func getDistrictID(for coordinate: CLLocationCoordinate2D) -> String? {
        let mapPoint = MKMapPoint(coordinate)
        
        for (id, polygon) in cachedPolygons {
            // Optimization 1: Fast Box Check
            // Check if point is roughly in the square area before checking the complex shape
            if polygon.boundingMapRect.contains(mapPoint) {
                
                // Optimization 2: Precise Shape Check
                if polygon.contains(coordinate: coordinate) {
                    return id
                }
            }
        }
        
        return nil // Outside all known districts
    }
}

// MARK: - MKPolygon Extension
// Apple does not provide a built-in "contains" for Coordinates, so we add it here.
extension MKPolygon {
    func contains(coordinate: CLLocationCoordinate2D) -> Bool {
        let polygonRenderer = MKPolygonRenderer(polygon: self)
        let mapPoint = MKMapPoint(coordinate)
        let polygonPoint = polygonRenderer.point(for: mapPoint)
        
        return polygonRenderer.path.contains(polygonPoint, using: .evenOdd, transform: .identity)
    }
}
