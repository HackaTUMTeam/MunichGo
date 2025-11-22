//
//  DiscoveredPolygon.swift
//  MunichGo
//
//  Created by Felix Haag on 22.11.25.
//

import Foundation
import SwiftData

@Model
final class DiscoveredPolygon {
    @Attribute(.unique) var id: String   // H3 index string
    var discoveredAt: Date

    init(id: String, discoveredAt: Date = .now) {
        self.id = id
        self.discoveredAt = discoveredAt
    }
}
