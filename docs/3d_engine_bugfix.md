# 3D Engine Bugfix Guide

## Overview
This guide provides a step-by-step process for fixing current issues in the 3D engine implementation. Each step includes implementation details, testing procedures, and expected outcomes.

## Prerequisites
- Basic understanding of Metal and 3D graphics concepts
- Access to the current codebase
- Xcode with iOS simulator or device for testing

## Step 1: Camera System Fix

### 1.1 Update View Matrix Calculation
```swift:Engine3D/Core/Camera.swift
var viewMatrix: matrix_float4x4 {
    // Calculate view vectors
    let forward = normalize(target - position)
    let right = normalize(cross(SIMD3<Float>(0, 1, 0), forward))
    let up = normalize(cross(forward, right))
    
    // Create matrices
    let translationMatrix = matrix_float4x4(columns: (
        SIMD4<Float>(1, 0, 0, 0),
        SIMD4<Float>(0, 1, 0, 0),
        SIMD4<Float>(0, 0, 1, 0),
        SIMD4<Float>(-dot(right, position), -dot(up, position), -dot(forward, position), 1)
    ))
    
    let rotationMatrix = matrix_float4x4(columns: (
        SIMD4<Float>(right.x, up.x, forward.x, 0),
        SIMD4<Float>(right.y, up.y, forward.y, 0),
        SIMD4<Float>(right.z, up.z, forward.z, 0),
        SIMD4<Float>(0, 0, 0, 1)
    ))
    
    return matrix_multiply(rotationMatrix, translationMatrix)
}
```

### Testing Step 1
1. Add debug visualization:
```swift
func debugPrintCameraMatrix() {
    print("Camera Position:", position)
    print("Camera Target:", target)
    print("View Matrix:\n", viewMatrix)
}
```

2. Test camera positioning:
```swift
// In Engine3DView
func testCameraSetup() {
    renderer?.camera.position = SIMD3<Float>(0, 0, -5)
    renderer?.camera.target = SIMD3<Float>(0, 0, 0)
    renderer?.camera.debugPrintCameraMatrix()
}
```

Expected output:
```
Camera Position: [0.0, 0.0, -5.0]
Camera Target: [0.0, 0.0, 0.0]
View Matrix:
[[ 1.0  0.0  0.0  0.0]
 [ 0.0  1.0  0.0  0.0]
 [ 0.0  0.0  1.0  5.0]
 [ 0.0  0.0  0.0  1.0]]
```

## Step 2: Node Geometry Implementation

### 2.1 Update Sphere Geometry
```swift:Engine3D/Geometry/SphereGeometry.swift
class SphereGeometry {
    private(set) var vertices: [Vertex] = []
    private(set) var indices: [UInt16] = []
    
    init(radius: Float = 0.1, segments: Int = 16) {
        generateSphere(radius: radius, segments: segments)
    }
    
    private func generateSphere(radius: Float, segments: Int) {
        vertices.removeAll()
        indices.removeAll()
        
        // Generate vertices
        for lat in 0...segments {
            let theta = Float.pi * Float(lat) / Float(segments)
            let sinTheta = sin(theta)
            let cosTheta = cos(theta)
            
            for long in 0...segments {
                let phi = 2.0 * Float.pi * Float(long) / Float(segments)
                let sinPhi = sin(phi)
                let cosPhi = cos(phi)
                
                let x = radius * sinTheta * cosPhi
                let y = radius * cosTheta
                let z = radius * sinTheta * sinPhi
                
                let position = SIMD3<Float>(x, y, z)
                let normal = normalize(position)
                
                vertices.append(Vertex(
                    position: position,
                    normal: normal,
                    color: SIMD4<Float>(1.0, 0.7, 0.3, 1.0)
                ))
            }
        }
        
        // Generate indices
        for lat in 0..<segments {
            for long in 0..<segments {
                let first = UInt16(lat * (segments + 1) + long)
                let second = first + UInt16(segments + 1)
                let third = first + 1
                let fourth = second + 1
                
                indices.append(first)
                indices.append(second)
                indices.append(third)
                
                indices.append(third)
                indices.append(second)
                indices.append(fourth)
            }
        }
    }
}
```

