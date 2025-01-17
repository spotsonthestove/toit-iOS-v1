import Foundation
import simd

// Just import the types we need
import Metal  // If needed for any metal types

class Engine3DScene {
    private(set) var nodes: Set<Engine3DSceneNode> = []
    private(set) var branches: [Engine3DBranch] = []
    
    // Scene configuration - increase distribution radius for better visibility
    private let nodeSpacing: Float = 1.0      // Increased from 0.5
    private let distributionRadius: Float = 3.0  // Increased from 0.8
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
        if nodes.isEmpty {
            return SIMD3<Float>(0, 0, 0)
        }
        
        let nodeCount = Float(nodes.count)
        let angle = (nodeCount - 1) * (2.0 * .pi / 6.0)
        let radius = distributionRadius
        
        // Position in XZ plane for better visibility with updated camera
        let x = cos(angle) * radius
        let z = sin(angle) * radius
        
        let position = SIMD3<Float>(x, 0, z)
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