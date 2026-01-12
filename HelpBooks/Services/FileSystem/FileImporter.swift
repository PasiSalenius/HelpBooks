import Foundation

enum FileImporterError: Error {
    case invalidDirectory
    case noMarkdownFiles
    case scanFailed(underlying: Error)
}

class FileImporter {
    func `import`(from url: URL) async throws -> HelpProject {
        guard url.hasDirectoryPath else {
            throw FileImporterError.invalidDirectory
        }

        let name = url.lastPathComponent

        // Load saved metadata from UserDefaults, or create default
        let savedMetadata = HelpBookMetadata.loadFromUserDefaults()
        var metadata: HelpBookMetadata
        if let saved = savedMetadata {
            // Use saved metadata but update the bundle name and title for new project
            metadata = HelpBookMetadata(
                bundleIdentifier: saved.bundleIdentifier,
                bundleName: name,
                helpBookTitle: "\(name) Help"
            )
            // Preserve saved settings
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

        var project = HelpProject(
            name: name,
            sourceDirectory: url,
            metadata: metadata
        )

        // Scan for markdown files
        let documents = try await scanMarkdownFiles(at: url)

        guard !documents.isEmpty else {
            throw FileImporterError.noMarkdownFiles
        }

        project.documents = documents

        // Scan for assets
        let assets = try await scanAssets(at: url, referencedBy: documents)
        project.assets = assets

        // Build file tree
        project.fileTree = buildFileTree(from: documents, baseName: name, baseURL: url)

        return project
    }

    private func scanMarkdownFiles(at url: URL) async throws -> [MarkdownDocument] {
        let fm = FileManager.default
        var documents = [MarkdownDocument]()

        let frontMatterParser = FrontMatterParser()
        let markdownParser = MarkdownParser()
        let shortcodeProcessor = ShortcodeProcessor()

        guard let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            throw FileImporterError.invalidDirectory
        }

        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension == "md" else { continue }

            let fileName = fileURL.lastPathComponent

            // Skip files that start with underscore (e.g., _index.md)
            // These are category metadata files, not content pages
            // They will be scanned separately for directory weights
            guard !fileName.hasPrefix("_") else {
                print("Skipping underscore file: \(fileName)")
                continue
            }

            do {
                let rawContent = try String(contentsOf: fileURL, encoding: .utf8)

                let relativePath = fileURL.path
                    .replacingOccurrences(of: url.path + "/", with: "")

                // Parse frontmatter
                let (frontMatter, content) = try frontMatterParser.parse(rawContent)

                // Process shortcodes first
                let processedContent = shortcodeProcessor.process(content)

                // Convert markdown to HTML
                let htmlContent = try markdownParser.convert(processedContent)

                let document = MarkdownDocument(
                    relativePath: relativePath,
                    fileName: fileURL.lastPathComponent,
                    frontMatter: frontMatter,
                    content: content,
                    htmlContent: htmlContent
                )

                documents.append(document)
            } catch {
                print("Warning: Could not process file \(fileURL.path): \(error)")
                continue
            }
        }

