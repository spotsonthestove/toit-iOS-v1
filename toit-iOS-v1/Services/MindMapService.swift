import Foundation

protocol MindMapServiceProtocol {
    func fetchMindMaps(token: String) async throws -> [MindMap]
    func createMindMap(token: String, request: CreateMindMapRequest) async throws -> MindMap
}

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case serverError(_ statusCode: Int)
    case decodingError
}

final class MindMapService: MindMapServiceProtocol {
    private let apiClient: APIClientProtocol
    private let baseURL = "https://toit-two.toit.workers.dev"  // Your API base URL
    
    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }
    
    func fetchMindMaps(token: String) async throws -> [MindMap] {
        guard let url = URL(string: "\(baseURL)/api/data") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // Debug prints
        print("Fetching mindmaps with URL: \(url)")
        print("Using token: \(token)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Debug print for raw response
        print("Raw response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode response")")
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        print("Response status code: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            throw NetworkError.serverError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let mindMapsResponse = try decoder.decode(MindMapsResponse.self, from: data)
            return mindMapsResponse.mindmaps
        } catch {
            print("Decoding error: \(error)")
            throw NetworkError.decodingError
        }
    }
    
    func createMindMap(token: String, request: CreateMindMapRequest) async throws -> MindMap {
        let response: MindMapResponse = try await apiClient.post(
            endpoint: "/api/data",
            body: request,
            token: token
        )
        return response.mindmap
    }
} 