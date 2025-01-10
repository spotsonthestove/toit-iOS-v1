import SwiftUI
import MetalKit

struct Engine3DTestView: View {
    @State private var renderer: TestRenderer?
    @State private var metalView = MTKView()
    @State private var selectedNodeId: UUID?
    
    var body: some View {
        ZStack {
            TestMetalViewRepresentable(metalView: metalView, renderer: $renderer)
                .onAppear {
                    setupRenderer()
                    createTestScene()
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
                    
                    Button(action: connectSelectedNodes) {
                        Label("Connect", systemImage: "link.circle.fill")
                            .padding()
                            .background(Color.green.opacity(0.7))
                            .cornerRadius(10)
                    }
                }
                .padding()
                .padding(.bottom, 60) // Add extra padding for tab bar
            }
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 50) // Reserve space for tab bar
        }
    }
    
    private func setupRenderer() {
        renderer = TestRenderer(metalView: metalView)
        print("Renderer setup: \(renderer != nil)")
    }
    
    private func createTestScene() {
        guard let renderer = renderer else {
            print("❌ Failed to create test scene - renderer is nil")
            return
        }
        
        print("Creating test scene...")
        
        // Create two initial test nodes
        let rootNode = TestSceneNode(
            id: UUID(),
            title: "Root Node",
            position: SIMD3<Float>(0, 0, 0)
        )
        let childNode = TestSceneNode(
            id: UUID(),
            title: "Child Node",
            position: SIMD3<Float>(1, 0, 0)
        )
        
        // Setup node geometries
        rootNode.setupGeometry(device: renderer.device)
        childNode.setupGeometry(device: renderer.device)
        
        // Add nodes to scene
        renderer.scene.addNode(rootNode)
        renderer.scene.addNode(childNode)
        
        // Create a branch between them
        let branch = rootNode.connect(to: childNode, device: renderer.device)
        renderer.scene.addBranch(branch)
        
        print("✅ Test scene created with \(renderer.scene.nodes.count) nodes")
    }
    
    private func addNode() {
        let newNode = TestSceneNode(
            id: UUID(),
            title: "New Node",
            position: SIMD3<Float>(0, 0, 0)
        )
        renderer?.scene.addNode(newNode)
    }
    
    private func connectSelectedNodes() {
        guard let renderer = renderer else { return }
        _ = renderer.connectSelectedNodes(device: renderer.device)
    }
}

// Update TestMetalViewRepresentable to handle touch events
struct TestMetalViewRepresentable: UIViewRepresentable {
    let metalView: MTKView
    @Binding var renderer: TestRenderer?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> MTKView {
        metalView.delegate = renderer
        
        // Add gesture recognizers
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
        var parent: TestMetalViewRepresentable
        private var draggedNode: TestSceneNode?
        
        init(_ parent: TestMetalViewRepresentable) {
            self.parent = parent
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let metalView = gesture.view as? MTKView else { return }
            let location = gesture.location(in: metalView)
            parent.renderer?.selectNode(at: location, in: metalView)
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let metalView = gesture.view as? MTKView,
                  let renderer = parent.renderer else { return }
            
            let location = gesture.location(in: metalView)
            
            switch gesture.state {
            case .began:
                // Try to select a node at the touch point
                renderer.selectNode(at: location, in: metalView)
                draggedNode = renderer.selectedNode
                
            case .changed:
                guard let node = draggedNode else { return }
                
                // Convert touch coordinates to scene coordinates
                let viewSize = metalView.bounds.size
                let x = (Float(location.x) / Float(viewSize.width)) * 2 - 1
                let y = -((Float(location.y) / Float(viewSize.height)) * 2 - 1)
                
                // Update node position
                node.position = SIMD3<Float>(x, y, 0)
                node.update()
                
            case .ended, .cancelled:
                draggedNode = nil
                
            default:
                break
            }
        }
    }
} 