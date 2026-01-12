import Foundation
import SwiftUI

@Observable
class ProjectViewModel {
    var project: HelpProject?
    var previewViewModel: PreviewViewModel
    var isImporting = false
    var importError: String?

    private let fileImporter: FileImporter
    private let markdownParser: MarkdownParser
    private let shortcodeProcessor: ShortcodeProcessor
    private let frontMatterParser: FrontMatterParser

    init() {
        self.fileImporter = FileImporter()
        self.markdownParser = MarkdownParser()
        self.shortcodeProcessor = ShortcodeProcessor()
        self.frontMatterParser = FrontMatterParser()
        self.previewViewModel = PreviewViewModel()
    }

    func importFolder(_ url: URL) {
        Task {
            isImporting = true
            importError = nil

            do {
                // Import Hugo content folder
                let importedProject = try await fileImporter.import(from: url)
                print("✅ Imported \(importedProject.documents.count) documents")

                // Process all markdown files
                for index in importedProject.documents.indices {
                    do {
                        // Note: Front matter is already parsed in FileImporter
                        // Just process shortcodes and convert to HTML

                        // Process shortcodes FIRST (before markdown conversion)
                        // This replaces {{< alert ... />}} with proper HTML <div> tags
                        let processedBody = shortcodeProcessor.process(importedProject.documents[index].content)

                        // Then convert markdown to HTML
                        // The .unsafe option allows the HTML we generated to pass through
                        var html = try markdownParser.convert(processedBody)

                        // Process any remaining shortcodes in the HTML output (just in case)
                        html = shortcodeProcessor.process(html)

                        importedProject.documents[index].htmlContent = html
                    } catch {
                        print("⚠️ Warning: Failed to process \(importedProject.documents[index].fileName): \(error)")
                    }
                }

                print("✅ File tree children count: \(importedProject.fileTree?.children?.count ?? 0)")

                await MainActor.run {
                    self.project = importedProject
                    self.isImporting = false
                    print("✅ Project set with \(importedProject.documents.count) documents")
                }
            } catch {
                await MainActor.run {
                    self.importError = error.localizedDescription
                    self.isImporting = false
                }
            }
        }
    }

    func importContentAndAssets(contentURL: URL, assetsURL: URL?) {
        Task {
            isImporting = true
            importError = nil

            do {
                // Import content first
                let importedProject = try await fileImporter.import(from: contentURL)
                print("✅ Imported \(importedProject.documents.count) documents")

                // Process all markdown files
                for index in importedProject.documents.indices {
                    do {
                        // Note: Front matter is already parsed in FileImporter
                        // Just process shortcodes and convert to HTML

                        // Process shortcodes FIRST (before markdown conversion)
                        let processedBody = shortcodeProcessor.process(importedProject.documents[index].content)

                        // Then convert markdown to HTML
                        var html = try markdownParser.convert(processedBody)

                        // Process any remaining shortcodes in the HTML output
                        html = shortcodeProcessor.process(html)

                        importedProject.documents[index].htmlContent = html
                    } catch {
                        print("⚠️ Warning: Failed to process \(importedProject.documents[index].fileName): \(error)")
                    }
                }

                // Import assets if provided
                if let assetsURL = assetsURL {
                    let assets = try await fileImporter.scanAssets(at: assetsURL, referencedBy: importedProject.documents)
                    importedProject.assets.append(contentsOf: assets)
                    importedProject.assetsDirectory = assetsURL
                    print("✅ Imported \(assets.count) assets")
                }

                await MainActor.run {
                    self.project = importedProject
                    self.isImporting = false
                    print("✅ Project ready with \(importedProject.documents.count) documents and \(importedProject.assets.count) assets")
                }
            } catch {
                await MainActor.run {
                    self.importError = error.localizedDescription
                    self.isImporting = false
                }
            }
        }
    }

    func addMarkdownFiles(_ urls: [URL]) {
        Task {
            guard let currentProject = project else {
                print("⚠️ No project - cannot add markdown files")
                return
            }

            print("📝 Processing \(urls.count) markdown files")
            var addedDocuments: [MarkdownDocument] = []

            for url in urls {
                do {
                    // Read file content
                    let rawContent = try String(contentsOf: url, encoding: .utf8)

                    // Parse frontmatter
                    let (frontMatter, content) = try frontMatterParser.parse(rawContent)

                    // Process shortcodes
                    let processedContent = shortcodeProcessor.process(content)

                    // Convert to HTML
                    let htmlContent = try markdownParser.convert(processedContent)

                    // Create document
                    let document = MarkdownDocument(
                        relativePath: url.lastPathComponent,
                        fileName: url.lastPathComponent,
                        frontMatter: frontMatter,
                        content: content,
                        htmlContent: htmlContent
                    )

                    addedDocuments.append(document)
                    print("✅ Added markdown file: \(url.lastPathComponent)")
                } catch {
                    print("⚠️ Failed to import \(url.lastPathComponent): \(error)")
                }
            }

            await MainActor.run {
                // Add documents to project
                currentProject.documents.append(contentsOf: addedDocuments)

                // Update file tree to include new documents
                if currentProject.fileTree == nil {
                    // Create root if it doesn't exist
                    currentProject.fileTree = FileTreeNode(
                        name: "Root",
                        isDirectory: true,
                        children: [],
                        relativePath: ""
                    )
                }

                // Add documents to root of file tree
                if var root = currentProject.fileTree {
                    var children = root.children ?? []
                    for doc in addedDocuments {
                        let node = FileTreeNode(
                            name: doc.fileName,
                            isDirectory: false,
                            documentId: doc.id,
                            relativePath: doc.relativePath
                        )
                        children.append(node)
                    }
                    root.children = children
                    currentProject.fileTree = root
                }

                self.project = currentProject
                print("✅ Added \(addedDocuments.count) markdown file(s)")
            }
        }
    }

