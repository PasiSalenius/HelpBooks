import Foundation
import Down

public enum MarkdownParserError: Error {
    case conversionFailed(String)
}

public class MarkdownParser {
    public init() {}

    public func convert(_ markdown: String) throws -> String {
        do {
            let down = Down(markdownString: preprocessTables(markdown))
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
            let down = Down(markdownString: preprocessTables(markdown))
            return try down.toHTML(options)
        } catch {
            throw MarkdownParserError.conversionFailed(error.localizedDescription)
        }
    }

    // MARK: - GFM Table Preprocessing

    // cmark (used by Down) does not support GFM table syntax, so we convert
    // tables to HTML before parsing. This lets raw HTML pass through via .unsafe.

    private func preprocessTables(_ markdown: String) -> String {
        let lines = markdown.components(separatedBy: "\n")
        var result: [String] = []
        var i = 0
        while i < lines.count {
            if i + 1 < lines.count,
               isTableRow(lines[i]),
               isTableSeparator(lines[i + 1]) {
                var tableLines = [lines[i], lines[i + 1]]
                i += 2
                while i < lines.count && isTableRow(lines[i]) {
                    tableLines.append(lines[i])
                    i += 1
                }
                result.append(tableToHTML(tableLines))
            } else {
                result.append(lines[i])
                i += 1
            }
        }
        return result.joined(separator: "\n")
    }

    private func isTableRow(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        return trimmed.filter({ $0 == "|" }).count >= 2
    }

    private func isTableSeparator(_ line: String) -> Bool {
        var s = line.trimmingCharacters(in: .whitespaces)
        guard s.contains("|") else { return false }
        if s.hasPrefix("|") { s = String(s.dropFirst()) }
        if s.hasSuffix("|") { s = String(s.dropLast()) }
        let cells = s.components(separatedBy: "|")
        return !cells.isEmpty && cells.allSatisfy { cell in
            let c = cell.trimmingCharacters(in: .whitespaces)
            return !c.isEmpty && c.allSatisfy { $0 == "-" || $0 == ":" }
        }
    }

    private func parseTableCells(_ line: String) -> [String] {
        var s = line.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("|") { s = String(s.dropFirst()) }
        if s.hasSuffix("|") { s = String(s.dropLast()) }
        return s.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
    }

    // Render inline markdown (e.g. backtick code spans) within a table cell.
    private func renderInline(_ text: String) -> String {
        guard let html = try? Down(markdownString: text).toHTML(.unsafe) else { return text }
        return html
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "<p>", with: "")
            .replacingOccurrences(of: "</p>", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func tableToHTML(_ lines: [String]) -> String {
        guard lines.count >= 2 else { return lines.joined(separator: "\n") }
        let header = parseTableCells(lines[0])
        var html = "<table>\n<thead>\n<tr>\n"
        for cell in header { html += "<th>\(renderInline(cell))</th>\n" }
        html += "</tr>\n</thead>\n<tbody>\n"
        for i in 2 ..< lines.count {
            let cells = parseTableCells(lines[i])
            html += "<tr>\n"
            for cell in cells { html += "<td>\(renderInline(cell))</td>\n" }
            html += "</tr>\n"
        }
        html += "</tbody>\n</table>"
        return html
    }
}
