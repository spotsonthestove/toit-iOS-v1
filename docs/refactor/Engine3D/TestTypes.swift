import Metal
import simd

struct TestVertex {
    var position: SIMD3<Float>
    var normal: SIMD3<Float>
    
    static var descriptor: MTLVertexDescriptor {
        let descriptor = MTLVertexDescriptor()
        
        // Position attribute
        descriptor.attributes[0].format = .float3
        descriptor.attributes[0].offset = 0
        descriptor.attributes[0].bufferIndex = 0
        
        // Normal attribute
        descriptor.attributes[1].format = .float3
        descriptor.attributes[1].offset = MemoryLayout<SIMD3<Float>>.stride
        descriptor.attributes[1].bufferIndex = 0
        
        // Layout
        descriptor.layouts[0].stride = MemoryLayout<TestVertex>.stride
        
        return descriptor
    }
}

// For backward compatibility with Engine3D module
typealias Engine3DVertex = TestVertex