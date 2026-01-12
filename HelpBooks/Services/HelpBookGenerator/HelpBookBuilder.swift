import Foundation

enum BuildPhase: Equatable {
    case preparing
    case creatingStructure
    case generatingHTML(current: Int, total: Int)
    case copyingAssets(current: Int, total: Int)
    case indexing
    case complete
    case failed(String)

    var description: String {
        switch self {
        case .preparing:
            return "Preparing..."
        case .creatingStructure:
            return "Creating bundle structure..."
        case .generatingHTML(let current, let total):
            return "Generating HTML files (\(current)/\(total))..."
        case .copyingAssets(let current, let total):
            return "Copying assets (\(current)/\(total))..."
        case .indexing:
            return "Creating search index..."
        case .complete:
            return "Complete!"
        case .failed(let error):
            return "Failed: \(error)"
        }
    }

    static func == (lhs: BuildPhase, rhs: BuildPhase) -> Bool {
        switch (lhs, rhs) {
        case (.preparing, .preparing),
             (.creatingStructure, .creatingStructure),
             (.indexing, .indexing),
             (.complete, .complete):
            return true
        case (.generatingHTML(let l1, let l2), .generatingHTML(let r1, let r2)):
            return l1 == r1 && l2 == r2
        case (.copyingAssets(let l1, let l2), .copyingAssets(let r1, let r2)):
            return l1 == r1 && l2 == r2
        case (.failed(let l), .failed(let r)):
            return l == r
        default:
            return false
        }
    }
}

@Observable
class HelpBookBuilder {
    var currentPhase: BuildPhase = .preparing
    var progress: Double = 0.0

    private let bundleBuilder: BundleBuilder
    private let infoPlistGenerator: InfoPlistGenerator
    private let htmlGenerator: HTMLGenerator
    private let assetCopier: AssetCopier
    private let assetPathRewriter: AssetPathRewriter
    private let searchIndexer: SearchIndexer
    private let tocGenerator: TOCGenerator

    init() {
        self.bundleBuilder = BundleBuilder()
        self.infoPlistGenerator = InfoPlistGenerator()
        self.htmlGenerator = HTMLGenerator()
        self.assetCopier = AssetCopier()
        self.assetPathRewriter = AssetPathRewriter()
        self.searchIndexer = SearchIndexer()
        self.tocGenerator = TOCGenerator()
    }

    func build(project: HelpProject, outputURL: URL) async throws -> URL {
        // Phase 1: Create bundle structure
        currentPhase = .creatingStructure
        progress = 0.1

        let bundleURL = try bundleBuilder.createBundle(at: outputURL, project: project)

        // Phase 2: Generate Info.plist
        progress = 0.2
        try infoPlistGenerator.generate(metadata: project.metadata, at: bundleURL)

        // Phase 3: Generate HTML files
        currentPhase = .generatingHTML(current: 0, total: project.documents.count)
        try await generateHTMLFiles(project, bundleURL)

        // Phase 3.5: Generate index.html
        try generateIndexHTML(project, bundleURL)

        // Phase 3.6: Generate section index pages
        let sectionIndexGenerator = SectionIndexGenerator()
        try sectionIndexGenerator.generateSectionIndexes(project: project, at: bundleURL)

        // Phase 3.7: Generate Table of Contents
        try tocGenerator.generate(project: project, at: bundleURL)

        // Phase 4: Copy assets
        currentPhase = .copyingAssets(current: 0, total: project.assets.count)
        try copyAssets(project, bundleURL)

        // Phase 5: Create search index
        currentPhase = .indexing
        progress = 0.9
        try await searchIndexer.createIndex(for: bundleURL)

        // Complete
        currentPhase = .complete
        progress = 1.0

        return bundleURL
    }

