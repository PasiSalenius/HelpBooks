import Foundation

public enum FileImporterError: Error {
    case invalidDirectory
    case noMarkdownFiles
    case scanFailed(underlying: Error)
}

/// Imports content from a directory using the specified content provider.
/// The content provider handles SSG-specific processing (e.g., Hugo, Jekyll).
public class FileImporter {
    private let contentProvider: ContentProvider

    /// Creates a file importer with the specified content provider.
    /// - Parameter contentProvider: The content provider to use. Defaults to Hugo.
    public init(contentProvider: ContentProvider = ContentProviderRegistry.shared.defaultProvider) {
        self.contentProvider = contentProvider
    }

    /// Imports content from a directory and creates a HelpProject.
    /// - Parameter url: The directory URL containing markdown content.
    /// - Returns: A HelpProject with all documents, assets, and metadata.
    public func `import`(from url: URL) async throws -> HelpProject {
        guard url.hasDirectoryPath else {
            throw FileImporterError.invalidDirectory
        }

        let name = url.lastPathComponent

        // Load saved metadata from UserDefaults, or create default
        let savedMetadata = HelpBookMetadata.loadFromUserDefaults()
        var metadata: HelpBookMetadata
        if let saved = savedMetadata {
            metadata = HelpBookMetadata(
                bundleIdentifier: saved.bundleIdentifier,
                bundleName: name,
                helpBookTitle: "\(name) Help"
            )
            metadata.bundleVersion = saved.bundleVersion
            metadata.bundleShortVersionString = saved.bundleShortVersionString
            metadata.developmentRegion = saved.developmentRegion
            metadata.theme = saved.theme
        } else {
            metadata = HelpBookMetadata(
                bundleIdentifier: "com.example.\(name).help",
                bundleName: name,
                helpBookTitle: "\(name) Help"
            )
        }

        let project = HelpProject(
            name: name,
            sourceDirectory: url,
            metadata: metadata
        )

        // Use the content provider to scan documents
        let frontMatterParser = FrontMatterParser()
        let markdownParser = MarkdownParser()

        let documents = try await contentProvider.scanDocuments(
            at: url,
            frontMatterParser: frontMatterParser,
            markdownParser: markdownParser
        )

        guard !documents.isEmpty else {
            throw FileImporterError.noMarkdownFiles
        }

        project.documents = documents

        // Scan for assets (generic, not SSG-specific)
        let assets = try await scanAssets(at: url, referencedBy: documents)
        project.assets = assets

        // Use the content provider to build file tree
        let directoryMetadata = contentProvider.scanDirectoryMetadata(at: url)
        project.fileTree = contentProvider.buildFileTree(
            from: documents,
            baseName: name,
            baseURL: url,
            directoryMetadata: directoryMetadata
        )

        return project
    }

    /// Scans a directory for asset files (images, CSS, JavaScript).
    /// - Parameters:
    ///   - url: The directory URL to scan.
    ///   - documents: Documents that may reference assets.
    /// - Returns: Array of asset references found.
    public func scanAssets(at url: URL, referencedBy documents: [MarkdownDocument]) async throws -> [AssetReference] {
        var assets = [AssetReference]()
        let validExtensions = ["png", "jpg", "jpeg", "gif", "svg", "webp", "css", "js"]

        let fm = FileManager.default

        let allURLs: [URL] = await Task.detached {
            guard let enumerator = fm.enumerator(
                at: url,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            ) else {
                return []
            }
            return enumerator.allObjects.compactMap { $0 as? URL }
        }.value

        for fileURL in allURLs {
            let ext = fileURL.pathExtension.lowercased()
            guard validExtensions.contains(ext) else {
                continue
            }

            let relativePath = fileURL.path
                .replacingOccurrences(of: url.path + "/", with: "")

            let asset = AssetReference(
                originalPath: fileURL,
                relativePath: relativePath,
                type: assetType(for: ext)
            )

            print("Found asset: \(relativePath) (type: \(asset.type))")
            assets.append(asset)
        }

        print("Total assets found: \(assets.count)")
        return assets
    }

    private func assetType(for ext: String) -> AssetReference.AssetType {
        switch ext.lowercased() {
        case "png", "jpg", "jpeg", "gif", "svg", "webp":
            return .image
        case "css":
            return .css
        case "js":
            return .javascript
        default:
            return .other
        }
    }
}
