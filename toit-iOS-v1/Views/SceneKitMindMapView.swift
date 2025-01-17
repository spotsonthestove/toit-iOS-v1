import SwiftUI
import SceneKit

struct SceneKitMindMapView: View {
    @StateObject private var viewModel = SceneKitMindMapViewModel()
    
    var body: some View {
        SceneKitView(viewModel: viewModel)
            .overlay(alignment: .bottom) {
                HStack {
                    Button(action: viewModel.addNode) {
                        Label("Add Node", systemImage: "plus.circle.fill")
                            .padding()
                            .background(Color.blue.opacity(0.7))
                            .cornerRadius(10)
                    }
                    
                    Button(action: viewModel.connectSelectedNodes) {
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

struct SceneKitView: UIViewRepresentable {
    var viewModel: SceneKitMindMapViewModel
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = viewModel.scene
        scnView.pointOfView = viewModel.cameraNode
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = true
        scnView.backgroundColor = .clear
        
        // Add tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)
        
        // Add pan gesture for dragging with higher priority than camera controls
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        panGesture.delegate = context.coordinator
        // Set this gesture to have higher priority
        panGesture.requiresExclusiveTouchType = true
        scnView.addGestureRecognizer(panGesture)
        
        viewModel.setSceneView(scnView)
        return scnView
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }
    
    func updateUIView(_ scnView: SCNView, context: Context) {
        // Update view if needed
    }
    
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var viewModel: SceneKitMindMapViewModel
        
        init(viewModel: SceneKitMindMapViewModel) {
            self.viewModel = viewModel
        }
        
        @objc func handleTap(_ gestureRecognize: UITapGestureRecognizer) {
            viewModel.handleTap(gestureRecognize)
        }
        
        @objc func handlePan(_ gestureRecognize: UIPanGestureRecognizer) {
            switch gestureRecognize.state {
            case .began:
                viewModel.startDrag(gestureRecognize)
            case .changed:
                if viewModel.isDraggingNode {
                    viewModel.continueDrag(gestureRecognize)
                }
            case .ended, .cancelled:
                viewModel.endDrag()
            default:
                break
            }
        }
        
        // UIGestureRecognizerDelegate method
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            // If we're dragging a node, prevent other gestures
            if viewModel.isDraggingNode {
                return false
            }
            
            // If this is our pan gesture starting, let's check if we're hitting a node
            if let panGesture = gestureRecognizer as? UIPanGestureRecognizer,
               panGesture.state == .began,
               let sceneView = viewModel.sceneView {
                let location = panGesture.location(in: sceneView)
                if viewModel.wouldHitNode(at: location) {
                    // If we're going to hit a node, prevent camera gestures
                    return false
                }
            }
            
            // Otherwise, allow simultaneous recognition
            return true
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            // If we're the pan gesture and we're hitting a node, we should take precedence
            if let panGesture = gestureRecognizer as? UIPanGestureRecognizer,
               let sceneView = viewModel.sceneView {
                let location = panGesture.location(in: sceneView)
                return viewModel.wouldHitNode(at: location)
            }
            return false
        }
    }
}

class SceneKitMindMapViewModel: ObservableObject {
    let scene: SCNScene
    let cameraNode: SCNNode
    private var selectedNode: SCNNode?
    private var draggedNode: SCNNode?
    private var lastDragLocation: CGPoint?
    private var nodes: [SCNNode] = []
    weak var sceneView: SCNView?
    
    init() {
        scene = SCNScene()
        
        // Setup camera
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
        scene.rootNode.addChildNode(cameraNode)
        
        // Add ambient light
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLight)
        
        // Add omnidirectional light
        let omniLight = SCNNode()
        omniLight.light = SCNLight()
        omniLight.light?.type = .omni
        omniLight.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(omniLight)
        
        setupInitialScene()
    }
    
    private func setupInitialScene() {
        // Add coordinate axes for reference
        let axesNode = createAxes(length: 10)
        scene.rootNode.addChildNode(axesNode)
    }
    
    private func createAxes(length: CGFloat) -> SCNNode {
        let axesNode = SCNNode()
        
        // X axis (red)
        let xAxis = SCNNode(geometry: SCNCylinder(radius: 0.02, height: length))
        xAxis.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        xAxis.position = SCNVector3(x: Float(length/2), y: 0, z: 0)
        xAxis.eulerAngles = SCNVector3(0, 0, Float.pi/2)
        axesNode.addChildNode(xAxis)
        
        // Y axis (green)
        let yAxis = SCNNode(geometry: SCNCylinder(radius: 0.02, height: length))
        yAxis.geometry?.firstMaterial?.diffuse.contents = UIColor.green
        yAxis.position = SCNVector3(x: 0, y: Float(length/2), z: 0)
        axesNode.addChildNode(yAxis)
        
        // Z axis (blue)
        let zAxis = SCNNode(geometry: SCNCylinder(radius: 0.02, height: length))
        zAxis.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        zAxis.position = SCNVector3(x: 0, y: 0, z: Float(length/2))
        zAxis.eulerAngles = SCNVector3(Float.pi/2, 0, 0)
        axesNode.addChildNode(zAxis)
        
        return axesNode
    }
    
    func addNode() {
        let sphere = SCNSphere(radius: 0.5)
        sphere.firstMaterial?.diffuse.contents = UIColor.systemBlue
        sphere.firstMaterial?.specular.contents = UIColor.white // Add shininess
        
        let node = SCNNode(geometry: sphere)
        node.position = SCNVector3(x: Float.random(in: -5...5),
                                 y: Float.random(in: -5...5),
                                 z: Float.random(in: -5...5))
        
        // Add physics body for interaction
        node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: sphere, options: nil))
        node.physicsBody?.isAffectedByGravity = false
        node.physicsBody?.mass = 0.1
        node.physicsBody?.categoryBitMask = 1
        node.physicsBody?.collisionBitMask = 1
        
