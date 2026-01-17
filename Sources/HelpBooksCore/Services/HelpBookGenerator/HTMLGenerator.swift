import Foundation
import SwiftSoup

enum HTMLGeneratorError: Error, LocalizedError {
    case noHTMLContent
    case processingFailed(String)

    var errorDescription: String? {
        switch self {
        case .noHTMLContent:
            return "Document has no HTML content. Make sure the markdown has been processed."
        case .processingFailed(let details):
            return "Failed to process HTML: \(details)"
        }
    }
}

class HTMLGenerator {
    private let template: String
    private let breadcrumbGenerator: BreadcrumbGenerator
    private let sidebarGenerator: SidebarGenerator

    init(template: String? = nil) {
        self.template = template ?? Self.defaultTemplate
        self.breadcrumbGenerator = BreadcrumbGenerator()
        self.sidebarGenerator = SidebarGenerator()
    }

    func generate(
        document: MarkdownDocument,
        metadata: HelpBookMetadata,
        project: HelpProject,
        includeSidebar: Bool = false
    ) throws -> String {
        guard let htmlBody = document.htmlContent else {
            throw HTMLGeneratorError.noHTMLContent
        }

        do {
            // Parse the HTML content with just the markdown-generated HTML
            let tempDoc = try SwiftSoup.parse(htmlBody)
            let tempBody = tempDoc.body() ?? tempDoc

            // Create a clean document structure
            let doc = Document("")
            let html = try doc.appendElement("html")
            try html.attr("lang", "en")

            // Build head FIRST (before body) so charset is declared early
            let head = try html.appendElement("head")

            // Add charset as the VERY FIRST element in head
            let charset = try head.appendElement("meta")
            try charset.attr("charset", "UTF-8")

            // Add viewport
            let viewport = try head.appendElement("meta")
            try viewport.attr("name", "viewport")
            try viewport.attr("content", "width=device-width, initial-scale=1.0")

            // Add title
            let title = try head.appendElement("title")
            try title.text(document.title)

            // Add description meta
            if let description = document.description {
                let descMeta = try head.appendElement("meta")
                try descMeta.attr("name", "description")
                try descMeta.attr("content", description)
            }

            // Add keywords meta
            if !document.keywords.isEmpty {
                let keywordsMeta = try head.appendElement("meta")
                try keywordsMeta.attr("name", "keywords")
                try keywordsMeta.attr("content", document.keywords.joined(separator: ", "))
            }

            // Add robots meta (required for search indexing)
            let robotsMeta = try head.appendElement("meta")
            try robotsMeta.attr("name", "robots")
            try robotsMeta.attr("content", "index, anchors")

            // Add CSS link
            // Calculate depth: count directory separators in relative path
            // All files are in en.lproj/, so we need at least one "../" to get to Resources/
            let pathComponents = document.relativePath.split(separator: "/")
            let depth = pathComponents.count // includes the filename
            let upLevels = String(repeating: "../", count: depth)
            let link = try head.appendElement("link")
            try link.attr("rel", "stylesheet")
            try link.attr("href", "\(upLevels)assets/style.css")

            // Add iframe detection script (unless sidebar is included)
            if !includeSidebar {
                let script = try head.appendElement("script")
                try script.html(buildIframeDetectionScript(depth: depth, relativePath: document.relativePath))
            }

            // Generate sidebar only if includeSidebar is true
            let currentHtmlPath = document.relativePath.replacingOccurrences(of: ".md", with: ".html")
            let sidebarHTML: String?
            let sidebarJS: String?

            if includeSidebar {
                sidebarHTML = sidebarGenerator.generateSidebar(
                    project: project,
                    currentPath: currentHtmlPath
                )
                sidebarJS = sidebarGenerator.generateSidebarJavaScript()
            } else {
                sidebarHTML = nil
                sidebarJS = nil
            }

            // Always generate breadcrumbs for content pages
            let breadcrumbsHTML = breadcrumbGenerator.generateBreadcrumbs(
                document: document,
                project: project
            )

            // Build body structure (AFTER head)
            let body = try html.appendElement("body")

            // Add sidebar if included
            if let sidebar = sidebarHTML {
                try body.append(sidebar)
            }

            // Create main content wrapper
            let mainDiv = try body.appendElement("div")
            try mainDiv.attr("id", "help-main-content")
            try mainDiv.attr("class", includeSidebar ? "help-main-content with-sidebar" : "help-main-content")

            // Add breadcrumbs to main
            try mainDiv.append(breadcrumbsHTML)

            // Create page content wrapper
            let pageContent = try mainDiv.appendElement("div")
            try pageContent.attr("class", "page-content")

            // Add title and subtitle to page content
            let h1 = try pageContent.appendElement("h1")
            try h1.text(document.title)

            if let subtitle = document.description {
                let subtitleP = try pageContent.appendElement("p")
                try subtitleP.attr("class", "subtitle")
                try subtitleP.text(subtitle)
            }

            // Add the processed markdown content
            try pageContent.append(try tempBody.html())

            // Add JavaScript for sidebar at the end of body if included
            if let js = sidebarJS {
                try body.append(js)
            }

            // Fix image paths in the body
            try fixImagePaths(doc, depth: depth)

            // Rewrite absolute URLs to relative paths if baseURL is configured
            if !metadata.baseURL.isEmpty {
                try rewriteAbsoluteLinks(doc, document: document, project: project, baseURL: metadata.baseURL, depth: depth)
            }

            // Add named anchors to headings for deep linking
            try addNamedAnchors(doc)

            return try doc.outerHtml()
        } catch {
            throw HTMLGeneratorError.processingFailed(error.localizedDescription)
        }
    }

