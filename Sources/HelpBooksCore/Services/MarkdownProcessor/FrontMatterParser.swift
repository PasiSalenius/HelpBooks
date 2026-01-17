import Foundation
import Yams

public enum FrontMatterFormat {
    case yaml
    case toml
    case none
}

public enum FrontMatterParserError: Error {
    case invalidFormat
    case unsupportedFormat
    case parsingFailed(String)
}

public class FrontMatterParser {
    public init() {}

    public func parse(_ content: String) throws -> (FrontMatter, String) {
        let format = detectFormat(content)

        switch format {
        case .yaml:
            return try parseYAML(content)
        case .toml:
            return try parseTOML(content)
        case .none:
            return (FrontMatter(), content)
        }
    }

    private func detectFormat(_ content: String) -> FrontMatterFormat {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.hasPrefix("---") {
            return .yaml
        } else if trimmed.hasPrefix("+++") {
            return .toml
        } else {
            return .none
        }
    }

    private func parseYAML(_ content: String) throws -> (FrontMatter, String) {
        // Find YAML delimiters
        let lines = content.components(separatedBy: .newlines)
        guard lines.first?.trimmingCharacters(in: .whitespaces) == "---" else {
            throw FrontMatterParserError.invalidFormat
        }

        // Find closing delimiter
        var yamlEndIndex = -1
        for (index, line) in lines.dropFirst().enumerated() {
            if line.trimmingCharacters(in: .whitespaces) == "---" {
                yamlEndIndex = index + 1
                break
            }
        }

        guard yamlEndIndex > 0 else {
            throw FrontMatterParserError.invalidFormat
        }

        // Extract YAML content
        let yamlLines = Array(lines[1..<yamlEndIndex])
        let yamlString = yamlLines.joined(separator: "\n")

        // Parse YAML
        do {
            let yaml = try Yams.load(yaml: yamlString) as? [String: Any] ?? [:]
            let frontMatter = parseFrontMatterDict(yaml)

            // Extract remaining body
            let bodyLines = Array(lines.dropFirst(yamlEndIndex + 1))
            let body = bodyLines.joined(separator: "\n")

            return (frontMatter, body)
        } catch {
            throw FrontMatterParserError.parsingFailed(error.localizedDescription)
        }
    }

    private func parseTOML(_ content: String) throws -> (FrontMatter, String) {
        // TOML parsing not implemented yet - would need TOMLDecoder dependency
        // For now, just return empty front matter and full content
        let lines = content.components(separatedBy: .newlines)
        guard lines.first?.trimmingCharacters(in: .whitespaces) == "+++" else {
            throw FrontMatterParserError.invalidFormat
        }

        // Find closing delimiter
        var tomlEndIndex = -1
        for (index, line) in lines.dropFirst().enumerated() {
            if line.trimmingCharacters(in: .whitespaces) == "+++" {
                tomlEndIndex = index + 1
                break
            }
        }

        guard tomlEndIndex > 0 else {
            throw FrontMatterParserError.invalidFormat
        }

        // Extract body (skip TOML parsing for now)
        let bodyLines = Array(lines.dropFirst(tomlEndIndex + 1))
        let body = bodyLines.joined(separator: "\n")

        // Return empty front matter for now - can implement TOML parsing later if needed
        print("Warning: TOML front matter detected but not fully parsed. Using defaults.")
        return (FrontMatter(), body)
    }

    private func parseFrontMatterDict(_ dict: [String: Any]) -> FrontMatter {
        var frontMatter = FrontMatter()

        if let title = dict["title"] as? String {
            frontMatter.title = title
        }

        if let description = dict["description"] as? String {
            frontMatter.description = description
        }

        if let keywords = dict["keywords"] as? [String] {
            frontMatter.keywords = keywords
        } else if let keywordsString = dict["keywords"] as? String {
            frontMatter.keywords = keywordsString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        }

        if let draft = dict["draft"] as? Bool {
            frontMatter.draft = draft
        }

        if let weight = dict["weight"] as? Int {
            frontMatter.weight = weight
        }

        if let aliases = dict["aliases"] as? [String] {
            frontMatter.aliases = aliases
        }

        if let tags = dict["tags"] as? [String] {
            frontMatter.tags = tags
        }

        if let categories = dict["categories"] as? [String] {
            frontMatter.categories = categories
        }

        // Store any custom properties
        var customProps: [String: String] = [:]
        let knownKeys = ["title", "description", "keywords", "date", "draft", "weight", "aliases", "tags", "categories"]
        for (key, value) in dict {
            if !knownKeys.contains(key), let stringValue = value as? String {
                customProps[key] = stringValue
            }
        }
        frontMatter.customProperties = customProps

        return frontMatter
    }
}
