import Foundation
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: String?
    @Published var user: User?
    
    private let authService: AuthServiceProtocol
    
    init(authService: AuthServiceProtocol = AuthService()) {
        self.authService = authService
    }
    
    func signIn(email: String, password: String) {
        isLoading = true
        error = nil
        
        Task {
            do {
                let response = try await authService.signIn(email: email, password: password)
                self.user = response.user
                self.isAuthenticated = true
                // In a real app, you'd want to store the token securely
                print("✅ Authentication successful")
                print("Token: \(response.session.accessToken)")
            } catch {
                self.error = error.localizedDescription
                print("❌ Authentication failed: \(error)")
            }
            self.isLoading = false
        }
    }
    
    func signOut() {
        isAuthenticated = false
        user = nil
        error = nil
    }
} 