    func addAssetsFromFolder(_ url: URL) {
        Task {
            guard let currentProject = project else {
                print("⚠️ No project - cannot add assets")
                return
            }

            print("🖼️ Processing asset: \(url.lastPathComponent)")

            do {
                var newAssets: [AssetReference] = []

                // Check if URL is a file or directory
                var isDirectory: ObjCBool = false
                FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
                print("📁 Is directory: \(isDirectory.boolValue)")

                if isDirectory.boolValue {
                    // Scan folder for assets
                    newAssets = try await fileImporter.scanAssets(at: url, referencedBy: currentProject.documents)
                } else {
                    // Single file - create asset directly
                    let validExtensions = ["png", "jpg", "jpeg", "gif", "svg", "webp", "css", "js"]
                    let ext = url.pathExtension.lowercased()

                    if validExtensions.contains(ext) {
                        let assetType: AssetReference.AssetType
                        switch ext {
                        case "png", "jpg", "jpeg", "gif", "svg", "webp":
                            assetType = .image
                        case "css":
                            assetType = .css
                        case "js":
                            assetType = .javascript
                        default:
                            assetType = .other
                        }

                        let asset = AssetReference(
                            originalPath: url,
                            relativePath: url.lastPathComponent,
                            type: assetType
                        )
                        newAssets = [asset]
                        print("Added single asset: \(url.lastPathComponent) (type: \(assetType))")
                    }
                }

                await MainActor.run {
                    // Add new assets to existing project
                    for asset in newAssets {
                        // Avoid duplicates based on file name (not full path since single files don't have original folder context)
                        if !currentProject.assets.contains(where: { $0.relativePath == asset.relativePath }) {
                            currentProject.assets.append(asset)
                        }
                    }
                    // Update assets directory if it was a folder
                    if isDirectory.boolValue {
                        currentProject.assetsDirectory = url
                    }
                    self.project = currentProject

                    // Refresh preview to show newly added assets
                    self.previewViewModel.refresh()

                    print("✅ Added \(newAssets.count) assets (Total: \(currentProject.assets.count))")
                }
            } catch {
                print("⚠️ Failed to import assets: \(error)")
            }
        }
    }

    func deleteDocuments(withIds ids: Set<UUID>) {
        guard let currentProject = project else { return }

        // Separate document IDs from directory IDs
        var documentIdsToDelete = Set<UUID>()
        var directoryIdsToDelete = Set<UUID>()

        for id in ids {
            // Check if it's a document ID
            if currentProject.documents.contains(where: { $0.id == id }) {
                documentIdsToDelete.insert(id)
            } else {
                // Assume it's a directory ID
                directoryIdsToDelete.insert(id)
            }
        }

        // For each directory, collect all document IDs within it
        if let tree = currentProject.fileTree {
            for dirId in directoryIdsToDelete {
                let docIds = collectDocumentIds(in: tree, directoryId: dirId)
                documentIdsToDelete.formUnion(docIds)
            }
        }

        // Remove all collected documents
        currentProject.documents.removeAll { documentIdsToDelete.contains($0.id) }

        // Rebuild file tree without deleted documents and directories
        if let tree = currentProject.fileTree {
            currentProject.fileTree = removeNodesFromTree(tree, documentIds: documentIdsToDelete, directoryIds: directoryIdsToDelete)
        }

        project = currentProject
        print("✅ Deleted \(ids.count) item(s) (\(documentIdsToDelete.count) documents)")
    }

    func deleteAssets(withIds ids: Set<UUID>) {
        guard let currentProject = project else { return }

        // Remove assets
        currentProject.assets.removeAll { ids.contains($0.id) }

        project = currentProject
        print("✅ Deleted \(ids.count) asset(s)")
    }

    /// Collects all document IDs within a directory
    private func collectDocumentIds(in node: FileTreeNode, directoryId: UUID) -> Set<UUID> {
        var documentIds = Set<UUID>()

        // If this is the directory we're looking for, collect all its document IDs
        if node.id == directoryId {
            collectAllDocumentIds(in: node, into: &documentIds)
            return documentIds
        }

        // Otherwise, recurse into children
        if let children = node.children {
            for child in children {
                let childDocIds = collectDocumentIds(in: child, directoryId: directoryId)
                documentIds.formUnion(childDocIds)
            }
        }

        return documentIds
    }

    /// Recursively collects all document IDs in a node and its descendants
    private func collectAllDocumentIds(in node: FileTreeNode, into documentIds: inout Set<UUID>) {
        if !node.isDirectory, let docId = node.documentId {
            documentIds.insert(docId)
        }

        if let children = node.children {
            for child in children {
                collectAllDocumentIds(in: child, into: &documentIds)
            }
        }
    }

    /// Removes nodes from tree based on document IDs and directory IDs
    private func removeNodesFromTree(_ node: FileTreeNode, documentIds: Set<UUID>, directoryIds: Set<UUID>) -> FileTreeNode? {
        // If this directory is being deleted, return nil
        if node.isDirectory && directoryIds.contains(node.id) {
            return nil
        }

        // If this is a file node and its document is being deleted, return nil
        if !node.isDirectory, let docId = node.documentId, documentIds.contains(docId) {
            return nil
        }

        // If this is a directory, filter its children
        if node.isDirectory {
            var updatedNode = node
            updatedNode.children = node.children?.compactMap { child in
                removeNodesFromTree(child, documentIds: documentIds, directoryIds: directoryIds)
            }

            // If directory is now empty, return nil to remove it
            if let children = updatedNode.children, children.isEmpty {
                return nil
            }

            return updatedNode
        }

        return node
    }
}
