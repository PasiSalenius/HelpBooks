import Foundation

public struct AssetReference: Identifiable, Codable {
    public enum AssetType: String, Codable {
        case image
        case css
        case javascript
        case other
    }

    public let id: UUID
    public let originalPath: URL
    public let relativePath: String
    public let type: AssetType
    public var referencedBy: [UUID]

    public var fileName: String {
        originalPath.lastPathComponent
    }

    public init(
        id: UUID = UUID(),
        originalPath: URL,
        relativePath: String,
        type: AssetType,
        referencedBy: [UUID] = []
    ) {
        self.id = id
        self.originalPath = originalPath
        self.relativePath = relativePath
        self.type = type
        self.referencedBy = referencedBy
    }
}
