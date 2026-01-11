import Foundation

struct MarkdownDocument: Identifiable, Codable {
    let id: UUID
    let relativePath: String
    let fileName: String
    var frontMatter: FrontMatter
    var content: String
    var htmlContent: String?
    var lastModified: Date

    var title: String {
        frontMatter.title ?? fileName.replacingOccurrences(of: ".md", with: "")
    }

    var keywords: [String] {
        frontMatter.keywords ?? []
    }

    var description: String? {
        frontMatter.description
    }

    init(
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
