# Development Issues and Progress

## Camera System Implementation (2025-01-15)

### 1. Camera Controls Implementation
**Status**: ✅ Complete
- Implemented orbit, zoom, and roll controls
- Fixed camera up vector persistence during orbit and roll
- Adjusted sensitivities for better user experience

**Changes Made**:
- Added camera control methods:
  - `orbit`: Single-finger pan to orbit around target
  - `zoom`: Pinch gesture to move camera closer/further
  - `roll`: Two-finger rotation for camera roll
- Fixed view matrix calculation to properly use camera's up vector
- Implemented proper matrix transformations for all camera movements
- Added debug visualization with coordinate axes

**Technical Details**:
- Orbit uses combined Y-axis and right-vector rotations
- Zoom maintains min/max distance constraints (1.0 to 20.0 units)
- Roll rotates around view direction while maintaining proper orientation
- View matrix calculation properly maintains camera orientation

**Gesture Implementation**:
- Single-finger pan: Orbit camera around target
- Pinch gesture: Zoom camera in/out
- Two-finger rotation: Roll camera
- All gestures work simultaneously with proper sensitivity

### Next Steps:
1. Node Interaction
   - Implement node selection
   - Add node dragging functionality
   - Visual feedback for selected nodes

2. Visual Feedback
   - Highlight selected nodes
   - Improve branch visualization
   - Add visual helpers for camera orientation

### Outstanding Tasks:
- [ ] Node selection hit testing
- [ ] Node drag-and-drop implementation
- [ ] Selection highlight shader
- [ ] Branch appearance improvements
- [ ] Camera orientation indicator

### Technical Notes:
- Camera controls use sensitivity multipliers for fine-tuning:
  - Orbit: 0.01 (precise control)
  - Zoom: 2.0 (comfortable range)
  - Roll: 0.5 (natural feel)
- Gesture recognition properly handles simultaneous inputs
- Debug visualization helps verify camera orientation 

# Ray Casting and Node Selection Implementation (2024-01-15)

## Current Implementation

### Ray Casting Pipeline
1. **Screen to World Space Transformation**
   - Convert tap coordinates to normalized device coordinates (-1 to 1)
   - Transform through clip space using inverse projection matrix
   - Transform to world space using inverse view matrix
   - Create ray from camera position in resulting direction

### Node Selection Logic
1. **Hit Testing**
   - Use sphere intersection testing with configurable hit radius
   - Hit radius scaled relative to node size (1.5x node scale)
   - Test all nodes and select closest intersection to camera

### Debug Visualization
1. **Ray Visualization**
   - White line showing ray direction
   - Cyan spheres along ray path
   - Magenta sphere at tap point projection
   - Green/red spheres showing hit testing volumes

## Current Issues

### Ray Alignment
1. **Coordinate Transformation**
   - Ray direction not perfectly aligned with tap point
   - Possible issues in projection/view matrix transformations
   - Need to verify coordinate space conversions

### Hit Detection
1. **Depth Issues**
   - Sometimes selecting nodes behind intended target
   - Need to improve closest intersection detection
   - May need to adjust hit radius based on distance

### Camera Interaction
1. **View Frustum**
   - Limited camera movement making some nodes hard to select
   - Need to improve orbit controls for better node access
   - Consider adding temporary transparency for occluded nodes

## Technical Notes

### Ray Casting Math
```swift
// Convert to NDC space
let normalizedX = (2.0 * Float(point.x) / Float(viewSize.width)) - 1.0
let normalizedY = 1.0 - (2.0 * Float(point.y) / Float(viewSize.height))

// Transform through projection
let clipCoords = SIMD4<Float>(normalizedX, normalizedY, -1.0, 1.0)
var viewCoords = invProjection * clipCoords
viewCoords = viewCoords / viewCoords.w  // Perspective divide

// Transform to world space
let worldCoords = invView * SIMD4<Float>(viewCoords.x, viewCoords.y, -1.0, 0.0)
let rayDirection = normalize(SIMD3<Float>(worldCoords.x, worldCoords.y, worldCoords.z))
```

### Intersection Testing
```swift
// Sphere intersection test
let oc = ray.origin - center
let a = dot(ray.direction, ray.direction)
let b = 2.0 * dot(oc, ray.direction)
let c = dot(oc, oc) - radius * radius
let discriminant = b * b - 4 * a * c
```

## Next Steps

1. **Ray Alignment**
   - Verify projection matrix setup
   - Double-check coordinate transformations
   - Add more detailed visualization of tap point projection

2. **Hit Detection**
   - Consider ray-box intersection instead of spheres
   - Implement more sophisticated depth sorting
   - Add visual feedback for occluded selectable nodes

3. **Debug Improvements**
   - Add coordinate axis visualization at tap point
   - Show projection of tap through view frustum
   - Visualize view frustum boundaries

## Outstanding Tasks

1. **Core Functionality**
   - Fix ray alignment with tap point
   - Improve depth-based selection
   - Handle occluded node selection

2. **User Experience**
   - Add visual feedback for selectable nodes
   - Improve camera controls for better node access
   - Consider adding node highlighting on hover

3. **Performance**
   - Optimize intersection testing
   - Reduce debug visualization overhead
   - Consider spatial partitioning for large scenes

## References
- [Ray-Sphere Intersection](https://www.scratchapixel.com/lessons/3d-basic-rendering/minimal-ray-tracer-rendering-simple-shapes/ray-sphere-intersection.html)
- [Picking with Ray Casting](https://antongerdelan.net/opengl/raycasting.html)
- [Screen to World Space](https://www.scratchapixel.com/lessons/3d-basic-rendering/ray-tracing-generating-camera-rays/generating-camera-rays.html)