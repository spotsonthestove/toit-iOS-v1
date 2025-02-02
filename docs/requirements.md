Requirements Document

Purpose

To develop a minimal 3D engine using SceneKit for rendering and interacting with a 3D mind map. The engine will handle nodes and branches, ensuring proper alignment, transformations, and interactivity. Other parts of the application will remain 2D or utilize non-2D functionality.

Functional Requirements

	1.	Scene Graph Management:
	•	Maintain hierarchical relationships between nodes and branches.
	•	Ensure transformations propagate correctly through the hierarchy.
	2.	Rendering:
	•	Nodes:
	•	Represented as spheres or similar primitives.
	•	Support customizable properties (size, color, labels).
	•	Branches:
	•	Rendered as cylinders, lines, or curves.
	•	Dynamically stretched between connected nodes.
	3.	Interactivity:
	•	Drag nodes in 3D space, with real-time updates to connected branches.
	•	Support for zooming, panning, and rotating the 3D view.
	•	Add, remove, and modify nodes and branches dynamically.
	4.	Performance:
	•	Efficient rendering and transformation handling for up to a few thousand nodes and branches.
	•	Use SceneKit's GPU capabilities for smooth interactivity.
	5.	Integration:
	•	Modular design to integrate the 3D engine with the rest of the application.
	•	Export/import functionality for the mind map data structure.

Non-Functional Requirements

	1.	Usability:
	•	Utilize SceneKit's built-in physics for natural interaction
	•	Leverage existing SCNView camera controls
	2.	Portability:
	•	Focus on iOS with SceneKit's cross-platform capabilities
	3.	Maintainability:
	•	Maintain SwiftUI/SceneKit separation of concerns
	•	Follow established SceneKit patterns and best practices
	4.	Scalability:
	•	Utilize SceneKit's optimizations for larger mind maps
	•	Implement proper node/branch management systems

Key Components

	1.	Scene Graph:
	•	Utilize SceneKit's built-in scene graph (SCNNode hierarchy) for managing nodes, branches, and their transformations.
	2.	Renderer:
	•	Leverage SceneKit's rendering engine for nodes and branches.
	•	Use SCNGeometry for efficient rendering of repeated objects (e.g., spheres for nodes).
	3.	Input Handling:
	•	Gesture-based interaction using SwiftUI gestures integrated with SceneKit.
	4.	Math Utilities:
	•	Use SceneKit's built-in vector and matrix operations (SCNVector3, SCNMatrix4).
	5.	Utility Functions:
	•	Debugging tools (e.g., axis visualizers as implemented in createAxes()).
	•	Data import/export for mind maps.

Code Development Workflow

Phase 1: Setup (Completed)

	1.	Initialize SceneKit:
	•	Set up a SceneKit-based project with SceneView for rendering ✓
	•	Create basic scene setup with camera and lighting ✓
	•	Implement debug visualization (axis system) ✓
	2.	Build Basic Rendering:
	•	Render static nodes (spheres) ✓
	•	Prepare for branch connections

Phase 2: Core Engine Development

	1.	Scene Graph Implementation:
	•	Leverage SCNNode hierarchy:
		•	Properties: position, rotation, scale
		•	Methods: addChildNode(), removeFromParentNode()
	•	Use existing scene graph for hierarchical transformations
	2.	Node and Branch Rendering:
	•	Implement node creation and placement ✓
	•	Develop branch geometry system using SCNCylinder or custom geometry
	3.	Camera Controls:
	•	Utilize SceneKit's built-in camera controls ✓
	•	Enhance with custom camera behaviors as needed

Phase 3: Interactivity

	1.	Drag-and-Drop Nodes:
	•	Implement hit-testing to detect node selection.
	•	Map screen coordinates to 3D space for dragging.
	2.	Dynamic Node and Branch Updates:
	•	Add functions to create, update, and delete nodes and branches.
	•	Ensure branches stay aligned during node transformations.

Phase 4: Optimization

	1.	GPU Optimization:
	•	Use SceneKit's optimizations for rendering nodes efficiently.
	•	Optimize shaders for performance on mobile devices.
	2.	Testing:
	•	Test with increasing numbers of nodes and branches to identify performance bottlenecks.

Phase 5: Integration

	1.	Modularize the Engine:
	•	Create a standalone module for the 3D engine.
	•	Expose an API for the main application to interact with.
	2.	Integration with App:
	•	Integrate the engine into the larger app structure.
	•	Synchronize the 3D mind map with other app functionalities.

