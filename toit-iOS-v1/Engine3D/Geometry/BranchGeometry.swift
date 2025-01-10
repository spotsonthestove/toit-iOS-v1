import Metal
import simd

class BranchGeometry {
    private(set) var vertices: [Vertex] = []
    private(set) var indices: [UInt16] = []
    
    private let radialSegments: Int
    private let radius: Float
    
    init(radius: Float = 0.05, radialSegments: Int = 8) {
        self.radius = radius
        self.radialSegments = radialSegments
    }
    
    func updateGeometry(from startNode: Engine3DSceneNode, to endNode: Engine3DSceneNode) {
        let startPos = startNode.worldMatrix.columns.3.xyz
        let endPos = endNode.worldMatrix.columns.3.xyz
        generateBranch(from: startPos, to: endPos)
    }
    
    private func generateBranch(from start: SIMD3<Float>, to end: SIMD3<Float>) {
        vertices.removeAll()
        indices.removeAll()
        
        let direction = end - start
        let length = simd.length(direction)
        let normalizedDirection = normalize(direction)
        
        // Calculate rotation matrix
        let defaultUp = SIMD3<Float>(0, 1, 0)
        let rotationAxis = cross(defaultUp, normalizedDirection)
        let rotationAngle = acos(dot(defaultUp, normalizedDirection))
        let rotationMatrix = simd_float4x4(
            simd_quatf(angle: rotationAngle, axis: normalize(rotationAxis))
        )
        
        // Generate vertices
        for segment in 0...1 {
            let z = Float(segment) * length
            let centerPoint = start + normalizedDirection * z
            
            for radialSegment in 0...radialSegments {
                let angle = Float(radialSegment) * 2.0 * .pi / Float(radialSegments)
                let x = cos(angle) * radius
                let y = sin(angle) * radius
                
                var point = SIMD3<Float>(x, y, 0)
                let rotatedPoint = (rotationMatrix * SIMD4<Float>(point, 1.0)).xyz
                point = centerPoint + rotatedPoint
                
                let normal = normalize(rotatedPoint)
                vertices.append(Vertex(
                    position: point,
                    normal: normal
                ))
            }
        }
        
        // Generate indices
        for segment in 0..<1 {
            let segmentOffset = segment * (radialSegments + 1)
            for radialSegment in 0..<radialSegments {
                let i0 = segmentOffset + radialSegment
                let i1 = segmentOffset + radialSegment + 1
                let i2 = i0 + radialSegments + 1
                let i3 = i1 + radialSegments + 1
                
                indices.append(contentsOf: [UInt16(i0), UInt16(i2), UInt16(i1)])
                indices.append(contentsOf: [UInt16(i1), UInt16(i2), UInt16(i3)])
            }
        }
    }
} 