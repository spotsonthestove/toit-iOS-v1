## Dev issues and solutions log 
timestamp each entry as yyyy-mm-dd and a count of the number of the entry.

We'll track code as it changes and the issues and solutions as they are resolved. We'll put milestones in the code as we reach them. and the next steps as we plan them.

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

