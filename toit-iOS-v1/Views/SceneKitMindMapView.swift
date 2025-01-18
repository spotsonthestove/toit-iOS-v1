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
    @Published private var nodePositions: [UUID: SCNVector3] = [:]
    @Published private var connections: [UUID: Set<UUID>] = [:]
    private var nodes: [UUID: SCNNode] = [:]
    private var branches: [String: SCNNode] = [:]
    weak var sceneView: SCNView?
    
    // Track parent and child selection for connections
    private var parentNode: SCNNode?
    private var childNode: SCNNode?
    
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
        sphere.firstMaterial?.specular.contents = UIColor.white
        
        let node = SCNNode(geometry: sphere)
        let position = SCNVector3(x: Float.random(in: -5...5),
                                y: Float.random(in: -5...5),
                                z: Float.random(in: -5...5))
        node.position = position
        
        // Store node with unique identifier
        let nodeId = UUID()
        nodes[nodeId] = node
        nodePositions[nodeId] = position
        
        // Add physics body and other properties as before
        node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: sphere, options: nil))
        node.physicsBody?.isAffectedByGravity = false
        node.physicsBody?.mass = 0.1
        
        // Store node ID as user data
        node.setValue(nodeId, forKey: "nodeId")
        
        scene.rootNode.addChildNode(node)
    }
    
    func connectSelectedNodes() {
        guard let parent = parentNode, let child = childNode,
              let parentId = parent.value(forKey: "nodeId") as? UUID,
              let childId = child.value(forKey: "nodeId") as? UUID else { return }
        
        // Store connection in our data structure
        connections[parentId, default: []].insert(childId)
        
        createBranch(from: parent, to: child)
        
        // Reset selections after connecting
        resetNodeSelections()
    }
    
    private func createBranch(from parent: SCNNode, to child: SCNNode) {
        guard let parentId = parent.value(forKey: "nodeId") as? UUID,
              let childId = child.value(forKey: "nodeId") as? UUID else { return }
        
        let branchId = "\(parentId.uuidString)-\(childId.uuidString)"
        
        // Remove existing branch if any
        branches[branchId]?.removeFromParentNode()
        
        // Get node radius (assuming both nodes are spheres with same radius)
        let nodeRadius: Float = 0.5 // This should match the sphere radius we set in addNode()
        
        // Calculate direction vector from parent to child
        let direction = child.position - parent.position
        let distance = direction.length()
        
        // Calculate normalized direction for precise surface points
        let normalizedDirection = direction.normalized()
        
        // Calculate exact connection points on sphere surfaces
        let startPoint = parent.position + (normalizedDirection * nodeRadius)
        let endPoint = child.position - (normalizedDirection * nodeRadius)
        
        // Calculate actual branch length (between surface points)
        let branchLength = (endPoint - startPoint).length()
        
        // Create branch geometry
        let branchGeometry = SCNCylinder(radius: 0.1, height: CGFloat(branchLength))
        branchGeometry.firstMaterial?.diffuse.contents = UIColor.gray
        
        let branchNode = SCNNode(geometry: branchGeometry)
        
        // Position branch at midpoint between surface points
        let midPoint = (startPoint + endPoint) * 0.5
        branchNode.position = midPoint
        
        // Calculate rotation to align branch with direction
        // By default, SCNCylinder is oriented along the y-axis
        // We need to rotate it to align with our direction vector
        let up = SCNVector3(0, 1, 0) // Default cylinder orientation
        let rotationAxis = up.cross(normalizedDirection)
        let rotationAngle = acos(up.dot(normalizedDirection))
        
        if rotationAxis.length() > 0.0001 { // Avoid rotation if vectors are parallel
            branchNode.rotation = SCNVector4(
                rotationAxis.x,
                rotationAxis.y,
                rotationAxis.z,
                rotationAngle
            )
        }
        
        // Store branch for future updates
        branches[branchId] = branchNode
        scene.rootNode.addChildNode(branchNode)
    }
    
    private func updateBranchImmediate(parent: SCNNode, child: SCNNode) {
        guard let parentId = parent.value(forKey: "nodeId") as? UUID,
              let childId = child.value(forKey: "nodeId") as? UUID else { return }
        
        let branchId = "\(parentId.uuidString)-\(childId.uuidString)"
        guard let branchNode = branches[branchId] else { return }
        
        let nodeRadius: Float = 0.5
        
        // Calculate new positions and orientation
        let direction = child.position - parent.position
        let distance = direction.length()
        let normalizedDirection = direction.normalized()
        
        let startPoint = parent.position + (normalizedDirection * nodeRadius)
        let endPoint = child.position - (normalizedDirection * nodeRadius)
        
        // Update branch length
        let branchLength = (endPoint - startPoint).length()
        if let cylinder = branchNode.geometry as? SCNCylinder {
            cylinder.height = CGFloat(branchLength)
        }
        
        // Update position and orientation
        let midPoint = (startPoint + endPoint) * 0.5
        branchNode.position = midPoint
        
        // Calculate rotation to align branch with direction
        let up = SCNVector3(0, 1, 0) // Default cylinder orientation
        let rotationAxis = up.cross(normalizedDirection)
        let rotationAngle = acos(up.dot(normalizedDirection))
        
        if rotationAxis.length() > 0.0001 { // Avoid rotation if vectors are parallel
            branchNode.rotation = SCNVector4(
                rotationAxis.x,
                rotationAxis.y,
                rotationAxis.z,
                rotationAngle
            )
        }
    }
    
    private func updateConnectedBranches(for node: SCNNode) {
        guard let nodeId = node.value(forKey: "nodeId") as? UUID else { return }
        
        // Update branches where this node is the parent
        if let childIds = connections[nodeId] {
            for childId in childIds {
                if let childNode = nodes[childId] {
                    updateBranchImmediate(parent: node, child: childNode)
                }
            }
        }
        
        // Update branches where this node is the child
        for (parentId, children) in connections {
            if children.contains(nodeId), let parentNode = nodes[parentId] {
                updateBranchImmediate(parent: parentNode, child: node)
            }
        }
    }
    
    func continueDrag(_ gesture: UIPanGestureRecognizer) {
        guard let sceneView = sceneView,
              let draggedNode = draggedNode,
              let lastLocation = lastDragLocation else { return }
        
        let location = gesture.location(in: sceneView)
        let deltaX = Float(location.x - lastLocation.x)
        let deltaY = Float(location.y - lastLocation.y)
        
        // Get the current camera orientation
        let cameraOrientation = sceneView.pointOfView?.orientation ?? SCNQuaternion()
        
        // Calculate movement in camera's coordinate system
        let dragSpeed: Float = 0.01
        let deltaPosition = SCNVector3(
            x: deltaX * dragSpeed,
            y: -deltaY * dragSpeed,
            z: 0
        )
        
        // Apply camera orientation to movement
        let rotatedDelta = deltaPosition.rotated(by: cameraOrientation)
        draggedNode.position += rotatedDelta
        
        // Update connected branches immediately
        updateConnectedBranches(for: draggedNode)
        
        // Update stored position
        if let nodeId = draggedNode.value(forKey: "nodeId") as? UUID {
            nodePositions[nodeId] = draggedNode.position
        }
        
        lastDragLocation = location
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
    
    func handleTap(_ gestureRecognize: UITapGestureRecognizer) {
        guard let sceneView = self.sceneView else { return }
        
        let location = gestureRecognize.location(in: sceneView)
        let hitResults = sceneView.hitTest(location, options: [
            .searchMode: SCNHitTestSearchMode.closest.rawValue,
            .boundingBoxOnly: true
        ])
        
        if let hitNode = hitResults.first?.node, nodes.contains(hitNode) {
            // If no parent selected, set as parent
            if parentNode == nil {
                // Reset previous selections
                selectedNode?.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
                childNode?.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
                
                parentNode = hitNode
                selectedNode = hitNode
                hitNode.geometry?.firstMaterial?.diffuse.contents = UIColor.systemGreen
                childNode = nil
            } else if hitNode != parentNode {
                // If parent exists and different node hit, set as child
                childNode = hitNode
                hitNode.geometry?.firstMaterial?.diffuse.contents = UIColor.systemYellow
            }
        } else {
            // Reset all if clicking empty space
            selectedNode?.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
            parentNode?.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
            childNode?.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
            selectedNode = nil
            parentNode = nil
            childNode = nil
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
    
    private func updateNodePosition(_ node: SCNNode, to position: SCNVector3) {
        guard let nodeId = node.value(forKey: "nodeId") as? UUID else { return }
        
        // Update stored position
        nodePositions[nodeId] = position
        node.position = position
        
        // Update connected branches
        updateConnectedBranches(for: node)
    }
    
    // Helper method to generate consistent branch IDs
    private func getBranchId(from parentId: UUID, to childId: UUID) -> String {
        return "\(min(parentId.uuidString, childId.uuidString))-\(max(parentId.uuidString, childId.uuidString))"
    }
    
    // Add method to export node positions and connections
    func exportMindMapData() -> MindMapData {
        return MindMapData(
            nodePositions: nodePositions,
            connections: connections
        )
    }
    
    // Add method to import node positions and connections
    func importMindMapData(_ data: MindMapData) {
        clearScene()
        
        // Recreate nodes with explicit conversion
        for (nodeId, position) in data.nodePositions {
            createNode(id: nodeId, at: position.toSCNVector3())
        }
        
        // Recreate connections
        for (parentId, childIds) in data.connections {
            for childId in childIds {
                if let parentNode = nodes[parentId],
                   let childNode = nodes[childId] {
                    createBranch(from: parentNode, to: childNode)
                }
            }
        }
    }
    
    // Add helper method to reset selections
    private func resetNodeSelections() {
        selectedNode?.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
        parentNode?.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
        childNode?.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
        selectedNode = nil
        parentNode = nil
        childNode = nil
    }
    
    // Add clearScene method
    private func clearScene() {
        // Remove all nodes except camera and lights
        for node in scene.rootNode.childNodes {
            if node != cameraNode && node.light == nil {
                node.removeFromParentNode()
            }
        }
        // Clear our data structures
        nodes.removeAll()
        branches.removeAll()
        nodePositions.removeAll()
        connections.removeAll()
    }
    
    // Add createNode method
    private func createNode(id: UUID, at position: SCNVector3) {
        let sphere = SCNSphere(radius: 0.5)
        sphere.firstMaterial?.diffuse.contents = UIColor.systemBlue
        sphere.firstMaterial?.specular.contents = UIColor.white
        
        let node = SCNNode(geometry: sphere)
        node.position = position
        
        // Store node with provided identifier
        nodes[id] = node
        nodePositions[id] = position
        
        // Add physics body
        node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: sphere, options: nil))
        node.physicsBody?.isAffectedByGravity = false
        node.physicsBody?.mass = 0.1
        
        // Store node ID as user data
        node.setValue(id, forKey: "nodeId")
        
        scene.rootNode.addChildNode(node)
    }
    
    // Add setSceneView method
    func setSceneView(_ view: SCNView) {
        self.sceneView = view
    }
    
    // Add startDrag method
    func startDrag(_ gesture: UIPanGestureRecognizer) {
        guard let sceneView = self.sceneView else { return }
        let location = gesture.location(in: sceneView)
        
        // Only perform hit test if we're not already dragging
        guard draggedNode == nil else { return }
        
        let hitResults = sceneView.hitTest(location, options: [
            .searchMode: SCNHitTestSearchMode.closest.rawValue,
            .boundingBoxOnly: true
        ])
        
        if let hitNode = hitResults.first?.node, nodes.contains(hitNode) {
            draggedNode = hitNode
            lastDragLocation = location
            
            // Highlight dragged node
            hitNode.geometry?.firstMaterial?.diffuse.contents = UIColor.systemOrange
            
            // Disable camera control while dragging
            sceneView.allowsCameraControl = false
        }
    }
}