        return documents
    }

    public func scanAssets(at url: URL, referencedBy documents: [MarkdownDocument]) async throws -> [AssetReference] {
        var assets = [AssetReference]()
        let validExtensions = ["png", "jpg", "jpeg", "gif", "svg", "webp", "css", "js"]

        let fm = FileManager.default
        guard let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        for case let fileURL as URL in enumerator {
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

    struct DirectoryMetadata {
        var weight: Int?
        var title: String?
        var description: String?
    }

    private func scanDirectoryMetadata(at url: URL) -> [String: DirectoryMetadata] {
        let fm = FileManager.default
        var metadata: [String: DirectoryMetadata] = [:]
        let frontMatterParser = FrontMatterParser()

        guard let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return metadata
        }

        for case let fileURL as URL in enumerator {
            let fileName = fileURL.lastPathComponent

            // Only process _index.md files
            guard fileName == "_index.md" else { continue }

            do {
                let rawContent = try String(contentsOf: fileURL, encoding: .utf8)
                let (frontMatter, _) = try frontMatterParser.parse(rawContent)

                // Get the directory path relative to base
                let dirPath = fileURL.deletingLastPathComponent().path
                    .replacingOccurrences(of: url.path + "/", with: "")

                metadata[dirPath] = DirectoryMetadata(
                    weight: frontMatter.weight,
                    title: frontMatter.title,
                    description: frontMatter.description
                )

                print("Found metadata for directory '\(dirPath)': title=\(frontMatter.title ?? "nil"), weight=\(frontMatter.weight?.description ?? "nil")")
            } catch {
                print("⚠️ Failed to parse _index.md at \(fileURL.path): \(error)")
            }
        }

        return metadata
    }

    private func buildFileTree(from documents: [MarkdownDocument], baseName: String, baseURL: URL) -> FileTreeNode {
        var root = FileTreeNode(
            name: baseName,
            isDirectory: true,
            children: [],
            relativePath: ""
        )

        // Scan for directory metadata from _index.md files
        let directoryMetadata = scanDirectoryMetadata(at: baseURL)

        // Group documents by directory
        var directoryMap: [String: [MarkdownDocument]] = [:]

        for doc in documents {
            let components = doc.relativePath.split(separator: "/")
            if components.count == 1 {
                // Root level file
                directoryMap[""] = (directoryMap[""] ?? []) + [doc]
            } else {
                // File in subdirectory
                let dirPath = components.dropLast().joined(separator: "/")
                directoryMap[dirPath] = (directoryMap[dirPath] ?? []) + [doc]
            }
        }

        // Build tree structure
        root.children = buildTreeNodes(
            directoryMap: directoryMap,
            currentPath: "",
            documents: documents,
            directoryMetadata: directoryMetadata
        )

        return root
    }

    private func buildTreeNodes(
        directoryMap: [String: [MarkdownDocument]],
        currentPath: String,
        documents: [MarkdownDocument],
        directoryMetadata: [String: DirectoryMetadata]
    ) -> [FileTreeNode] {
        var nodes: [FileTreeNode] = []

        // Get files at current level
        let filesAtLevel = directoryMap[currentPath] ?? []

        for doc in filesAtLevel {
            let fileName = doc.fileName
            let node = FileTreeNode(
                name: fileName,
                isDirectory: false,
                documentId: doc.id,
                relativePath: doc.relativePath,
                weight: doc.frontMatter.weight
            )
            nodes.append(node)
        }

        // Get subdirectories at current level
        let subdirs = Set(directoryMap.keys.compactMap { key -> String? in
            guard key.hasPrefix(currentPath) && key != currentPath else { return nil }
            let remaining = key.dropFirst(currentPath.isEmpty ? 0 : currentPath.count + 1)
            return remaining.split(separator: "/").first.map(String.init)
        })

        for subdir in subdirs.sorted() {
            let subdirPath = currentPath.isEmpty ? subdir : "\(currentPath)/\(subdir)"
            let children = buildTreeNodes(
                directoryMap: directoryMap,
                currentPath: subdirPath,
                documents: documents,
                directoryMetadata: directoryMetadata
            )

            let metadata = directoryMetadata[subdirPath]
            let dirNode = FileTreeNode(
                name: subdir,
                isDirectory: true,
                children: children,
                relativePath: subdirPath,
                weight: metadata?.weight,
                title: metadata?.title,
                description: metadata?.description
            )
            nodes.append(dirNode)
        }

        // Sort all nodes (files and folders) together by weight
        return nodes.sorted { node1, node2 in
            // Both files and folders use weight for sorting
            let weight1 = node1.weight ?? Int.max
            let weight2 = node2.weight ?? Int.max
            if weight1 != weight2 {
                return weight1 < weight2
            }
            // If weights are equal, sort alphabetically
            return node1.name < node2.name
        }
    }
}
