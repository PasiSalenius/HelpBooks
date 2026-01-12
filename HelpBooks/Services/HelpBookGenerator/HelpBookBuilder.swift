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
    private let frameGenerator: FrameGenerator
    private let welcomePageGenerator: WelcomePageGenerator
    private let assetCopier: AssetCopier
    private let assetPathRewriter: AssetPathRewriter
    private let searchIndexer: SearchIndexer
    private let tocGenerator: TOCGenerator

    init() {
        self.bundleBuilder = BundleBuilder()
        self.infoPlistGenerator = InfoPlistGenerator()
        self.htmlGenerator = HTMLGenerator()
        self.frameGenerator = FrameGenerator()
        self.welcomePageGenerator = WelcomePageGenerator()
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

        // Phase 3: Generate HTML files (content-only, without sidebar)
        currentPhase = .generatingHTML(current: 0, total: project.documents.count)
        try await generateHTMLFiles(project, bundleURL)

        // Phase 3.5: Generate welcome.html (content-only welcome page)
        try generateWelcomeHTML(project, bundleURL)

        // Phase 3.6: Generate index.html (main frame page with sidebar and iframe)
        try generateFrameHTML(project, bundleURL)

        // Phase 3.7: Generate section index pages
        let sectionIndexGenerator = SectionIndexGenerator()
        try sectionIndexGenerator.generateSectionIndexes(project: project, at: bundleURL)

        // Phase 3.8: Generate Table of Contents
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

    private func generateWelcomeHTML(_ project: HelpProject, _ bundleURL: URL) throws {
        let lprojURL = bundleURL.appendingPathComponent("Contents/Resources/en.lproj")
        let welcomeURL = lprojURL.appendingPathComponent("welcome.html")

        let htmlContent = welcomePageGenerator.generateWelcomePage(project: project)
        try htmlContent.write(to: welcomeURL, atomically: true, encoding: .utf8)
    }

    private func generateFrameHTML(_ project: HelpProject, _ bundleURL: URL) throws {
        let lprojURL = bundleURL.appendingPathComponent("Contents/Resources/en.lproj")
        let indexURL = lprojURL.appendingPathComponent("index.html")

        let frameHTML = frameGenerator.generateFramePage(
            project: project,
            defaultContentPath: "welcome.html"
        )

        try frameHTML.write(to: indexURL, atomically: true, encoding: .utf8)
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
