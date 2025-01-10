import Metal
import simd

class Engine3DSceneNode: Hashable {
    var position: SIMD3<Float> {
        didSet {
            updateLocalMatrix()
            print("Node position updated to: \(position)")
        }
    }
    var rotation: SIMD3<Float>
    var scale: SIMD3<Float>
    
    private(set) var localMatrix: simd_float4x4
    private(set) var worldMatrix: simd_float4x4
    
    weak var parent: Engine3DSceneNode?
    private var children: [Engine3DSceneNode] = []
    
    // Node properties
    let id: UUID
    var title: String
    var description: String?
    var connections: Set<UUID>
    
    // Metadata
    var lastModified: Date
    var isDeleted: Bool
    var needsSync: Bool
    
    init(id: UUID = UUID(), title: String = "", position: SIMD3<Float>) {
        self.id = id
        self.title = title
        self.description = nil
        self.position = position
        self.rotation = .zero
        self.scale = SIMD3<Float>(1, 1, 1)
        self.connections = []
        self.lastModified = Date()
        self.isDeleted = false
        self.needsSync = true
        
        self.localMatrix = matrix_identity_float4x4
        self.worldMatrix = matrix_identity_float4x4
        
        updateLocalMatrix()
    }
    
    func update() {
        updateLocalMatrix()
    }
    
    private func updateLocalMatrix() {
        // Create translation matrix from SIMD3<Float>
        let translationMatrix = simd_float4x4(translation: position)
        
        // Create rotation matrix from SIMD3<Float> (Euler angles)
        let rotationMatrix = simd_float4x4(rotation: rotation)
        
        // Create scale matrix from SIMD3<Float>
        let scaleMatrix = simd_float4x4(scale: scale)
        
        localMatrix = simd_mul(translationMatrix, 
                              simd_mul(rotationMatrix, scaleMatrix))
        updateWorldMatrix()
    }
    
    private func updateWorldMatrix() {
        if let parent = parent {
            worldMatrix = matrix_multiply(parent.worldMatrix, localMatrix)
        } else {
            worldMatrix = localMatrix
        }
        
        // Update children
        children.forEach { $0.updateWorldMatrix() }
    }
    
    func addChild(_ child: Engine3DSceneNode) {
        children.append(child)
        child.parent = self
        child.updateWorldMatrix()
    }
    
    func removeChild(_ child: Engine3DSceneNode) {
        children.removeAll { $0 === child }
        child.parent = nil
        child.updateWorldMatrix()
    }
    
    // MARK: - Hashable
    static func == (lhs: Engine3DSceneNode, rhs: Engine3DSceneNode) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
} 