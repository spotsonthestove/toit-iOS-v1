import Foundation

// MARK: - Data Models
private struct NodeData: Codable {
    let id: UUID
    let title: String
    let description: String
    let position: Position
    let connections: Set<UUID>
}

private struct Position: Codable {
    let x: Float
    let y: Float
    let z: Float
}

class NodeStorage {
    static let shared = NodeStorage()
    private let queue = DispatchQueue(label: "com.engine3d.nodestorage")
    
    private let defaults = UserDefaults.standard
    private let nodeStorageKey = "engine3d.nodes"
    
    func saveNodes(_ nodes: [Engine3DSceneNode]) {
        queue.async {
            let nodeData = nodes.map { node in
                NodeData(
                    id: node.id,
                    title: node.title,
                    description: node.description ?? "",
                    position: Position(
                        x: node.position.x,
                        y: node.position.y,
                        z: node.position.z
                    ),
                    connections: node.connections
                )
            }
            
            if let encoded = try? JSONEncoder().encode(nodeData) {
                self.defaults.set(encoded, forKey: self.nodeStorageKey)
                print("✅ Saved \(nodes.count) nodes")
            } else {
                print("❌ Failed to encode nodes")
            }
        }
    }
    
    func loadNodes() -> [Engine3DSceneNode] {
        guard let data = defaults.data(forKey: nodeStorageKey),
              let nodeData = try? JSONDecoder().decode([NodeData].self, from: data) else {
            print("⚠️ No saved nodes found")
            return []
        }
        
        let nodes = nodeData.map { data in
            let position = SIMD3<Float>(data.position.x, data.position.y, data.position.z)
            let node = Engine3DSceneNode(id: data.id, title: data.title, position: position)
            node.description = data.description
            node.connections = data.connections
            return node
        }
        
        print("✅ Loaded \(nodes.count) nodes")
        return nodes
    }
} 