    private func buildMetaTags(_ document: MarkdownDocument) -> String {
        var tags: [String] = []

        // Description
        if let desc = document.description {
            tags.append("<meta name=\"description\" content=\"\(escape(desc))\" />")
        }

        // Keywords
        if !document.keywords.isEmpty {
            let keywords = document.keywords.map { escape($0) }.joined(separator: ", ")
            tags.append("<meta name=\"keywords\" content=\"\(keywords)\" />")
        }

        // Robots (for indexing)
        tags.append("<meta name=\"robots\" content=\"index, anchors\" />")

        return tags.joined(separator: "\n    ")
    }

    private func ensureTitleHeading(in body: Element, title: String, subtitle: String?) throws {
        // Check if the first element is an H1
        let firstChild = body.children().first()

        if let first = firstChild, first.tagName() == "h1" {
            // H1 already exists
            // Check if we need to add subtitle after it
            if let subtitle = subtitle {
                let subtitleP = Element(Tag("p"), "")
                try subtitleP.addClass("subtitle")
                try subtitleP.text(subtitle)
                try first.after(subtitleP.outerHtml())
            }
            return
        }

        // No H1 at the top, insert one
        let h1 = Element(Tag("h1"), "")
        try h1.text(title)
        try body.prependChild(h1)

        // Add subtitle if present
        if let subtitle = subtitle {
            let subtitleP = Element(Tag("p"), "")
            try subtitleP.addClass("subtitle")
            try subtitleP.text(subtitle)
            try h1.after(subtitleP.outerHtml())
        }
    }

    private func fixImagePaths(_ doc: Document, depth: Int) throws {
        let images = try doc.select("img")
        let upLevels = String(repeating: "../", count: depth)

        for img in images.array() {
            guard let src = try? img.attr("src"), !src.isEmpty else { continue }

            // Fix paths that start with / (absolute from content root)
            // e.g., /images/foo.png -> ../assets/foo.png
            if src.hasPrefix("/") {
                let fileName = URL(fileURLWithPath: src).lastPathComponent
                try img.attr("src", "\(upLevels)assets/\(fileName)")
            }
            // Fix paths that are relative but don't start with ../
            // e.g., images/foo.png -> ../assets/foo.png
            else if !src.hasPrefix("http") && !src.hasPrefix("../") {
                let fileName = URL(fileURLWithPath: src).lastPathComponent
                try img.attr("src", "\(upLevels)assets/\(fileName)")
            }
        }
    }

