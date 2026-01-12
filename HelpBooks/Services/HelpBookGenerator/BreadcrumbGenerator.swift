import Foundation

class BreadcrumbGenerator {
    /// Generates breadcrumb navigation based on file tree hierarchy
    /// - Parameters:
    ///   - document: The current document
    ///   - project: The help project
    /// - Returns: HTML for breadcrumb navigation
    func generateBreadcrumbs(document: MarkdownDocument, project: HelpProject) -> String {
        guard let fileTree = project.fileTree else {
            return generateSimpleBreadcrumb(document: document)
        }

        // Find path to current document in tree
        let pathComponents = findPathToDocument(
            documentId: document.id,
            in: fileTree,
            currentPath: []
        )

        guard !pathComponents.isEmpty else {
            return generateSimpleBreadcrumb(document: document)
        }

        var html = "<nav class=\"breadcrumb\" aria-label=\"Breadcrumb\">\n"
        html += "<ol>\n"

        // Home link
        let depth = document.relativePath.split(separator: "/").count
        let upLevels = String(repeating: "../", count: depth - 1)
        html += "<li><a href=\"\(upLevels)index.html\" title=\"Home\">🏠</a></li>\n"

        // Parent sections
        for (index, component) in pathComponents.enumerated() {
            let isLast = index == pathComponents.count - 1

            // Skip the root node - it's artificial and index.html serves as home
            // Root node has an empty or minimal relative path
            if component.isDirectory && (component.relativePath.isEmpty || component.relativePath == "/") {
                continue
            }

            if component.isDirectory {
                let displayName = component.title ?? formatName(component.name)

                // Link to the section index page
                let sectionIndexPath = component.relativePath + "/_index.html"
                // Calculate relative path from current document
                let relativePath = calculateRelativePath(
                    from: document.relativePath,
                    to: sectionIndexPath
                )
                html += "<li><a href=\"\(escapeHTML(relativePath))\">\(escapeHTML(displayName))</a></li>\n"
            } else if isLast {
                // Current page (no link)
                html += "<li aria-current=\"page\"><span>\(escapeHTML(document.title))</span></li>\n"
            }
        }

        html += "</ol>\n"
        html += "</nav>\n"

        return html
    }

    /// Recursively find path to document in tree
    private func findPathToDocument(
        documentId: UUID,
        in node: FileTreeNode,
        currentPath: [FileTreeNode]
    ) -> [FileTreeNode] {
        // Check if this node matches
        if node.documentId == documentId {
            return currentPath + [node]
        }

        // Search children
        if let children = node.children {
            for child in children {
                let result = findPathToDocument(
                    documentId: documentId,
                    in: child,
                    currentPath: currentPath + (node.name.isEmpty ? [] : [node])
                )
                if !result.isEmpty {
                    return result
                }
            }
        }

        return []
    }

    private func findIndexDocument(for node: FileTreeNode, in project: HelpProject) -> MarkdownDocument? {
        // Look for a document in the same directory as this folder node
        // _index.md files are not included in documents array (they're filtered out)
        // so we need to check if there's a document that represents this section

        // For now, if there's no _index.md document, we won't link to anything
        // This is a safe approach since _index.md files are excluded from the documents list
        return nil
    }

    private func calculateRelativePath(from: String, to: String) -> String {
        let fromComponents = from.split(separator: "/").dropLast() // Remove filename
        let toComponents = to.split(separator: "/")

        let fromDepth = fromComponents.count
        let upLevels = String(repeating: "../", count: fromDepth)

        return upLevels + toComponents.joined(separator: "/")
    }

    private func generateSimpleBreadcrumb(document: MarkdownDocument) -> String {
        // Calculate relative path to index
        let depth = document.relativePath.split(separator: "/").count
        let upLevels = String(repeating: "../", count: depth - 1)

        return """
        <nav class="breadcrumb" aria-label="Breadcrumb">
            <ol>
                <li><a href="\(upLevels)index.html" title="Home">🏠</a></li>
                <li aria-current="page"><span>\(escapeHTML(document.title))</span></li>
            </ol>
        </nav>
        """
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
