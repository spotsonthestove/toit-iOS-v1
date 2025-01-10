import SwiftUI
import MetalKit

struct MindMapView: View {
    @State private var renderer: MindMapRenderer?
    @State private var selectedNodeId: UUID?
    
    var body: some View {
        ZStack {
            MetalViewRepresentable(renderer: $renderer, selectedNodeId: $selectedNodeId)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
            
            // Add a button to create child nodes when a node is selected
            if selectedNodeId != nil {
                VStack {
                    Spacer()
                    Button(action: createChildNode) {
                        Label("Add Child", systemImage: "plus.circle.fill")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue.opacity(0.8))
                            .cornerRadius(10)
                    }
                    .padding(.bottom, 100)
                    .zIndex(1)
                }
            }
        }
        .onAppear {
            print("MindMapView appeared")
            // Create initial center node
            let centerNode = MindMapNode(
                title: "Center",
                position: SIMD3<Float>(0, 0, 0),
                isCenter: true
            )
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                print("Attempting to create center node")
                if let renderer = renderer {
                    renderer.createNode(from: centerNode)
                    print("Center node created")
                } else {
                    print("Renderer was nil when trying to create center node")
                }
            }
        }
    }
    
    private func createChildNode() {
        guard let selectedNodeId = selectedNodeId,
              let renderer = renderer,
              let parentNode = renderer.getNode(for: selectedNodeId) else { return }
        
        // Calculate optimal distance based on node sizes
        let parentRadius: Float = parentNode.isCenter ? 0.3 : 0.2
        let childRadius: Float = 0.2  // Child nodes are never center nodes
        let minSpacing: Float = 0.2   // Minimum space between nodes
        let optimalDistance = parentRadius + childRadius + minSpacing
        
        // Calculate position relative to parent node
        let angle = Float.random(in: 0...(2 * .pi))
        
        let offset = SIMD3<Float>(
            cos(angle) * optimalDistance,  // X offset in circle
            sin(angle) * optimalDistance,  // Y offset in circle
            0  // Keep on same Z plane
        )
        
        let newPosition = parentNode.position + offset
        renderer.createChildNode(position: newPosition)
    }
}

struct MetalViewRepresentable: UIViewRepresentable {
    @Binding var renderer: MindMapRenderer?
    @Binding var selectedNodeId: UUID?
    
    func makeUIView(context: Context) -> MTKView {
        print("Creating MTKView")
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Failed to create MTLDevice")
        }
        
        let metalView = MTKView(frame: .zero, device: device)
        metalView.clearColor = MTLClearColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        metalView.depthStencilPixelFormat = .depth32Float
        metalView.colorPixelFormat = .bgra8Unorm
        metalView.sampleCount = 1
        
        // Set initial size
        metalView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        metalView.drawableSize = metalView.bounds.size
        
        guard let newRenderer = MindMapRenderer(metalView: metalView) else {
            fatalError("Failed to create renderer")
        }
        
        renderer = newRenderer
        metalView.delegate = newRenderer
        metalView.enableSetNeedsDisplay = true
        metalView.isPaused = false
        metalView.preferredFramesPerSecond = 60
        
        // Set up the node selection callback
        newRenderer.setNodeSelectedCallback { nodeId in
            DispatchQueue.main.async {
                self.selectedNodeId = nodeId
            }
        }
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        metalView.addGestureRecognizer(tapGesture)
        
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        metalView.addGestureRecognizer(panGesture)
        
        return metalView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        if uiView.drawableSize != uiView.bounds.size {
            uiView.drawableSize = uiView.bounds.size
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: MetalViewRepresentable
        private var draggedNodeId: UUID?
        
        init(_ parent: MetalViewRepresentable) {
            self.parent = parent
            super.init()
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let metalView = gesture.view as? MTKView else { return }
            let location = gesture.location(in: metalView)
            parent.renderer?.handleTap(at: location, in: metalView)
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let metalView = gesture.view as? MTKView else { return }
            
            switch gesture.state {
            case .began:
                let location = gesture.location(in: metalView)
                parent.renderer?.handleTap(at: location, in: metalView)
                draggedNodeId = parent.selectedNodeId
                
            case .changed:
                guard let nodeId = draggedNodeId else { return }
                let translation = gesture.translation(in: metalView)
                
                let dx = Float(translation.x) / Float(metalView.bounds.width) * 4
                let dy = -Float(translation.y) / Float(metalView.bounds.height) * 4
                
                if let node = parent.renderer?.getNode(for: nodeId) {
                    let newPosition = SIMD3<Float>(
                        node.position.x + dx,
                        node.position.y + dy,
                        node.position.z
                    )
                    parent.renderer?.handleNodeDrag(nodeId: nodeId, newPosition: newPosition)
                }
                
                gesture.setTranslation(.zero, in: metalView)
                
            case .ended, .cancelled:
                draggedNodeId = nil
                
            default:
                break
            }
        }
    }
}