### Testing Step 2
1. Add debug visualization for node geometry:
```swift
extension Engine3DSceneNode {
    func debugPrintGeometry() {
        print("Node ID:", id)
        print("Vertex Count:", vertexCount)
        print("First 3 vertices:")
        // Print first 3 vertices if available
        for i in 0..<min(3, vertexCount) {
            let vertex = vertices[i]
            print("  Position:", vertex.position)
            print("  Normal:", vertex.normal)
        }
    }
}
```

## Step 3: Node Selection Implementation

### 3.1 Add Ray Casting
```swift:Engine3D/Core/Math.swift
struct Ray {
    let origin: SIMD3<Float>
    let direction: SIMD3<Float>
}

extension Engine3DView {
    func raycastFromScreenPoint(_ point: CGPoint) -> Ray {
        let viewport = metalView.bounds
        let normalizedPoint = CGPoint(
            x: point.x / viewport.width,
            y: point.y / viewport.height
        )
        
        let clipX = Float(normalizedPoint.x) * 2.0 - 1.0
        let clipY = -(Float(normalizedPoint.y) * 2.0 - 1.0)
        
        guard let renderer = renderer else { 
            return Ray(origin: .zero, direction: .zero) 
        }
        
        let clipCoords = SIMD4<Float>(clipX, clipY, -1.0, 1.0)
        let inverseProjection = renderer.camera.projectionMatrix.inverse
        let inverseView = renderer.camera.viewMatrix.inverse
        
        var rayWorld = matrix_multiply(inverseView, 
                                     matrix_multiply(inverseProjection, clipCoords))
        rayWorld = rayWorld / rayWorld.w
        
        let rayDirection = normalize(
            SIMD3<Float>(rayWorld.x, rayWorld.y, rayWorld.z) - 
            renderer.camera.position
        )
        
        return Ray(origin: renderer.camera.position, direction: rayDirection)
    }
}
```

### 3.2 Implement Node Selection
```swift:Engine3D/Views/Engine3DView.swift
extension Engine3DView {
    func selectNodeAtPoint(_ point: CGPoint) {
        let ray = raycastFromScreenPoint(point)
        
        // Find closest intersecting node
        var closestNode: Engine3DSceneNode?
        var closestDistance = Float.infinity
        
        for node in renderer?.scene.nodes ?? [] {
            if let intersection = intersectSphere(ray: ray, 
                                               center: node.position, 
                                               radius: 0.1) {
                if intersection < closestDistance {
                    closestDistance = intersection
                    closestNode = node
                }
            }
        }
        
        if let node = closestNode {
            print("Selected node:", node.id)
            // Highlight selected node
            node.color = SIMD4<Float>(1.0, 0.0, 0.0, 1.0)
        }
    }
    
    private func intersectSphere(ray: Ray, center: SIMD3<Float>, radius: Float) -> Float? {
        let oc = ray.origin - center
        let a = dot(ray.direction, ray.direction)
        let b = 2.0 * dot(oc, ray.direction)
        let c = dot(oc, oc) - radius * radius
        let discriminant = b * b - 4 * a * c
        
        if discriminant < 0 {
            return nil
        }
        
        let t = (-b - sqrt(discriminant)) / (2.0 * a)
        return t > 0 ? t : nil
    }
}
```

### Testing Step 3
1. Add debug visualization for ray casting:
```swift
extension Engine3DView {
    func debugRaycast(_ point: CGPoint) {
        let ray = raycastFromScreenPoint(point)
        print("Ray Origin:", ray.origin)
        print("Ray Direction:", ray.direction)
        
        // Draw debug line for ray
        renderer?.debugDrawLine(
            start: ray.origin,
            end: ray.origin + ray.direction * 10.0,
            color: SIMD4<Float>(1.0, 1.0, 0.0, 1.0)
        )
    }
}
```

## Step 4: Debug Visualization

### 4.1 Add Coordinate Axes
```swift:Engine3D/Debug/DebugRenderer.swift
extension Renderer {
    func drawDebugAxes(length: Float = 1.0) {
        let origin = SIMD3<Float>(0, 0, 0)
        
        // X axis (red)
        debugDrawLine(
            start: origin,
            end: SIMD3<Float>(length, 0, 0),
            color: SIMD4<Float>(1, 0, 0, 1)
        )
        
        // Y axis (green)
        debugDrawLine(
            start: origin,
            end: SIMD3<Float>(0, length, 0),
            color: SIMD4<Float>(0, 1, 0, 1)
        )
        
        // Z axis (blue)
        debugDrawLine(
            start: origin,
            end: SIMD3<Float>(0, 0, length),
            color: SIMD4<Float>(0, 0, 1, 1)
        )
    }
}
```

