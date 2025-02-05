import Foundation

// MARK: - Authentication Models
struct User: Codable {
    let id: String
    let email: String
    let emailConfirmedAt: String?
    let lastSignInAt: String?
    let role: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case emailConfirmedAt = "email_confirmed_at"
        case lastSignInAt = "last_sign_in_at"
        case role
    }
}

struct Session: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let expiresAt: Int
    let refreshToken: String
    let user: User
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case expiresAt = "expires_at"
        case refreshToken = "refresh_token"
        case user
    }
}

// This matches the exact structure of the Supabase response
struct AuthResponse: Codable {
    let user: User
    let session: Session
}

struct AuthRequest: Codable {
    let email: String
    let password: String
}

// MARK: - Mind Map Models
struct MindMapNode: Codable, Identifiable {
    let id: String
    let content: String
    var position: Position
    let parentNodeId: String?
    let nodeType: String
    
    struct Position: Codable {
        let x: Float
        let y: Float
        let z: Float
    }
}

struct MindMap: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let createdAt: Date
    var nodes: [MindMapNode]
}

struct CreateMindMapRequest: Codable {
    let name: String
    let description: String
    let nodes: [MindMapNode]
}

struct MindMapResponse: Codable {
    let mindmap: MindMap
}

struct MindMapsResponse: Codable {
    let mindmaps: [MindMap]
} 