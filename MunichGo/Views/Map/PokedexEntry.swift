//
//  PokedexEntry.swift
//  MunichGo
//
//  Created by Assistant on 22.11.25.
//

import Foundation
import SwiftData

@Model
final class PokedexEntry {
    @Attribute(.unique) var districtId: String
    var displayName: String?
    var latitude: Double?
    var longitude: Double?
    var symbolName: String?
    
    // Make optional to allow migration; treat nil as false in code/UI
    var discovered: Bool
    
    var firstSeen: Date
    var lastSeen: Date
    var discoveredCellCount: Int
    var visitCount: Int
    
    init(districtId: String,
         displayName: String? = nil,
         latitude: Double? = nil,
         longitude: Double? = nil,
         symbolName: String? = nil,
         discovered: Bool = false,
         firstSeen: Date = .now,
         lastSeen: Date = .now,
         discoveredCellCount: Int = 0,
         visitCount: Int = 0) {
        self.districtId = districtId
        self.displayName = displayName
        self.latitude = latitude
        self.longitude = longitude
        self.symbolName = symbolName
        self.discovered = discovered
        self.firstSeen = firstSeen
        self.lastSeen = lastSeen
        self.discoveredCellCount = discoveredCellCount
        self.visitCount = visitCount
    }
}