### Testing Step 4
1. Enable debug visualization:
```swift
// In Engine3DView
func enableDebugVisualization() {
    renderer?.isDebugEnabled = true
    renderer?.drawDebugAxes(length: 2.0)
}
```

## Step 5: Camera and Scene Orientation Fix

### 5.1 Update Camera System
```swift:Engine3D/Core/Camera.swift
// Update camera initialization
init(position: SIMD3<Float>, target: SIMD3<Float>) {
    // Match Three.js-style camera positioning for more intuitive control
    self.position = SIMD3<Float>(0, 2, 10)  // Changed from z=-5 to z=10
    self.target = SIMD3<Float>(0, 0, 0)     // Looking at center
    self.up = SIMD3<Float>(0, 1, 0)
    
    print("Camera initialized at position: \(self.position), looking at: \(self.target)")
}

// Update view matrix calculation
var viewMatrix: matrix_float4x4 {
    // Calculate view vectors with adjusted forward direction
    let forward = normalize(position - target)  // Reversed from (target - position)
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
    
    return matrix_multiply(rotationMatrix, translationMatrix)
}
```

### 5.2 Update Orbit Controls
```swift:Engine3D/Core/Camera.swift
func orbit(deltaX: Float, deltaY: Float, sensitivity: Float = 0.01) {
    // Invert deltaX for more intuitive horizontal orbit
    let angleX = -deltaX * sensitivity * 2.0
    let angleY = deltaY * sensitivity * 2.0
    
    // Calculate camera vectors
    let forward = normalize(target - position)
    let right = normalize(cross(up, forward))
    
    // Create rotation matrices
    let rotationAroundY = simd_float4x4(rotationAroundAxis: SIMD3<Float>(0, 1, 0) * angleX)
    let rotationAroundX = simd_float4x4(rotationAroundAxis: right * angleY)
    
    // Apply rotations
    let combinedRotation = matrix_multiply(rotationAroundY, rotationAroundX)
    let relativePosition = position - target
    let rotatedPosition = combinedRotation * SIMD4<Float>(relativePosition.x, relativePosition.y, relativePosition.z, 1.0)
    
    // Update position
    position = target + SIMD3<Float>(rotatedPosition.x, rotatedPosition.y, rotatedPosition.z)
    
    // Ensure up vector stays relatively upright but allows for some tilt
    let newUp = SIMD4<Float>(up.x, up.y, up.z, 0.0)
    let rotatedUp = combinedRotation * newUp
    up = normalize(SIMD3<Float>(rotatedUp.x, rotatedUp.y, rotatedUp.z))
    
    // Clamp vertical rotation to prevent camera flipping
    let verticalAngle = asin(dot(normalize(target - position), SIMD3<Float>(0, 1, 0)))
    if abs(verticalAngle) > Float.pi * 0.49 {
        up = SIMD3<Float>(0, 1, 0)
    }
}
```

### 5.3 Update Node Distribution
```swift:Engine3D/Core/Scene.swift
func calculateNewNodePosition() -> SIMD3<Float> {
    if nodes.isEmpty {
        return SIMD3<Float>(0, 0, 0)
    }
    
    let nodeCount = Float(nodes.count)
    let angle = (nodeCount - 1) * (2.0 * .pi / 6.0)
    let radius = distributionRadius
    
    // Position in XZ plane for better visibility with updated camera
    let x = cos(angle) * radius
    let z = sin(angle) * radius
    
    let position = SIMD3<Float>(x, 0, z)
    print("Calculated new node position: \(position)")
    return position
}
```

### Testing Step 5
1. Test camera positioning:
```swift
func testCameraOrientation() {
    renderer?.camera.position = SIMD3<Float>(0, 2, 10)
    renderer?.camera.target = SIMD3<Float>(0, 0, 0)
    renderer?.camera.debugPrintCameraMatrix()
    
    // Add visual debug markers
    renderer?.debugDrawSphere(
        center: .zero,
        radius: 0.1,
        color: SIMD4<Float>(1, 1, 1, 1)
    )
}
```

