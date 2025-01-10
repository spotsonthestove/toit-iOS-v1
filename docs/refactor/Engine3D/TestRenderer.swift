import Metal
import MetalKit

class TestRenderer: NSObject, MTKViewDelegate {
    private let metalView: MTKView
    private let cameraDistance: Float = 8.0
    private let cameraHeight: Float = 5.0
    private let cameraFOV: Float = 90.0 * .pi / 180.0
    
    let device: MTLDevice
    let scene: TestScene
    private let commandQueue: MTLCommandQueue
    private var pipelineState: MTLRenderPipelineState?
    
    // Sphere rendering properties
    private var sphereGeometry: TestSphereGeometry?
    private var sphereVertexBuffer: MTLBuffer?
    private var sphereIndexBuffer: MTLBuffer?
    private var uniformsBuffer: MTLBuffer?
    
    // Add selection tracking
    private(set) var selectedNode: TestSceneNode?
    private(set) var lastSelectedNode: TestSceneNode?
    
    // Camera properties
    private var viewMatrix: simd_float4x4 = matrix_identity_float4x4  // Initialize with identity
    private var projectionMatrix: simd_float4x4 = matrix_identity_float4x4  // Initialize with identity
    
    // Add depth state setup
    private var depthState: MTLDepthStencilState?
    
    // Add property to track if we need to update matrices
    private var needsMatrixUpdate = true
    
    // Add these properties at the top of TestRenderer
    private var camera: TestCamera!
    private let lightPosition = SIMD3<Float>(2.0, 5.0, 2.0)
    
    // Add to TestRenderer class
    private var isDragging = false
    private var draggedNode: TestSceneNode?
    private var lastDragPosition: CGPoint?
    
    init?(metalView: MTKView) {
        self.metalView = metalView
        
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else {
            return nil
        }
        
        self.device = device
        self.commandQueue = commandQueue
        self.scene = TestScene()
        
        super.init()
        
        // Initialize camera after super.init()
        self.camera = TestCamera(
            position: SIMD3<Float>(0, cameraHeight, cameraDistance),
            target: SIMD3<Float>(0, 0, 0)
        )
        
        metalView.device = device
        metalView.delegate = self
        metalView.depthStencilPixelFormat = .depth32Float
        metalView.clearDepth = 1.0
        
        setupRenderer(metalView)
    }
    
    private func setupRenderer(_ metalView: MTKView) {
        // Make background lighter for debugging
        metalView.clearColor = MTLClearColor(red: 0.2, green: 0.2, blue: 0.3, alpha: 1.0)  // Slightly blue background
        metalView.colorPixelFormat = .bgra8Unorm
        
        // Move camera further back and up for better view
        let cameraPosition = SIMD3<Float>(0, 3, 8)  // Further back and higher up
        let lookAt = SIMD3<Float>(0, 0, 0)
        let up = SIMD3<Float>(0, 1, 0)
        
        // Create view matrix
        let forward = normalize(lookAt - cameraPosition)
        let right = normalize(cross(forward, up))
        let upAdjusted = normalize(cross(right, forward))
        
        viewMatrix = simd_float4x4(
            SIMD4<Float>(right.x, upAdjusted.x, -forward.x, 0),
            SIMD4<Float>(right.y, upAdjusted.y, -forward.y, 0),
            SIMD4<Float>(right.z, upAdjusted.z, -forward.z, 0),
            SIMD4<Float>(-dot(right, cameraPosition),
                         -dot(upAdjusted, cameraPosition),
                         dot(forward, cameraPosition), 1)
        )
        
        setupPipelineState()
        
        // Create a larger uniforms buffer to handle multiple nodes
        let maxNodes = 100 // Adjust this number based on your needs
        let uniformsSize = MemoryLayout<TestUniforms>.stride * maxNodes
        uniformsBuffer = device.makeBuffer(length: uniformsSize, options: [])
    }
    