Deliverables

	1.	Engine Core:
	•	Scene graph implementation.
	•	Rendering pipeline with node and branch support.
	2.	Interactivity Layer:
	•	Drag-and-drop functionality.
	•	Camera controls.
	3.	Integration:
	•	API for adding, removing, and updating nodes/branches.
	•	Export/import for mind map data.
	4.	Documentation:
	•	Code comments and a developer guide.
	•	Usage instructions for integrating the engine.


### additional detail


    Scene Graph Concept

A scene graph is a tree structure where:
	1.	Each node represents an object (your MindMap nodes and branches).
	2.	Transformations are hierarchical: child objects inherit transformations from their parents.

For your use case:
	•	Each node is a parent object.
	•	Each branch is a child object connected to two nodes.

Problem: Misalignment

The misalignment likely arises from how local and world coordinates are computed and applied. Each object's final position in 3D space is determined by combining its local transformation with its parent's world transformation.

Core Requirements

	1.	Local Coordinates: Define the position, rotation, and scale relative to the parent.
	2.	World Coordinates: Calculate by propagating the transformations up the scene graph hierarchy.
	3.	Branch Alignment: Dynamically update branch geometry to follow connected nodes.

    Steps to Build a Mini 3D Engine for MindMap

1. Scene Graph Architecture

    • Utilize SCNNode for MindMap elements:
        • Nodes are parent SCNNodes with sphere geometry
        • Branches are child SCNNodes with cylinder geometry
        • Leverage SCNNode's built-in transform properties:
            • position (SCNVector3)
            • rotation (SCNVector4)
            • transform (SCNMatrix4)

    Scene graph hierarchy example:
    ```swift
    rootNode
    ├── nodeA (SCNNode with sphere)
    │   └── branchAB (SCNNode with cylinder)
    └── nodeB (SCNNode with sphere)
    ```

2. Branch Renderer

    • Create branches using SCNCylinder:
    ```swift
    func createBranch(from nodeA: SCNNode, to nodeB: SCNNode) -> SCNNode {
        let distance = nodeA.position.distance(to: nodeB.position)
        let cylinder = SCNCylinder(radius: 0.1, height: distance)
        let branch = SCNNode(geometry: cylinder)
        
        // Position branch at midpoint
        branch.position = SCNVector3.midpoint(nodeA.position, nodeB.position)
        
        // Calculate rotation to point from nodeA to nodeB
        branch.eulerAngles = SCNVector3.calculateRotation(from: nodeA.position, to: nodeB.position)
        
        return branch
    }
    ```

3. Node-Branch Relationships

    • Maintain branch connections:
    ```swift
    class MindMapNode: SCNNode {
        var connections: [Connection] = []
        
        struct Connection {
            let targetNode: MindMapNode
            let branch: SCNNode
        }
        
        func connectTo(_ node: MindMapNode) {
            let branch = createBranch(from: self, to: node)
            self.addChildNode(branch)
            connections.append(Connection(targetNode: node, branch: branch))
        }
        
        func updateConnections() {
            for connection in connections {
                let branch = connection.branch
                let target = connection.targetNode
                
                // Update branch position and rotation
                branch.position = SCNVector3.midpoint(self.position, target.position)
                branch.eulerAngles = SCNVector3.calculateRotation(from: self.position, 
                                                                to: target.position)
                
                // Update branch length
                if let cylinder = branch.geometry as? SCNCylinder {
                    cylinder.height = self.position.distance(to: target.position)
                }
            }
        }
    }
    ```

4. Interaction Support

    • Implement node dragging with hit testing:
    ```swift
    func handleDrag(_ gesture: DragGesture.Value) {
        guard let hitNode = findHitNode(at: gesture.location) else { return }
        
        // Convert 2D screen point to 3D world position
        let newPosition = convertScreenToWorld(gesture.location)
        
        // Update node position
        hitNode.position = newPosition
        
        // Update all connected branches
        if let mindMapNode = hitNode as? MindMapNode {
            mindMapNode.updateConnections()
        }
    }
    ```

5. Physics and Constraints

    • Add physics bodies for natural interaction:
    ```swift
    func setupNodePhysics(_ node: SCNNode) {
        node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        node.physicsBody?.isAffectedByGravity = false
        node.physicsBody?.categoryBitMask = NodeCategory.mindNode.rawValue
        
        // Add constraints to limit movement if needed
        let distanceLimit = SCNDistanceConstraint(target: rootNode)
        distanceLimit.maximumDistance = 10
        node.constraints = [distanceLimit]
    }
    ```

