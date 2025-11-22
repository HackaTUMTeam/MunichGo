//
//  apiClient.swift
//  MunichGo
//
//  Created by Dominik on 22.11.25.
//

import Foundation
import SwiftyH3

let BasePath: String = "http://localhost:8080/"

struct EmptyResponse: Decodable {}

enum APIError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case serverError(statusCode: Int)
    case decodingFailed(Error)
}

class APIClient {
    
    static let shared = APIClient()
    
    private init() {}
    
    func request<T: Decodable>(endpoint: String, method: String = "GET", body: Data? = nil) async throws -> T {
        
        guard let url = URL(string: BasePath + endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            print("Server Error: \(httpResponse.statusCode)")
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }
        
        // Handle empty response for 204 No Content
        if httpResponse.statusCode == 204 || data.isEmpty {
            if T.self == EmptyResponse.self {
                return EmptyResponse() as! T
            }
        }
        
        do {
            let decoder = JSONDecoder()

            return try decoder.decode(T.self, from: data)
        } catch {
            print("Decoding Error: \(error)")
            throw APIError.decodingFailed(error)
        }
    }
    
    func addCell(cell: H3Cell) async {
        
        let endpoint = "addCell"
        let method = "POST"
        let bodyDict = ["id" : cell.id]
        let body: Data? = try? JSONSerialization.data(withJSONObject: bodyDict)
        
        do {
            let _: EmptyResponse = try await APIClient.shared.request(
                endpoint: endpoint,
                method: method,
                body: body
            )
            print("Upload success")
        } catch {
            print("Upload failed: \(error)")
        }
    }
    
    func getCells() async -> Set<H3Cell>{
        
        let endpoint = "getCells"
        
        do{
            let response: [UInt64] = try await APIClient.shared.request(endpoint: endpoint)
            var cells: Set<H3Cell> = []
            for id in response{
                cells.insert(H3Cell(id))
            }
            return cells
        }catch{
            print("Error in getting cells: \(error)")
            return Set()
        }
    }
    
    
}