2. Test orbit controls:
```swift
// In Engine3DView
func testOrbitControls() {
    // Test horizontal orbit
    renderer?.camera.orbit(deltaX: Float.pi/4, deltaY: 0)
    print("Camera position after horizontal orbit:", renderer?.camera.position ?? "nil")
    
    // Test vertical orbit
    renderer?.camera.orbit(deltaX: 0, deltaY: Float.pi/4)
    print("Camera position after vertical orbit:", renderer?.camera.position ?? "nil")
}
```

Expected behavior:
- Camera should start at (0, 2, 10) looking at origin
- Horizontal orbit should move camera left/right around the scene
- Vertical orbit should move camera up/down while maintaining scene orientation
- Node selection (from tap_issues.md) should continue to work correctly
- Nodes should be distributed in a circle on the XZ plane

### Common Issues and Solutions

1. Camera Flipping
- Symptom: Camera orientation becomes inverted during vertical orbit
- Solution: Implement vertical angle clamping in orbit function

2. Node Visibility
- Symptom: Nodes appear too small or large based on camera distance
- Solution: Adjust node scale based on camera distance

3. Selection Accuracy
- Symptom: Node selection becomes less accurate after camera movement
- Solution: Update ray casting to account for new camera orientation

4. Performance
- Symptom: Frame rate drops during continuous orbit
- Solution: Optimize matrix calculations and implement frame rate limiting

## Next Steps

After implementing these camera and orientation fixes:
1. Fine-tune orbit sensitivity
2. Add smooth camera transitions
3. Implement zoom limits
4. Add camera reset functionality
5. Consider adding alternative camera modes (First Person, Top Down, etc.)

Remember to maintain compatibility with the ray casting and node selection system detailed in `tap_issues.md`. The updated camera system should enhance the mind map visualization while preserving all existing functionality.
```



## Final Testing Checklist

1. Camera Positioning
- [ ] Camera properly positioned at (0, 2, 10)
- [ ] Objects visible in view
- [ ] Correct perspective projection

2. Node Rendering
- [ ] Spheres properly shaped
- [ ] Smooth shading on spheres
- [ ] Correct normals for lighting

3. Node Selection
- [ ] Ray casting picks correct node
- [ ] Visual feedback on selection
- [ ] Proper hit testing distance

4. Debug Visualization
- [ ] Coordinate axes visible
- [ ] Ray cast lines visible when debugging
- [ ] Node positions clearly indicated

## Troubleshooting Common Issues

1. Nodes not visible
- Check camera position and orientation
- Verify projection matrix setup
- Confirm node positions within view frustum

2. Incorrect selection
- Verify ray calculation
- Check intersection math
- Confirm viewport coordinates

3. Poor performance
- Monitor frame rate
- Check geometry complexity
- Verify buffer management

## Next Steps

After implementing these fixes:
1. Add node movement controls
2. Implement proper branch rendering
3. Add node labels and UI elements
4. Optimize rendering performance

Remember to commit changes after each successful step and maintain proper error logging throughout the implementation.

## Ray Casting and Node Selection
For detailed analysis and debugging of the ray casting and node selection system, refer to `docs/tap_issues.md`. This document contains:
- Coordinate space transformation analysis
- Camera matrix construction verification
- Ray-sphere intersection testing
- Debug visualization recommendations
- Step-by-step solutions

Follow the debugging steps in `tap_issues.md` to verify and fix ray casting issues.

## Step 6: True Orbital Camera Movement

### Issue Identified
Current single-finger drag implements panning instead of true orbital movement. For a mind map visualization, we want the camera to orbit around the scene like a satellite around Earth, allowing users to view the mind map from different angles.

### 6.1 Separate Pan and Orbit Controls
```swift:Engine3D/Core/Camera.swift
enum CameraMovement {
    case pan    // Single-finger drag: moves camera parallel to view plane
    case orbit  // Two-finger drag: rotates camera around scene center
}

class Camera {
    // ... existing properties ...
    
    // Add movement mode
    var currentMovement: CameraMovement = .orbit
    
