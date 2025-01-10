import Foundation

struct NodeData: Codable {
    let id: UUID
    let title: String
    let description: String
    let position: Position
    let lastModified: Date
    let connections: Set<UUID>
    
    init(from node: TestSceneNode) {
        self.id = node.id
        self.title = node.title
        self.description = node.description ?? ""
        self.position = Position(x: node.position.x, y: node.position.y, z: node.position.z)
        self.lastModified = Date()
        self.connections = node.connections
    }
    
    struct Position: Codable {
        let x: Float
        let y: Float
        let z: Float
    }
}

class NodeStorage {
    static let shared = NodeStorage()
    private let queue = DispatchQueue(label: "com.tryToit.nodeStorage")
    
    func saveNodes(_ nodes: [TestSceneNode]) {
        queue.async {
            let nodeData = nodes.map { NodeData(from: $0) }
            // Save to UserDefaults for now, replace with proper DB later
            if let encoded = try? JSONEncoder().encode(nodeData) {
                UserDefaults.standard.set(encoded, forKey: "mindMapNodes")
            }
        }
    }
    
    func loadNodes() -> [TestSceneNode] {
        guard let data = UserDefaults.standard.data(forKey: "mindMapNodes"),
              let nodeData = try? JSONDecoder().decode([NodeData].self, from: data) else {
            return []
        }
        
        return nodeData.map { data in
            let position = SIMD3<Float>(data.position.x, data.position.y, data.position.z)
            let node = TestSceneNode(id: data.id, title: data.title, position: position)
            node.connections = Set(data.connections)
            return node
        }
    }
}