    private func generateHTMLFiles(_ project: HelpProject, _ bundleURL: URL) async throws {
        let lprojURL = bundleURL
            .appendingPathComponent("Contents/Resources/en.lproj")

        let total = Double(project.documents.count)

        for (index, doc) in project.documents.enumerated() {
            // Generate HTML with meta tags
            let html = try htmlGenerator.generate(
                document: doc,
                metadata: project.metadata,
                project: project
            )

            // Preserve folder structure
            let fileName = doc.relativePath
                .replacingOccurrences(of: ".md", with: ".html")
            let fileURL = lprojURL.appendingPathComponent(fileName)

            // Create parent directories
            let parentURL = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(
                at: parentURL,
                withIntermediateDirectories: true
            )

            // Write HTML file
            try html.write(to: fileURL, atomically: true, encoding: .utf8)

            await MainActor.run {
                currentPhase = .generatingHTML(
                    current: index + 1,
                    total: project.documents.count
                )
                progress = 0.3 + (Double(index + 1) / total * 0.4)
            }
        }
    }

    private func generateIndexHTML(_ project: HelpProject, _ bundleURL: URL) throws {
        let lprojURL = bundleURL
            .appendingPathComponent("Contents/Resources/en.lproj")
        let indexURL = lprojURL.appendingPathComponent("index.html")

        // Generate sidebar for index page
        let sidebarGenerator = SidebarGenerator()
        let sidebarHTML = sidebarGenerator.generateSidebar(
            project: project,
            currentPath: "index.html"
        )
        let sidebarJS = sidebarGenerator.generateSidebarJavaScript()

        // Build HTML content
        var htmlContent = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>\(project.metadata.helpBookTitle)</title>
            <meta name="robots" content="index, anchors" />
            <link rel="stylesheet" href="../assets/style.css">
        </head>
        <body>
            \(sidebarHTML)
            <div id="help-main-content" class="help-main-content with-sidebar">
                <div class="page-content">
                    <h1>\(project.metadata.helpBookTitle)</h1>
                    <p>Welcome to the help documentation for \(project.metadata.bundleName).</p>
        """

        // Generate table of contents from file tree (respects mixed file/folder ordering)
        if let fileTree = project.fileTree, let children = fileTree.children, !children.isEmpty {
            htmlContent += "\n<h2>Topics</h2>\n"
            htmlContent += generateIndexFromTree(children, project: project)
        }

        htmlContent += """
                </div>
            </div>
            \(sidebarJS)
        </body>
        </html>
        """

        try htmlContent.write(to: indexURL, atomically: true, encoding: String.Encoding.utf8)
    }

    private func generateIndexFromTree(_ nodes: [FileTreeNode], project: HelpProject, level: Int = 0) -> String {
        var html = ""

        if level == 0 {
            html += "<ul>\n"
        }

        for node in nodes {
            if node.isDirectory {
                // Folder - create a section
                // Use title from _index.md if available, otherwise use folder name
                let displayName = node.title ?? node.name.replacingOccurrences(of: "-", with: " ")
                    .replacingOccurrences(of: "_", with: " ")

                if level == 0 {
                    html += "<li>\n"
                    html += "<h3>\(displayName)</h3>\n"
                    // Add description if available
                    if let description = node.description {
                        html += "<p class=\"section-description\">\(description)</p>\n"
                    }
                } else {
                    html += "<li><strong>\(displayName)</strong>\n"
                    // Add description if available
                    if let description = node.description {
                        html += "<p class=\"section-description\">\(description)</p>\n"
                    }
                }

                if let children = node.children, !children.isEmpty {
                    html += "<ul>\n"
                    for child in children {
                        html += generateIndexFromTree([child], project: project, level: level + 1)
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
        }

        if level == 0 {
            html += "</ul>\n"
        }

        return html
    }

    private func copyAssets(_ project: HelpProject, _ bundleURL: URL) throws {
        let hasCustomCSS = project.assets.contains { $0.type == .css }

        // Copy project assets
        if !project.assets.isEmpty {
            try assetCopier.copyAssets(project.assets, to: bundleURL) { [weak self] prog, file in
                guard let self else { return }
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    let count = Int(prog * Double(project.assets.count))
                    self.currentPhase = .copyingAssets(
                        current: count,
                        total: project.assets.count
                    )
                    self.progress = 0.7 + (prog * 0.15)
                }
            }
        }

        // Copy themed CSS if no custom CSS asset provided
        if !hasCustomCSS {
            try assetCopier.copyDefaultStylesheet(
                to: bundleURL,
                theme: project.metadata.theme
            )
        }

        progress = 0.85
    }
}
