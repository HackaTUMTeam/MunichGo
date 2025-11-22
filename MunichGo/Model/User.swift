//
//  User.swift
//  HackaTUM_25_App
//
//  Created by Felix Haag on 21.11.25.
//

import Foundation

struct User: Codable, Identifiable{
    let id: UUID
    let email: String
    let name: String
    let createdAt: Date
    
    init(id: UUID = UUID(), email: String, name: String, createdAt: Date = Date()) {
        self.id = id
        self.email = email
        self.name = name
        self.createdAt = createdAt
    }
}

// Mock user for testing
extension User {
    static let mock = User(
        email: "test@example.com",
        name: "Test User"
    )
}
