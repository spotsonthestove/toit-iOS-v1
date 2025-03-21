## Dev issues and solutions log 
timestamp each entry as yyyy-mm-dd and a count of the number of the entry.

We'll track code as it changes and the issues and solutions as they are resolved. We'll put milestones in the code as we reach them. and the next steps as we plan them.

### 2024-03-19 #10: Fixed Access Control

**Issue:**
- Build error: "'sceneView' is inaccessible due to 'private' protection level"
- Coordinator couldn't access ViewModel's sceneView property

**Solution:**
1. Changed sceneView access level from private to internal
2. Updated gesture recognizer methods to safely access sceneView
3. Added proper optional binding for sceneView access

**Technical Notes:**
- Internal access level allows access within the same module
- Maintained weak reference to avoid retain cycles
- Added safe optional binding for better safety

### 2024-03-19 #9: Fixed Node Dragging Priority

**Issue:**
- Node dragging not working properly - camera orbiting instead of moving node
- Gesture conflict resolution not properly prioritizing node interaction

**Solution:**
1. Gesture Priority:
   - Added exclusive touch type for pan gesture
   - Implemented proper gesture delegate methods for priority
   - Added shouldBeRequiredToFailBy to ensure node drag takes precedence
2. Camera Control:
   - Temporarily disable camera control during node drag
   - Re-enable camera control after drag ends
3. Hit Testing:
   - Added wouldHitNode helper to check for node hits before gesture starts
   - Use hit testing to determine gesture priority

**Technical Notes:**
- Using UIGestureRecognizerDelegate for fine-grained gesture control
- Proper gesture failure requirements for priority handling
- Dynamic camera control toggling during drag operations

### 2024-03-19 #8: Fixed Gesture Conflicts

**Issue:**
- Node dragging gesture preventing camera orbit/pan
- Single-finger pan conflicting with SceneKit's camera controls

**Solution:**
1. Gesture Recognition:
   - Implemented UIGestureRecognizerDelegate
   - Added simultaneous gesture recognition logic
   - Only prevent camera movement when actually dragging a node
2. State Management:
   - Added isDraggingNode property to track drag state
   - Improved gesture state handling
   - Cancel touches only when actively dragging

**Technical Notes:**
- Using gesture delegate to handle simultaneous recognition
- Proper state tracking prevents unwanted gesture interference
- Camera controls work normally until a node is grabbed

### 2024-03-19 #7: Fixed Node Dragging and Camera Control

**Issues:**
- Node dragging not working with SwiftUI gesture
- Fly camera mode less intuitive than orbit
- Gesture conflicts between camera and node interaction

**Solutions:**
1. Gesture Handling:
   - Replaced SwiftUI DragGesture with UIPanGestureRecognizer
   - Added proper gesture state handling (began, changed, ended)
   - Limited pan gesture to single touch
2. Camera Control:
   - Reverted to default orbit camera mode
   - Removed fly mode and inertia settings
3. Drag Implementation:
   - Split drag logic into start, continue, and end phases
   - Improved coordinate space handling

**Technical Notes:**
- UIPanGestureRecognizer provides better control over touch handling
- Default orbit camera more intuitive for mind map navigation
- Proper gesture state management improves drag reliability

### 2024-03-19 #6: Improved Node Interaction and Hit Testing

**Issues:**
- Node hit testing not working properly
- Camera orbit interfering with node interaction
- SCNView caching warning on initialization
- Lack of visual feedback for node selection/dragging

**Solutions:**
1. Camera Control:
   - Set camera controller to fly mode
   - Enabled inertia for smoother camera movement
2. Hit Testing:
   - Added proper hit test options (searchMode, boundingBoxOnly)
   - Improved physics body configuration with proper collision shape
3. Visual Feedback:
   - Added color changes for selected (green) and dragged (orange) nodes
   - Added specular highlights for better 3D appearance
4. Interaction:
   - Added separate tap gesture for node selection
   - Improved drag gesture handling
   - Added proper state management for selection/dragging

**Technical Notes:**
- Using SCNHitTestSearchMode.closest for more accurate hit detection
- Proper physics body setup with collision masks
- Visual state management with color feedback
- Separate gesture recognizers for different interactions

### 2024-03-19 #5: Fixed Node Dragging Implementation

**Issue:**
- Node dragging was not working
- Drag gesture detection and position updates were unreliable

**Solution:**
- Implemented proper drag state tracking with draggedNode and lastDragLocation
- Added drag gesture end handling
- Improved hit testing with boundingBoxOnly option
- Calculate drag deltas between frames instead of using gesture translation
- Added small mass to nodes for better physics behavior

**Technical Notes:**
- Using screen-space deltas for more precise movement
- Maintaining drag state between gesture updates
- Added proper cleanup on drag end
- Improved hit testing accuracy

### 2024-03-19 #4: Improved SceneKit Integration with SwiftUI

**Issue:**
- Build error: "Value of type 'UInt' has no member 'codingPath'"
- Previous approach using GeometryReader was unreliable for getting SceneView reference

