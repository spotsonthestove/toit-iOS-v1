import simd

// Basic type definitions
typealias Float2 = SIMD2<Float>
typealias Float3 = SIMD3<Float>
typealias Float4 = SIMD4<Float>
typealias Matrix4 = simd_float4x4

// Helper functions for SIMD operations
extension Float3 {
    static func - (lhs: Float3, rhs: Float3) -> Float3 {
        return Float3(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z)
    }
}

extension SIMD4 where Scalar == Float {
    var xyz: SIMD3<Float> {
        return SIMD3<Float>(x, y, z)
    }
} 