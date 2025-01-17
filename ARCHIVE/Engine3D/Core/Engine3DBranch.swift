import Metal
import simd

class Engine3DBranch: Hashable {
    weak var startNode: Engine3DSceneNode?
    weak var endNode: Engine3DSceneNode?
    var vertexBuffer: MTLBuffer?
    var vertexCount: Int
    
    init(startNode: Engine3DSceneNode, endNode: Engine3DSceneNode, vertexBuffer: MTLBuffer, vertexCount: Int) {
        self.startNode = startNode
        self.endNode = endNode
        self.vertexBuffer = vertexBuffer
        self.vertexCount = vertexCount
    }
    
    // Required for Hashable
    static func == (lhs: Engine3DBranch, rhs: Engine3DBranch) -> Bool {
        return lhs.startNode === rhs.startNode && 
               lhs.endNode === rhs.endNode
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
    
    var modelMatrix: simd_float4x4 {
        // For branches, we use identity matrix as the vertices are in world space
        return matrix_identity_float4x4
    }
} 