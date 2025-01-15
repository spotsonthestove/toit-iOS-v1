import SwiftUI
import MetalKit

struct Engine3DView: View {
    @State private var renderer: Renderer?
    @State private var metalView = MTKView()
    @State private var selectedNodeId: UUID?
    
    var body: some View {
        ZStack {
            MetalViewRepresentable(metalView: metalView, renderer: $renderer, view: self)
                .onAppear {
                    setupRenderer()
                    testCameraSetup()
                    createInitialScene()
                    
                    // Force initial aspect ratio update
                    updateAspectRatio()
                }
                .onDisappear {
                    // Ensure we update aspect ratio when returning to view
                    DispatchQueue.main.async {
                        updateAspectRatio()
                    }
                }
                // Handle both size changes and view appearance
                .onChange(of: metalView.bounds.size) { oldValue, newValue in
                    updateAspectRatio()
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
        
        // Enable debug visualization immediately
        renderer?.enableDebugVisualization(true)
    }
    
    private func testCameraSetup() {
        guard let renderer = renderer else { return }
        
        print("📸 Setting up test camera and debug visualization")
        
        // Enable debug visualization first
        renderer.enableDebugVisualization(true)
        
        // Set up camera
        renderer.camera.position = SIMD3<Float>(0, 0, -5)
        renderer.camera.target = SIMD3<Float>(0, 0, 0)
        
        // Draw debug axes with a larger size for visibility
        renderer.drawDebugAxes(length: 5.0)  // Increased from 2.0 to 5.0
        
        // Print debug info
        print("📸 Camera setup complete:")
        print("  Position: \(renderer.camera.position)")
        print("  Target: \(renderer.camera.target)")
        print("  Debug visualization enabled: \(renderer.isDebugEnabled)")
        print("  Debug renderer exists: \(renderer.debugLineRenderer != nil)")
        renderer.camera.debugPrintCameraMatrix()
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
    
    // MARK: - Node Selection
    
    func handleTap(_ location: CGPoint) {
        print("👆 Handling tap at: \(location)")
        selectNodeAtPoint(location)
    }
    
    private func selectNodeAtPoint(_ point: CGPoint) {
        guard let renderer = renderer else { return }
        
        // Ensure debug visualization is enabled
        if !renderer.isDebugEnabled {
            renderer.enableDebugVisualization(true)
            renderer.drawDebugAxes(length: 5.0)
        }
        
        // Only clear previous selection visualization, not axes
        if let selectedId = selectedNodeId,
           let previousNode = renderer.scene.nodes.first(where: { $0.id == selectedId }) {
            previousNode.deselect()
            // Clear only the previous selection's debug visualization
            renderer.clearDebugLines()
            renderer.drawDebugAxes(length: 5.0)
        }
        
        // Get view and drawable sizes
        let viewSize = metalView.bounds.size
        let drawableSize = metalView.drawableSize
        let scale = metalView.contentScaleFactor
        
        // Convert tap location to normalized device coordinates (-1 to 1)
        let normalizedX = (2.0 * Float(point.x) / Float(viewSize.width)) - 1.0
        let normalizedY = 1.0 - (2.0 * Float(point.y) / Float(viewSize.height))  // Flip Y and normalize
        
        print("📍 Tap coordinates:")
        print("  Screen tap: \(point)")
        print("  View size: \(viewSize)")
        print("  Normalized: (\(normalizedX), \(normalizedY))")
        
        // Create ray in clip space
        let clipCoords = SIMD4<Float>(normalizedX, normalizedY, -1.0, 1.0)
        
        // Transform to view space
        let invProjection = simd_inverse(renderer.camera.projectionMatrix)
        var viewCoords = invProjection * clipCoords
        viewCoords = viewCoords / viewCoords.w
        
        // Create ray direction in world space
        let invView = simd_inverse(renderer.camera.viewMatrix)
        let worldCoords = invView * SIMD4<Float>(viewCoords.x, viewCoords.y, -1.0, 0.0)
        let rayDirection = normalize(SIMD3<Float>(worldCoords.x, worldCoords.y, worldCoords.z))
        
        // Create ray from camera position
        let ray = Ray(origin: renderer.camera.position, direction: rayDirection)
        
        print("🌐 Ray calculation:")
        print("  Camera: \(renderer.camera.position)")
        print("  Direction: \(rayDirection)")
        
        // Draw debug visualization
        renderer.debugDrawLine(
            start: ray.origin,
            end: ray.origin + ray.direction * 10.0,
            color: SIMD4<Float>(1, 1, 1, 0.9)  // White
        )
        
        // Draw points along the ray (cyan)
        for t in stride(from: 1.0, through: 10.0, by: 2.0) {
            let point = ray.origin + ray.direction * Float(t)
            renderer.debugDrawSphere(
                center: point,
                radius: 0.05,
                color: SIMD4<Float>(0, 1, 1, 0.8)
            )
        }
        
        // Draw tap point at target plane distance (magenta)
        let targetDistance = length(renderer.camera.target - renderer.camera.position)
        let tapPoint = ray.origin + ray.direction * targetDistance
        renderer.debugDrawSphere(
            center: tapPoint,
            radius: 0.1,
            color: SIMD4<Float>(1, 0, 1, 1)
        )
        
        // Draw a line from camera to target for reference (blue)
        renderer.debugDrawLine(
            start: renderer.camera.position,
            end: renderer.camera.target,
            color: SIMD4<Float>(0, 0, 1, 0.5)  // Blue
        )
        
        print("🎯 Ray visualization points:")
        print("  Camera position: \(ray.origin)")
        print("  Camera target: \(renderer.camera.target)")
        print("  Target distance: \(targetDistance)")
        print("  Tap world position: \(tapPoint)")
        
        // Use smaller hit radius that matches node scale
        let nodeScale: Float = 0.2  // Typical node size
        let hitRadius: Float = nodeScale * 1.5  // Slightly larger than node for easier selection
        
        // Initialize tracking variables for closest intersection
        var closestNode: Engine3DSceneNode?
        var minDistance = Float.infinity
        
        print("🔍 Testing nodes for intersection (hit radius: \(hitRadius)):")
        for node in renderer.scene.nodes {
            print("  Testing node at position: \(node.position)")
            
            // Calculate distance from camera to node
            let cameraToNode = length(node.position - ray.origin)
            print("  Distance from camera: \(cameraToNode)")
            
            if let intersection = intersectSphere(ray: ray, center: node.position, radius: hitRadius) {
                // The intersection distance is along the ray
                let intersectionPoint = ray.origin + ray.direction * intersection
                let distanceToCamera = length(intersectionPoint - ray.origin)
                
                print("  ✅ Hit node at ray distance: \(intersection)")
                print("  Intersection point: \(intersectionPoint)")
                print("  Distance to camera: \(distanceToCamera)")
                
                // Only update if this is the closest intersection to the camera
                if distanceToCamera < minDistance {
                    minDistance = distanceToCamera
                    closestNode = node
                    print("  📍 New closest node!")
                }
            } else {
                // Calculate closest point on ray for debug visualization
                let toCenter = node.position - ray.origin
                let rayDotCenter = dot(ray.direction, toCenter)
                let closestPoint = ray.origin + ray.direction * rayDotCenter
                let distanceToNode = length(closestPoint - node.position)
                
                print("  ❌ No intersection - closest approach: \(distanceToNode)")
            }
            
            // Draw debug sphere showing hit radius (red for non-selected, green for closest)
            let sphereColor = node === closestNode ? 
                SIMD4<Float>(0.2, 1, 0.2, 0.5) :  // Green for closest
                SIMD4<Float>(1, 0.2, 0.2, 0.5)    // Red for others
            
            renderer.debugDrawSphere(
                center: node.position,
                radius: hitRadius,
                color: sphereColor
            )
        }
        
        // Deselect previously selected node
        if let selectedId = selectedNodeId,
           let previousNode = renderer.scene.nodes.first(where: { $0.id == selectedId }) {
            previousNode.deselect()
        }
        
        // Select new node
        if let node = closestNode {
            selectedNodeId = node.id
            node.select()
            print("✅ Selected node: \(node.id) at position \(node.position)")
            
            // Draw debug sphere around selected node (bright green)
            renderer.debugDrawSphere(
                center: node.position,
                radius: hitRadius * 1.1,
                color: SIMD4<Float>(0.2, 1, 0.2, 0.7)
            )
            
            // Draw line from camera to selected node (green)
            renderer.debugDrawLine(
                start: ray.origin,
                end: node.position,
                color: SIMD4<Float>(0.2, 1, 0.2, 0.7)
            )
        } else {
            selectedNodeId = nil
            print("❌ No node selected - no intersection found")
        }
    }
    
    private func intersectSphere(ray: Ray, center: SIMD3<Float>, radius: Float) -> Float? {
        let oc = ray.origin - center
        let a = dot(ray.direction, ray.direction)  // Should be 1.0 since direction is normalized
        let b = 2.0 * dot(oc, ray.direction)
        let c = dot(oc, oc) - radius * radius
        let discriminant = b * b - 4 * a * c
        
        if discriminant < 0 {
            return nil
        }
        
        // Calculate both intersection points
        let sqrtDisc = sqrt(discriminant)
        let t1 = (-b - sqrtDisc) / (2.0 * a)
        let t2 = (-b + sqrtDisc) / (2.0 * a)
        
        // Return the closest positive intersection
        if t1 > 0 {
            return t1
        } else if t2 > 0 {
            return t2
        }
        return nil
    }
    
    private func updateAspectRatio() {
        guard let renderer = renderer else { return }
        let drawableSize = metalView.drawableSize
        let aspect = Float(drawableSize.width) / Float(drawableSize.height)
        print("📐 Updating aspect ratio: \(aspect)")
        print("  Drawable size: \(drawableSize)")
        print("  View bounds: \(metalView.bounds)")
        renderer.mtkView(metalView, drawableSizeWillChange: drawableSize)
    }
}

struct MetalViewRepresentable: UIViewRepresentable {
    let metalView: MTKView
    @Binding var renderer: Renderer?
    let view: Engine3DView
    
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
        
        // Force initial aspect ratio update
        if let renderer = renderer {
            let size = metalView.drawableSize
            renderer.mtkView(metalView, drawableSizeWillChange: size)
            print("📐 Initial aspect ratio set to: \(Float(size.width) / Float(size.height))")
        }
        
        // Enable user interaction
        metalView.isUserInteractionEnabled = true
        metalView.isMultipleTouchEnabled = true
        print("🔧 Setting up gesture recognizers")
        
        // Add tap gesture first
        let tapGesture = UITapGestureRecognizer(target: context.coordinator,
                                               action: #selector(Coordinator.handleTap(_:)))
        tapGesture.name = "Tap"
        metalView.addGestureRecognizer(tapGesture)
        
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
        
        // Add other gestures
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
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            let location = gesture.location(in: gesture.view)
            print("👆 Tap detected at: \(location)")
            parent.view.handleTap(location)
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

// MARK: - Ray Structure
struct Ray {
    let origin: SIMD3<Float>
    let direction: SIMD3<Float>
} 