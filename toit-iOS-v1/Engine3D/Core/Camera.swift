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
        let forward = normalize(target - position)
        let right = normalize(cross(up, forward))
        let upNew = cross(forward, right)
        
        let translationMatrix = matrix_float4x4(columns: (
            SIMD4<Float>(1, 0, 0, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(0, 0, 1, 0),
            SIMD4<Float>(-position.x, -position.y, -position.z, 1)
        ))
        
        let rotationMatrix = matrix_float4x4(columns: (
            SIMD4<Float>(right.x, right.y, right.z, 0),
            SIMD4<Float>(upNew.x, upNew.y, upNew.z, 0),
            SIMD4<Float>(forward.x, forward.y, forward.z, 0),
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
} 