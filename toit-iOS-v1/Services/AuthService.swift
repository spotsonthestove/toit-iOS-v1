import Foundation

protocol AuthServiceProtocol {
    func signIn(email: String, password: String) async throws -> AuthResponse
}

final class AuthService: AuthServiceProtocol {
    private let apiClient: APIClientProtocol
    
    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }
    
    func signIn(email: String, password: String) async throws -> AuthResponse {
        let request = AuthRequest(email: email, password: password)
        return try await apiClient.post(
            endpoint: "/api/auth",
            body: request,
            token: nil
        )
    }
} 