**Solution:**
- Created proper UIViewRepresentable wrapper for SCNView
- Implemented direct SceneView creation and configuration
- Removed complex view hierarchy traversal

**Technical Notes:**
- UIViewRepresentable provides cleaner SwiftUI integration
- Direct SCNView configuration gives better control over SceneKit features
- Maintains proper view lifecycle management

### 2024-03-19 #3: Fixed Vector Operations and SceneView Access

**Issues:**
1. Build error: "Value of type 'SCNScene' has no member 'view'"
2. Build error: "Binary operator '+=' cannot be applied to two 'SCNVector3' operands"
3. Build error: "Referencing operator function '+=' requires 'SCNVector3' conform to 'FloatingPoint'"

**Solutions:**
1. Implemented proper SceneView access using GeometryReader
2. Added mutating `add` method for SCNVector3
3. Fixed vector operation syntax and implementation
4. Updated node position updates to use proper vector operations

**Technical Notes:**
- SCNVector3 doesn't conform to FloatingPoint, requiring custom vector operations
- Using GeometryReader for reliable SceneView access in SwiftUI
- Vector operations now use component-wise updates

### 2024-03-19 #2: Fixed SceneView Reference Issue

**Issue:**
- Build error: "Value of type 'SCNScene' has no member 'view'"
- Need proper way to access SceneView for hit testing

**Solution:**
- Added weak SceneView reference in ViewModel
- Added setSceneView method to store reference
- Setup reference in View's onAppear
- Updated handleDrag to use stored reference

**Technical Notes:**
- Using weak reference to avoid retain cycles
- SceneView reference is set after view appears
- This maintains proper SwiftUI/SceneKit integration

### 2024-03-19 #1: Implemented Node Dragging

**Implementation:**
- Added 3D node dragging with hit testing
- Implemented camera-relative movement for intuitive dragging from any angle
- Added vector math extensions for SCNVector3 and SCNNode

**Next Steps:**
1. Implement immediate branch updates during drag
2. Refine branch endpoint calculations
3. Consider using SCNConstraints for branch connections
4. Add visual feedback for connection points
5. Optimize physics body interactions

**Technical Notes:**
- Consider caching normalized vectors
- May need to adjust branch update frequency
- Watch for performance impact of frequent updates
- Consider adding debug visualization for connection points

This comparison shows the Three.js implementation maintains better connection consistency through simpler vector math and immediate updates. The SceneKit implementation can be improved by following similar patterns while accounting for SceneKit's specific requirements around transforms and physics.

### 2024-03-19 #17: Implemented Three.js-Inspired Branch Updates

**Implementation:**
1. Immediate Branch Updates:
   - Direct position updates during drag operations
   - Immediate branch geometry updates
   - Bidirectional branch updates (parent and child connections)

2. Precise Connection Points:
   - Exact sphere surface intersection calculations
   - Normalized direction vectors for accuracy
   - Proper branch length calculations

3. Performance Optimizations:
   - Reduced update chain
   - Direct node position updates
   - Streamlined branch geometry updates

**Technical Notes:**
- Removed intermediate update steps
- Added immediate branch updates during drag
- Improved connection point precision
- Maintained consistent branch orientations

**Next Steps:**
1. Test branch behavior during rapid node movement
2. Consider adding visual feedback at connection points
3. Implement branch animation for smoother transitions

### 2024-03-19 MILESTONE: Branch Connection System Complete

**Achievements:**
1. Stable Branch System:
   - Precise surface-to-surface connections between nodes
   - Proper branch orientation using quaternion rotation
   - Immediate updates during node dragging
   - Bidirectional connection tracking

2. Interaction System:
   - Smooth node dragging with camera-relative movement
   - Clear visual feedback (green for parent, yellow for child)
   - Proper gesture handling between camera and node interaction
   - Reliable node selection and connection workflow

3. Data Management:
   - Robust UUID-based node tracking
   - Efficient branch lookup using consistent ID generation
   - Clean data structures for positions and connections
   - Import/export functionality for mind map data

**Technical Implementation:**
- Vector math extensions for precise calculations
- Optimized branch updates using normalized vectors
- Proper quaternion-based rotation for branch alignment
- Efficient branch geometry updates during movement
- Physics body configuration for better interaction
- Camera-relative movement calculations

**Current State:**
- Can add nodes with random 3D positions
- Can select parent (green) and child (yellow) nodes
- Can create branches that properly connect at node surfaces
- Can drag nodes with immediate branch updates
- Can orbit/zoom camera while maintaining proper connections
- Clean visual feedback for all interactions

**Next Steps:**
1. User Experience:
   - Add node labels/text
   - Implement node deletion
   - Add branch styling options
   - Consider adding animations for smoother transitions

2. Advanced Features:
   - Multi-node selection
   - Branch deletion
   - Node grouping
   - Undo/redo system

3. Performance:
   - Add node/branch culling for large maps
   - Optimize update frequency during rapid movement
   - Consider level-of-detail system for complex maps

4. Data Management:
   - Implement persistent storage
   - Add export to different formats
   - Consider cloud sync capabilities

[Previous content remains exactly the same until the end of the file]

