import SwiftUI
import MetalKit

struct Engine3DView: View {
    @State private var renderer: Renderer?
    @State private var metalView = MTKView()
    @State private var selectedNodeId: UUID?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                MetalViewRepresentable(metalView: metalView, renderer: $renderer, view: self)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .onAppear {
                        metalView.frame = CGRect(x: 0, y: 0, width: geometry.size.width, height: geometry.size.height)
                        
                        // First set up the renderer
                        setupRenderer()
                        
                        // Then handle all scene setup in a single async block
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            updateAspectRatio()
                            // Skip testCameraSetup since we've fixed the Camera init
                            createInitialScene()
                        }
                    }
                    .onDisappear {
                        renderer = nil
                    }
                    .onChange(of: geometry.size) { oldValue, newValue in
                        metalView.frame = CGRect(x: 0, y: 0, width: newValue.width, height: newValue.height)
                        updateAspectRatio()
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
    }
    
    private func setupRenderer() {
        renderer = Renderer(metalView: metalView)
        print("Renderer setup: \(renderer != nil)")
        
        // Enable debug visualization immediately
        renderer?.enableDebugVisualization(true)
    }
    
    private func testCameraSetup() {
        guard let renderer = renderer else { return }
        
        print("📸 Setting up test camera...")
        
        // Set initial camera position for better view of scene
        renderer.camera.position = SIMD3<Float>(5, 5, 5)  // 45-degree angle view
        renderer.camera.target = SIMD3<Float>(0, 0, 0)    // Looking at center
        renderer.camera.up = SIMD3<Float>(0, 1, 0)        // Keep Y-up orientation
        
        // Enable debug visualization
        renderer.enableDebugVisualization(true)
        renderer.drawDebugAxes(length: 5.0)
        
        print("📸 Camera setup complete:")
        print("  Position: \(renderer.camera.position)")
        print("  Target: \(renderer.camera.target)")
        renderer.camera.debugPrintCameraMatrix()
    }
    
    private func testCameraMovements() {
        guard let renderer = renderer else { return }
        
        // Test orbit movement
        print("Testing orbital movement...")
        print("Initial camera position:", renderer.camera.position)
        
        // Simulate 90-degree orbital rotation
        renderer.camera.orbit(deltaX: Float.pi/2, deltaY: 0)
        print("Camera position after horizontal orbit:", renderer.camera.position)
        
        // Test pan movement
        print("Testing pan movement...")
        renderer.camera.pan(deltaX: 1.0, deltaY: 0)
        print("Camera position after horizontal pan:", renderer.camera.position)
        
        // Reset camera position
        renderer.camera.position = SIMD3<Float>(0, 2, 10)
        renderer.camera.target = SIMD3<Float>(0, 0, 0)
        renderer.camera.up = SIMD3<Float>(0, 1, 0)
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
        
        print("🎨 Creating initial scene...")
        
        // Clear any existing debug visualization and reset
        renderer.clearDebugLines()
        renderer.drawDebugAxes(length: 5.0)
        
        // Draw a ground grid for reference first
        drawDebugGrid(size: 10, divisions: 10)
        
        // Define node configurations with positions and colors
        let nodeConfigs: [(position: SIMD3<Float>, color: SIMD4<Float>)] = [
            // Center node (white)
            (SIMD3<Float>(0, 0, 0), SIMD4<Float>(1, 1, 1, 1)),
            
            // Front nodes (blue)
            (SIMD3<Float>(0, 0, 3), SIMD4<Float>(0, 0, 1, 1)),
            (SIMD3<Float>(3, 0, 3), SIMD4<Float>(0, 0, 1, 1)),
            
            // Back nodes (green)
            (SIMD3<Float>(0, 0, -3), SIMD4<Float>(0, 1, 0, 1)),
            (SIMD3<Float>(-3, 0, -3), SIMD4<Float>(0, 1, 0, 1)),
            
            // Upper nodes (red)
            (SIMD3<Float>(0, 3, 0), SIMD4<Float>(1, 0, 0, 1)),
            (SIMD3<Float>(0, 3, 3), SIMD4<Float>(1, 0, 0, 1))
        ]
        
        // Create nodes
        var nodes: [Engine3DSceneNode] = []
        for (position, color) in nodeConfigs {
            let node = Engine3DSceneNode(position: position, color: color)
            node.setupGeometry(device: renderer.device)
            renderer.scene.addNode(node)
            nodes.append(node)
            
            // Add debug sphere to visualize node position
            renderer.debugDrawSphere(
                center: position,
                radius: 0.2,
                color: SIMD4<Float>(color.x, color.y, color.z, 0.3)
            )
            
            print("📍 Created node at position: \(position) with color: \(color)")
        }
        
        // Create branches between center node and adjacent nodes
        if let centerNode = nodes.first {
            for i in 1..<nodes.count {
                if let branch = centerNode.connect(to: nodes[i], device: renderer.device) {
                    renderer.scene.addBranch(branch)
                    
                    // Add debug line to visualize branch
                    renderer.debugDrawLine(
                        start: centerNode.position,
                        end: nodes[i].position,
                        color: SIMD4<Float>(1, 1, 1, 0.5)
                    )
                    
                    print("🔗 Created branch from center to node \(i)")
                }
            }
            
            // Connect upper nodes to each other
            if let branch = nodes[5].connect(to: nodes[6], device: renderer.device) {
                renderer.scene.addBranch(branch)
                
                // Add debug line for upper connection
                renderer.debugDrawLine(
                    start: nodes[5].position,
                    end: nodes[6].position,
                    color: SIMD4<Float>(1, 1, 1, 0.5)
                )
                
                print("🔗 Connected upper nodes")
            }
        }
        
        print("✅ Created test scene with \(nodes.count) nodes")
    }
    
    private func drawDebugGrid(size: Float, divisions: Int) {
        guard let renderer = renderer else { return }
        
        let step = size / Float(divisions)
        let start = -size / 2
        let end = size / 2
        
        // Draw grid lines
        for i in 0...divisions {
            let position = start + step * Float(i)
            
            // Draw X lines
            renderer.debugDrawLine(
                start: SIMD3<Float>(start, 0, position),
                end: SIMD3<Float>(end, 0, position),
                color: SIMD4<Float>(0.3, 0.3, 0.3, 0.5)
            )
            
            // Draw Z lines
            renderer.debugDrawLine(
                start: SIMD3<Float>(position, 0, start),
                end: SIMD3<Float>(position, 0, end),
                color: SIMD4<Float>(0.3, 0.3, 0.3, 0.5)
            )
        }
        
        // Draw coordinate axes
        renderer.debugDrawLine(
            start: SIMD3<Float>(0, 0, 0),
            end: SIMD3<Float>(size/2, 0, 0),
            color: SIMD4<Float>(1, 0, 0, 1)  // X axis - red
        )
        renderer.debugDrawLine(
            start: SIMD3<Float>(0, 0, 0),
            end: SIMD3<Float>(0, size/2, 0),
            color: SIMD4<Float>(0, 1, 0, 1)  // Y axis - green
        )
        renderer.debugDrawLine(
            start: SIMD3<Float>(0, 0, 0),
            end: SIMD3<Float>(0, 0, size/2),
            color: SIMD4<Float>(0, 0, 1, 1)  // Z axis - blue
        )
    }
    
    // MARK: - Node Selection
    
    func handleTap(_ location: CGPoint) {
        print("👆 Handling tap at: \(location)")
        selectNodeAtPoint(location)
    }
    
    private func selectNodeAtPoint(_ point: CGPoint) {
        guard let renderer = renderer else { return }
        
        // Clear previous debug visualization but keep axes
        renderer.clearDebugLines()
        renderer.drawDebugAxes(length: 5.0)
        
        // Get view and drawable sizes for proper scaling
        let viewSize = metalView.bounds.size
        let drawableSize = metalView.drawableSize
        
        // Convert tap location to drawable space first
        let drawableX = point.x * drawableSize.width / viewSize.width
        let drawableY = point.y * drawableSize.height / viewSize.height
        
        // Convert to normalized device coordinates (-1 to 1)
        let normalizedX = (2.0 * Float(drawableX) / Float(drawableSize.width)) - 1.0
        let normalizedY = -((2.0 * Float(drawableY) / Float(drawableSize.height)) - 1.0)  // Flip Y and negate
        
        print("📍 Tap coordinates:")
        print("  Screen tap: \(point)")
        print("  Drawable coords: (\(drawableX), \(drawableY))")
        print("  View size: \(viewSize)")
        print("  Drawable size: \(drawableSize)")
        print("  Normalized: (\(normalizedX), \(normalizedY))")
        
        // Create ray in clip space (use -1 for near plane, 1 for far plane)
        let clipNear = SIMD4<Float>(normalizedX, normalizedY, -1.0, 1.0)
        let clipFar = SIMD4<Float>(normalizedX, normalizedY, 1.0, 1.0)
        
        // Transform to view space
        let invProjection = simd_inverse(renderer.camera.projectionMatrix)
        var viewNear = invProjection * clipNear
        var viewFar = invProjection * clipFar
        
        // Perform perspective divide
        viewNear = viewNear / viewNear.w
        viewFar = viewFar / viewFar.w
        
        // Transform to world space
        let invView = simd_inverse(renderer.camera.viewMatrix)
        let worldNear = invView * viewNear
        let worldFar = invView * viewFar
        
        // Create ray from near to far points
        let rayOrigin = SIMD3<Float>(worldNear.x, worldNear.y, worldNear.z)
        let rayTarget = SIMD3<Float>(worldFar.x, worldFar.y, worldFar.z)
        let rayDirection = normalize(rayTarget - rayOrigin)
        
        let ray = Ray(origin: rayOrigin, direction: rayDirection)
        
        print("🌐 Ray calculation:")
        print("  Origin: \(rayOrigin)")
        print("  Target: \(rayTarget)")
        print("  Direction: \(rayDirection)")
        
        // Draw ray path for debugging (white)
        renderer.debugDrawLine(
            start: ray.origin,
            end: ray.origin + ray.direction * 10.0,
            color: SIMD4<Float>(1, 1, 1, 0.5)
        )
        
        // Add debug points along ray path
        for t in stride(from: 0.0, through: 10.0, by: 0.5) {
            let point = ray.origin + ray.direction * Float(t)
            renderer.debugDrawSphere(
                center: point,
                radius: 0.02,
                color: SIMD4<Float>(1, 1, 0, 0.5)
            )
        }
        
        // Calculate hit testing parameters
        let nodeScale: Float = 0.2  // Base node size
        let baseHitRadius: Float = nodeScale * 2.0  // Increased from 1.5 to 2.0
        
        // Initialize tracking variables for closest intersection
        var closestNode: Engine3DSceneNode?
        var minDistance = Float.infinity
        var closestIntersectionPoint: SIMD3<Float>?
        
        print("🔍 Testing nodes for intersection (base hit radius: \(baseHitRadius)):")
        for node in renderer.scene.nodes {
            // Calculate distance-based hit radius
            let distanceToCamera = length(node.position - ray.origin)
            let hitRadius = baseHitRadius * (1.0 + distanceToCamera * 0.15)  // Increased from 0.1 to 0.15
            
            print("  Testing node at position: \(node.position)")
            print("  Distance from camera: \(distanceToCamera)")
            print("  Adjusted hit radius: \(hitRadius)")
            
            // Draw hit testing sphere for debugging
            renderer.debugDrawSphere(
                center: node.position,
                radius: hitRadius,
                color: SIMD4<Float>(1, 0, 0, 0.1)
            )
            
            // Calculate closest point on ray to node center
            let toCenter = node.position - ray.origin
            let projection = dot(toCenter, ray.direction)
            let closestPoint = ray.origin + ray.direction * max(0, projection)
            let distanceToRay = length(node.position - closestPoint)
            
            print("  Distance to ray: \(distanceToRay)")
            
            if distanceToRay <= hitRadius {
                let distanceToIntersection = length(closestPoint - ray.origin)
                
                print("  ✅ Hit at distance: \(distanceToIntersection)")
                
                // Update if this is the closest valid intersection
                if distanceToIntersection < minDistance {
                    minDistance = distanceToIntersection
                    closestNode = node
                    closestIntersectionPoint = closestPoint
                    
                    // Draw intersection point (yellow)
                    renderer.debugDrawSphere(
                        center: closestPoint,
                        radius: 0.05,
                        color: SIMD4<Float>(1, 1, 0, 1)
                    )
                    
                    // Draw line from ray to node center (cyan)
                    renderer.debugDrawLine(
                        start: closestPoint,
                        end: node.position,
                        color: SIMD4<Float>(0, 1, 1, 0.5)
                    )
                }
            }
        }
        
        // Update selection
        if let selectedId = selectedNodeId,
           let previousNode = renderer.scene.nodes.first(where: { $0.id == selectedId }) {
            previousNode.deselect()
        }
        
        if let node = closestNode,
           let intersectionPoint = closestIntersectionPoint {
            selectedNodeId = node.id
            node.select()
            
            print("✅ Selected node: \(node.id)")
            print("  Position: \(node.position)")
            print("  Intersection point: \(intersectionPoint)")
            
            // Draw selection visualization
            renderer.debugDrawSphere(
                center: node.position,
                radius: baseHitRadius * 1.2,
                color: SIMD4<Float>(0, 1, 0, 0.5)  // Bright green
            )
            
            // Draw line from camera to selected node
            renderer.debugDrawLine(
                start: ray.origin,
                end: intersectionPoint,
                color: SIMD4<Float>(0, 1, 0, 0.8)  // Bright green
            )
        } else {
            selectedNodeId = nil
            print("❌ No node selected")
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
        guard let renderer = renderer,
              metalView.bounds.size.width > 0,
              metalView.bounds.size.height > 0 else {
            print("⚠️ Cannot update aspect ratio - invalid view size or missing renderer")
            return
        }
        
        let aspect = Float(metalView.bounds.size.width / metalView.bounds.size.height)
        print("📐 Updating aspect ratio: \(aspect)")
        print("  Drawable size: \(metalView.drawableSize)")
        print("  View bounds: \(metalView.bounds)")
        
        renderer.camera.updateProjection(aspect: aspect)
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
                print(" \(gesture.numberOfTouches == 1 ? "Orbit" : "Pan") began at: \(lastPanLocation!)")
            case .changed:
                guard let lastLocation = lastPanLocation,
                      let view = gesture.view else { return }
                
                let currentLocation = gesture.location(in: view)
                
                // Calculate delta in view space coordinates
                let deltaX = Float(currentLocation.x - lastLocation.x)
                let deltaY = Float(currentLocation.y - lastLocation.y)
                
                // Scale deltas based on view size for consistent movement
                let viewSize = view.bounds.size
                let scaledDeltaX = deltaX / Float(viewSize.width) * 2.0  // Reduced scaling for more precise control
                let scaledDeltaY = deltaY / Float(viewSize.height) * 2.0
                
                if gesture.numberOfTouches == 1 {
                    // Single finger: orbit (like rotating a globe)
                    renderer.camera.orbit(deltaX: scaledDeltaX, deltaY: scaledDeltaY)
                    print("🔄 Orbit updated - Delta: (\(scaledDeltaX), \(scaledDeltaY))")
                } else if gesture.numberOfTouches == 2 {
                    // Two fingers: pan (parallel to view plane)
                    renderer.camera.pan(deltaX: scaledDeltaX, deltaY: scaledDeltaY)
                    print("✋ Pan updated - Delta: (\(scaledDeltaX), \(scaledDeltaY))")
                }
                
                lastPanLocation = currentLocation
            case .ended, .cancelled:
                lastPanLocation = nil
                print("�� \(gesture.numberOfTouches == 1 ? "Orbit" : "Pan") ended")
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