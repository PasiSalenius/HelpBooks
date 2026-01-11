import Foundation

struct FrontMatter: Codable {
    var title: String?
    var description: String?
    var keywords: [String]?
    var date: Date?
    var draft: Bool?
    var weight: Int?

    // Hugo-specific (may vary)
    var aliases: [String]?
    var tags: [String]?
    var categories: [String]?

    // Custom properties stored as dictionary
    var customProperties: [String: String] = [:]

    init(
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
