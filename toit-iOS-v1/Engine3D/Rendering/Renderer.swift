import Metal
import MetalKit

struct Uniforms {
    var modelMatrix: float4x4
    var viewMatrix: float4x4
    var projectionMatrix: float4x4
    var normalMatrix: float4x4
    var color: SIMD4<Float>
    var lightPosition: SIMD3<Float>
    var ambientIntensity: Float
    var diffuseIntensity: Float
}

class Renderer: NSObject, MTKViewDelegate {
    let device: MTLDevice
    let scene: Engine3DScene
    private let commandQueue: MTLCommandQueue
    private var pipelineState: MTLRenderPipelineState?
    private var depthState: MTLDepthStencilState?
    
    // Camera
    let camera: Camera
    
    // Debug state
    private var isDebugEnabled: Bool = false
    private var debugLineRenderer: DebugLineRenderer?
    private var pendingDebugLines: [(start: SIMD3<Float>, end: SIMD3<Float>, color: SIMD4<Float>)] = []
    
    // Uniforms buffer
    private var uniformsBuffer: MTLBuffer?
    
    init?(metalView: MTKView) {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else {
            print("❌ Failed to create Metal device or command queue")
            return nil
        }
        
        self.device = device
        self.commandQueue = commandQueue
        self.scene = Engine3DScene()
        
        // Initialize camera with better default position
        self.camera = Camera(
            position: SIMD3<Float>(0, 2, 5),  // Moved closer and lower
            target: SIMD3<Float>(0, 0, 0)
        )
        
        super.init()
        
        // Configure metal view
        metalView.device = device
        metalView.delegate = self
        metalView.depthStencilPixelFormat = .depth32Float
        metalView.clearDepth = 1.0
        metalView.clearColor = MTLClearColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        metalView.colorPixelFormat = .bgra8Unorm
        metalView.sampleCount = 1
        
        setupRenderer(metalView)
        print("✅ Renderer initialized successfully")
        debugPrintSceneState()
    }
    
    private func setupRenderer(_ metalView: MTKView) {
        setupPipelineState(metalView)
        setupDepthState()
        setupUniformsBuffer()
        setupDebugRenderer()
    }
    
