import Foundation

@Observable
class HelpProject {
    var id: UUID
    var name: String
    var sourceDirectory: URL?
    var assetsDirectory: URL?
    var documents: [MarkdownDocument]
    var fileTree: FileTreeNode?
    var metadata: HelpBookMetadata
    var assets: [AssetReference]
    var createdAt: Date
    var modifiedAt: Date

    var isValid: Bool {
        !metadata.bundleIdentifier.isEmpty &&
        !metadata.bundleName.isEmpty &&
        !metadata.helpBookTitle.isEmpty &&
        !documents.isEmpty
    }

    var validationErrors: [String] {
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

    init(
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
