//
//  StorageManager.swift
//  HackaTUM_25_App
//
//  Created by Felix Haag on 21.11.25.
//

import Foundation

class StorageService {
    static let shared = StorageService()
    
    private let userDefaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - Generic Methods
    
    func save<T: Encodable>(_ value: T, key: String) {
        guard let data = try? encoder.encode(value) else {
            print("Failed to encode \(key)")
            return
        }
        userDefaults.set(data, forKey: key)
    }
    
    func get<T: Decodable>(key: String, as type: T.Type) -> T? {
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }
        return try? decoder.decode(T.self, from: data)
    }
    
    func remove(key: String) {
        userDefaults.removeObject(forKey: key)
    }
    
    func clear() {
        if let bundleID = Bundle.main.bundleIdentifier {
            userDefaults.removePersistentDomain(forName: bundleID)
        }
    }
    
    // MARK: - String Values
    
    func saveString(_ value: String, key: String) {
        userDefaults.set(value, forKey: key)
    }
    
    func getString(key: String) -> String? {
        return userDefaults.string(forKey: key)
    }
    
    // MARK: - Bool Values
    
    func saveBool(_ value: Bool, key: String) {
        userDefaults.set(value, forKey: key)
    }
    
    func getBool(key: String) -> Bool {
        return userDefaults.bool(forKey: key)
    }
    
    // MARK: - Int Values
    
    func saveInt(_ value: Int, key: String) {
        userDefaults.set(value, forKey: key)
    }
    
    func getInt(key: String) -> Int {
        return userDefaults.integer(forKey: key)
    }
    
    // MARK: - Double Values
    
    func saveDouble(_ value: Double, key: String) {
        userDefaults.set(value, forKey: key)
    }
    
    func getDouble(key: String) -> Double {
        return userDefaults.double(forKey: key)
    }
}
