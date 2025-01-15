# Node Selection and Ray Casting Analysis

## Current Implementation Analysis

### 1. Coordinate Space Transformations

The current implementation follows this flow:
```swift
// 1. Screen to NDC (Normalized Device Coordinates)
let normalizedX = (2.0 * Float(point.x) / Float(viewSize.width)) - 1.0
let normalizedY = 1.0 - (2.0 * Float(point.y) / Float(viewSize.height))

// 2. NDC to View Space
let clipCoords = SIMD4<Float>(normalizedX, normalizedY, -1.0, 1.0)
var viewCoords = invProjection * clipCoords
viewCoords = viewCoords / viewCoords.w  // Perspective divide

// 3. View Space to World Space
let worldCoords = invView * SIMD4<Float>(viewCoords.x, viewCoords.y, -1.0, 0.0)
let rayDirection = normalize(SIMD3<Float>(worldCoords.x, worldCoords.y, worldCoords.z))
```

#### Potential Issues:
1. The `-1.0` in clip space might need to be adjusted based on the coordinate system
2. The perspective divide might be happening at the wrong step
3. The final world space transformation might not properly account for the camera's orientation

### 2. Camera Matrix Construction

Current view matrix construction:
```swift
// Calculate view vectors
let forward = normalize(target - position)
let right = normalize(cross(up, forward))
let upAdjusted = normalize(cross(forward, right))

// Create matrices
let translationMatrix = matrix_float4x4(columns: (
    SIMD4<Float>(1, 0, 0, 0),
    SIMD4<Float>(0, 1, 0, 0),
    SIMD4<Float>(0, 0, 1, 0),
    SIMD4<Float>(-dot(right, position), -dot(upAdjusted, position), -dot(forward, position), 1)
))

let rotationMatrix = matrix_float4x4(columns: (
    SIMD4<Float>(right.x, upAdjusted.x, forward.x, 0),
    SIMD4<Float>(right.y, upAdjusted.y, forward.y, 0),
    SIMD4<Float>(right.z, upAdjusted.z, forward.z, 0),
    SIMD4<Float>(0, 0, 0, 1)
))
```

#### Potential Issues:
1. Matrix multiplication order might need to be reversed
2. The rotation matrix construction might need transposition
3. The up vector adjustment might be affecting orientation

### 3. Ray-Sphere Intersection

Current intersection test:
```swift
let oc = ray.origin - center
let a = dot(ray.direction, ray.direction)
let b = 2.0 * dot(oc, ray.direction)
let c = dot(oc, oc) - radius * radius
let discriminant = b * b - 4 * a * c
```

#### Potential Issues:
1. Ray direction might not be properly normalized
2. Hit radius scaling might need adjustment
3. Distance comparison might need to consider camera orientation

## Recommended Investigation Steps

### 1. Verify Camera Setup
```swift
// Add debug visualization for camera orientation
func debugDrawCameraFrame() {
    let position = camera.position
    let forward = normalize(camera.target - camera.position)
    let right = normalize(cross(camera.up, forward))
    let up = normalize(cross(forward, right))
    
    // Draw camera axes (longer for visibility)
    renderer.debugDrawLine(start: position, end: position + forward * 2, color: SIMD4<Float>(0, 0, 1, 1))  // Forward = Blue
    renderer.debugDrawLine(start: position, end: position + right * 2, color: SIMD4<Float>(1, 0, 0, 1))    // Right = Red
    renderer.debugDrawLine(start: position, end: position + up * 2, color: SIMD4<Float>(0, 1, 0, 1))       // Up = Green
}
```

### 2. Validate Ray Construction
```swift
// Add intermediate coordinate space checks
func debugRayConstruction(_ point: CGPoint) {
    // 1. Screen to NDC
    let ndc = screenToNDC(point)
    print("NDC coordinates: \(ndc)")
    
    // 2. NDC to View
    let viewSpace = ndcToViewSpace(ndc)
    print("View space coordinates: \(viewSpace)")
    
    // 3. View to World
    let worldSpace = viewToWorldSpace(viewSpace)
    print("World space coordinates: \(worldSpace)")
    
    // Visualize ray path
    let rayStart = camera.position
    let rayEnd = rayStart + worldSpace * 10.0
    renderer.debugDrawLine(start: rayStart, end: rayEnd, color: SIMD4<Float>(1, 1, 0, 1))
}
```

