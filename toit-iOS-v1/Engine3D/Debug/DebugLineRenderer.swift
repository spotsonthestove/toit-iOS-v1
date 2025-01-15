import Metal
import simd

struct DebugLineVertex {
    var position: SIMD3<Float>
    var color: SIMD4<Float>
    
    static var descriptor: MTLVertexDescriptor {
        let descriptor = MTLVertexDescriptor()
        
        // Position attribute
        descriptor.attributes[0].format = .float3
        descriptor.attributes[0].offset = 0
        descriptor.attributes[0].bufferIndex = 0
        
        // Color attribute
        descriptor.attributes[1].format = .float4
        descriptor.attributes[1].offset = MemoryLayout<SIMD3<Float>>.stride
        descriptor.attributes[1].bufferIndex = 0
        
        // Layout
        descriptor.layouts[0].stride = MemoryLayout<DebugLineVertex>.stride
        
        return descriptor
    }
}

class DebugLineRenderer {
    private let device: MTLDevice
    private var pipelineState: MTLRenderPipelineState?
    private var vertexBuffer: MTLBuffer?
    private var vertices: [DebugLineVertex] = []
    
    init(device: MTLDevice) {
        self.device = device
        setupPipelineState()
    }
    
    private func setupPipelineState() {
        guard let library = device.makeDefaultLibrary() else {
            print("❌ Failed to create debug line shader library")
            return
        }
        
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: "debug_line_vertex")
        descriptor.fragmentFunction = library.makeFunction(name: "debug_line_fragment")
        descriptor.vertexDescriptor = DebugLineVertex.descriptor
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.depthAttachmentPixelFormat = .depth32Float
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
            print("✅ Debug line pipeline state created")
        } catch {
            print("❌ Failed to create debug line pipeline state: \(error)")
        }
    }
    
    func addLine(start: SIMD3<Float>, end: SIMD3<Float>, color: SIMD4<Float>) {
        vertices.append(DebugLineVertex(position: start, color: color))
        vertices.append(DebugLineVertex(position: end, color: color))
    }
    
    func updateBuffers() {
        guard !vertices.isEmpty else {
            vertexBuffer = nil
            return
        }
        let bufferSize = vertices.count * MemoryLayout<DebugLineVertex>.stride
        vertexBuffer = device.makeBuffer(bytes: vertices, length: bufferSize, options: [])
        vertices.removeAll()
    }
    
    func render(encoder: MTLRenderCommandEncoder, viewMatrix: matrix_float4x4, projectionMatrix: matrix_float4x4) {
        guard let pipelineState = pipelineState,
              let vertexBuffer = vertexBuffer,
              vertexBuffer.length > 0 else {
            return
        }
        
        encoder.pushDebugGroup("Debug Line Rendering")
        
        encoder.setRenderPipelineState(pipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        // Copy matrices to avoid inout parameter requirement
        var viewMatrixCopy = viewMatrix
        var projectionMatrixCopy = projectionMatrix
        
        encoder.setVertexBytes(&viewMatrixCopy, length: MemoryLayout<matrix_float4x4>.stride, index: 1)
        encoder.setVertexBytes(&projectionMatrixCopy, length: MemoryLayout<matrix_float4x4>.stride, index: 2)
        
        let vertexCount = vertexBuffer.length / MemoryLayout<DebugLineVertex>.stride
        encoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: Int(vertexCount))
        
        encoder.popDebugGroup()
    }
    
    func clear() {
        vertices.removeAll()
        vertexBuffer = nil
    }
} 