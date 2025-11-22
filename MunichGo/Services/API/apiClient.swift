//
//  apiClient.swift
//  MunichGo
//
//  Created by Dominik on 22.11.25.
//

import Foundation
import SwiftyH3

let BasePath: String = Endpoints.host

struct EmptyResponse: Decodable {}

struct StatusResponse: Decodable {
    let status: String
    let message: String
}

struct EventCollectionResponse: Decodable {
    let events: [Event]
}

enum APIError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case serverError(statusCode: Int)
    case decodingFailed(Error)
}

enum APIMethod: String {
    case POST="POST"
    case GET="GET"
    case PUT="PUT"
    case DELETE="DELETE"
}

class APIClient {
    
    static let shared = APIClient()
    
    private init() {}
    
    func request<T: Decodable>(endpoint: String, method: APIMethod=APIMethod.GET, body: Data? = nil, decoder:JSONDecoder=JSONDecoder()) async throws -> T {
        // build url throws error if it is an invalid URL
        guard let url = URL(string: BasePath + endpoint) else {
            throw APIError.invalidURL
        }
        
        // build request
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // checks the statuscode, throws error if it is not 200-299
        guard (200...299).contains(httpResponse.statusCode) else {
            print("Server Error: \(httpResponse.statusCode)")
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }
        
        print(String(data:data, encoding: .utf8))
        
        // Handle empty response for 204 No Content
        if httpResponse.statusCode == 204 || data.isEmpty {
            if T.self == EmptyResponse.self {
                return EmptyResponse() as! T
            }
        }
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            print("Decoding Error: \(error)")
            throw APIError.decodingFailed(error)
        }
    }
    
    func checkHealth() async -> StatusResponse? {
        
        let method = APIMethod.GET
        do{
            let data:StatusResponse = try await request(endpoint: "/", method: method)
            return data
        } catch {
            print("Health check failed: \(error)")
        }
        return nil;
    }
    
    func getEvents() async -> [Event]{
        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = Constants.DATE_FORMAT

        decoder.dateDecodingStrategy = .formatted(formatter)
        do{
            let events:[Event] = try await request(endpoint:Endpoints.EVENT, decoder:decoder)
        


            return events
        } catch {
            print("Fetching events failed: \(error)")
        }
        return [];
    }
    
    func addCell(cell: H3Cell) async {
        
        let endpoint = "addCell"
        let bodyDict = ["id" : cell.id]
        let body: Data? = try? JSONSerialization.data(withJSONObject: bodyDict)
        
        do {
            let _: EmptyResponse = try await APIClient.shared.request(
                endpoint: endpoint,
                method: APIMethod.POST,
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
