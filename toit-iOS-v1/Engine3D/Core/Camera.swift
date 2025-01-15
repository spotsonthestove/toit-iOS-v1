import simd

class Camera {
    var position: SIMD3<Float>
    var target: SIMD3<Float>
    var up: SIMD3<Float> = SIMD3<Float>(0, 1, 0)
    
    private var aspect: Float = 1.0
    private let fov: Float = Float.pi / 3.0
    private let near: Float = 0.1
    private let far: Float = 100.0
    
    init(position: SIMD3<Float>, target: SIMD3<Float>) {
        self.position = position
        self.target = target
        print("Camera initialized at position: \(position), looking at: \(target)")
    }
    
    var viewMatrix: matrix_float4x4 {
        // Calculate view vectors
        let forward = normalize(target - position)
        let right = normalize(cross(up, forward))
        let upAdjusted = normalize(cross(forward, right))  // Use this for orthogonalization
        
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
        // Convert screen deltas to radians
        let angleX = deltaX * sensitivity
        let angleY = deltaY * sensitivity
        
        // Calculate camera vectors
        let forward = normalize(target - position)
        let right = normalize(cross(up, forward))
        
        // Create rotation matrices
        let rotationAroundY = simd_float4x4(rotationAroundAxis: SIMD3<Float>(0, angleX, 0))
        let rotationAroundX = simd_float4x4(rotationAroundAxis: right * angleY)
        
        // Apply rotations
        let combinedRotation = matrix_multiply(rotationAroundY, rotationAroundX)
        let relativePosition = position - target
        let rotatedPosition = combinedRotation * SIMD4<Float>(relativePosition.x, relativePosition.y, relativePosition.z, 1.0)
        position = target + SIMD3<Float>(rotatedPosition.x, rotatedPosition.y, rotatedPosition.z)
        
        // Rotate the up vector as well
        let upVector = SIMD4<Float>(up.x, up.y, up.z, 0.0)
        let rotatedUp = combinedRotation * upVector
        up = normalize(SIMD3<Float>(rotatedUp.x, rotatedUp.y, rotatedUp.z))
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