    private func setupPipelineState() {
        print("Setting up pipeline state...")
        guard let library = device.makeDefaultLibrary() else {
            print("❌ Failed to create default library")
            return
        }
        
        guard let vertexFunction = library.makeFunction(name: "vertex_main"),
              let fragmentFunction = library.makeFunction(name: "fragment_main") else {
            print("❌ Failed to create shader functions")
            return
        }
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = TestVertex.descriptor
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            print("✅ Pipeline state created successfully")
        } catch {
            print("❌ Failed to create pipeline state: \(error)")
        }
        
        // Add depth state setup
        let depthStateDescriptor = MTLDepthStencilDescriptor()
        depthStateDescriptor.depthCompareFunction = .less
        depthStateDescriptor.isDepthWriteEnabled = true
        
        guard let depthState = device.makeDepthStencilState(descriptor: depthStateDescriptor) else {
            print("❌ Failed to create depth state")
            return
        }
        
        // Store depth state as a property
        self.depthState = depthState
        
        setupSphereGeometry()
    }
    
    private func setupSphereGeometry() {
        sphereGeometry = TestSphereGeometry(radius: 0.3)
        
        guard let geometry = sphereGeometry else { return }
        
        // Create vertex buffer
        sphereVertexBuffer = device.makeBuffer(
            bytes: geometry.vertices,
            length: geometry.vertices.count * MemoryLayout<Engine3DVertex>.stride,
            options: []
        )
        
        // Create index buffer
        sphereIndexBuffer = device.makeBuffer(
            bytes: geometry.indices,
            length: geometry.indices.count * MemoryLayout<UInt16>.stride,
            options: []
        )
        
        // Update uniforms
        let uniformsSize = MemoryLayout<TestUniforms>.stride
        uniformsBuffer = device.makeBuffer(length: uniformsSize, options: [])
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        print("View size changing to: \(size)")
        
        // Update projection matrix with new aspect ratio
        let aspect = Float(size.width) / Float(size.height)
        projectionMatrix = matrix_perspective_right_hand(
            Float.pi / 3,
            aspect,
            0.1,
            100.0
        )
        
        needsMatrixUpdate = true
    }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor),
              let pipelineState = pipelineState,
              let uniformsBuffer = uniformsBuffer else {
            return
        }
        
        // Set render state
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setDepthStencilState(depthState)
        
        // Set vertex buffer once
        renderEncoder.setVertexBuffer(sphereVertexBuffer, offset: 0, index: 0)
        
        // Draw each node in the scene
        for (index, node) in scene.nodes.enumerated() {
            let uniformsOffset = index * MemoryLayout<TestUniforms>.stride
            
            // Update uniforms for this specific node
            var uniforms = TestUniforms(
                modelMatrix: node.worldMatrix,
                viewMatrix: camera.viewMatrix,
                projectionMatrix: camera.projectionMatrix,
                normalMatrix: matrix_identity_float4x4,
                color: SIMD4<Float>(0.8, 0.8, 1.0, 1.0),
                lightPosition: lightPosition,
                ambientIntensity: 0.3,
                diffuseIntensity: 0.7
            )
            
            // Copy uniforms to the correct offset in the buffer
            memcpy(uniformsBuffer.contents() + uniformsOffset, &uniforms, MemoryLayout<TestUniforms>.size)
            
            // Set vertex and fragment buffer with correct offset
            renderEncoder.setVertexBuffer(uniformsBuffer, offset: uniformsOffset, index: 1)
            renderEncoder.setFragmentBuffer(uniformsBuffer, offset: uniformsOffset, index: 1)
            
            // Draw sphere for this node
            if let indexBuffer = sphereIndexBuffer {
                renderEncoder.drawIndexedPrimitives(
                    type: .triangle,
                    indexCount: sphereGeometry?.indices.count ?? 0,
                    indexType: .uint16,
                    indexBuffer: indexBuffer,
                    indexBufferOffset: 0
                )
            }
        }
        
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
        
        print("🎨 Drawing \(scene.nodes.count) nodes")
    }
    
    func selectNode(at position: CGPoint, in view: MTKView) {
        // Convert screen coordinates to normalized device coordinates
        let viewSize = view.bounds.size
        let x = (Float(position.x) / Float(viewSize.width)) * 2 - 1
        let y = -((Float(position.y) / Float(viewSize.height)) * 2 - 1)
        
        // Simple distance-based hit testing
        let hitPosition = SIMD3<Float>(x, y, 0)
        var closestNode: TestSceneNode?
        var closestDistance: Float = 0.2 // Hit threshold
        
        for node in scene.nodes {
            let nodePos = node.worldMatrix.columns.3.xyz
            let distance = length(hitPosition - nodePos)
            
            if distance < closestDistance {
                closestDistance = distance
                closestNode = node
            }
        }
        
        if let node = closestNode {
            if node === selectedNode {
                // If tapping the same node, store it as last selected
                lastSelectedNode = node
                selectedNode = nil
            } else if selectedNode == nil {
                // If no node is selected, select this one
                selectedNode = node
            } else {
                // If another node is already selected, store it as last selected
                lastSelectedNode = selectedNode
                selectedNode = node
            }
        } else {
            // Clicking empty space clears selection
            selectedNode = nil
            lastSelectedNode = nil
        }
    }
    
    func connectSelectedNodes(device: MTLDevice) -> Bool {
        guard let startNode = lastSelectedNode,
              let endNode = selectedNode,
              startNode !== endNode else {
            return false
        }
        
        let branch = startNode.connect(to: endNode, device: device)
        scene.addBranch(branch)
        
        // Clear selection after connecting
        selectedNode = nil
        lastSelectedNode = nil
        
        return true
    }
    
    // Add this method to update uniforms
    private func updateUniforms() {
        guard let uniformsBuffer = uniformsBuffer,
              let camera = camera else { return }
        
        let modelMatrix = matrix_identity_float4x4
        
        let normalMatrix = simd_float4x4(
            SIMD4<Float>(modelMatrix[0].xyz, 0),
            SIMD4<Float>(modelMatrix[1].xyz, 0),
            SIMD4<Float>(modelMatrix[2].xyz, 0),
            SIMD4<Float>(0, 0, 0, 1)
        )
        
        // Brighter base color and ambient light
        var uniforms = TestUniforms(
            modelMatrix: modelMatrix,
            viewMatrix: camera.viewMatrix,
            projectionMatrix: camera.projectionMatrix,
            normalMatrix: normalMatrix,
            color: SIMD4<Float>(0.8, 0.8, 1.0, 1.0),  // Brighter base color
            lightPosition: lightPosition,
            ambientIntensity: 0.3,  // Add some ambient light
            diffuseIntensity: 0.7   // Adjust diffuse intensity
        )
        
        memcpy(uniformsBuffer.contents(), &uniforms, MemoryLayout<TestUniforms>.size)
    }
    
    private func updateCameraMatrix() {
        // Position camera at an angle for debugging
        let eye = SIMD3<Float>(
            cameraDistance * sin(0.5),
            cameraHeight,
            cameraDistance * cos(0.5)
        )
        let target = SIMD3<Float>(0, 0, 0)
        let up = SIMD3<Float>(0, 1, 0)
        
        viewMatrix = matrix_look_at_right_hand(eye, target, up)
        
        let aspect = Float(self.metalView.drawableSize.width) / 
                    Float(self.metalView.drawableSize.height)
        projectionMatrix = matrix_perspective_right_hand(
            cameraFOV,
            aspect,
            0.1,
            100.0
        )
        
        print(" Debug Camera - Position: \(eye), FOV: \(cameraFOV), Aspect: \(aspect)")
    }
    
    func handlePan(_ gesture: UIPanGestureRecognizer, in view: MTKView) {
        let location = gesture.location(in: view)
        
        switch gesture.state {
        case .began:
            // Try to select a node at the touch position
            if let node = hitTest(at: location, in: view) {
                isDragging = true
                draggedNode = node
                lastDragPosition = location
            }
            
        case .changed:
            guard isDragging,
                  let node = draggedNode,
                  let lastPosition = lastDragPosition else { return }
            
            // Calculate movement in screen space
            let delta = CGPoint(
                x: location.x - lastPosition.x,
                y: location.y - lastPosition.y
            )
            
            // Convert screen movement to world space movement
            let worldDelta = convertScreenDeltaToWorld(delta: delta, in: view)
            // Create a new position by adding the delta to all components of the current position
            let newPosition = SIMD3<Float>(
                node.position.x + worldDelta.x,
                node.position.y + worldDelta.y,
                node.position.z  // Keep the same Z coordinate
            )
            
            // Update node position
            node.updatePosition(newPosition)
            lastDragPosition = location
            
            // Mark for storage update
            scheduleStorageUpdate()
            
        case .ended, .cancelled:
            isDragging = false
            draggedNode = nil
            lastDragPosition = nil
            
        default:
            break
        }
    }
    
    // Add debounced storage update
    private var storageUpdateWorkItem: DispatchWorkItem?
    
    private func scheduleStorageUpdate() {
        storageUpdateWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            NodeStorage.shared.saveNodes(Array(self.scene.nodes))
        }
        
        storageUpdateWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }
    
    private func hitTest(at location: CGPoint, in view: MTKView) -> TestSceneNode? {
        // Convert screen coordinates to normalized device coordinates
        let viewportSize = vector_float2(Float(view.bounds.width), Float(view.bounds.height))
        let normalizedX = (Float(location.x) / viewportSize.x) * 2 - 1
        let normalizedY = -((Float(location.y) / viewportSize.y) * 2 - 1)
        
        // Test against each node
        for node in scene.nodes {
            let nodePos = node.position
            let distance = sqrt(pow(normalizedX - nodePos.x, 2) + pow(normalizedY - nodePos.y, 2))
            if distance < 0.1 { // Adjust hit test radius as needed
                return node
            }
        }
        return nil
    }
    
    private func convertScreenDeltaToWorld(delta: CGPoint, in view: MTKView) -> SIMD2<Float> {
        let viewportSize = vector_float2(Float(view.bounds.width), Float(view.bounds.height))
        return SIMD2<Float>(
            Float(delta.x) / viewportSize.x * 2,
            -Float(delta.y) / viewportSize.y * 2
        )
    }
}

