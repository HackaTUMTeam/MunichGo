//
//  h3Helper.swift
//  MunichGo
//
//  Created by Dominik on 22.11.25.
//

import Foundation
import SwiftyH3
import MapKit

func h3FromPos(lat: Double, lng: Double, res: H3Cell.Resolution = H3Cell.Resolution.res9) -> H3Cell?{
    
    do{
        let coordinate = H3LatLng(latitudeDegs: lat, longitudeDegs: lng)
        let cell = try coordinate.cell(at: res)
        return cell
    }catch{
        
    }
    
    return nil
}

func polygonPromCell(from cell: H3Cell) -> MKPolygon {

    guard let boundaryVertices = try? cell.boundary else {
        return MKPolygon()
    }
    
    var coordinates = boundaryVertices.map { point in
        CLLocationCoordinate2D(latitude: point.latitudeDegs, longitude: point.longitudeDegs)
    }

    return MKPolygon(coordinates: &coordinates, count: coordinates.count)
}

func getPolygnos(cells: Set<H3Cell>) -> Set<MKPolygon>{
    
    var polygons: Set<MKPolygon> = []
    
    for cell in cells{
        let polygon = polygonPromCell(from: cell)
        polygons.insert(polygon)
    }
    
    return polygons
}


func runH3SanityCheck() {
    print("\n========================================")
    print("🧪 STARTING H3 SANITY CHECK")
    print("========================================")
    
    // 1. Setup a test location (New York City)
    let lat = 40.7831
    let lng = -73.9712

    if let cell = h3FromPos(lat: lat, lng: lng) {
        // Code here only runs if result is NOT nil
        print("Cell: \(cell.id)")
    } else {
        // Code here runs if result WAS nil
        print("Invalid cell.")
    }
}
