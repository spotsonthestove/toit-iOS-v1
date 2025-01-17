## Dev issues and solutions log 
timestamp each entry as yyyy-mm-dd and a count of the number of the entry.

We'll track code as it changes and the issues and solutions as they are resolved. We'll put milestones in the code as we reach them. and the next steps as we plan them.

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
1. Implement node connection system (branches)
2. Add visual feedback for node selection
3. Implement branch updating during node movement

**Technical Notes:**
- Using SceneKit's hitTest for node selection
- Camera-relative movement ensures consistent drag behavior regardless of view angle
- Added dragSpeed parameter (0.01) that may need tuning for optimal feel

