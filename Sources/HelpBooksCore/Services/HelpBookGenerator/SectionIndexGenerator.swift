import Foundation

/// Generates index pages for directory sections within the help book
class SectionIndexGenerator {
    init() {
    }

    /// Generates index pages for all directories in the file tree
    func generateSectionIndexes(
        project: HelpProject,
        at bundleURL: URL
    ) throws {
        guard let fileTree = project.fileTree else { return }

        let lprojURL = bundleURL
            .appendingPathComponent("Contents/Resources/en.lproj")

        // Recursively generate index pages for directories
        try generateIndexForNode(
            node: fileTree,
            project: project,
            lprojURL: lprojURL,
            pathComponents: []
        )
    }

    private func generateIndexForNode(
        node: FileTreeNode,
        project: HelpProject,
        lprojURL: URL,
        pathComponents: [String]
    ) throws {
        // Skip root node, process children
        if pathComponents.isEmpty {
            guard let children = node.children else { return }
            for child in children where child.isDirectory {
                try generateIndexForNode(
                    node: child,
                    project: project,
                    lprojURL: lprojURL,
                    pathComponents: [child.name]
                )
            }
            return
        }

        // Generate index page for this directory
        let indexPath = pathComponents.joined(separator: "/") + "/_index.html"
        let indexURL = lprojURL.appendingPathComponent(indexPath)

        // Create directory if needed
        let dirURL = indexURL.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: dirURL.path) {
            try FileManager.default.createDirectory(
                at: dirURL,
                withIntermediateDirectories: true
            )
        }

        // Generate HTML content for this section
        let htmlContent = try generateSectionHTML(
            node: node,
            project: project,
            pathComponents: pathComponents
        )

        try htmlContent.write(to: indexURL, atomically: true, encoding: String.Encoding.utf8)

        // Recursively process child directories
        if let children = node.children {
            for child in children where child.isDirectory {
                try generateIndexForNode(
                    node: child,
                    project: project,
                    lprojURL: lprojURL,
                    pathComponents: pathComponents + [child.name]
                )
            }
        }
    }

    private func generateSectionHTML(
        node: FileTreeNode,
        project: HelpProject,
        pathComponents: [String]
    ) throws -> String {
        let sectionTitle = node.title ?? formatName(node.name)
        let depth = pathComponents.count
        let upLevels = String(repeating: "../", count: depth + 1)

        return buildHTML(
            title: sectionTitle,
            bookTitle: project.metadata.helpBookTitle,
            description: node.description,
            children: node.children,
            project: project,
            pathComponents: pathComponents,
            cssPath: "\(upLevels)assets/style.css"
        )
    }

    // MARK: - HTML Structure

    private func buildHTML(
        title: String,
        bookTitle: String,
        description: String?,
        children: [FileTreeNode]?,
        project: HelpProject,
        pathComponents: [String],
        cssPath: String
    ) -> String {
        """
        <!DOCTYPE html>
        <html lang="en">
        \(buildHead(title: title, bookTitle: bookTitle, cssPath: cssPath))
        <body>
            <div id="help-main-content" class="help-main-content">
                <div class="page-content">
                    \(buildContent(title: title, description: description, children: children, project: project, pathComponents: pathComponents))
                </div>
            </div>
        </body>
        </html>
        """
    }

    private func buildHead(title: String, bookTitle: String, cssPath: String) -> String {
        """
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>\(escapeHTML(title)) - \(escapeHTML(bookTitle))</title>
            <meta name="robots" content="index, anchors" />
            <link rel="stylesheet" href="\(escapeHTML(cssPath))">
        </head>
        """
    }

    private func buildContent(
        title: String,
        description: String?,
        children: [FileTreeNode]?,
        project: HelpProject,
        pathComponents: [String]
    ) -> String {
        var content = "<h1>\(escapeHTML(title))</h1>\n"

        if let description = description {
            content += "<p class=\"subtitle\">\(escapeHTML(description))</p>\n"
        }

        if let children = children, !children.isEmpty {
            content += """

            <h2>Topics</h2>
            \(generateSectionTOC(children, project: project, basePath: pathComponents))
            """
        }

        return content
    }

    // MARK: - Table of Contents

    private func generateSectionTOC(_ nodes: [FileTreeNode], project: HelpProject, basePath: [String]) -> String {
        """
        <ul>
        \(nodes.map { buildTOCNode($0, project: project, basePath: basePath) }.joined())
        </ul>
        """
    }

    private func buildTOCNode(_ node: FileTreeNode, project: HelpProject, basePath: [String]) -> String {
        if node.isDirectory {
            return buildTOCDirectoryNode(node, basePath: basePath)
        } else if let docId = node.documentId {
            return buildTOCDocumentNode(docId: docId, project: project)
        }
        return ""
    }

    private func buildTOCDirectoryNode(_ node: FileTreeNode, basePath: [String]) -> String {
        let displayName = node.title ?? formatName(node.name)
        // Just use the subdirectory name since we're in the parent directory
        let sectionIndexPath = "\(node.name)/_index.html"

        var html = "<li>\n"
        html += "<h3><a href=\"\(escapeHTML(sectionIndexPath))\">\(escapeHTML(displayName))</a></h3>\n"

        if let description = node.description {
            html += "<p class=\"section-description\">\(escapeHTML(description))</p>\n"
        }

        html += "</li>\n"
        return html
    }

    private func buildTOCDocumentNode(docId: UUID, project: HelpProject) -> String {
        guard let doc = project.documents.first(where: { $0.id == docId }) else {
            return ""
        }

        // Get just the filename - section index and documents are in the same directory
        let htmlPath = doc.relativePath.replacingOccurrences(of: ".md", with: ".html")
        let filename = (htmlPath as NSString).lastPathComponent

        var html = "<li>\n"
        html += "<h3><a href=\"\(escapeHTML(filename))\">\(escapeHTML(doc.title))</a></h3>\n"

        if let description = doc.description {
            html += "<p class=\"section-description\">\(escapeHTML(description))</p>\n"
        }

        html += "</li>\n"
        return html
    }

    // MARK: - Utilities

    private func formatName(_ name: String) -> String {
        name.replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
    }

    private func escapeHTML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
