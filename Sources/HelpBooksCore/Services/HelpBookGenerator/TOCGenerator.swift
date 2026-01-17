import Foundation

class TOCGenerator {
    func generate(project: HelpProject, at bundleURL: URL) throws {
        let lprojURL = bundleURL
            .appendingPathComponent("Contents/Resources/en.lproj")
        let tocURL = lprojURL.appendingPathComponent("toc.html")

        var htmlContent = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="AppleTitle" content="\(project.metadata.helpBookTitle)" />
            <meta name="AppleIcon" content="../siteicon.png" />
            <meta name="robots" content="anchors" />
            <meta name="description" content="Table of Contents" />
            <title>\(project.metadata.helpBookTitle)</title>
            <link rel="stylesheet" href="../assets/style.css">
        </head>
        <body>
            <h1>\(project.metadata.helpBookTitle)</h1>
            <div class="toc">
        """

        // Generate hierarchical navigation based on file tree
        if let fileTree = project.fileTree {
            htmlContent += generateTOCFromTree(fileTree, project: project)
        }

        htmlContent += """
            </div>
        </body>
        </html>
        """

        try htmlContent.write(to: tocURL, atomically: true, encoding: .utf8)
    }

    private func generateTOCFromTree(_ node: FileTreeNode, project: HelpProject, level: Int = 0) -> String {
        var html = ""

        // Skip root node, start with first level
        if level == 0, let children = node.children {
            html += "<ul>\n"
            for child in children {
                html += generateTOCFromTree(child, project: project, level: level + 1)
            }
            html += "</ul>\n"
            return html
        }

        if node.isDirectory {
            // Folder - create a section
            // Use title from _index.md if available, otherwise use folder name
            let displayName = node.title ?? node.name.replacingOccurrences(of: "-", with: " ")
                .replacingOccurrences(of: "_", with: " ")

            html += "<li>\n"
            html += "<strong>\(displayName)</strong>\n"

            if let children = node.children, !children.isEmpty {
                html += "<ul>\n"
                for child in children {
                    html += generateTOCFromTree(child, project: project, level: level + 1)
                }
                html += "</ul>\n"
            }

            html += "</li>\n"
        } else if let docId = node.documentId {
            // File - find the document to get its title and path
            if let doc = project.documents.first(where: { $0.id == docId }) {
                let htmlPath = doc.relativePath.replacingOccurrences(of: ".md", with: ".html")
                let title = doc.title
                html += "<li><a href=\"\(htmlPath)\">\(title)</a></li>\n"
            }
        }

        return html
    }
}
