import SwiftUI
import SceneKit

struct SceneKitMindMapView: View {
    @StateObject private var viewModel = SceneKitMindMapViewModel()
    
    var body: some View {
        SceneKitView(viewModel: viewModel)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        viewModel.handleDrag(gesture)
                    }
            )
            // Debug controls overlay
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
        viewModel.setSceneView(scnView)
        return scnView
    }
    
    func updateUIView(_ scnView: SCNView, context: Context) {
        // Update view if needed
    }
}

class SceneKitMindMapViewModel: ObservableObject {
    let scene: SCNScene
    let cameraNode: SCNNode
    private var selectedNode: SCNNode?
    private var nodes: [SCNNode] = []
    private weak var sceneView: SCNView?
    
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
        
        let node = SCNNode(geometry: sphere)
        node.position = SCNVector3(x: Float.random(in: -5...5),
                                 y: Float.random(in: -5...5),
                                 z: Float.random(in: -5...5))
        
        // Add physics body for interaction
        node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        node.physicsBody?.isAffectedByGravity = false
        
        scene.rootNode.addChildNode(node)
        nodes.append(node)
    }
    
    func connectSelectedNodes() {
        // TODO: Implement node connection logic
    }
    
    func setSceneView(_ view: SCNView) {
        self.sceneView = view
    }
    
    func handleDrag(_ gesture: DragGesture.Value) {
        guard let sceneView = self.sceneView else { return }
        
        let location = gesture.location
        let hitResults = sceneView.hitTest(CGPoint(x: location.x, y: location.y), options: [:])
        
        if let hitNode = hitResults.first?.node {
            // Skip if we hit an axis or non-draggable node
            guard nodes.contains(hitNode) else { return }
            
            // Convert the drag movement to 3D space
            let dragVector = gesture.translation
            let dragSpeed: Float = 0.01  // Adjust this for sensitivity
            
            // Update node position based on drag
            let cameraPOV = sceneView.pointOfView
            let cameraRight = cameraPOV?.rightVector ?? SCNVector3(1, 0, 0)
            let cameraUp = cameraPOV?.upVector ?? SCNVector3(0, 1, 0)
            
            var newPosition = hitNode.position
            newPosition.add(cameraRight * Float(dragVector.width) * dragSpeed)
            newPosition.add(cameraUp * Float(-dragVector.height) * dragSpeed)
            hitNode.position = newPosition
            
            // Update any connected branches (will implement later)
            updateConnections(for: hitNode)
        }
    }
    
    private func updateConnections(for node: SCNNode) {
        // TODO: Will implement this when we add branch connections
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