//
//  Place.swift
//  MunichGo
//
//  Created by Felix Haag on 22.11.25.
//

import SwiftData
import CoreLocation
import MapKit

func placeKey(for item: MKMapItem) -> String {
    // Name als stabiler Bestandteil
    let name = (item.name ?? "unknown")
        .lowercased()
        .trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Koordinaten ab iOS 26 nur noch über .location
    let coord = item.location.coordinate
    
    // leichte Rundung um Floating-Point Noise zu vermeiden
    let lat = (coord.latitude * 10_000).rounded() / 10_000
    let lon = (coord.longitude * 10_000).rounded() / 10_000
    
    // sicherer, stabiler Hash-Key
    return "\(name)|\(lat)|\(lon)"
}

enum PlaceListType: String, Codable {
    case visited
    case wishlist
}

@Model
final class Place {
    @Attribute(.unique) var key: String   // unser eigener stabiler Key
    var name: String
    var latitude: Double
    var longitude: Double
    var categoryRaw: String
    var listTypeRaw: String
    
    var listType: PlaceListType {
        get { PlaceListType(rawValue: listTypeRaw) ?? .visited }
        set { listTypeRaw = newValue.rawValue }
    }

    init(key: String, name: String, latitude: Double, longitude: Double, categoryRaw: String, listType: PlaceListType) {
        self.key = key
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.categoryRaw = categoryRaw
        self.listTypeRaw = listType.rawValue
    }
}