### 3. Test Intersection Math
```swift
// Add visualization for intersection tests
func debugIntersectionTest(_ ray: Ray, _ node: Engine3DSceneNode) {
    let hitRadius = node.scale * 1.5
    
    // Draw hit sphere
    renderer.debugDrawSphere(
        center: node.position,
        radius: hitRadius,
        color: SIMD4<Float>(1, 0, 0, 0.3)
    )
    
    // Calculate and visualize closest point on ray
    let toNode = node.position - ray.origin
    let projection = dot(toNode, ray.direction)
    let closestPoint = ray.origin + ray.direction * projection
    
    renderer.debugDrawSphere(
        center: closestPoint,
        radius: 0.1,
        color: SIMD4<Float>(0, 1, 1, 1)
    )
    
    // Draw line from closest point to node center
    renderer.debugDrawLine(
        start: closestPoint,
        end: node.position,
        color: SIMD4<Float>(1, 1, 0, 0.5)
    )
}
```

## Proposed Solutions

### 1. Update Ray Construction
```swift
func constructRay(from point: CGPoint) -> Ray {
    let viewSize = metalView.bounds.size
    
    // 1. Screen to NDC (flip Y and adjust depth range)
    let normalizedX = (2.0 * Float(point.x) / Float(viewSize.width)) - 1.0
    let normalizedY = -((2.0 * Float(point.y) / Float(viewSize.height)) - 1.0)
    
    // 2. Create ray in clip space (using -1 for near plane)
    let clipCoords = SIMD4<Float>(normalizedX, normalizedY, -1.0, 1.0)
    
    // 3. Transform to view space
    let invProjection = simd_inverse(camera.projectionMatrix)
    var viewCoords = invProjection * clipCoords
    
    // Important: Set z to -1 and w to 0 for direction vector
    viewCoords = SIMD4<Float>(viewCoords.x, viewCoords.y, -1.0, 0.0)
    
    // 4. Transform to world space
    let invView = simd_inverse(camera.viewMatrix)
    let worldCoords = invView * viewCoords
    
    // 5. Create and return normalized ray
    return Ray(
        origin: camera.position,
        direction: normalize(SIMD3<Float>(worldCoords.x, worldCoords.y, worldCoords.z))
    )
}
```

### 2. Improve Camera Matrix Construction
```swift
var viewMatrix: matrix_float4x4 {
    // 1. Calculate orthonormal basis
    let forward = normalize(target - position)
    let right = normalize(cross(SIMD3<Float>(0, 1, 0), forward))
    let up = normalize(cross(forward, right))
    
    // 2. Create rotation matrix (transposed for view matrix)
    let rotation = matrix_float4x4(columns: (
        SIMD4<Float>(right.x, up.x, forward.x, 0),
        SIMD4<Float>(right.y, up.y, forward.y, 0),
        SIMD4<Float>(right.z, up.z, forward.z, 0),
        SIMD4<Float>(0, 0, 0, 1)
    ))
    
    // 3. Create translation matrix
    let translation = matrix_float4x4(columns: (
        SIMD4<Float>(1, 0, 0, 0),
        SIMD4<Float>(0, 1, 0, 0),
        SIMD4<Float>(0, 0, 1, 0),
        SIMD4<Float>(-position.x, -position.y, -position.z, 1)
    ))
    
    // 4. Combine matrices (translation first, then rotation)
    return matrix_multiply(rotation, translation)
}
```

### 3. Enhanced Intersection Testing
```swift
func findIntersectedNode(_ ray: Ray) -> Engine3DSceneNode? {
    var closestNode: Engine3DSceneNode?
    var minDistance = Float.infinity
    
    for node in scene.nodes {
        // 1. Quick sphere test first
        if let intersection = intersectSphere(ray: ray, node: node) {
            // 2. Calculate actual distance to intersection point
            let hitPoint = ray.origin + ray.direction * intersection
            let distanceToCamera = length(hitPoint - ray.origin)
            
            // 3. Update if this is the closest hit
            if distanceToCamera < minDistance {
                minDistance = distanceToCamera
                closestNode = node
            }
        }
    }
    
    return closestNode
}
```

## Testing and Verification

1. Add visual debug markers at each step:
   - Camera orientation axes
   - Ray direction in world space
   - Intersection test points
   - Hit spheres around nodes

2. Log coordinate transformations:
   - Screen coordinates
   - NDC coordinates
   - View space coordinates
   - World space coordinates

3. Verify matrix operations:
   - Camera view matrix determinant
   - Projection matrix properties
   - Matrix multiplication order

4. Test with known positions:
   - Place node at (0,0,0)
   - Click center of screen
   - Verify ray passes through origin

## References

- [Metal Coordinate Systems](https://developer.apple.com/documentation/metal/using_metal_to_draw_a_view_s_contents/creating_and_sampling_textures)
- [Ray-Sphere Intersection](https://www.scratchapixel.com/lessons/3d-basic-rendering/minimal-ray-tracer-rendering-simple-shapes/ray-sphere-intersection.html)
- [View Matrix Construction](https://www.3dgep.com/understanding-the-view-matrix/)
