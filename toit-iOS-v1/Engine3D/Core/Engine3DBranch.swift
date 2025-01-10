import Metal
import simd

class Engine3DBranch {
    private weak var startNode: Engine3DSceneNode?
    private weak var endNode: Engine3DSceneNode?
    private var geometry: BranchGeometry
    private var vertexBuffer: MTLBuffer?
    private var indexBuffer: MTLBuffer?
    private var uniformsBuffer: MTLBuffer?
    
    init(from startNode: Engine3DSceneNode, to endNode: Engine3DSceneNode, device: MTLDevice) {
        self.startNode = startNode
        self.endNode = endNode
        self.geometry = BranchGeometry(radius: 0.05, radialSegments: 8)
        
        updateGeometry(device: device)
    }
    
    func updateGeometry(device: MTLDevice) {
        guard let startNode = startNode, let endNode = endNode else { return }
        
        geometry.updateGeometry(from: startNode, to: endNode)
        
        vertexBuffer = device.makeBuffer(
            bytes: geometry.vertices,
            length: geometry.vertices.count * MemoryLayout<Engine3DVertex>.stride,
            options: []
        )
        
        indexBuffer = device.makeBuffer(
            bytes: geometry.indices,
            length: geometry.indices.count * MemoryLayout<UInt16>.stride,
            options: []
        )
    }
    
    func isConnectedTo(_ node: Engine3DSceneNode) -> Bool {
        return startNode === node || endNode === node
    }
} 