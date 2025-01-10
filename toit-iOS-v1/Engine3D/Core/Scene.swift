import Foundation
import simd

// Just import the types we need
import Metal  // If needed for any metal types

class Engine3DScene {
    private(set) var nodes: Set<Engine3DSceneNode> = []
    private(set) var branches: [Engine3DBranch] = []
    
    // Scene configuration
    private let nodeSpacing: Float = 0.5
    private let distributionRadius: Float = 0.8
    private let zRange: Float = 0.0
    
    func addNode(_ node: Engine3DSceneNode) {
        nodes.insert(node)
        print("Added node: \(node.id) to scene. Total nodes: \(nodes.count)")
    }
    
    func removeNode(_ node: Engine3DSceneNode) {
        nodes.remove(node)
        // Remove any branches connected to this node
        branches.removeAll { branch in
            return branch.startNode === node || branch.endNode === node
        }
        print("Removed node: \(node.id) from scene. Remaining nodes: \(nodes.count)")
    }
    
    func calculateNewNodePosition() -> SIMD3<Float> {
        let nodeCount = Float(nodes.count)
        
        // First node at center
        if nodes.isEmpty {
            return SIMD3<Float>(0, 0, 0)
        }
        
        // Distribute subsequent nodes in circle
        let angle = (nodeCount - 1) * (2.0 * .pi / 6.0)
        let x = cos(angle) * distributionRadius
        let y = sin(angle) * distributionRadius
        
        let position = SIMD3<Float>(x, y, 0)
        print("Calculated new node position: \(position)")
        return position
    }
    
    func update() {
        nodes.forEach { $0.update() }
    }
    
    func addBranch(_ branch: Engine3DBranch) {
        branches.append(branch)
        print("Added branch to scene. Total branches: \(branches.count)")
    }
} 