import Metal
import simd

class TestSceneNode: Hashable {
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
    
    weak var parent: TestSceneNode?
    private var children: [TestSceneNode] = []
    
    // Add geometry properties
    private(set) var geometry: TestSphereGeometry?
    private(set) var vertexBuffer: MTLBuffer?
    private(set) var indexBuffer: MTLBuffer?
    
    // New properties for node data
    var id: UUID
    var title: String
    var description: String
    var connections: Set<UUID>  // Store connected node IDs
    
    // Metadata for sync
    var lastModified: Date
    var isDeleted: Bool
    var needsSync: Bool
    
    init(id: UUID = UUID(), title: String = "", position: SIMD3<Float>) {
        self.id = id
        self.title = title
        self.description = ""
        self.position = position
        self.rotation = .zero
        self.scale = SIMD3<Float>(1, 1, 1)
        self.connections = []
        self.lastModified = Date()
        self.isDeleted = false
        self.needsSync = true
        
        // Initialize matrices with default values first
        self.localMatrix = matrix_identity_float4x4
        self.worldMatrix = matrix_identity_float4x4
        
        // Then update matrices with the correct values
        self.localMatrix = simd_float4x4(translation: position)
        self.worldMatrix = self.localMatrix
    }
    
    convenience init(position: SIMD3<Float>) {
        self.init(
            id: UUID(),
            title: "",
            position: position
        )
    }
    
    // Public update method for external use
    func update() {
        updateLocalMatrix()  // This will trigger updateWorldMatrix()
    }
    
    // Keep these private for internal use
    private func updateLocalMatrix() {
        let translationMatrix = matrix_float4x4(translation: position)
        let rotationMatrix = matrix_float4x4(rotation: rotation)
        let scaleMatrix = matrix_float4x4(scale: scale)
        
        // Order: Scale -> Rotate -> Translate
        localMatrix = matrix_multiply(translationMatrix, 
                                    matrix_multiply(rotationMatrix, scaleMatrix))
        updateWorldMatrix()
    }
    
    private func updateWorldMatrix() {
        if let parent = parent {
            worldMatrix = matrix_multiply(parent.worldMatrix, localMatrix)
        } else {
            worldMatrix = localMatrix
        }
        
        // Update children
        for child in children {
            child.updateWorldMatrix()
        }
    }
    
    func addChild(_ child: TestSceneNode) {
        children.append(child)
        child.parent = self
        child.updateWorldMatrix()
    }
    
    func removeChild(_ child: TestSceneNode) {
        children.removeAll { $0 === child }
        child.parent = nil
        child.updateWorldMatrix()
    }
    
    // Add setup method for geometry
    func setupGeometry(device: MTLDevice, radius: Float = 0.3) {
        print("Setting up geometry for node with radius: \(radius)")
        
        // Create sphere geometry
        geometry = TestSphereGeometry(radius: radius)
        
        guard let geometry = geometry else {
            print("❌ Failed to create geometry")
            return
        }
        
        // Create vertex buffer
        vertexBuffer = device.makeBuffer(
            bytes: geometry.vertices,
            length: geometry.vertices.count * MemoryLayout<Engine3DVertex>.stride,
            options: []
        )
        
        // Create index buffer
        indexBuffer = device.makeBuffer(
            bytes: geometry.indices,
            length: geometry.indices.count * MemoryLayout<UInt16>.stride,
            options: []
        )
        
        print("✅ Geometry setup complete - vertices: \(geometry.vertices.count), indices: \(geometry.indices.count)")
    }
    
    // Add connection method
    func connect(to target: TestSceneNode, device: MTLDevice) -> TestBranch {
        let branch = TestBranch(from: self, to: target, device: device)
        return branch
    }
    
    // Add method to update position with proper matrix handling
    func updatePosition(_ newPosition: SIMD3<Float>) {
        position = newPosition
        localMatrix = simd_float4x4(translation: position)
        updateWorldMatrix()
        needsSync = true
        lastModified = Date()
    }
    
    static func == (lhs: TestSceneNode, rhs: TestSceneNode) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// Add matrix utility extensions
extension matrix_float4x4 {
    init(translation: SIMD3<Float>) {
        self = matrix_identity_float4x4
        columns.3 = SIMD4<Float>(translation.x, translation.y, translation.z, 1)
    }
    
    init(rotation: SIMD3<Float>) {
        let rotationX = matrix_float4x4(rotationX: rotation.x)
        let rotationY = matrix_float4x4(rotationY: rotation.y)
        let rotationZ = matrix_float4x4(rotationZ: rotation.z)
        self = matrix_multiply(matrix_multiply(rotationZ, rotationY), rotationX)
    }
    
    init(scale: SIMD3<Float>) {
        self = matrix_identity_float4x4
        columns.0.x = scale.x
        columns.1.y = scale.y
        columns.2.z = scale.z
    }
    
    init(rotationX angle: Float) {
        let c = cos(angle)
        let s = sin(angle)
        self = matrix_identity_float4x4
        columns.1.y = c
        columns.1.z = s
        columns.2.y = -s
        columns.2.z = c
    }
    
    init(rotationY angle: Float) {
        let c = cos(angle)
        let s = sin(angle)
        self = matrix_identity_float4x4
        columns.0.x = c
        columns.0.z = -s
        columns.2.x = s
        columns.2.z = c
    }
    
    init(rotationZ angle: Float) {
        let c = cos(angle)
        let s = sin(angle)
        self = matrix_identity_float4x4
        columns.0.x = c
        columns.0.y = s
        columns.1.x = -s
        columns.1.y = c
    }
} 