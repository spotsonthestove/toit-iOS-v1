import simd

class TestCamera {
    var position: Float3
    var target: Float3
    var up: Float3
    
    init(position: Float3 = Float3(0, 0, -5),
         target: Float3 = Float3(0, 0, 0),
         up: Float3 = Float3(0, 1, 0)) {
        self.position = position
        self.target = target
        self.up = up
    }
    
    func viewMatrix() -> Matrix4 {
        return simd_look_at_matrix(position, target, up)
    }
}

private func simd_look_at_matrix(_ eye: Float3, _ center: Float3, _ up: Float3) -> Matrix4 {
    let z = normalize(eye - center)
    let x = normalize(cross(up, z))
    let y = cross(z, x)
    
    let translate = Matrix4(
        [1, 0, 0, 0],
        [0, 1, 0, 0],
        [0, 0, 1, 0],
        [-eye.x, -eye.y, -eye.z, 1]
    )
    
    let rotate = Matrix4(
        [x.x, y.x, z.x, 0],
        [x.y, y.y, z.y, 0],
        [x.z, y.z, z.z, 0],
        [0, 0, 0, 1]
    )
    
    return matrix_multiply(rotate, translate)
} 