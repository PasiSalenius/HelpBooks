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
        project: HelpProject
    ) throws -> String {
        guard let htmlBody = document.htmlContent else {
            throw HTMLGeneratorError.noHTMLContent
        }

        do {
            // Parse the HTML content with just the markdown-generated HTML
            let tempDoc = try SwiftSoup.parse(htmlBody)
            let tempBody = try tempDoc.body() ?? tempDoc

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

            // Generate sidebar
            let currentHtmlPath = document.relativePath.replacingOccurrences(of: ".md", with: ".html")
            let sidebarHTML = sidebarGenerator.generateSidebar(
                project: project,
                currentPath: currentHtmlPath
            )

            // Generate breadcrumbs
            let breadcrumbsHTML = breadcrumbGenerator.generateBreadcrumbs(
                document: document,
                project: project
            )

            // Generate JavaScript for sidebar
            let sidebarJS = sidebarGenerator.generateSidebarJavaScript()

            // Build body structure (AFTER head)
            let body = try html.appendElement("body")

            // Add sidebar
            try body.append(sidebarHTML)

            // Create main content wrapper
            let mainDiv = try body.appendElement("div")
            try mainDiv.attr("id", "help-main-content")
            try mainDiv.attr("class", "help-main-content with-sidebar")

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

            // Add JavaScript for sidebar at the end of body
            try body.append(sidebarJS)

            // Fix image paths in the body
            try fixImagePaths(doc, depth: depth)

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
        let firstChild = try body.children().first()

        if let first = firstChild, try first.tagName() == "h1" {
            // H1 already exists
            // Check if we need to add subtitle after it
            if let subtitle = subtitle {
                let subtitleP = try Element(Tag("p"), "")
                try subtitleP.addClass("subtitle")
                try subtitleP.text(subtitle)
                try first.after(subtitleP.outerHtml())
            }
            return
        }

        // No H1 at the top, insert one
        let h1 = try Element(Tag("h1"), "")
        try h1.text(title)
        try body.prependChild(h1)

        // Add subtitle if present
        if let subtitle = subtitle {
            let subtitleP = try Element(Tag("p"), "")
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

    private func addNamedAnchors(_ doc: Document) throws {
        let headings = try doc.select("h1, h2, h3, h4, h5, h6")

        for heading in headings.array() {
            let text = try heading.text()
            let anchorName = sanitizeAnchorName(text)

            // Create anchor element
            let anchor = try Element(Tag("a"), "")
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
