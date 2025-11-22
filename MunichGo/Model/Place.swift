//
//  Place.swift
//  MunichGo
//
//  Created by Felix Haag on 22.11.25.
//

import Foundation
import MapKit
import SwiftUI

struct Place: Identifiable {
    let id = UUID()
    let title: String
    let category: MKPointOfInterestCategory?
    let coordinate: CLLocationCoordinate2D?
    let image: Image?
    let kind: MapFeature.FeatureKind?
}
