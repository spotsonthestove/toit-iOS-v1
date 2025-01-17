import simd

extension simd_float4x4 {
    init(translation: SIMD3<Float>) {
        self = matrix_identity_float4x4
        columns.3.x = translation.x
        columns.3.y = translation.y
        columns.3.z = translation.z
    }
    
    init(scale: SIMD3<Float>) {
        self = matrix_identity_float4x4
        columns.0.x = scale.x
        columns.1.y = scale.y
        columns.2.z = scale.z
    }
    
    init(rotation: SIMD3<Float>) {
        let rotationX = simd_float4x4(rotationX: rotation.x)
        let rotationY = simd_float4x4(rotationY: rotation.y)
        let rotationZ = simd_float4x4(rotationZ: rotation.z)
        self = rotationX * rotationY * rotationZ
    }
    
    init(rotationX: Float) {
        self = matrix_identity_float4x4
        columns.1.y = cos(rotationX)
        columns.1.z = sin(rotationX)
        columns.2.y = -sin(rotationX)
        columns.2.z = cos(rotationX)
    }
    
    init(rotationY: Float) {
        self = matrix_identity_float4x4
        columns.0.x = cos(rotationY)
        columns.0.z = -sin(rotationY)
        columns.2.x = sin(rotationY)
        columns.2.z = cos(rotationY)
    }
    
    init(rotationZ: Float) {
        self = matrix_identity_float4x4
        columns.0.x = cos(rotationZ)
        columns.0.y = sin(rotationZ)
        columns.1.x = -sin(rotationZ)
        columns.1.y = cos(rotationZ)
    }
} 