// Update Dictionary extension to work with UUID keys
extension Dictionary where Key == UUID, Value == SCNNode {
    func findNode(withHash hash: Int) -> SCNNode? {
        return self.values.first { $0.hash == hash }
    }
}

// Update Vector3 struct and conversion methods
struct MindMapData: Codable {
    struct Vector3: Codable {
        let x, y, z: Float
        
        init(from vector: SCNVector3) {
            self.x = vector.x
            self.y = vector.y
            self.z = vector.z
        }
        
        // Add explicit conversion method
        func toSCNVector3() -> SCNVector3 {
            return SCNVector3(x: x, y: y, z: z)
        }
    }
    
    let nodePositions: [UUID: Vector3]
    let connections: [UUID: Set<UUID>]
    
    init(nodePositions: [UUID: SCNVector3], connections: [UUID: Set<UUID>]) {
        self.nodePositions = nodePositions.mapValues { Vector3(from: $0) }
        self.connections = connections
    }
}

// Add Dictionary extension for contains check
extension Dictionary where Value: AnyObject {
    func contains(_ value: Value) -> Bool {
        return self.values.contains { $0 === value }
    }
}

// MARK: - Vector Extensions
extension SCNVector3 {
    static func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3(left.x + right.x, left.y + right.y, left.z + right.z)
    }
    
    static func -(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3(left.x - right.x, left.y - right.y, left.z - right.z)
    }
    
    static func *(left: SCNVector3, right: Float) -> SCNVector3 {
        return SCNVector3(left.x * right, left.y * right, left.z * right)
    }
    
    static func /(left: SCNVector3, right: Float) -> SCNVector3 {
        return SCNVector3(left.x / right, left.y / right, left.z / right)
    }
    
    static func +=(left: inout SCNVector3, right: SCNVector3) {
        left = left + right
    }
    
    func length() -> Float {
        return sqrt(x * x + y * y + z * z)
    }
    
    func normalized() -> SCNVector3 {
        let len = length()
        guard len > 0 else { return self }
        return self / len
    }
    
    func rotated(by quaternion: SCNQuaternion) -> SCNVector3 {
        let qv = SCNVector3(quaternion.x, quaternion.y, quaternion.z)
        let uv = qv.cross(self)
        let uuv = qv.cross(uv)
        return self + ((uv * 2.0 * quaternion.w) + (uuv * 2.0))
    }
    
    func cross(_ vector: SCNVector3) -> SCNVector3 {
        return SCNVector3(y * vector.z - z * vector.y,
                         z * vector.x - x * vector.z,
                         x * vector.y - y * vector.x)
    }
    
    func dot(_ vector: SCNVector3) -> Float {
        return x * vector.x + y * vector.y + z * vector.z
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