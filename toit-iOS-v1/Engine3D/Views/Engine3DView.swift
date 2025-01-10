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
    
    private func addNode() {
        guard let renderer = renderer else { return }
        let position = SIMD3<Float>(0, 0, 0)
        let node = Engine3DSceneNode(position: position)
        renderer.scene.addNode(node)
    }
    
    private func connectNodes() {
        // TODO: Implement node connection logic
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