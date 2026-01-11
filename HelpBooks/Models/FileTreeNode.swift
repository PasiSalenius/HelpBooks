import Foundation

struct FileTreeNode: Identifiable {
    let id: UUID
    let name: String
    let isDirectory: Bool
    var children: [FileTreeNode]?
    var documentId: UUID?
    var relativePath: String
    var isExpanded: Bool = true
    var weight: Int? // For sorting directories based on _index.md weight
    var title: String? // Display title from _index.md
    var description: String? // Description from _index.md

    init(
        id: UUID = UUID(),
        name: String,
        isDirectory: Bool,
        children: [FileTreeNode]? = nil,
        documentId: UUID? = nil,
        relativePath: String,
        isExpanded: Bool = true,
        weight: Int? = nil,
        title: String? = nil,
        description: String? = nil
    ) {
        self.id = id
        self.name = name
        self.isDirectory = isDirectory
        self.children = children
        self.documentId = documentId
        self.relativePath = relativePath
        self.isExpanded = isExpanded
        self.weight = weight
        self.title = title
        self.description = description
    }
}
