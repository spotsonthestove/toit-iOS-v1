# Node Selection and Ray Casting Analysis

## Updated Implementation Analysis (2024-03-21)

### 1. Coordinate Space Transformation Solution

The key to fixing the ray casting was proper handling of coordinate spaces:

```swift
// 1. Screen to Drawable Space
let drawableX = point.x * drawableSize.width / viewSize.width
let drawableY = point.y * drawableSize.height / viewSize.height

// 2. Drawable to NDC Space
let normalizedX = (2.0 * Float(drawableX) / Float(drawableSize.width)) - 1.0
let normalizedY = -((2.0 * Float(drawableY) / Float(drawableSize.height)) - 1.0)  // Note the flip and negate

// 3. Create ray using both near and far clip planes
let clipNear = SIMD4<Float>(normalizedX, normalizedY, -1.0, 1.0)
let clipFar = SIMD4<Float>(normalizedX, normalizedY, 1.0, 1.0)

// 4. Transform to view space with proper perspective divide
let viewNear = (invProjection * clipNear) / viewNear.w
let viewFar = (invProjection * clipFar) / viewFar.w

// 5. Transform to world space
let worldNear = invView * viewNear
let worldFar = invView * viewFar

// 6. Create final ray
let rayOrigin = SIMD3<Float>(worldNear.x, worldNear.y, worldNear.z)
let rayTarget = SIMD3<Float>(worldFar.x, worldFar.y, worldFar.z)
let rayDirection = normalize(rayTarget - rayOrigin)
```

#### Key Insights:
1. Screen coordinates must be properly mapped to drawable space
2. Y-axis must be flipped and negated for Metal's coordinate system
3. Ray should be constructed using both near and far clip planes
4. Perspective divide must be performed at the correct step

### 2. Improved Hit Testing

Updated the hit testing to use distance-based scaling:

```swift
// Base hit radius calculation
let nodeScale: Float = 0.2
let baseHitRadius: Float = nodeScale * 2.0

// Distance-based scaling
let distanceToCamera = length(node.position - ray.origin)
let hitRadius = baseHitRadius * (1.0 + distanceToCamera * 0.15)

// Closest point calculation
let toCenter = node.position - ray.origin
let projection = dot(toCenter, ray.direction)
let closestPoint = ray.origin + ray.direction * max(0, projection)
let distanceToRay = length(node.position - closestPoint)
```

#### Improvements:
1. Hit radius scales with distance for better selection of far nodes
2. Uses closest point on ray for more accurate hit testing
3. Prevents selection through objects with proper depth handling

### 3. Debug Visualization System

Enhanced debug visualization helps understand the ray casting:

```swift
// Ray path visualization
renderer.debugDrawLine(
    start: ray.origin,
    end: ray.origin + ray.direction * 10.0,
    color: SIMD4<Float>(1, 1, 1, 0.5)
)

// Points along ray path
for t in stride(from: 0.0, through: 10.0, by: 0.5) {
    let point = ray.origin + ray.direction * Float(t)
    renderer.debugDrawSphere(
        center: point,
        radius: 0.02,
        color: SIMD4<Float>(1, 1, 0, 0.5)
    )
}

// Hit testing visualization
renderer.debugDrawSphere(
    center: node.position,
    radius: hitRadius,
    color: SIMD4<Float>(1, 0, 0, 0.1)
)
```

## Current Status

### Working Features:
✅ Accurate ray casting from tap points
✅ Proper coordinate space transformation
✅ Distance-based hit testing
✅ Visual debugging system
✅ Proper depth handling

### Areas for Enhancement:
1. Consider adding hover state feedback
2. Implement multi-selection capability
3. Add drag and drop support
4. Optimize hit testing for larger node counts

## References
- [Metal Coordinate Systems](https://developer.apple.com/documentation/metal/using_metal_to_draw_a_view_s_contents)
- [Ray-Sphere Intersection](https://www.scratchapixel.com/lessons/3d-basic-rendering/minimal-ray-tracer-rendering-simple-shapes/ray-sphere-intersection.html)
- [Coordinate Space Transformations in Metal](https://developer.apple.com/documentation/metal/using_metal_to_draw_a_view_s_contents/creating_and_sampling_textures)
