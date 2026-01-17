import Foundation

public struct MarkdownDocument: Identifiable, Codable {
    public let id: UUID
    public let relativePath: String
    public let fileName: String
    public var frontMatter: FrontMatter
    public var content: String
    public var htmlContent: String?
    public var lastModified: Date

    public var title: String {
        frontMatter.title ?? fileName.replacingOccurrences(of: ".md", with: "")
    }

    public var keywords: [String] {
        frontMatter.keywords ?? []
    }

    public var description: String? {
        frontMatter.description
    }

    public init(
        id: UUID = UUID(),
        relativePath: String,
        fileName: String,
        frontMatter: FrontMatter = FrontMatter(),
        content: String,
        htmlContent: String? = nil,
        lastModified: Date = Date()
    ) {
        self.id = id
        self.relativePath = relativePath
        self.fileName = fileName
        self.frontMatter = frontMatter
        self.content = content
        self.htmlContent = htmlContent
        self.lastModified = lastModified
    }
}
