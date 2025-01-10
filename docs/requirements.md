Requirements Document

Purpose

To develop a minimal 3D engine using Metal for rendering and interacting with a 3D mind map. The engine will handle nodes and branches, ensuring proper alignment, transformations, and interactivity. Other parts of the application will remain 2D or utilize non-3D functionality.

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
	•	Use Metal’s GPU capabilities for smooth interactivity.
	5.	Integration:
	•	Modular design to integrate the 3D engine with the rest of the application.
	•	Export/import functionality for the mind map data structure.

Non-Functional Requirements

	1.	Usability:
	•	Intuitive camera controls and drag-and-drop interactions.
	•	Smooth user experience on iOS devices.
	2.	Portability:
	•	Focus on iOS but design for potential extension to macOS or other platforms.
	3.	Maintainability:
	•	Clear separation of concerns (e.g., rendering, data, and interactivity).
	•	Well-documented and modular code.
	4.	Scalability:
	•	Capable of handling increasing complexity (e.g., larger mind maps, additional 3D features).

Key Components

	1.	Scene Graph:
	•	Core data structure managing nodes, branches, and their transformations.
	2.	Renderer:
	•	Handles rendering of nodes and branches using Metal.
	•	Supports instancing for efficient rendering of repeated objects (e.g., nodes).
	3.	Input Handling:
	•	Gesture-based interaction for touch and mouse input.
	4.	Math Utilities:
	•	Matrix and vector operations for transformations.
	5.	Utility Functions:
	•	Debugging tools (e.g., axis visualizers).
	•	Data import/export for mind maps.

Code Development Workflow

Phase 1: Setup

	1.	Initialize Metal:
	•	Set up a Metal-based project in Xcode with a MTKView for rendering.
	•	Create a basic render pipeline with vertex and fragment shaders.
	2.	Build Basic Rendering:
	•	Render static nodes (e.g., spheres) and branches (e.g., lines or cylinders).
	•	Verify basic rendering in 3D space.

Phase 2: Core Engine Development

	1.	Scene Graph Implementation:
	•	Build a SceneNode class:
	•	Properties: localMatrix, worldMatrix, children, parent.
	•	Methods: updateWorldMatrix(), addChild(), removeChild().
	•	Use this graph to manage hierarchical transformations.
	2.	Node and Branch Rendering:
	•	Use instancing for nodes to reduce rendering overhead.
	•	Implement a dynamic branch generator that updates branch geometry in real time.
	3.	Camera Controls:
	•	Implement basic 3D camera with orbit, zoom, and pan functionality.

Phase 3: Interactivity

	1.	Drag-and-Drop Nodes:
	•	Implement hit-testing to detect node selection.
	•	Map screen coordinates to 3D space for dragging.
	2.	Dynamic Node and Branch Updates:
	•	Add functions to create, update, and delete nodes and branches.
	•	Ensure branches stay aligned during node transformations.

Phase 4: Optimization

	1.	GPU Optimization:
	•	Use Metal instancing for rendering nodes efficiently.
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

The misalignment likely arises from how local and world coordinates are computed and applied. Each object’s final position in 3D space is determined by combining its local transformation with its parent’s world transformation.

Core Requirements

	1.	Local Coordinates: Define the position, rotation, and scale relative to the parent.
	2.	World Coordinates: Calculate by propagating the transformations up the scene graph hierarchy.
	3.	Branch Alignment: Dynamically update branch geometry to follow connected nodes.

    Steps to Build a Mini 3D Engine for MindMap

1. Scene Graph Architecture

	•	Create a Node class to represent each MindMap element.
	•	Maintain:
	•	Local transformation matrix (localMatrix).
	•	World transformation matrix (worldMatrix).
	•	List of child nodes.

Update the world matrix like this:

func updateWorldMatrix(parentMatrix: Matrix4) {
    worldMatrix = parentMatrix * localMatrix
    for child in children {
        child.updateWorldMatrix(parentMatrix: worldMatrix)
    }
}

2. Branch Renderer

	•	Define branches as cylinders or lines dynamically stretched between node positions.
	•	Recompute branch endpoints whenever nodes move.


let start = nodeA.worldMatrix.position
let end = nodeB.worldMatrix.position
branch.updateGeometry(from: start, to: end)

3. Interaction Support

	•	Add gesture recognition to select and drag nodes.
	•	During dragging, update only the local transformation matrix of the node. Recompute the scene graph to propagate changes.

4. Matrix Operations

Use a library like SIMD for efficient matrix math. Ensure:
	•	Proper matrix multiplication order: worldMatrix = parentWorldMatrix * localMatrix.
	•	Uniform scaling and correct order of rotation and translation.

5. Debugging

	•	Render debugging lines or spheres for local and world axes.
	•	Visualize how transformations propagate through the hierarchy.

Tools and Frameworks

	1.	MetalKit:
	•	Provides utility functions for rendering and matrix math.
	2.	Swift3D:
	•	A lightweight engine that integrates with Metal and uses a SwiftUI-like DSL.
	3.	MetalEngine:
	•	Offers a more robust framework for scene graph and rendering.
	4.	Custom Libraries:
	•	Consider building matrix operations and scene graph utilities tailored to your needs.

Updated Requirements

Branch System Requirements:
1. Visual Representation:
   - Cylindrical geometry for branches
   - Configurable radius and detail level
   - Support for different visual styles
   - Dynamic updates with node movement

2. Performance:
   - Efficient geometry updates
   - LOD system for distant branches
   - Culling for off-screen elements
   - Optimized for mobile devices

3. Interaction:
   - Visual feedback during branch creation
   - Support for branch selection
   - Branch style customization
   - Branch deletion capability

4. Data Management:
   - Efficient storage of branch data
   - Synchronization with node updates
   - Connection persistence
   - Branch metadata support

Node Movement Requirements:
1. Interaction:
   - Smooth drag and drop functionality
   - Collision detection between nodes
   - Position constraints
   - Movement animation

2. Data Management:
   - Efficient position updates
   - Position persistence
   - Synchronization system
   - Undo/redo support

Storage Requirements:
1. Node Data:
   - Position information
   - Connection data
   - Metadata storage
   - Version control

2. Performance:
   - Efficient data structures
   - Batch updates
   - Background synchronization
   - Cache management

3. Sync System:
   - Real-time updates
   - Conflict resolution
   - Data validation
   - Error recovery

Implementation Phases:

Phase 1: Core Branch System (Current)
- [x] Basic branch geometry
- [x] Branch rendering pipeline
- [x] Initial connection system
- [ ] Basic movement support

Phase 2: Enhanced Interaction
- [ ] Improved node movement
- [ ] Branch creation feedback
- [ ] Selection system
- [ ] Basic storage implementation

Phase 3: Visual Enhancement
- [ ] Branch styles
- [ ] Movement animation
- [ ] Visual feedback
- [ ] LOD system

Phase 4: Storage and Sync
- [ ] Position persistence
- [ ] Connection storage
- [ ] Sync system
- [ ] Cache management

Phase 5: Optimization
- [ ] Performance tuning
- [ ] Memory management
- [ ] Battery efficiency
- [ ] Resource optimization