    private func rewriteAbsoluteLinks(_ doc: Document, document: MarkdownDocument, project: HelpProject, baseURL: String, depth: Int) throws {
        let links = try doc.select("a[href]")

        // Extract the directory prefix from the base URL
        // e.g., https://proxygen.app/docs → "docs"
        let baseURLPath = URL(string: baseURL)?.path ?? ""
        let baseDirName = baseURLPath.split(separator: "/").last.map(String.init) ?? ""

        for link in links.array() {
            guard let href = try? link.attr("href"), !href.isEmpty else { continue }

            // Check if this is an absolute URL that starts with our baseURL
            if href.hasPrefix(baseURL) {
                // Extract the path after the base URL
                var targetPath = String(href.dropFirst(baseURL.count))

                // Remove leading slash if present
                if targetPath.hasPrefix("/") {
                    targetPath = String(targetPath.dropFirst())
                }

                // Remove any fragment/anchor for path calculation
                var pathWithoutFragment: String
                let fragment: String?
                if let hashIndex = targetPath.firstIndex(of: "#") {
                    pathWithoutFragment = String(targetPath[..<hashIndex])
                    fragment = String(targetPath[hashIndex...])
                } else {
                    pathWithoutFragment = targetPath
                    fragment = nil
                }

                // Remove trailing slashes from path (after extracting fragment)
                if pathWithoutFragment.hasSuffix("/") {
                    pathWithoutFragment.removeLast()
                }

                // Convert .md to .html, or add .html if no extension present
                var targetPathHtml = pathWithoutFragment.replacingOccurrences(of: ".md", with: ".html")

                // If no extension at all, add .html
                if !targetPathHtml.hasSuffix(".html") && !targetPathHtml.contains(".") {
                    targetPathHtml += ".html"
                }

                // Normalize the current document path to URL space
                // by stripping the directory prefix that corresponds to the base URL
                let currentDocPath = document.relativePath.replacingOccurrences(of: ".md", with: ".html")
                var normalizedCurrentPath = currentDocPath

                // If we found a base directory name and the current path starts with it, strip it
                if !baseDirName.isEmpty && currentDocPath.hasPrefix(baseDirName + "/") {
                    normalizedCurrentPath = String(currentDocPath.dropFirst(baseDirName.count + 1))
                }

                // Calculate proper relative path in normalized URL space
                let relativePath = calculateRelativePath(from: normalizedCurrentPath, to: targetPathHtml)

                // Reconstruct the href with fragment if present
                let newHref = fragment != nil ? relativePath + fragment! : relativePath

                try link.attr("href", newHref)
            }
        }
    }

    private func calculateRelativePath(from: String, to: String) -> String {
        let fromComponents = Array(from.split(separator: "/").dropLast()) // Remove filename, get directory
        let toComponents = Array(to.split(separator: "/"))

        // Find common prefix
        var commonCount = 0
        let minCount = min(fromComponents.count, toComponents.count)
        for i in 0..<minCount {
            if fromComponents[i] == toComponents[i] {
                commonCount += 1
            } else {
                break
            }
        }

        // Calculate how many levels to go up from the "from" directory
        let upLevels = fromComponents.count - commonCount
        let upPath = String(repeating: "../", count: upLevels)

        // Take the non-common part of the "to" path
        let remainingToComponents = toComponents.dropFirst(commonCount)
        let downPath = remainingToComponents.joined(separator: "/")

        // If both are empty, files are in the same directory
        if upPath.isEmpty && !downPath.isEmpty {
            return downPath
        } else if upPath.isEmpty && downPath.isEmpty {
            // Same file? Shouldn't happen but handle gracefully
            return to.split(separator: "/").last.map(String.init) ?? to
        } else {
            return upPath + downPath
        }
    }

    private func addNamedAnchors(_ doc: Document) throws {
        let headings = try doc.select("h1, h2, h3, h4, h5, h6")

        for heading in headings.array() {
            let text = try heading.text()
            let anchorName = sanitizeAnchorName(text)

            // Create anchor element
            let anchor = Element(Tag("a"), "")
            try anchor.attr("name", anchorName)

            // Insert before heading
            try heading.before(anchor.outerHtml())
        }
    }

    private func sanitizeAnchorName(_ text: String) -> String {
        // Remove special characters, replace spaces with underscores
        let allowed = CharacterSet.alphanumerics
        let sanitized = text.components(separatedBy: allowed.inverted).joined()
        return sanitized.replacingOccurrences(of: " ", with: "_")
    }

    private func escape(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    /// Generates JavaScript that detects if the page is loaded outside an iframe
    /// and redirects to the main frame page with a hash fragment
    private func buildIframeDetectionScript(depth: Int, relativePath: String) -> String {
        let upLevels = String(repeating: "../", count: depth)
        let pagePath = relativePath.replacingOccurrences(of: ".md", with: ".html")

        return """
        (function() {
            'use strict';
            // Check if this page is loaded outside of an iframe
            if (window.self === window.top) {
                // Not in an iframe - redirect to index.html with this page as the target
                const indexPath = '\(upLevels)index.html';
                const targetPage = '\(pagePath)';
                // Use location.replace to avoid adding to browser history
                window.location.replace(indexPath + '#' + targetPage);
            }
        })();
        """
    }

    static var defaultTemplate: String {
        """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>{{TITLE}}</title>
            {{META}}
            <link rel="stylesheet" href="../assets/style.css">
        </head>
        <body>
            {{CONTENT}}
        </body>
        </html>
        """
    }
}
