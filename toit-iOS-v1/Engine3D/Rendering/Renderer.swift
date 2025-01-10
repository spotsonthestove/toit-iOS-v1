import Metal
import MetalKit

struct Uniforms {
    var modelMatrix: float4x4
    var viewMatrix: float4x4
    var projectionMatrix: float4x4
}

class Renderer: NSObject, MTKViewDelegate {
    let device: MTLDevice
    let scene: Engine3DScene
    private let commandQueue: MTLCommandQueue
    private var pipelineState: MTLRenderPipelineState?
    private var depthState: MTLDepthStencilState?
    
    // Camera
    private let camera: Camera
    
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
        uniformsBuffer = device.makeBuffer(length: uniformsSize * 100, options: [])
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
                projectionMatrix: projectionMatrix
            )
            
            // Copy uniforms to buffer at offset for this node
            let uniformsOffset = MemoryLayout<Uniforms>.stride * index
            uniformsBuffer.contents().advanced(by: uniformsOffset).copyMemory(
                from: &uniforms,
                byteCount: MemoryLayout<Uniforms>.stride
            )
            
            // Set vertex buffer and uniforms
            encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            encoder.setVertexBuffer(uniformsBuffer, offset: uniformsOffset, index: 1)
            
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
                projectionMatrix: projectionMatrix
            )
            
            let uniformsOffset = MemoryLayout<Uniforms>.stride * (scene.nodes.count + (scene.branches.firstIndex(of: branch) ?? 0))
            uniformsBuffer.contents().advanced(by: uniformsOffset).copyMemory(
                from: &uniforms,
                byteCount: MemoryLayout<Uniforms>.stride
            )
            
            encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            encoder.setVertexBuffer(uniformsBuffer, offset: uniformsOffset, index: 1)
            
            encoder.drawPrimitives(
                type: .line,
                vertexStart: 0,
                vertexCount: branch.vertexCount
            )
        }
        
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    // Add debug methods
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
    }
} 