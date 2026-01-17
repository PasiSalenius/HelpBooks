import Foundation
import Down

public enum MarkdownParserError: Error {
    case conversionFailed(String)
}

public class MarkdownParser {
    public init() {}

    public func convert(_ markdown: String) throws -> String {
        do {
            let down = Down(markdownString: markdown)
            // Use .unsafe option to allow raw HTML to pass through
            // This is needed for shortcode processing after markdown conversion
            let html = try down.toHTML(.unsafe)
            return html
        } catch {
            throw MarkdownParserError.conversionFailed(error.localizedDescription)
        }
    }

    func convertWithOptions(_ markdown: String, options: DownOptions = .default) throws -> String {
        do {
            let down = Down(markdownString: markdown)
            return try down.toHTML(options)
        } catch {
            throw MarkdownParserError.conversionFailed(error.localizedDescription)
        }
    }
}
