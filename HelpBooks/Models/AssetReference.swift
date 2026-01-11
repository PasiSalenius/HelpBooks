import Foundation

struct AssetReference: Identifiable, Codable {
    enum AssetType: String, Codable {
        case image
        case css
        case javascript
        case other

        var displayName: String {
            switch self {
            case .image: return "Images"
            case .css: return "Stylesheets"
            case .javascript: return "Scripts"
            case .other: return "Other"
            }
        }

        var systemImage: String {
            switch self {
            case .image: return "photo"
            case .css: return "doc.text"
            case .javascript: return "chevron.left.forwardslash.chevron.right"
            case .other: return "doc"
            }
        }
    }

    let id: UUID
    let originalPath: URL
    let relativePath: String
    let type: AssetType
    var referencedBy: [UUID]

    var fileName: String {
        originalPath.lastPathComponent
    }

    init(
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
