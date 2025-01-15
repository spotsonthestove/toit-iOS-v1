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
                .allowsHitTesting(true)
            
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
        
        // Enable user interaction
        metalView.isUserInteractionEnabled = true
        metalView.isMultipleTouchEnabled = true  // Enable multi-touch explicitly
        print("🔧 Setting up gesture recognizers")
        
        // Single-finger pan for orbit
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, 
                                               action: #selector(Coordinator.handlePan(_:)))
        panGesture.name = "Pan"
        
        // Pinch for zoom
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator,
                                                   action: #selector(Coordinator.handlePinch(_:)))
        pinchGesture.delegate = context.coordinator
        pinchGesture.name = "Pinch"
        
        // Rotation gesture for camera roll
        let rotationGesture = UIRotationGestureRecognizer(target: context.coordinator,
                                                         action: #selector(Coordinator.handleRotation(_:)))
        rotationGesture.delegate = context.coordinator
        rotationGesture.name = "Rotation"
        
        // Add gestures in specific order
        metalView.addGestureRecognizer(pinchGesture)
        metalView.addGestureRecognizer(rotationGesture)
        metalView.addGestureRecognizer(panGesture)
        
        // Print active gesture recognizers
        print("📱 Active gesture recognizers:")
        metalView.gestureRecognizers?.forEach { gesture in
            print(" - \(gesture.name ?? "Unnamed")")
        }
        
        return metalView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {}
    
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var parent: MetalViewRepresentable
        private var lastPanLocation: CGPoint?
        
        init(_ parent: MetalViewRepresentable) {
            self.parent = parent
            super.init()
            print("🎮 Coordinator initialized")
        }
        
        // Allow simultaneous gesture recognition
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, 
                             shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            print("👥 Checking gesture recognition: \(gestureRecognizer.name ?? "Unnamed") with \(otherGestureRecognizer.name ?? "Unnamed")")
            return true
        }
        
        // Ensure gestures can begin
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            print("🎯 Should begin gesture: \(gestureRecognizer.name ?? "Unnamed")")
            return true
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let renderer = parent.renderer else { return }
            
            switch gesture.state {
            case .began:
                lastPanLocation = gesture.location(in: gesture.view)
            case .changed:
                guard let lastLocation = lastPanLocation else { return }
                let currentLocation = gesture.location(in: gesture.view)
                
                let deltaX = Float(currentLocation.x - lastLocation.x)
                let deltaY = Float(currentLocation.y - lastLocation.y)
                
                renderer.camera.orbit(deltaX: deltaX, deltaY: deltaY)
                lastPanLocation = currentLocation
            case .ended, .cancelled:
                lastPanLocation = nil
            default:
                break
            }
        }
        
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let renderer = parent.renderer else { return }
            
            switch gesture.state {
            case .began:
                print("📏 Pinch began: scale = \(gesture.scale)")
            case .changed:
                print("📏 Pinch changed: scale = \(gesture.scale)")
                let factor = Float(1.0 - gesture.scale)
                renderer.camera.zoom(factor: factor)
                gesture.scale = 1.0
            case .ended:
                print("📏 Pinch ended")
            case .failed:
                print("📏 Pinch failed")
            case .cancelled:
                print("📏 Pinch cancelled")
            default:
                break
            }
        }
        
        @objc func handleRotation(_ gesture: UIRotationGestureRecognizer) {
            guard let renderer = parent.renderer else { return }
            
            switch gesture.state {
            case .began:
                print("🔄 Rotation began: rotation = \(gesture.rotation)")
            case .changed:
                print("🔄 Rotation changed: rotation = \(gesture.rotation)")
                // Increase rotation sensitivity significantly
                let angle = Float(-gesture.rotation * 10.0)  // Increased from 3.0 to 10.0
                renderer.camera.roll(angle: angle)
                gesture.rotation = 0
            case .ended:
                print("🔄 Rotation ended")
            case .failed:
                print("🔄 Rotation failed")
            case .cancelled:
                print("🔄 Rotation cancelled")
            default:
                break
            }
        }
    }
} 