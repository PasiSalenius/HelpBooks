import Foundation

/// Generates the welcome page with table of contents
class WelcomePageGenerator {

    /// Generates the welcome page HTML
    /// - Parameters:
    ///   - project: The help project
    /// - Returns: Complete HTML for the welcome page
    func generateWelcomePage(project: HelpProject) -> String {
        buildHTML(
            title: project.metadata.helpBookTitle,
            bundleName: project.metadata.bundleName,
            fileTree: project.fileTree,
            project: project
        )
    }

    // MARK: - HTML Structure

    private func buildHTML(
        title: String,
        bundleName: String,
        fileTree: FileTreeNode?,
        project: HelpProject
    ) -> String {
        """
        <!DOCTYPE html>
        <html lang="en">
        \(buildHead(title: title))
        <body>
            <div id="help-main-content" class="help-main-content">
                <div class="page-content">
                    \(buildContent(title: title, bundleName: bundleName, fileTree: fileTree, project: project))
                </div>
            </div>
        </body>
        </html>
        """
    }

    private func buildHead(title: String) -> String {
        """
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>\(escapeHTML(title))</title>
            <meta name="robots" content="index, anchors" />
            <link rel="stylesheet" href="../assets/style.css">
        </head>
        """
    }

    private func buildContent(
        title: String,
        bundleName: String,
        fileTree: FileTreeNode?,
        project: HelpProject
    ) -> String {
        var content = """
        <h1>\(escapeHTML(title))</h1>
        <p>Welcome to the help documentation for \(escapeHTML(bundleName)).</p>
        """

        if let fileTree = fileTree {
            let contentNodes = getContentNodes(from: fileTree)
            if !contentNodes.isEmpty {
                content += """

                <h2>Topics</h2>
                \(buildTableOfContents(nodes: contentNodes, project: project))
                """
            }
        }

        return content
    }

    /// Gets the actual content nodes, skipping the root container directory if present
    private func getContentNodes(from root: FileTreeNode) -> [FileTreeNode] {
        guard let children = root.children, !children.isEmpty else {
            return []
        }

        // If there's only one child and it's a directory, it's likely a root container
        // Skip it and return its children instead
        if children.count == 1,
           let singleChild = children.first,
           singleChild.isDirectory,
           let grandchildren = singleChild.children {
            return grandchildren
        }

        // Otherwise return children as-is
        return children
    }

    // MARK: - Table of Contents

    private func buildTableOfContents(nodes: [FileTreeNode], project: HelpProject) -> String {
        """
        <ul>
        \(nodes.map { buildTreeNode($0, project: project, level: 0) }.joined())
        </ul>
        """
    }

    private func buildTreeNode(_ node: FileTreeNode, project: HelpProject, level: Int) -> String {
        if node.isDirectory {
            return buildDirectoryNode(node, project: project, level: level)
        } else if let docId = node.documentId {
            return buildDocumentNode(docId: docId, project: project)
        }
        return ""
    }

    private func buildDirectoryNode(_ node: FileTreeNode, project: HelpProject, level: Int) -> String {
        let displayName = formatDisplayName(node)
        let description = formatDescription(node.description)

        var html = "<li>\n"

        if level == 0 {
            html += "<h3>\(escapeHTML(displayName))</h3>\n"
        } else {
            html += "<strong>\(escapeHTML(displayName))</strong>\n"
        }

        if !description.isEmpty {
            html += "<p class=\"section-description\">\(escapeHTML(description))</p>\n"
        }

        if let children = node.children, !children.isEmpty {
            html += "<ul>\n"
            for child in children {
                html += buildTreeNode(child, project: project, level: level + 1)
            }
            html += "</ul>\n"
        }

        html += "</li>\n"
        return html
    }

    private func buildDocumentNode(docId: UUID, project: HelpProject) -> String {
        guard let doc = project.documents.first(where: { $0.id == docId }) else {
            return ""
        }

        let htmlPath = doc.relativePath.replacingOccurrences(of: ".md", with: ".html")
        return "<li><a href=\"\(escapeHTML(htmlPath))\">\(escapeHTML(doc.title))</a></li>\n"
    }

    // MARK: - Utilities

    private func formatDisplayName(_ node: FileTreeNode) -> String {
        node.title ?? node.name
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
    }

    private func formatDescription(_ description: String?) -> String {
        description ?? ""
    }

    private func escapeHTML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
