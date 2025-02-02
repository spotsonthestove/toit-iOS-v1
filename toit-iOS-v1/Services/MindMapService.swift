import Foundation

protocol MindMapServiceProtocol {
    func fetchMindMaps(token: String) async throws -> [MindMap]
    func createMindMap(token: String, request: CreateMindMapRequest) async throws -> MindMap
}

final class MindMapService: MindMapServiceProtocol {
    private let apiClient: APIClientProtocol
    
    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }
    
    func fetchMindMaps(token: String) async throws -> [MindMap] {
        let response: MindMapsResponse = try await apiClient.get(
            endpoint: "/api/data",
            token: token
        )
        return response.mindmaps
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