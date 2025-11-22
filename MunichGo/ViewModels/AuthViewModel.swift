//
//  AuthViewModel.swift
//  HackaTUM_25_App
//
//  Created by Felix Haag on 21.11.25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = true
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let storageManager = StorageService.shared
    //private let networkManager = ApiService()
    
    init() {
        checkAuthStatus()
    }
    
    func checkAuthStatus() {
        // Check if user is stored locally
        if let userData = storageManager.get(key: "currentUser", as: User.self) {
            currentUser = userData
            isAuthenticated = true
        }
    }
    
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Mock login
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            let user = User(email: email, name: email.components(separatedBy: "@").first ?? "User")
            
            currentUser = user
            isAuthenticated = true
            
            storageManager.save(user, key: "currentUser")
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func register(email: String, password: String, name: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Mock registration
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            let user = User(email: email, name: name)
            
            currentUser = user
            isAuthenticated = true
            
            storageManager.save(user, key: "currentUser")
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func logout() {
        currentUser = nil
        isAuthenticated = false
        storageManager.remove(key: "currentUser")
    }
}

