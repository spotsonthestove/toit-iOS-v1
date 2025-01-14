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

## Final Testing Checklist

1. Camera Positioning
- [ ] Camera properly positioned at (0, 0, -5)
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
