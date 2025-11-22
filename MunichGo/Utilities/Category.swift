//
//  Category.swift
//  MunichGo
//
//  Created by Felix Haag on 22.11.25.
//

import Foundation
import MapKit
import SwiftUI

extension MKPointOfInterestCategory {
    var categoryName: String {
        switch self {
        case .restaurant: return "Restaurant"
        case .cafe: return "Café"
        case .park: return "Park"
        case .museum: return "Museum"
        case .theater: return "Theater"
        case .library: return "Bibliothek"
        case .nightlife: return "Nachtleben"
        case .stadium: return "Stadium"
        case .landmark: return "Sehenswürdigkeit"
        case .zoo: return "Zoo"
        case .aquarium: return "Aquarium"
        case .amusementPark: return "Freizeitpark"
        case .university: return "Universität"
        case .foodMarket: return "Markt"
        default: return "Ort"
        }
    }

    var categoryIcon: String {
        switch self {
        case .restaurant: return "fork.knife"
        case .cafe: return "cup.and.saucer.fill"
        case .park: return "tree.fill"
        case .museum: return "building.columns.fill"
        case .theater: return "theatermasks.fill"
        case .library: return "books.vertical.fill"
        case .nightlife: return "music.note"
        case .stadium: return "sportscourt.fill"
        case .landmark: return "building.2.fill"
        case .zoo: return "pawprint.fill"
        case .aquarium: return "fish.fill"
        case .amusementPark: return "ferriswheel"
        case .university: return "graduationcap.fill"
        case .foodMarket: return "basket.fill"
        default: return "mappin.circle.fill"
        }
    }

    var categoryColor: Color {
        switch self {
        case .restaurant, .cafe, .foodMarket: return .orange
        case .park: return .green
        case .museum, .theater, .library: return .purple
        case .nightlife: return .pink
        case .stadium, .amusementPark: return .red
        case .landmark: return .blue
        case .zoo, .aquarium: return .teal
        case .university: return .indigo
        default: return .gray
        }
    }
    
    static let trackedCategories: Set<MKPointOfInterestCategory> = [
        // Essen & Trinken
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
        
        // Sightseeing / Tourismus
        .landmark,

        // Öffentliche Einrichtungen
        .library,
        .university,
    ]
}

