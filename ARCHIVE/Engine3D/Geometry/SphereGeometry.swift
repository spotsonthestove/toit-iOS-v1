import Metal
import simd

class SphereGeometry {
    private(set) var vertices: [Vertex] = []
    private(set) var indices: [UInt16] = []
    
    init(radius: Float, segments: Int = 16) {
        generateSphere(radius: radius, segments: segments)
    }
    
    private func generateSphere(radius: Float, segments: Int) {
        vertices.removeAll()
        indices.removeAll()
        
        // Generate vertices
        for lat in 0...segments {
            let phi = Float.pi * Float(lat) / Float(segments)
            let sinPhi = sin(phi)
            let cosPhi = cos(phi)
            
            for long in 0...segments {
                let theta = 2.0 * Float.pi * Float(long) / Float(segments)
                let sinTheta = sin(theta)
                let cosTheta = cos(theta)
                
                // Calculate position
                let x = radius * sinPhi * cosTheta
                let y = radius * cosPhi
                let z = radius * sinPhi * sinTheta
                
                let position = SIMD3<Float>(x, y, z)
                let normal = normalize(position) // For a sphere, normal is normalized position
                
                vertices.append(Vertex(
                    position: position,
                    normal: normal,
                    color: SIMD4<Float>(1.0, 1.0, 1.0, 1.0)
                ))
            }
        }
        
        // Generate indices
        for lat in 0..<segments {
            for long in 0..<segments {
                let first = UInt16(lat * (segments + 1) + long)
                let second = first + 1
                let third = first + UInt16(segments + 1)
                let fourth = third + 1
                
                // First triangle
                indices.append(first)
                indices.append(third)
                indices.append(second)
                
                // Second triangle
                indices.append(second)
                indices.append(third)
                indices.append(fourth)
            }
        }
        
        print("Generated sphere: \(vertices.count) vertices, \(indices.count) indices")
    }
} 