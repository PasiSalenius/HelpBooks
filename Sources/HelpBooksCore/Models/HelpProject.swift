import Foundation

public class HelpProject {
    public var id: UUID
    public var name: String
    public var sourceDirectory: URL?
    public var assetsDirectory: URL?
    public var documents: [MarkdownDocument]
    public var fileTree: FileTreeNode?
    public var metadata: HelpBookMetadata
    public var assets: [AssetReference]
    public var createdAt: Date
    public var modifiedAt: Date

    public var isValid: Bool {
        !metadata.bundleIdentifier.isEmpty &&
        !metadata.bundleName.isEmpty &&
        !metadata.helpBookTitle.isEmpty &&
        !documents.isEmpty
    }

    public var validationErrors: [String] {
        var errors: [String] = []
        if metadata.bundleIdentifier.isEmpty {
            errors.append("Bundle identifier is required")
        }
        if metadata.bundleName.isEmpty {
            errors.append("Bundle name is required")
        }
        if metadata.helpBookTitle.isEmpty {
            errors.append("Help Book title is required")
        }
        if documents.isEmpty {
            errors.append("No documents found")
        }
        return errors
    }

    public init(
        id: UUID = UUID(),
        name: String,
        sourceDirectory: URL? = nil,
        assetsDirectory: URL? = nil,
        documents: [MarkdownDocument] = [],
        fileTree: FileTreeNode? = nil,
        metadata: HelpBookMetadata,
        assets: [AssetReference] = [],
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.sourceDirectory = sourceDirectory
        self.assetsDirectory = assetsDirectory
        self.documents = documents
        self.fileTree = fileTree
        self.metadata = metadata
        self.assets = assets
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}
