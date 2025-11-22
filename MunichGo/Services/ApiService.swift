//
//  APICLient.swift
//  HackaTUM_25_App
//
//  Created by Felix Haag on 21.11.25.
//

import Foundation
import Combine

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int)
    case decodingError
    case noData
    case custom(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let statusCode):
            return "Server error with status code: \(statusCode)"
        case .decodingError:
            return "Failed to decode response"
        case .noData:
            return "No data received"
        case .custom(let message):
            return message
        }
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

// MARK: - API Endpoints
enum APIEndpoint {
    case login(email: String, password: String)
    case register(email: String, password: String, name: String)
    case todos
    case createTodo(title: String, description: String)
    case updateTodo(id: UUID, isCompleted: Bool)
    case deleteTodo(id: UUID)
    
    var path: String {
        switch self {
        case .login:
            return "/auth/login"
        case .register:
            return "/auth/register"
        case .todos:
            return "/todos"
        case .createTodo:
            return "/todos"
        case .updateTodo(let id, _):
            return "/todos/\(id.uuidString)"
        case .deleteTodo(let id):
            return "/todos/\(id.uuidString)"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .login, .register, .createTodo:
            return .post
        case .todos:
            return .get
        case .updateTodo:
            return .patch
        case .deleteTodo:
            return .delete
        }
    }
    
    var body: [String: Any]? {
        switch self {
        case .login(let email, let password):
            return ["email": email, "password": password]
        case .register(let email, let password, let name):
            return ["email": email, "password": password, "name": name]
        case .createTodo(let title, let description):
            return ["title": title, "description": description]
        case .updateTodo(_, let isCompleted):
            return ["isCompleted": isCompleted]
        default:
            return nil
        }
    }
}

@MainActor
class ApiService: ObservableObject {
    // TODO: Replace with your actual backend URL
    private let baseURL = "https://your-api-url.com/api"
    
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func request<T: Decodable>(
        endpoint: APIEndpoint,
        responseType: T.Type
    ) async throws -> T {
        guard let url = URL(string: baseURL + endpoint.path) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication token if available
        if let token = StorageService.shared.get(key: "authToken", as: String.self) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add body if needed
        if let body = endpoint.body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError(statusCode: httpResponse.statusCode)
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError
        }
    }
    
    func requestNoResponse(endpoint: APIEndpoint) async throws {
        guard let url = URL(string: baseURL + endpoint.path) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = StorageService.shared.get(key: "authToken", as: String.self) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = endpoint.body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError(statusCode: httpResponse.statusCode)
        }
    }
}


