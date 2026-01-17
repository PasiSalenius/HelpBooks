import Foundation

public struct FrontMatter: Codable {
    public var title: String?
    public var description: String?
    public var keywords: [String]?
    public var date: Date?
    public var draft: Bool?
    public var weight: Int?

    // Hugo-specific
    public var aliases: [String]?
    public var tags: [String]?
    public var categories: [String]?

    // Custom properties stored as dictionary
    public var customProperties: [String: String] = [:]

    public init(
        title: String? = nil,
        description: String? = nil,
        keywords: [String]? = nil,
        date: Date? = nil,
        draft: Bool? = nil,
        weight: Int? = nil,
        aliases: [String]? = nil,
        tags: [String]? = nil,
        categories: [String]? = nil,
        customProperties: [String: String] = [:]
    ) {
        self.title = title
        self.description = description
        self.keywords = keywords
        self.date = date
        self.draft = draft
        self.weight = weight
        self.aliases = aliases
        self.tags = tags
        self.categories = categories
        self.customProperties = customProperties
    }
}
