//
//  DistrictDetection.swift
//  MunichGo
//
//  Created by Dominik on 22.11.25.
//

import Foundation
import SwiftyH3


@Observable
class DistrictDetector {
    var location_count: [String: UInt] = [:]
    
    
    // MARK: - Singleton Instance
    static let shared = DistrictDetector()
    
    // Private init prevents creating a second instance
    private init() {}
    
    func addCell(cell: H3Cell) {
        // H3Cell.center is throwing; handle safely
        guard let center = try? cell.center.coordinates else {
            // If center can't be computed, skip
            return
        }
        
        // Look up district for this coordinate
        if let district = DistrictManager.getDistrictID(for: center) {
            // Increment count for district
            location_count[district, default: 0] += 1
        }
    }
    
    func fromCells(cells: Set<H3Cell>){
        for cell in cells {
            addCell(cell: cell)
        }
    }
    
    func fromStorage(store: DiscoveredPolygonsStore){
        let cells = store.cells
        fromCells(cells: cells)
    }
    
    
}