// Rename Uniforms to TestUniforms to avoid ambiguity
struct TestUniforms {
    var modelMatrix: simd_float4x4
    var viewMatrix: simd_float4x4
    var projectionMatrix: simd_float4x4
    var normalMatrix: simd_float4x4
    var color: SIMD4<Float>
    var lightPosition: SIMD3<Float>
    var ambientIntensity: Float
    var diffuseIntensity: Float
}

// Add matrix utilities
extension simd_float4x4 {
    init(lookAt eye: SIMD3<Float>, target: SIMD3<Float>, up: SIMD3<Float>) {
        let z = normalize(target - eye)
        let x = normalize(cross(up, z))
        let y = normalize(cross(z, x))
        
        let translateMatrix = simd_float4x4(
            SIMD4<Float>(1, 0, 0, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(0, 0, 1, 0),
            SIMD4<Float>(-eye.x, -eye.y, -eye.z, 1)
        )
        
        let rotateMatrix = simd_float4x4(
            SIMD4<Float>(x.x, y.x, z.x, 0),
            SIMD4<Float>(x.y, y.y, z.y, 0),
            SIMD4<Float>(x.z, y.z, z.z, 0),
            SIMD4<Float>(0, 0, 0, 1)
        )
        
        self = matrix_multiply(rotateMatrix, translateMatrix)
    }
    
    init(perspectiveProjectionFov fov: Float, aspectRatio: Float, nearZ: Float, farZ: Float) {
        let y = 1 / tan(fov * 0.5)
        let x = y / aspectRatio
        let z = farZ / (nearZ - farZ)
        
        self.init(columns: (
            SIMD4<Float>(x, 0, 0, 0),
            SIMD4<Float>(0, y, 0, 0),
            SIMD4<Float>(0, 0, z, -1),
            SIMD4<Float>(0, 0, z * nearZ, 0)
        ))
    }
} 