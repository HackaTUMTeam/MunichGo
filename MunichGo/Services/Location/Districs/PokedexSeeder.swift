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
        ("frauenkirche", "Frauenkirche", "https://www.h-hotels.com/_Resources/Persistent/3/c/1/9/3c19500be1321a31379114f91961aa1978aaf3f9/muenchen-frauenkirche-04-1433x1433-390x390.webp", 48.1387, 11.5736, true),
        ("marienplatz", "Marienplatz", "https://mnd-assets.mynewsdesk.com/image/upload/c_fill,dpr_auto,f_auto,g_xy_center,q_auto:good,w_746,x_4128,y_2792/naxvaayd18gkx6nfbqag51", 48.1371, 11.5754,true),
        ("englischer_garten", "Englischer Garten", "https://www.passengeronearth.com/wp-content/uploads/2020/07/Englischer-Garten-Munchen.jpg", 48.1640, 11.6050,true),
        ("deutsches_museum", "Deutsches Museum", "https://www1.wdr.de/radio/wdr3/kulturnachrichten/deutsches-museum-muenchen-100~_v-square-m.jpg", 48.1303, 11.5838,true),
        ("allianz_arena", "Allianz Arena", "https://2wjyoqczplq2loncx0jfrnk1q5w-thumbnail.storage.muc1.de.bnerd.com/thumbnail/Instagram/Location/Allianz%20Arena/7706/image-thumb__7706__responsive-image/day-3-AA.d93e7f95.webp", 48.2188, 11.6247,false),
        ("nymphenburg_palace", "Nymphenburg Palace", "https://s3.travel-cdn.net/pictures/345697/feed_newsletter_square.jpg?rev=1", 48.1581, 11.5037,true),
        ("viktualienmarkt", "Viktualienmarkt", "https://www.mux.de/images/1500x1200z/object/39/1525426239/viktualienmarkt-muenchen.jpg", 48.1352, 11.5768,false),
        ("olympiapark", "Olympiapark", "https://www.muenchenarchitektur.com/images/20803/public%20release.jpg", 48.1740, 11.5540,false),
        ("atom_ei", "Atom-Ei", "https://upload.wikimedia.org/wikipedia/commons/thumb/9/9d/Atomei_-_Forschungsreaktor_M%C3%BCnchen_I_%28FRM_I%29.JPG/1280px-Atomei_-_Forschungsreaktor_M%C3%BCnchen_I_%28FRM_I%29.JPG", 48.2650, 11.6760, true),

        ("ludwigskirche", "Ludwigskirche", "https://tipps-muenchen.de/wp-content/uploads/2025/10/Ludwigskirche-2-1536x864.jpg", 48.1486, 11.5801, false),

        ("muenchner_freiheit", "Münchner Freiheit", "https://geheimtippmuenchen.de/content/uploads/2022/03/geheimtipp-muenchen-place2be-place-to-be-muenchner-freiheit-5.jpg", 48.1620, 11.5863, false),

        ("sendlinger_tor", "Sendlinger Tor", "https://airial.travel/_next/image?url=https%3A%2F%2Fupload.wikimedia.org%2Fwikipedia%2Fcommons%2Fe%2Fee%2FSendlinger_Tor_Muenchen_2004.jpg&w=3840&q=70", 48.1339, 11.5674, false),
    ]
    
    static func seedIfNeeded(modelContext: ModelContext) {
        // If we have any entries already, skip seeding
        //let existing = (try? modelContext.fetch(FetchDescriptor<PokedexEntry>(predicate: nil))) ?? []
        //guard existing.isEmpty else {
        //    return
        //}
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

