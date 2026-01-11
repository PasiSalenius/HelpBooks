import Foundation
import Down

class ShortcodeProcessor {
    func process(_ content: String) -> String {
        var processed = content

        // Process alert shortcodes
        processed = processAlertShortcodes(processed)

        // Add more shortcode processors here as needed

        return processed
    }

    private func processAlertShortcodes(_ content: String) -> String {
        // Match: {{< alert icon="..." context="..." text="..." />}}
        let pattern = #"\{\{<\s*alert\s+([^>]*)/>\s*\}\}"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            print("⚠️ Failed to create regex for alert shortcodes")
            return content
        }

        let nsString = content as NSString
        let matches = regex.matches(in: content, options: [], range: NSRange(location: 0, length: nsString.length))

        var result = content

        // Process matches in reverse to maintain string indices
        for match in matches.reversed() {
            let attributesRange = match.range(at: 1)
            let attributes = nsString.substring(with: attributesRange)

            // Parse attributes
            let icon = extractAttribute(name: "icon", from: attributes) ?? ""
            let context = extractAttribute(name: "context", from: attributes) ?? "info"
            let text = extractAttribute(name: "text", from: attributes) ?? ""

            // Convert to HTML
            let html = generateAlertHTML(icon: icon, context: context, text: text)

            // Replace in result
            if let range = Range(match.range, in: result) {
                result.replaceSubrange(range, with: html)
            }
        }

        return result
    }

    private func extractAttribute(name: String, from attributes: String) -> String? {
        // Use regex to properly match: name="value" or name='value'
        // Handle both quote types separately to allow opposite quotes inside values
        // Pattern: name = "..." OR name = '...'
        let pattern = "\\b\(name)\\s*=\\s*(?:\"([^\"]*)\"|'([^']*)')"

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }

        let nsString = attributes as NSString
        let range = NSRange(location: 0, length: nsString.length)

        guard let match = regex.firstMatch(in: attributes, options: [], range: range) else {
            return nil
        }

        // Check which capture group matched (group 1 for double quotes, group 2 for single quotes)
        let doubleQuoteRange = match.range(at: 1)
        let singleQuoteRange = match.range(at: 2)

        let valueRange = doubleQuoteRange.location != NSNotFound ? doubleQuoteRange : singleQuoteRange
        guard valueRange.location != NSNotFound else {
            return nil
        }

        let value = nsString.substring(with: valueRange)
        return value
    }

    private func generateAlertHTML(icon: String, context: String, text: String) -> String {
        let contextClass: String
        let backgroundColor: String
        let borderColor: String
        let defaultIcon: String

        switch context.lowercased() {
        case "info":
            contextClass = "alert-info"
            backgroundColor = "#d1ecf1"
            borderColor = "#bee5eb"
            defaultIcon = "ℹ️"
        case "primary":
            contextClass = "alert-primary"
            backgroundColor = "#cce5ff"
            borderColor = "#b8daff"
            defaultIcon = "ℹ️"  // info material symbol
        case "warning":
            contextClass = "alert-warning"
            backgroundColor = "#fff3cd"
            borderColor = "#ffeaa7"
            defaultIcon = "⚠️"  // warning material symbol
        case "danger", "error":
            contextClass = "alert-danger"
            backgroundColor = "#f8d7da"
            borderColor = "#f5c6cb"
            defaultIcon = "❗️"  // report material symbol
        case "success":
            contextClass = "alert-success"
            backgroundColor = "#d4edda"
            borderColor = "#c3e6cb"
            defaultIcon = "✅"  // check_circle material symbol
        case "light":
            contextClass = "alert-light"
            backgroundColor = "#fefefe"
            borderColor = "#e9ecef"
            defaultIcon = "💡"
        case "dark":
            contextClass = "alert-dark"
            backgroundColor = "#d6d8d9"
            borderColor = "#c6c8ca"
            defaultIcon = "◾️"
        default:
            contextClass = "alert-info"
            backgroundColor = "#d1ecf1"
            borderColor = "#bee5eb"
            defaultIcon = "ℹ️"
        }

        // Use provided icon or default icon based on context
        let displayIcon = icon.isEmpty ? defaultIcon : icon

        // Process inline markdown in text
        let processedText = processInlineMarkdown(text)

        return """
        <div class="alert \(contextClass)" style="padding: 12px 16px; margin: 16px 0; border-left: 4px solid \(borderColor); background-color: \(backgroundColor); border-radius: 4px;">
            <span style="font-size: 1.2em; margin-right: 8px;">\(displayIcon)</span>
            <span>\(processedText)</span>
        </div>
        """
    }

    private func processInlineMarkdown(_ text: String) -> String {
        do {
            let down = Down(markdownString: text)
            var html = try down.toHTML(.unsafe)

            // Remove the wrapping <p> tags that Down adds
            html = html.trimmingCharacters(in: .whitespacesAndNewlines)
            if html.hasPrefix("<p>") && html.hasSuffix("</p>") {
                html = String(html.dropFirst(3).dropLast(4))
            }

            return html
        } catch {
            // If markdown processing fails, return the original text
            return text
        }
    }
}
