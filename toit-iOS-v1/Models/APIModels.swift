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
    let id: Int
    let content: String
    let x: Float
    let y: Float
    let z: Float
    let parentNodeId: Int?
    let nodeType: String
    
    enum CodingKeys: String, CodingKey {
        case id = "node_id"
        case content
        case x, y, z
        case parentNodeId = "parent_node_id"
        case nodeType = "node_type"
    }
}

struct MindMap: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String
    let createdAt: Date
    let nodes: [MindMapNode]
    
    enum CodingKeys: String, CodingKey {
        case id = "mindmap_id"
        case name
        case description
        case createdAt = "created_at"
        case nodes = "mindmap_nodes"
    }
}

struct CreateMindMapRequest: Codable {
    let name: String
    let description: String
    let nodes: [MindMapNode]
}

struct MindMapResponse: Codable {
    let mindmap: MindMap
    
    enum CodingKeys: String, CodingKey {
        case mindmap = "mindMap"
    }
}

struct MindMapsResponse: Codable {
    let mindmaps: [MindMap]
    
    enum CodingKeys: String, CodingKey {
        case mindmaps = "mindMaps"
    }
} 