import Foundation

/// Generates index pages for directory sections within the help book
class SectionIndexGenerator {
    private let sidebarGenerator: SidebarGenerator

    init() {
        self.sidebarGenerator = SidebarGenerator()
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

        // Generate sidebar
        let currentPath = pathComponents.joined(separator: "/") + "/_index.html"
        let sidebarHTML = sidebarGenerator.generateSidebar(
            project: project,
            currentPath: currentPath
        )
        let sidebarJS = sidebarGenerator.generateSidebarJavaScript()

        var htmlContent = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>\(escapeHTML(sectionTitle)) - \(escapeHTML(project.metadata.helpBookTitle))</title>
            <meta name="robots" content="index, anchors" />
            <link rel="stylesheet" href="\(upLevels)assets/style.css">
        </head>
        <body>
            \(sidebarHTML)
            <div id="help-main-content" class="help-main-content with-sidebar">
                <div class="page-content">
                    <h1>\(escapeHTML(sectionTitle))</h1>
        """

        if let description = node.description {
            htmlContent += "                    <p class=\"subtitle\">\(escapeHTML(description))</p>\n"
        }

        // Generate table of contents for this section
        if let children = node.children, !children.isEmpty {
            htmlContent += "\n<h2>Topics</h2>\n"
            htmlContent += generateSectionTOC(children, project: project, basePath: pathComponents)
        }

        htmlContent += """
                </div>
            </div>
            \(sidebarJS)
        </body>
        </html>
        """

        return htmlContent
    }

    private func generateSectionTOC(_ nodes: [FileTreeNode], project: HelpProject, basePath: [String]) -> String {
        var html = "<ul>\n"

        for node in nodes {
            if node.isDirectory {
                let displayName = node.title ?? formatName(node.name)
                let sectionIndexPath = (basePath + [node.name, "_index.html"]).joined(separator: "/")

                html += "<li>\n"
                html += "<h3><a href=\"\(escapeHTML(sectionIndexPath))\">\(escapeHTML(displayName))</a></h3>\n"

                if let description = node.description {
                    html += "<p class=\"section-description\">\(escapeHTML(description))</p>\n"
                }
                html += "</li>\n"
            } else if let docId = node.documentId {
                if let doc = project.documents.first(where: { $0.id == docId }) {
                    let htmlPath = doc.relativePath.replacingOccurrences(of: ".md", with: ".html")
                    html += "<li>\n"
                    html += "<h3><a href=\"\(escapeHTML("../" + htmlPath))\">\(escapeHTML(doc.title))</a></h3>\n"

                    if let description = doc.description {
                        html += "<p class=\"section-description\">\(escapeHTML(description))</p>\n"
                    }
                    html += "</li>\n"
                }
            }
        }

        html += "</ul>\n"
        return html
    }

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
