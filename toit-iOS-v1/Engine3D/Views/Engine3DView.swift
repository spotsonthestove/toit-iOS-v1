import SwiftUI
import MetalKit

struct Engine3DView: View {
    @State private var renderer: Renderer?
    @State private var metalView = MTKView()
    @State private var selectedNodeId: UUID?
    
    var body: some View {
        ZStack {
            MetalViewRepresentable(metalView: metalView, renderer: $renderer)
                .onAppear {
                    setupRenderer()
                    testCameraSetup()
                    createInitialScene()
                }
            
            // Debug controls overlay
            VStack {
                Spacer()
                HStack {
                    Button(action: addNode) {
                        Label("Add Node", systemImage: "plus.circle.fill")
                            .padding()
                            .background(Color.blue.opacity(0.7))
                            .cornerRadius(10)
                    }
                    
                    Button(action: connectNodes) {
                        Label("Connect", systemImage: "link.circle.fill")
                            .padding()
                            .background(Color.green.opacity(0.7))
                            .cornerRadius(10)
                    }
                }
                .padding()
            }
        }
    }
    
    private func setupRenderer() {
        renderer = Renderer(metalView: metalView)
        print("Renderer setup: \(renderer != nil)")
    }
    
    private func testCameraSetup() {
        guard let renderer = renderer else { return }
        
        // Enable debug visualization
        renderer.enableDebugVisualization(true)
        renderer.drawDebugAxes(length: 2.0)
        
        // Set up and test camera
        renderer.camera.position = SIMD3<Float>(0, 0, -5)
        renderer.camera.target = SIMD3<Float>(0, 0, 0)
        renderer.camera.debugPrintCameraMatrix()
        
        print("Camera test setup complete")
    }
    
    private func addNode() {
        guard let renderer = renderer else {
            print("❌ Cannot add node - renderer is nil")
            return 
        }
        let position = SIMD3<Float>(0, 0, 0)
        let node = Engine3DSceneNode(position: position)
        node.setupGeometry(device: renderer.device)
        renderer.scene.addNode(node)
        print("✅ Added node. Total nodes: \(renderer.scene.nodes.count)")
    }
    
    private func connectNodes() {
        // TODO: Implement node connection logic
    }
    
    private func createInitialScene() {
        guard let renderer = renderer else {
            print("❌ Cannot create scene - renderer is nil")
            return
        }
        
        // Define node configurations with positions and colors
        let nodeConfigs: [(position: SIMD3<Float>, color: SIMD4<Float>)] = [
            // Center node (white)
            (SIMD3<Float>(0, 0, 0), SIMD4<Float>(1, 1, 1, 1)),
            
            // Front nodes (blue)
            (SIMD3<Float>(0, 0, 1), SIMD4<Float>(0, 0, 1, 1)),
            (SIMD3<Float>(1, 0, 1), SIMD4<Float>(0, 0, 1, 1)),
            
            // Back nodes (green)
            (SIMD3<Float>(0, 0, -1), SIMD4<Float>(0, 1, 0, 1)),
            (SIMD3<Float>(-1, 0, -1), SIMD4<Float>(0, 1, 0, 1)),
            
            // Upper nodes (red)
            (SIMD3<Float>(0, 1, 0), SIMD4<Float>(1, 0, 0, 1)),
            (SIMD3<Float>(0, 1, 1), SIMD4<Float>(1, 0, 0, 1))
        ]
        
        // Create nodes
        var nodes: [Engine3DSceneNode] = []
        for (position, color) in nodeConfigs {
            let node = Engine3DSceneNode(position: position, color: color)
            node.setupGeometry(device: renderer.device)
            renderer.scene.addNode(node)
            nodes.append(node)
        }
        
        // Create branches between center node and adjacent nodes
        if let centerNode = nodes.first {
            for i in 1..<nodes.count {
                if let branch = centerNode.connect(to: nodes[i], device: renderer.device) {
                    renderer.scene.addBranch(branch)
                }
            }
            
            // Connect upper nodes to each other
            if let branch = nodes[5].connect(to: nodes[6], device: renderer.device) {
                renderer.scene.addBranch(branch)
            }
        }
        
        print("✅ Created test scene with \(nodes.count) nodes")
    }
}

struct MetalViewRepresentable: UIViewRepresentable {
    let metalView: MTKView
    @Binding var renderer: Renderer?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> MTKView {
        metalView.delegate = renderer
        
        metalView.clearColor = MTLClearColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        metalView.depthStencilPixelFormat = .depth32Float
        metalView.colorPixelFormat = .bgra8Unorm
        metalView.sampleCount = 1
        metalView.enableSetNeedsDisplay = true
        metalView.isPaused = false
        metalView.preferredFramesPerSecond = 60
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, 
                                               action: #selector(Coordinator.handleTap(_:)))
        metalView.addGestureRecognizer(tapGesture)
        
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, 
                                               action: #selector(Coordinator.handlePan(_:)))
        metalView.addGestureRecognizer(panGesture)
        
        return metalView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {}
    
    class Coordinator: NSObject {
        var parent: MetalViewRepresentable
        
        init(_ parent: MetalViewRepresentable) {
            self.parent = parent
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            // TODO: Implement node selection
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            // TODO: Implement node dragging
        }
    }
} 