    private func setupPipelineState(_ metalView: MTKView) {
        guard let library = device.makeDefaultLibrary() else {
            print("❌ Failed to create default library")
            return
        }
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = library.makeFunction(name: "vertex_main")
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragment_main")
        pipelineDescriptor.vertexDescriptor = Vertex.descriptor
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = metalView.depthStencilPixelFormat
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            print("✅ Pipeline state created successfully")
        } catch {
            print("❌ Failed to create pipeline state: \(error)")
        }
    }
    
    private func setupDepthState() {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.depthCompareFunction = .less
        descriptor.isDepthWriteEnabled = true
        
        depthState = device.makeDepthStencilState(descriptor: descriptor)
    }
    
    private func setupUniformsBuffer() {
        let uniformsSize = MemoryLayout<Uniforms>.stride
        let alignedUniformsSize = (uniformsSize + 0xFF) & ~0xFF  // Align to 256 bytes
        uniformsBuffer = device.makeBuffer(length: alignedUniformsSize * 100, options: [])
    }
    
    private func setupDebugRenderer() {
        debugLineRenderer = DebugLineRenderer(device: device)
    }
    
    // MARK: - MTKViewDelegate
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        let aspect = Float(size.width) / Float(size.height)
        camera.updateProjection(aspect: aspect)
    }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor,
              let pipelineState = pipelineState,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor),
              let uniformsBuffer = uniformsBuffer else {
            print("❌ Draw failed - missing required resources")
            return
        }
        
        encoder.setRenderPipelineState(pipelineState)
        encoder.setDepthStencilState(depthState)
        
        // Update camera matrices
        let viewMatrix = camera.viewMatrix
        let projectionMatrix = camera.projectionMatrix
        
        // Render scene objects
        renderSceneObjects(encoder: encoder, viewMatrix: viewMatrix, projectionMatrix: projectionMatrix)
        
        // Render debug lines if enabled
        if isDebugEnabled {
            renderDebugLines(encoder: encoder, viewMatrix: viewMatrix, projectionMatrix: projectionMatrix)
        }
        
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    private func renderSceneObjects(encoder: MTLRenderCommandEncoder, viewMatrix: matrix_float4x4, projectionMatrix: matrix_float4x4) {
        // Render each node
        for (index, node) in scene.nodes.enumerated() {
            guard let vertexBuffer = node.vertexBuffer else {
                print("⚠️ Node \(index) has no vertex buffer")
                continue
            }
            
            // Update uniforms for this node
            var uniforms = Uniforms(
                modelMatrix: node.modelMatrix,
                viewMatrix: viewMatrix,
                projectionMatrix: projectionMatrix,
                normalMatrix: simd_transpose(simd_inverse(node.modelMatrix)),
                color: node.color,
                lightPosition: SIMD3<Float>(5, 5, 5),
                ambientIntensity: 0.2,
                diffuseIntensity: 0.8
            )
            
            // Copy uniforms to buffer at offset for this node
            let alignedUniformsSize = (MemoryLayout<Uniforms>.stride + 0xFF) & ~0xFF  // Align to 256 bytes
            let uniformsOffset = alignedUniformsSize * index
            uniformsBuffer?.contents().advanced(by: uniformsOffset).copyMemory(
                from: &uniforms,
                byteCount: MemoryLayout<Uniforms>.stride
            )
            
            // Set vertex buffer and uniforms
            encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            encoder.setVertexBuffer(uniformsBuffer, offset: uniformsOffset, index: 1)
            encoder.setFragmentBuffer(uniformsBuffer, offset: uniformsOffset, index: 1)
            
            // Draw the node
            encoder.drawPrimitives(
                type: .triangle,
                vertexStart: 0,
                vertexCount: node.vertexCount
            )
        }
        
        // Render branches if any
        for branch in scene.branches {
            guard let vertexBuffer = branch.vertexBuffer else {
                print("⚠️ Branch has no vertex buffer")
                continue
            }
            
            // Similar uniform setup for branch...
            var uniforms = Uniforms(
                modelMatrix: branch.modelMatrix,
                viewMatrix: viewMatrix,
                projectionMatrix: projectionMatrix,
                normalMatrix: matrix_identity_float4x4,
                color: SIMD4<Float>(1, 1, 1, 1),  // White color for branches
                lightPosition: SIMD3<Float>(5, 5, 5),
                ambientIntensity: 0.2,
                diffuseIntensity: 0.8
            )
            
            let alignedUniformsSize = (MemoryLayout<Uniforms>.stride + 0xFF) & ~0xFF  // Align to 256 bytes
            let uniformsOffset = alignedUniformsSize * (scene.nodes.count + (scene.branches.firstIndex(of: branch) ?? 0))
            uniformsBuffer?.contents().advanced(by: uniformsOffset).copyMemory(
                from: &uniforms,
                byteCount: MemoryLayout<Uniforms>.stride
            )
            
            encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            encoder.setVertexBuffer(uniformsBuffer, offset: uniformsOffset, index: 1)
            encoder.setFragmentBuffer(uniformsBuffer, offset: uniformsOffset, index: 1)
            
            encoder.drawPrimitives(
                type: .line,
                vertexStart: 0,
                vertexCount: branch.vertexCount
            )
        }
    }
    
    private func renderDebugLines(encoder: MTLRenderCommandEncoder, viewMatrix: matrix_float4x4, projectionMatrix: matrix_float4x4) {
        guard let debugLineRenderer = debugLineRenderer else { return }
        
        // Add any pending debug lines
        for line in pendingDebugLines {
            debugLineRenderer.addLine(start: line.start, end: line.end, color: line.color)
        }
        pendingDebugLines.removeAll()
        
        // Update and render debug lines
        debugLineRenderer.updateBuffers()
        debugLineRenderer.render(encoder: encoder, viewMatrix: viewMatrix, projectionMatrix: projectionMatrix)
    }
    
    // Debug methods
    func enableDebugVisualization(_ enabled: Bool) {
        isDebugEnabled = enabled
        if !enabled {
            debugLineRenderer?.clear()
            pendingDebugLines.removeAll()
        }
        print("Debug visualization \(enabled ? "enabled" : "disabled")")
    }
    
    func debugDrawLine(start: SIMD3<Float>, end: SIMD3<Float>, color: SIMD4<Float>) {
        guard isDebugEnabled else { return }
        pendingDebugLines.append((start: start, end: end, color: color))
    }
    
    func drawDebugAxes(length: Float = 1.0) {
        guard isDebugEnabled else { return }
        let origin = SIMD3<Float>(0, 0, 0)
        
        // X axis (red)
        debugDrawLine(
            start: origin,
            end: SIMD3<Float>(length, 0, 0),
            color: SIMD4<Float>(1, 0, 0, 1)
        )
        
        // Y axis (green)
        debugDrawLine(
            start: origin,
            end: SIMD3<Float>(0, length, 0),
            color: SIMD4<Float>(0, 1, 0, 1)
        )
        
        // Z axis (blue)
        debugDrawLine(
            start: origin,
            end: SIMD3<Float>(0, 0, length),
            color: SIMD4<Float>(0, 0, 1, 1)
        )
    }
    
    func debugPrintSceneState() {
        print("🔍 Scene State:")
        print("Nodes: \(scene.nodes.count)")
        print("Branches: \(scene.branches.count)")
        
        for (index, node) in scene.nodes.enumerated() {
            print("Node \(index):")
            print("  - Position: \(node.position)")
            print("  - Has vertex buffer: \(node.vertexBuffer != nil)")
            print("  - Vertex count: \(node.vertexCount)")
        }
        
        print("Camera:")
        print("  - Position: \(camera.position)")
        print("  - Target: \(camera.target)")
        camera.debugPrintCameraMatrix()
    }
} 