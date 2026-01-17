import Foundation

/// Protocol for static site generator content providers.
/// Implement this protocol to add support for different SSGs like Hugo, Jekyll, etc.
public protocol ContentProvider {
    /// Unique identifier for this provider (e.g., "hugo", "jekyll")
    var identifier: String { get }

    /// Display name for this provider
    var displayName: String { get }

    /// File name used for directory/section metadata (e.g., "_index.md" for Hugo)
    var directoryMetadataFileName: String? { get }

    /// Whether files starting with underscore should be skipped as content
    var skipsUnderscoreFiles: Bool { get }

    /// Scans a directory for markdown documents
    /// - Parameters:
    ///   - url: The directory URL to scan
    ///   - frontMatterParser: Parser for frontmatter extraction
    ///   - markdownParser: Parser for markdown to HTML conversion
    /// - Returns: Array of parsed markdown documents
    func scanDocuments(
        at url: URL,
        frontMatterParser: FrontMatterParser,
        markdownParser: MarkdownParser
    ) async throws -> [MarkdownDocument]

    /// Scans for directory metadata files and extracts section information
    /// - Parameter url: The base directory URL
    /// - Returns: Dictionary mapping relative paths to directory metadata
    func scanDirectoryMetadata(at url: URL) -> [String: DirectoryMetadata]

    /// Processes content-specific shortcodes or includes
    /// - Parameter content: Raw markdown content
    /// - Returns: Processed content with shortcodes converted to HTML
    func processShortcodes(_ content: String) -> String

    /// Builds a file tree structure from documents
    /// - Parameters:
    ///   - documents: Array of markdown documents
    ///   - baseName: Name for the root node
    ///   - baseURL: Base directory URL
    ///   - directoryMetadata: Metadata for directories
    /// - Returns: Root file tree node
    func buildFileTree(
        from documents: [MarkdownDocument],
        baseName: String,
        baseURL: URL,
        directoryMetadata: [String: DirectoryMetadata]
    ) -> FileTreeNode
}

/// Metadata extracted from directory index files
public struct DirectoryMetadata {
    public var weight: Int?
    public var title: String?
    public var description: String?

    public init(weight: Int? = nil, title: String? = nil, description: String? = nil) {
        self.weight = weight
        self.title = title
        self.description = description
    }
}

/// Registry of available content providers
public class ContentProviderRegistry {
    public static let shared = ContentProviderRegistry()

    private var providers: [String: ContentProvider] = [:]

    private init() {
        // Register built-in providers
        register(HugoContentProvider())
    }

    public func register(_ provider: ContentProvider) {
        providers[provider.identifier] = provider
    }

    public func provider(for identifier: String) -> ContentProvider? {
        providers[identifier]
    }

    public var availableProviders: [ContentProvider] {
        Array(providers.values)
    }

    public var defaultProvider: ContentProvider {
        providers["hugo"]!
    }
}