    // True orbital movement
    func orbit(deltaX: Float, deltaY: Float, sensitivity: Float = 0.01) {
        // Calculate the orbital rotation
        let horizontalRotation = simd_float4x4(rotationY: -deltaX * sensitivity)
        let verticalRotation = simd_float4x4(rotationX: -deltaY * sensitivity)
        
        // Combine rotations
        let rotation = matrix_multiply(horizontalRotation, verticalRotation)
        
        // Calculate new camera position by rotating current position around target
        let positionRelativeToTarget = position - target
        let rotatedPosition = rotation * SIMD4<Float>(positionRelativeToTarget.x,
                                                     positionRelativeToTarget.y,
                                                     positionRelativeToTarget.z,
                                                     1.0)
        
        // Update camera position
        position = target + SIMD3<Float>(rotatedPosition.x,
                                       rotatedPosition.y,
                                       rotatedPosition.z)
        
        // Update up vector to maintain proper orientation
        let upVector = rotation * SIMD4<Float>(up.x, up.y, up.z, 0.0)
        up = normalize(SIMD3<Float>(upVector.x, upVector.y, upVector.z))
    }
    
    // Separate pan function
    func pan(deltaX: Float, deltaY: Float, sensitivity: Float = 0.01) {
        let forward = normalize(target - position)
        let right = normalize(cross(up, forward))
        let upAdjusted = normalize(cross(forward, right))
        
        // Scale movement based on distance from target
        let distanceToTarget = length(target - position)
        let moveScale = distanceToTarget * sensitivity
        
        // Calculate movement in camera's local space
        let movement = right * (-deltaX * moveScale) + upAdjusted * (-deltaY * moveScale)
        
        // Move both camera and target to maintain relative position
        position += movement
        target += movement
    }
}
```

### 6.2 Update Gesture Handling
```swift:Engine3D/Views/Engine3DView.swift
@objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
    guard let renderer = parent.renderer else { return }
    
    switch gesture.state {
    case .began:
        lastPanLocation = gesture.location(in: gesture.view)
        
    case .changed:
        guard let lastLocation = lastPanLocation,
              let view = gesture.view else { return }
        
        let currentLocation = gesture.location(in: view)
        let deltaX = Float(currentLocation.x - lastLocation.x)
        let deltaY = Float(currentLocation.y - lastLocation.y)
        
        // Scale deltas based on view size
        let viewSize = view.bounds.size
        let scaledDeltaX = deltaX / Float(viewSize.width) * 2.0
        let scaledDeltaY = deltaY / Float(viewSize.height) * 2.0
        
        if gesture.numberOfTouches == 1 {
            // Single finger: pan
            renderer.camera.pan(deltaX: scaledDeltaX, deltaY: scaledDeltaY)
        } else if gesture.numberOfTouches == 2 {
            // Two fingers: orbit
            renderer.camera.orbit(deltaX: scaledDeltaX, deltaY: scaledDeltaY)
        }
        
        lastPanLocation = currentLocation
        
    case .ended, .cancelled:
        lastPanLocation = nil
        
    default:
        break
    }
}
```

### Expected Behavior
1. **Single-finger Pan**:
   - Camera moves parallel to view plane
   - Mind map appears to slide left/right/up/down
   - Maintains current viewing angle

2. **Two-finger Orbit**:
   - Camera rotates around scene center
   - Mind map appears to spin like a globe
   - Can see different sides of the mind map structure
   - Maintains constant distance from center

### Testing Step 6
```swift
func testCameraMovements() {
    guard let renderer = renderer else { return }
    
    // Test orbit movement
    print("Testing orbital movement...")
    print("Initial camera position:", renderer.camera.position)
    
    // Simulate 90-degree orbital rotation
    renderer.camera.orbit(deltaX: Float.pi/2, deltaY: 0)
    print("Camera position after horizontal orbit:", renderer.camera.position)
    
    // Test pan movement
    print("Testing pan movement...")
    renderer.camera.pan(deltaX: 1.0, deltaY: 0)
    print("Camera position after horizontal pan:", renderer.camera.position)
}
```

### Verification Steps
1. Start with camera at (0, 2, 10)
2. Perform two-finger drag:
   - Mind map should rotate as a whole
   - Should be able to see "behind" nodes
   - Camera maintains distance from center
3. Perform single-finger drag:
   - Mind map should slide without rotation
   - View angle remains constant
4. Verify node selection still works from all angles

### Common Issues and Solutions
1. **Disorientation During Orbit**
   - Add visual reference point at scene center
   - Implement smooth rotation transitions
   - Add optional grid or ground plane

2. **Loss of Up Vector**
   - Implement up vector correction during orbit
   - Add optional camera auto-leveling

3. **Selection After Orbit**
   - Ensure ray casting accounts for new camera orientation
   - Update hit testing for rotated view