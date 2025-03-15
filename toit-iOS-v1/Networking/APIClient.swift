import Foundation

/// Represents possible API errors
enum APIError: Error {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case unauthorized
    case serverError(String)
    case decodingError(Error)
    case httpError(Int)
}

/// Base API configuration
struct APIConfig {
    static let baseURL = "https://toitdoit.com"
    static let defaultHeaders = [
        "Content-Type": "application/json",
        "Accept": "application/json"
    ]
}

/// Protocol defining the basic API client capabilities
protocol APIClientProtocol {
    func get<T: Decodable>(endpoint: String, token: String?) async throws -> T
    func post<T: Decodable, U: Encodable>(endpoint: String, body: U, token: String?) async throws -> T
}

/// Main API client implementation
final class APIClient: APIClientProtocol {
    static let shared = APIClient()
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func get<T: Decodable>(endpoint: String, token: String? = nil) async throws -> T {
        let request = try createRequest(
            endpoint: endpoint,
            method: "GET",
            token: token
        )
        
        return try await performRequest(request)
    }
    
    func post<T: Decodable, U: Encodable>(
        endpoint: String,
        body: U,
        token: String? = nil
    ) async throws -> T {
        var request = try createRequest(
            endpoint: endpoint,
            method: "POST",
            token: token
        )
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(body)
        
        return try await performRequest(request)
    }
    
    // MARK: - Private Methods
    
    private func createRequest(
        endpoint: String,
        method: String,
        token: String?
    ) throws -> URLRequest {
        guard let url = URL(string: "\(APIConfig.baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        // Add default headers
        APIConfig.defaultHeaders.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add authorization if token exists
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
    
    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        
        // Debug print to see raw response
        if let jsonString = String(data: data, encoding: .utf8) {
            print("API Response:", jsonString)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // Check if status code is in the successful range (200-299)
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        // decoder.keyDecodingStrategy = .convertFromSnakeCase // Remove this if using custom CodingKeys
        
        do {
            // Try to decode directly first
            return try decoder.decode(T.self, from: data)
        } catch {
            print("Decoding error:", error)
            // If direct decoding fails, you might want to examine the raw response
            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                print("Raw JSON structure:", json)
            }
            throw error
        }
    }
} 