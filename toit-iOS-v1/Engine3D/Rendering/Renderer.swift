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
            return nil
        }
        
        self.device = device
        self.commandQueue = commandQueue
        self.scene = Engine3DScene()
        
        // Initialize camera
        self.camera = Camera(
            position: SIMD3<Float>(0, 3, 8),
            target: SIMD3<Float>(0, 0, 0)
        )
        
        super.init()
        
        metalView.device = device
        metalView.delegate = self
        metalView.depthStencilPixelFormat = .depth32Float
        metalView.clearDepth = 1.0
        
        setupRenderer(metalView)
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
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }
        
        encoder.setRenderPipelineState(pipelineState)
        encoder.setDepthStencilState(depthState)
        
        // Update and render scene
        scene.update()
        
        // End encoding and commit
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
} 