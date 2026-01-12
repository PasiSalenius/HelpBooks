import Foundation
import SwiftUI

@Observable
class PreviewViewModel {
    var refreshTrigger = 0

    func refresh() {
        refreshTrigger += 1
    }

    private func fixImagePaths(_ html: String) -> String {
        // Convert image paths to use the asset:// scheme
        // This allows the custom URL scheme handler to serve images from any location
        // Example: /images/foo.webp -> asset:///images/foo.webp
        // Example: images/foo.webp -> asset:///images/foo.webp
        var fixed = html

        // Match img src attributes (both absolute and relative paths)
        let pattern = #"<img\s+([^>]*\s)?src="([^"]+)"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let nsString = html as NSString
            let matches = regex.matches(in: html, options: [], range: NSRange(location: 0, length: nsString.length))

            // Process in reverse to maintain indices
            for match in matches.reversed() {
                let pathRange = match.range(at: 2)
                if pathRange.location != NSNotFound {
                    let path = nsString.substring(with: pathRange)

                    // Skip data URLs and external URLs
                    if path.hasPrefix("data:") || path.hasPrefix("http://") || path.hasPrefix("https://") {
                        continue
                    }

                    // Convert to asset:// scheme
                    let assetPath = "asset://\(path)"

                    if let range = Range(pathRange, in: fixed) {
                        fixed.replaceSubrange(range, with: assetPath)
                    }
                }
            }
        }

        return fixed
    }

    func htmlForPreview(
        _ document: MarkdownDocument,
        colorScheme: ColorScheme,
        theme: HelpBookTheme
    ) -> String {
        let isDark = colorScheme == .dark

        guard let htmlContent = document.htmlContent else {
            return """
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="UTF-8">
                <title>\(document.title)</title>
                <style>
                    body {
                        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
                        padding: 20px;
                        max-width: 800px;
                        margin: 0 auto;
                        background: \(isDark ? "#1e1e1e" : "#ffffff");
                        color: \(isDark ? "#e6e6e6" : "#333");
                    }
                    .error {
                        color: \(isDark ? "#ff6961" : "#ff3b30");
                        background: \(isDark ? "#3d2b2b" : "#ffebee");
                        padding: 10px;
                        border-radius: 4px;
                    }
                </style>
            </head>
            <body>
                <div class="error">
                    <h2>No Content</h2>
                    <p>This document has not been processed yet.</p>
                </div>
            </body>
            </html>
            """
        }

        // Fix image paths to be relative (remove leading /)
        let fixedContent = fixImagePaths(htmlContent)

        // Get CSS from ThemeManager based on selected theme
        let css = ThemeManager.css(for: theme)

        // Wrap the HTML content in a complete HTML document with the selected theme styling
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>\(document.title)</title>
            <style>
                \(css)

                /* Preview-specific adjustments: hide sidebar elements */
                .help-sidebar,
                .breadcrumb {
                    display: none;
                }

                .help-main-content {
                    margin-left: 0 !important;
                }

                .page-content {
                    max-width: 900px;
                    margin: 0 auto;
                }
            </style>
        </head>
        <body>
            <div class="page-content">
                <h1>\(document.title)</h1>
                \(document.description.map { "<p class=\"subtitle\">\($0)</p>" } ?? "")
                \(fixedContent)
            </div>
        </body>
        </html>
        """
    }
}
