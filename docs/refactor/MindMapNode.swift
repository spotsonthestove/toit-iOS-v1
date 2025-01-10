import Foundation

struct MindMapNode: Identifiable {
    let id: UUID
    var title: String
    var description: String?
    var position: SIMD3<Float>
    var parentId: UUID?
    var isCenter: Bool
    var nodeType: String
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String? = nil,
        position: SIMD3<Float>,
        parentId: UUID? = nil,
        isCenter: Bool = false,
        nodeType: String = "default"
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.position = position
        self.parentId = parentId
        self.isCenter = isCenter
        self.nodeType = nodeType
    }
} 