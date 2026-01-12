import Foundation

class SidebarGenerator {
    /// Generates sidebar HTML with collapsible navigation
    /// - Parameters:
    ///   - project: The help project with file tree
    ///   - currentPath: Relative path of current document (for highlighting)
    /// - Returns: Complete sidebar HTML
    func generateSidebar(project: HelpProject, currentPath: String) -> String {
        guard let fileTree = project.fileTree else {
            return ""
        }

        var html = """
        <nav id="help-sidebar" class="help-sidebar">
            <div class="sidebar-header">
                <h2>\(escapeHTML(project.metadata.helpBookTitle))</h2>
            </div>
            <div class="sidebar-content">
        """

        // Generate tree from root children
        if let children = fileTree.children {
            html += generateTreeHTML(
                nodes: children,
                project: project,
                currentPath: currentPath,
                level: 0
            )
        }

        html += """
            </div>
        </nav>
        """

        return html
    }

    private func generateTreeHTML(
        nodes: [FileTreeNode],
        project: HelpProject,
        currentPath: String,
        level: Int
    ) -> String {
        var html = "<ul class=\"toc-list\">\n"

        for node in nodes {
            if node.isDirectory {
                // Directory with disclosure triangle
                let displayName = node.title ?? formatName(node.name)
                let hasChildren = node.children?.isEmpty == false

                html += "<li class=\"toc-section\">\n"

                if hasChildren {
                    html += "<div class=\"toc-section-header\" onclick=\"toggleSection(this)\" aria-expanded=\"true\">\n"
                    html += "<span class=\"disclosure-button\">▼</span>\n"
                } else {
                    html += "<div class=\"toc-section-header\">\n"
                    html += "<span class=\"disclosure-spacer\"></span>\n"
                }

                html += "<span class=\"section-title\">\(escapeHTML(displayName))</span>\n"
                html += "</div>\n"

                if let children = node.children, !children.isEmpty {
                    html += "<div class=\"toc-section-content\">\n"
                    html += generateTreeHTML(
                        nodes: children,
                        project: project,
                        currentPath: currentPath,
                        level: level + 1
                    )
                    html += "</div>\n"
                }

                html += "</li>\n"
            } else if let docId = node.documentId {
                // Document link
                if let doc = project.documents.first(where: { $0.id == docId }) {
                    let htmlPath = doc.relativePath.replacingOccurrences(of: ".md", with: ".html")
                    let isCurrent = htmlPath == currentPath
                    let currentClass = isCurrent ? " class=\"current-page\"" : ""

                    // Calculate relative path from current page to target page
                    let relativePath = self.calculateRelativePath(from: currentPath, to: htmlPath)

                    html += "<li><a href=\"\(escapeHTML(relativePath))\"\(currentClass)>\(escapeHTML(doc.title))</a></li>\n"
                }
            }
        }

        html += "</ul>\n"
        return html
    }

    /// Generates JavaScript for sidebar functionality
    func generateSidebarJavaScript() -> String {
        """
        <script>
        // Collapse/expand sections
        function toggleSection(header) {
            const content = header.parentElement.querySelector('.toc-section-content');
            if (!content) return;

            const isExpanded = header.getAttribute('aria-expanded') === 'true';
            header.setAttribute('aria-expanded', !isExpanded);

            const disclosureButton = header.querySelector('.disclosure-button');
            if (disclosureButton) {
                disclosureButton.textContent = isExpanded ? '\\u25B6' : '\\u25BC';
            }

            content.style.display = isExpanded ? 'none' : 'block';
        }
        </script>
        """
    }

    private func calculateRelativePath(from: String, to: String) -> String {
        let fromComponents = from.split(separator: "/").dropLast() // Remove filename
        let toComponents = to.split(separator: "/")

        let fromDepth = fromComponents.count
        let upLevels = String(repeating: "../", count: fromDepth)

        return upLevels + toComponents.joined(separator: "/")
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
