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

    func htmlForPreview(_ document: MarkdownDocument, colorScheme: ColorScheme) -> String {
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

        // Wrap the HTML content in a complete HTML document with macOS Help Book styling
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>\(document.title)</title>
            <style>
                /* macOS Help Book styling - clean and minimal */
                body {
                    font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "Helvetica Neue", sans-serif;
                    font-size: 14px;
                    line-height: 1.5;
                    color: \(isDark ? "#e6e6e6" : "#000");
                    background: \(isDark ? "#1e1e1e" : "#fff");
                    padding: 20px 30px;
                    max-width: 100%;
                    margin: 0;
                    overflow-x: hidden;
                    box-sizing: border-box;
                }

                * {
                    box-sizing: border-box;
                }

                h1, h2, h3, h4, h5, h6 {
                    font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", "Helvetica Neue", sans-serif;
                    font-weight: 600;
                    margin-top: 24px;
                    margin-bottom: 12px;
                    line-height: 1.3;
                }

                h1 {
                    font-size: 28px;
                    font-weight: 700;
                    margin-top: 0;
                    margin-bottom: 8px;
                }

                .subtitle {
                    font-size: 15px;
                    color: \(isDark ? "rgba(255, 255, 255, 0.6)" : "rgba(0, 0, 0, 0.6)");
                    margin-top: 0;
                    margin-bottom: 24px;
                    font-weight: 400;
                }

                h2 {
                    font-size: 20px;
                    margin-top: 32px;
                }

                h3 {
                    font-size: 17px;
                    margin-top: 24px;
                }

                h4 {
                    font-size: 15px;
                    margin-top: 20px;
                }

                p {
                    margin: 0 0 12px 0;
                }

                ul, ol {
                    margin: 12px 0;
                    padding-left: 28px;
                }

                li {
                    margin: 6px 0;
                }

                code {
                    font-family: "SF Mono", "Menlo", "Monaco", "Courier New", monospace;
                    font-size: 12px;
                    background: \(isDark ? "rgba(255, 255, 255, 0.1)" : "rgba(0, 0, 0, 0.05)");
                    padding: 2px 5px;
                    border-radius: 3px;
                }

                pre {
                    background: \(isDark ? "rgba(255, 255, 255, 0.1)" : "rgba(0, 0, 0, 0.05)");
                    padding: 12px 16px;
                    border-radius: 6px;
                    overflow-x: auto;
                    overflow-y: hidden;
                    margin: 16px 0;
                    max-width: 100%;
                    word-wrap: break-word;
                }

                pre code {
                    background: none;
                    padding: 0;
                }

                a {
                    color: \(isDark ? "#6bb5ff" : "#007AFF");
                    text-decoration: none;
                }

                a:hover {
                    text-decoration: underline;
                }

                img {
                    max-width: 100%;
                    height: auto;
                    margin: 16px 0;
                    display: block;
                }

                blockquote {
                    border-left: 3px solid \(isDark ? "rgba(255, 255, 255, 0.2)" : "rgba(0, 0, 0, 0.15)");
                    padding-left: 16px;
                    margin: 16px 0;
                    color: \(isDark ? "rgba(255, 255, 255, 0.7)" : "rgba(0, 0, 0, 0.7)");
                }

                table {
                    border-collapse: collapse;
                    width: 100%;
                    max-width: 100%;
                    margin: 16px 0;
                    font-size: 13px;
                    table-layout: auto;
                    word-wrap: break-word;
                }

                th, td {
                    border: 1px solid \(isDark ? "rgba(255, 255, 255, 0.15)" : "rgba(0, 0, 0, 0.1)");
                    padding: 8px 12px;
                    text-align: left;
                }

                th {
                    background: \(isDark ? "rgba(255, 255, 255, 0.08)" : "rgba(0, 0, 0, 0.04)");
                    font-weight: 600;
                }

                /* Alert boxes */
                .alert {
                    display: flex;
                    align-items: flex-start;
                    padding: 12px 16px;
                    margin: 16px 0;
                    border-radius: 6px;
                    border-left: 4px solid;
                }

                .alert > span:first-child {
                    font-size: 1.2em;
                    margin-right: 8px;
                    flex-shrink: 0;
                }

                /* Dark mode alert box colors */
                \(isDark ? """
                .alert-info {
                    background-color: #1a3a4a !important;
                    border-color: #2a5a6a !important;
                    color: #e6e6e6 !important;
                }

                .alert-primary {
                    background-color: #1a2a4a !important;
                    border-color: #2a4a7a !important;
                    color: #e6e6e6 !important;
                }

                .alert-warning {
                    background-color: #4a3a1a !important;
                    border-color: #6a5a2a !important;
                    color: #e6e6e6 !important;
                }

                .alert-danger {
                    background-color: #4a1a1a !important;
                    border-color: #6a2a2a !important;
                    color: #e6e6e6 !important;
                }

                .alert-success {
                    background-color: #1a4a2a !important;
                    border-color: #2a6a3a !important;
                    color: #e6e6e6 !important;
                }

                .alert-light {
                    background-color: #2a2a2a !important;
                    border-color: #3a3a3a !important;
                    color: #e6e6e6 !important;
                }

                .alert-dark {
                    background-color: #1a1a1a !important;
                    border-color: #2a2a2a !important;
                    color: #e6e6e6 !important;
                }
                """ : "")
            </style>
        </head>
        <body>
            <h1>\(document.title)</h1>
            \(document.description.map { "<p class=\"subtitle\">\($0)</p>" } ?? "")
            \(fixedContent)
        </body>
        </html>
        """
    }
}
