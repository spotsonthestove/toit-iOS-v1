import simd

enum CameraMovement {
    case pan    // Two-finger drag: moves camera parallel to view plane
    case orbit  // Single-finger drag: rotates camera around scene center
}

class Camera {
    var position: SIMD3<Float>
    var target: SIMD3<Float>
    var up: SIMD3<Float> = SIMD3<Float>(0, 1, 0)
    
    // Add movement mode
    var currentMovement: CameraMovement = .orbit
    
    private var aspect: Float = 1.0
    private let fov: Float = Float.pi / 3.0
    private let near: Float = 0.1
    private let far: Float = 100.0
    
    init(position: SIMD3<Float>, target: SIMD3<Float>) {
        // Start with a better default position that matches testCameraSetup
        self.position = SIMD3<Float>(5, 5, 5)  // Changed from (0, 2, 10)
        self.target = SIMD3<Float>(0, 0, 0)     // Looking at center
        self.up = SIMD3<Float>(0, 1, 0)
        
        // Override with provided values if they're different from default
        if position != SIMD3<Float>(5, 5, 5) {  // Updated default check
            self.position = position
        }
        if target != SIMD3<Float>(0, 0, 0) {
            self.target = target
        }
        
        print("Camera initialized at position: \(self.position), looking at: \(self.target)")
    }
    
    var viewMatrix: matrix_float4x4 {
        // Calculate view vectors with adjusted forward direction
        let forward = normalize(position - target)  // Reversed from (target - position)
        let right = normalize(cross(up, forward))   // Changed order for right-handed coordinate system
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
    
    var projectionMatrix: matrix_float4x4 {
        let y = 1 / tan(fov * 0.5)
        let x = y / aspect
        let z = far / (far - near)
        let w = -z * near
        
        return matrix_float4x4(
            SIMD4<Float>(x, 0, 0, 0),
            SIMD4<Float>(0, y, 0, 0),
            SIMD4<Float>(0, 0, z, 1),
            SIMD4<Float>(0, 0, w, 0)
        )
    }
    
    func updateProjection(aspect: Float) {
        self.aspect = aspect
        print("Camera projection updated with aspect ratio: \(aspect)")
    }
    
    func debugPrintCameraMatrix() {
        print("Camera Position:", position)
        print("Camera Target:", target)
        print("View Matrix:\n", viewMatrix)
    }
    
    // MARK: - Camera Controls
    
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
        
        // Clamp vertical rotation to prevent camera flipping
        let verticalAngle = asin(dot(normalize(target - position), SIMD3<Float>(0, 1, 0)))
        if abs(verticalAngle) > Float.pi * 0.49 {
            up = SIMD3<Float>(0, 1, 0)
        }
        
        print("🔄 Orbital movement - Position: \(position), Up: \(up)")
    }
    
    func zoom(factor: Float, sensitivity: Float = 2.0) {
        let zoomAmount = factor * sensitivity
        let forward = normalize(target - position)
        position += forward * zoomAmount
        
        // Prevent zooming too close or too far
        let distance = length(target - position)
        if distance < 1.0 {
            position = target - forward
        } else if distance > 20.0 {
            position = target - forward * 20.0
        }
    }
    
    func roll(angle: Float, sensitivity: Float = 0.5) {
        let rotationAngle = angle * sensitivity
        let forward = normalize(target - position)
        let rotationMatrix = simd_float4x4(rotationAroundAxis: forward * rotationAngle)
        let upVector = SIMD4<Float>(up.x, up.y, up.z, 0.0)
        let rotatedUp = rotationMatrix * upVector
        up = normalize(SIMD3<Float>(rotatedUp.x, rotatedUp.y, rotatedUp.z))
        print("📐 Camera roll: angle=\(rotationAngle), up=\(up)")
    }
    
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
        
        print("✋ Pan movement - Position: \(position), Target: \(target)")
    }
} 

// MARK: - Matrix Extensions
extension simd_float4x4 {
    init(rotationAroundAxis axis: SIMD3<Float>) {
        let length = simd_length(axis)
        guard length > 0 else {
            self = matrix_identity_float4x4
            return
        }
        
        let x = axis.x / length
        let y = axis.y / length
        let z = axis.z / length
        let c = cosf(length)
        let s = sinf(length)
        let t = 1 - c
        
        self.init(columns: (
            SIMD4<Float>(t*x*x + c,   t*x*y + z*s, t*x*z - y*s, 0),
            SIMD4<Float>(t*x*y - z*s, t*y*y + c,   t*y*z + x*s, 0),
            SIMD4<Float>(t*x*z + y*s, t*y*z - x*s, t*z*z + c,   0),
            SIMD4<Float>(0,          0,          0,          1)
        ))
    }
} 