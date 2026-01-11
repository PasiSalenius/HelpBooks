import Foundation
import Down

enum MarkdownParserError: Error {
    case conversionFailed(String)
}

class MarkdownParser {
    func convert(_ markdown: String) throws -> String {
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