        scene.rootNode.addChildNode(node)
        nodes.append(node)
    }
    
    func connectSelectedNodes() {
        // TODO: Implement node connection logic
    }
    
    func setSceneView(_ view: SCNView) {
        self.sceneView = view
    }
    
    func startDrag(_ gesture: UIPanGestureRecognizer) {
        guard let sceneView = self.sceneView else { return }
        let location = gesture.location(in: sceneView)
        
        // Only perform hit test if we're not already dragging
        guard draggedNode == nil else { return }
        
        let hitResults = sceneView.hitTest(location, options: [
            .searchMode: SCNHitTestSearchMode.closest.rawValue,
            .boundingBoxOnly: true
        ])
        
        if let hitNode = hitResults.first?.node {
            // Skip if we hit an axis or non-draggable node
            guard nodes.contains(hitNode) else { return }
            draggedNode = hitNode
            lastDragLocation = location
            
            // Highlight dragged node
            hitNode.geometry?.firstMaterial?.diffuse.contents = UIColor.systemOrange
            
            // Disable camera control while dragging
            sceneView.allowsCameraControl = false
        }
    }
    
    func continueDrag(_ gesture: UIPanGestureRecognizer) {
        guard let sceneView = self.sceneView,
              let node = draggedNode,
              let lastLocation = lastDragLocation else { return }
        
        let location = gesture.location(in: sceneView)
        
        // Calculate drag delta in screen coordinates
        let deltaX = Float(location.x - lastLocation.x)
        let deltaY = Float(location.y - lastLocation.y)
        
        // Get camera orientation vectors
        let cameraPOV = sceneView.pointOfView
        let cameraRight = cameraPOV?.rightVector ?? SCNVector3(1, 0, 0)
        let cameraUp = cameraPOV?.upVector ?? SCNVector3(0, 1, 0)
        
        // Scale the movement
        let dragSpeed: Float = 0.01
        
        // Update node position
        var newPosition = node.position
        newPosition.add(cameraRight * deltaX * dragSpeed)
        newPosition.add(cameraUp * -deltaY * dragSpeed)
        node.position = newPosition
        
        // Store current location for next frame
        lastDragLocation = location
        
        // Update any connected branches
        updateConnections(for: node)
    }
    
    func endDrag() {
        // Reset node color if it wasn't previously selected
        if let node = draggedNode {
            if node != selectedNode {
                node.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
            }
        }
        
        // Re-enable camera control
        sceneView?.allowsCameraControl = true
        
        draggedNode = nil
        lastDragLocation = nil
    }
    
    private func updateConnections(for node: SCNNode) {
        // TODO: Will implement this when we add branch connections
    }
    
    func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        guard let sceneView = self.sceneView else { return }
        
        // Get tap location
        let location = gestureRecognize.location(in: sceneView)
        let hitResults = sceneView.hitTest(location, options: [
            .searchMode: SCNHitTestSearchMode.closest.rawValue,
            .boundingBoxOnly: true
        ])
        
        // Reset previous selection
        selectedNode?.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
        
        if let hitNode = hitResults.first?.node, nodes.contains(hitNode) {
            selectedNode = hitNode
            // Highlight selected node
            hitNode.geometry?.firstMaterial?.diffuse.contents = UIColor.systemGreen
        } else {
            selectedNode = nil
        }
    }
    
    // Add property to track dragging state
    var isDraggingNode: Bool {
        draggedNode != nil
    }
    
    // Helper method to check if we would hit a node at a given point
    func wouldHitNode(at location: CGPoint) -> Bool {
        guard let sceneView = self.sceneView else { return false }
        
        let hitResults = sceneView.hitTest(location, options: [
            .searchMode: SCNHitTestSearchMode.closest.rawValue,
            .boundingBoxOnly: true
        ])
        
        if let hitNode = hitResults.first?.node {
            return nodes.contains(hitNode)
        }
        return false
    }
}

// MARK: - Vector Extensions
extension SCNVector3 {
    static func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3(left.x + right.x, left.y + right.y, left.z + right.z)
    }
    
    static func * (left: SCNVector3, right: Float) -> SCNVector3 {
        return SCNVector3(left.x * right, left.y * right, left.z * right)
    }
    
    mutating func add(_ vector: SCNVector3) {
        self.x += vector.x
        self.y += vector.y
        self.z += vector.z
    }
}

extension SCNNode {
    var rightVector: SCNVector3 {
        return SCNVector3(
            transform.m11,
            transform.m12,
            transform.m13
        )
    }
    
    var upVector: SCNVector3 {
        return SCNVector3(
            transform.m21,
            transform.m22,
            transform.m23
        )
    }
}

#Preview {
    SceneKitMindMapView()
}