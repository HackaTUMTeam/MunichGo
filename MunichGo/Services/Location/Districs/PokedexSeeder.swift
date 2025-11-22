//
//  PokedexSeeder.swift
//  MunichGo
//
//  Created by Assistant on 22.11.25.
//

import Foundation
import SwiftData
import MapKit

enum PokedexSeeder {
    // Curated sights with a stable key, a preferred SF Symbol, and static coordinates
    private static let sights: [(key: String, name: String, symbol: String, lat: Double, lon: Double, discovered: Bool)] = [
        ("frauenkirche", "Frauenkirche", "building.columns.fill", 48.1387, 11.5736, true),
        ("marienplatz", "Marienplatz", "mappin.and.ellipse", 48.1371, 11.5754,true),
        ("englischer_garten", "Englischer Garten", "leaf.fill", 48.1640, 11.6050,false),
        ("deutsches_museum", "Deutsches Museum", "gearshape.2.fill", 48.1303, 11.5838,true),
        ("allianz_arena", "Allianz Arena", "soccerball", 48.2188, 11.6247,false),
        ("nymphenburg_palace", "Nymphenburg Palace", "crown.fill", 48.1581, 11.5037,true),
        ("viktualienmarkt", "Viktualienmarkt", "basket.fill", 48.1352, 11.5768,false),
        ("olympiapark", "Olympiapark", "figure.run", 48.1740, 11.5540,false)
    ]
    
    static func seedIfNeeded(modelContext: ModelContext) {
        // If we have any entries already, skip seeding
        //let existing = (try? modelContext.fetch(FetchDescriptor<PokedexEntry>(predicate: nil))) ?? []
        //guard existing.isEmpty else {
        //    return
        //}
        let poiService = POIProgressService.shared
        
        
        
        let sights = poiService.searchPOIs(in: <#T##MKCoordinateRegion#>, category: .landmark)
        
        for sight in sights {
            let entry = PokedexEntry(
                districtId: sight.key,
                displayName: sight.name,
                latitude: sight.lat,
                longitude: sight.lon,
                symbolName: sight.symbol,
                discovered: sight.discovered,
                firstSeen: .now,
                lastSeen: .now,
                discoveredCellCount: 0,
                visitCount: 0
            )
            modelContext.insert(entry)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("❌ Pokedex seeding save error: \(error)")
        }
    }
}

