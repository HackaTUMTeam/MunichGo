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


func adjacentH3FromPos(lat: Double, lng: Double, res: H3Cell.Resolution = H3Cell.Resolution.res11) -> Set<H3Cell>?{
    
    do{
        let coordinate = H3LatLng(latitudeDegs: lat, longitudeDegs: lng)
        let cell = try coordinate.cell(at: res)
        var adjacent = try cell.gridDisk(distance: 1)
        adjacent.append(cell)
        var adjacent_set = Set(adjacent)
        return adjacent_set
    }catch{

    }

    return nil
}

