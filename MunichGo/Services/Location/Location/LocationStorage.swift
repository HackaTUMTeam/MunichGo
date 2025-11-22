//
//  LocationStorage.swift
//  MunichGo
//
//  Created by Dominik on 22.11.25.
//

import Foundation
import CoreLocation

final class LocationStorage {
    
    // 1. Singleton Instance
    static let shared = LocationStorage()
    
    // 2. The Storage (Array of Tuples)
    // We store (Date, CLLocation) pairs
    private(set) var trace: [CLLocation] = []
    
    private init() {}
    
    // MARK: - Functions
    
    func add(_ location: CLLocation) {
        // Simple append
        trace.append(location)
    }
    
    func getAllPoints() -> [CLLocation] {
        // Return just the locations if needed for analysis
        return trace
    }
    
    func clear() {
        trace.removeAll()
    }
    
    var count: Int {
        return trace.count
    }
}
