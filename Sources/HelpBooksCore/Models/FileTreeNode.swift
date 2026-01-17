import Foundation

public struct FileTreeNode: Identifiable {
    public let id: UUID
    public let name: String
    public let isDirectory: Bool
    public var children: [FileTreeNode]?
    public var documentId: UUID?
    public var relativePath: String
    public var isExpanded: Bool = true
    public var weight: Int?
    public var title: String?
    public var description: String?

    public init(
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
