//
//  DiscoveredPolygonStore.swift
//  MunichGo
//
//  Created by Felix Haag on 22.11.25.
//

import Foundation
import SwiftData
import SwiftyH3
import Observation
import SwiftUI

@Observable
final class DiscoveredPolygonsStore {

    // MARK: - SwiftData
    private let context: ModelContext

    // MARK: - Public state
    /// Alle besuchten Zellen (Single Source of Truth)
    private(set) var cells: Set<H3Cell> = []

    /// Snapshot für Diff-Animation (MapViewModel vergleicht neu ↔ alt)
    var lastCellsSnapshot: Set<H3Cell> = []

    // MARK: - Init
    init(context: ModelContext, eraseOnStartup: Bool = true) {
        print("🔧 DiscoveredPolygonsStore init started")
        self.context = context
        
        // TODO: remove for production - erases all data on startup for testing
        if eraseOnStartup {
            eraseAllData()
        }
        
        // Synchron laden, aber mit Timeout-Schutz
        loadFromDB()
        lastCellsSnapshot = cells
        
        print("✅ Store initialized with \(cells.count) cells")
    }

    // MARK: - Insert (Single Cell)
    func add(cell: H3Cell) {
        guard cells.insert(cell).inserted else { return }

        // Persistieren
        let entity = DiscoveredPolygon(id: cell.description)
        context.insert(entity)

        do { 
            try context.save()
            print("✅ Saved cell: \(cell.description)")
        } catch { 
            print("❌ SwiftData save error:", error) 
        }
    }


    // MARK: - Insert (Multiple)
    func add(cells newCells: [H3Cell]) {
        var changed = false

        for cell in newCells {
            if cells.insert(cell).inserted {
                changed = true
                context.insert(DiscoveredPolygon(id: cell.description))
            }
        }

        guard changed else { return }

        do { 
            try context.save()
            print("✅ Saved \(newCells.count) cells")
        } catch { 
            print("❌ SwiftData save error:", error) 
        }
    }


    // MARK: - Load from SwiftData
    private func loadFromDB() {
        let descriptor = FetchDescriptor<DiscoveredPolygon>()
                
        do {
            let entities = try context.fetch(descriptor)
            print("✅ Loaded \(entities.count) polygons from DB")
            
            let loadedCells = entities.compactMap { entity -> H3Cell? in
                guard let cell = H3Cell(entity.id) else {
                    print("⚠️ Invalid H3 cell ID: \(entity.id)")
                    return nil
                }
                return cell
            }
            
            cells = Set(loadedCells)
            print("✅ Successfully converted \(cells.count) cells")
        } catch {
            print("❌ SwiftData fetch error:", error)
            cells = []
        }
    }
    
    // MARK: - Erase Data (for testing)
    private func eraseAllData() {
        print("🗑️ Erasing all discovered polygons...")
        
        // 1. Alle Entities aus der DB löschen
        let descriptor = FetchDescriptor<DiscoveredPolygon>()
        
        do {
            let entities = try context.fetch(descriptor)
            print("📋 Found \(entities.count) entities to delete")
            
            for entity in entities {
                context.delete(entity)
            }
            
            try context.save()
            print("✅ Successfully deleted all \(entities.count) entities from DB")
        } catch {
            print("❌ Error erasing data:", error)
        }
        
        // 2. In-Memory Set leeren
        cells.removeAll()
        lastCellsSnapshot.removeAll()
        
        print("✅ Store erased - starting fresh")
    }
    
    func percentageDiscovered() -> Double {

        let totalAvailable = Double(PolygonsMunich.count * 7 * 7 * 7 * 7)

        let userDiscovered = Double(cells.count)
        
        if totalAvailable == 0 {
            return 0.0
        }
        
        let percentage = userDiscovered / totalAvailable
        
        return min(percentage, 1.0)
    }
}

private struct DiscoveredPolygonsStoreKey: EnvironmentKey {
    static let defaultValue: DiscoveredPolygonsStore? = nil
}

extension EnvironmentValues {
    var discoveredPolygonStore: DiscoveredPolygonsStore? {
        get { self[DiscoveredPolygonsStoreKey.self] }
        set { self[DiscoveredPolygonsStoreKey.self] = newValue }
    }
}
