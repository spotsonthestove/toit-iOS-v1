import Foundation

// MARK: - Authentication Models
struct User: Codable {
    let id: String
    let email: String
    let createdAt: Date
}

struct Session: Codable {
    let token: String
    let expiresAt: Date
}

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