import Metal
import simd

class TestScene {
    private(set) var nodes: Set<TestSceneNode> = []
    private(set) var branches: [TestBranch] = []
    
    // Update constants for better visibility
    private let nodeSpacing: Float = 0.5       // Reduced from 1.0
    private let distributionRadius: Float = 0.8  // Reduced from 1.5
    private let zRange: Float = 0.0             // Keep all nodes on same Z plane for now
    
    func addNode(_ node: TestSceneNode) {
        nodes.insert(node)
    }
    
    private func calculateNewNodePosition() -> SIMD3<Float> {
        let nodeCount = Float(nodes.count)
        
        // First node at center, others in circle
        if nodes.isEmpty {
            return SIMD3<Float>(0, 0, 0)
        }
        
        // Distribute subsequent nodes in slightly tighter circle
        let angle = (nodeCount - 1) * (2.0 * .pi / 6.0)  // 6 positions around circle
        let x = cos(angle) * distributionRadius
        let y = sin(angle) * distributionRadius
        
        print("📍 Calculated new node position: (\(x), \(y), 0.0)")
        return SIMD3<Float>(x, y, 0)
    }
    
    private func isPositionValid(_ position: SIMD3<Float>) -> Bool {
        for node in nodes {
            let distance = length(node.position - position)
            if distance < nodeSpacing {
                return false
            }
        }
        return true
    }
    
    private func generateFallbackPosition() -> SIMD3<Float> {
        // If we can't find a random position, use systematic placement
        let index = Float(nodes.count)
        let angle = index * (Float.pi * 0.5)  // Spiral out
        let radius = (index * 0.5) + nodeSpacing
        
        return SIMD3<Float>(
            radius * cos(angle),
            0,
            radius * sin(angle)
        )
    }
    
    func addBranch(_ branch: TestBranch) {
        branches.append(branch)
    }
    
    func removeNode(_ node: TestSceneNode) {
        nodes.remove(node)
        // Remove any branches connected to this node
        branches.removeAll { branch in
            branch.isConnectedTo(node)
        }
    }
    
    func updateBranches(device: MTLDevice) {
        for branch in branches {
            branch.updateGeometry(device: device)
        }
    }
    
    func update() {
        // Update all nodes
        for node in nodes {
            node.update()
        }
    }
} 