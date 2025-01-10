import Metal
import Foundation
import simd

// MARK: - Basic Types
struct Vertex {
    var position: SIMD3<Float>
    var normal: SIMD3<Float>
    var color: SIMD4<Float>
}

// MARK: - Uniforms
struct Uniforms {
    var modelMatrix: matrix_float4x4
    var viewMatrix: matrix_float4x4
    var projectionMatrix: matrix_float4x4
    var normalMatrix: matrix_float3x3
    var color: SIMD4<Float>
    var lightPosition: SIMD3<Float>
}

// Add BranchUniforms struct
struct BranchUniforms {
    var modelMatrix: simd_float4x4
    var viewMatrix: simd_float4x4
    var projectionMatrix: simd_float4x4
    var normalMatrix: simd_float4x4
    var color: SIMD4<Float>
    var lightPosition: SIMD3<Float>
    var ambientIntensity: Float
    var diffuseIntensity: Float
}

// MARK: - Matrix Helper Functions
func createTranslationMatrix(_ translationX: Float, _ translationY: Float, _ translationZ: Float) -> matrix_float4x4 {
    return matrix_float4x4(
        SIMD4<Float>(1, 0, 0, 0),
        SIMD4<Float>(0, 1, 0, 0),
        SIMD4<Float>(0, 0, 1, 0),
        SIMD4<Float>(translationX, translationY, translationZ, 1)
    )
}

func matrix_perspective_right_hand(fovyRadians: Float, aspectRatio: Float, nearZ: Float, farZ: Float) -> matrix_float4x4 {
    let ys = 1 / tanf(fovyRadians * 0.5)
    let xs = ys / aspectRatio
    let zs = farZ / (nearZ - farZ)
    
    return matrix_float4x4(
        SIMD4<Float>(xs, 0, 0, 0),
        SIMD4<Float>(0, ys, 0, 0),
        SIMD4<Float>(0, 0, zs, -1),
        SIMD4<Float>(0, 0, zs * nearZ, 0)
    )
}

extension matrix_float4x4 {
    var upperLeft3x3: matrix_float3x3 {
        let x = columns.0.xyz
        let y = columns.1.xyz
        let z = columns.2.xyz
        return matrix_float3x3(columns: (x, y, z))
    }
}

extension SIMD4 {
    var xyz: SIMD3<Scalar> {
        return SIMD3(x, y, z)
    }
}

func matrix_float3x3(normalFrom4x4 matrix: matrix_float4x4) -> matrix_float3x3 {
    let upperLeft = matrix.upperLeft3x3
    return upperLeft.transpose
}

extension SIMD3 where Scalar == Float {
    var normalized: Self {
        let length = sqrt(x*x + y*y + z*z)
        return length > 0 ? self / length : self
    }
} 

extension simd_float4x4 {
    init(rotationAxis axis: SIMD3<Float>, angle: Float) {
        let normalizedAxis = normalize(axis)
        let ct = cosf(angle)
        let st = sinf(angle)
        let ci = 1 - ct
        
        let x = normalizedAxis.x, y = normalizedAxis.y, z = normalizedAxis.z
        
        self.init(
            SIMD4<Float>(ct + x * x * ci, y * x * ci + z * st, z * x * ci - y * st, 0),
            SIMD4<Float>(x * y * ci - z * st, ct + y * y * ci, z * y * ci + x * st, 0),
            SIMD4<Float>(x * z * ci + y * st, y * z * ci - x * st, ct + z * z * ci, 0),
            SIMD4<Float>(0, 0, 0, 1)
        )
    }
} 