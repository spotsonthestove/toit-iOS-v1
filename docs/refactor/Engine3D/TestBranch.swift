import Metal
import simd

class TestBranch {
    private weak var startNode: TestSceneNode?
    private weak var endNode: TestSceneNode?
    private var geometry: TestBranchGeometry
    private var vertexBuffer: MTLBuffer?
    private var indexBuffer: MTLBuffer?
    private var uniformsBuffer: MTLBuffer?
    
    init(from startNode: TestSceneNode, to endNode: TestSceneNode, device: MTLDevice) {
        self.startNode = startNode
        self.endNode = endNode
        self.geometry = TestBranchGeometry(radius: 0.05, radialSegments: 8)
        
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
    
    func updateUniforms(device: MTLDevice, viewMatrix: simd_float4x4, projectionMatrix: simd_float4x4) {
        var uniforms = BranchUniforms(
            modelMatrix: matrix_identity_float4x4,
            viewMatrix: viewMatrix,
            projectionMatrix: projectionMatrix,
            normalMatrix: matrix_identity_float4x4,
            color: SIMD4<Float>(0.6, 0.6, 0.6, 1.0),  // Gray color for branches
            lightPosition: SIMD3<Float>(2.0, 5.0, 2.0),
            ambientIntensity: 0.3,
            diffuseIntensity: 0.7
        )
        
        uniformsBuffer = device.makeBuffer(
            bytes: &uniforms,
            length: MemoryLayout<BranchUniforms>.size,
            options: []
        )
    }
    
    func render(encoder: MTLRenderCommandEncoder) {
        guard let vertexBuffer = vertexBuffer,
              let indexBuffer = indexBuffer,
              let uniformsBuffer = uniformsBuffer else { return }
        
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 1)
        encoder.setFragmentBuffer(uniformsBuffer, offset: 0, index: 1)
        
        encoder.drawIndexedPrimitives(
            type: .triangle,
            indexCount: geometry.indices.count,
            indexType: .uint16,
            indexBuffer: indexBuffer,
            indexBufferOffset: 0
        )
    }
    
    func isConnectedTo(_ node: TestSceneNode) -> Bool {
        return startNode === node || endNode === node
    }
} 