6. Debugging Tools

    • Implement visual debugging helpers:
    ```swift
    func toggleNodeAxes(_ node: SCNNode) {
        if node.childNodes.contains(where: { $0.name == "axes" }) {
            node.childNode(withName: "axes", recursively: false)?.removeFromParentNode()
        } else {
            let axes = createAxes(length: 2)
            axes.name = "axes"
            node.addChildNode(axes)
        }
    }
    ```

Tools and Frameworks

    1. SceneKit:
        • Built-in scene graph management
        • Physics simulation
        • Gesture handling
        • 3D math utilities
    2. CoreAnimation:
        • Smooth transitions and animations
    3. SwiftUI:
        • UI integration via SceneView
        • Gesture recognition
    4. Combine:
        • State management and updates
        • Node synchronization

This implementation leverages SceneKit's built-in functionality for efficient 3D rendering and physics, while maintaining a clean architecture for mind map specific features. The node-branch relationship is maintained through parent-child relationships in the scene graph, with automatic updates when nodes are moved.

API Integration Requirements

1. Authentication API
    • Endpoint: `/api/auth`
    • Authentication using Supabase through REST API
    • Implementation example:
    ```swift
    struct AuthService {
        static func signIn(email: String, password: String) async throws -> User {
            let url = URL(string: "https://your-api.domain/api/auth")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body = ["email": email, "password": password]
            request.httpBody = try JSONEncoder().encode(body)
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(AuthResponse.self, from: data)
            return response.user
        }
    }
    ```

2. Mind Map Data API
    • Endpoint: `/api/data`
    • Requires Bearer token authentication
    • Key operations:
        - Fetch mind maps: GET
        - Create mind maps: POST
    • Implementation example:
    ```swift
    class MindMapService {
        static func fetchMindMaps(token: String) async throws -> [MindMap] {
            let url = URL(string: "https://your-api.domain/api/data")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(MindMapResponse.self, from: data)
            return response.mindMaps
        }
        
        static func createMindMap(token: String, mindMap: MindMap) async throws -> MindMap {
            let url = URL(string: "https://your-api.domain/api/data")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            request.httpBody = try JSONEncoder().encode(mindMap)
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(CreateMindMapResponse.self, from: data)
            return response.mindmap
        }
    }
    ```

3. Data Models
    ```swift
    struct MindMap: Codable {
        let mindmap_id: String
        let name: String
        let description: String
        let created_at: Date
        let mindmap_nodes: [MindMapNode]
    }

    struct MindMapNode: Codable {
        let node_id: String
        let content: String
        let x: Float
        let y: Float
        let z: Float
        let parent_node_id: String?
        let node_type: String
    }

    struct AuthResponse: Codable {
        let user: User
        let session: Session
    }

    struct CreateMindMapResponse: Codable {
        let mindmap: MindMap
    }
    ```

4. Error Handling
    • Implement comprehensive error handling for API responses:
    ```swift
    enum APIError: Error {
        case unauthorized
        case networkError
        case invalidData
        case serverError(String)
    }

    extension MindMapService {
        static func handleAPIError(_ statusCode: Int, data: Data) throws {
            switch statusCode {
            case 401:
                throw APIError.unauthorized
            case 500:
                throw APIError.serverError(String(data: data, encoding: .utf8) ?? "Unknown error")
            default:
                throw APIError.networkError
            }
        }
    }
    ```

5. Integration Requirements
    • Implement proper token management and storage
    • Handle authentication state
    • Sync local changes with server
    • Implement retry logic for failed requests
    • Cache responses when appropriate

6. Security Considerations
    • Store authentication tokens securely using Keychain
    • Implement certificate pinning for API requests
    • Clear sensitive data on logout
    • Example secure token storage:
    ```swift
    class SecureStorage {
        static func saveToken(_ token: String) throws {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: "authToken",
                kSecValueData as String: token.data(using: .utf8)!
            ]
            SecItemAdd(query as CFDictionary, nil)
        }
        
        static func getToken() throws -> String? {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: "authToken",
                kSecReturnData as String: true
            ]
            var result: AnyObject?
            SecItemCopyMatching(query as CFDictionary, &result)
            
            guard let data = result as? Data,
                  let token = String(data: data, encoding: .utf8) else {
                return nil
            }
            return token
        }
    }
    ```

