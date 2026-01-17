import Foundation
import Down

/// Content provider for Hugo static site generator.
/// Handles Hugo-specific content structure including _index.md files,
/// weight-based ordering, and Hugo shortcode syntax.
public class HugoContentProvider: ContentProvider {
    public var identifier: String { "hugo" }
    public var displayName: String { "Hugo" }
    public var directoryMetadataFileName: String? { "_index.md" }
    public var skipsUnderscoreFiles: Bool { true }

    public init() {}

    public func scanDocuments(
        at url: URL,
        frontMatterParser: FrontMatterParser,
        markdownParser: MarkdownParser
    ) async throws -> [MarkdownDocument] {
        let fm = FileManager.default
        var documents = [MarkdownDocument]()

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
            guard fileURL.pathExtension == "md" else { continue }

            let fileName = fileURL.lastPathComponent

            // Skip files that start with underscore (Hugo convention)
            if skipsUnderscoreFiles && fileName.hasPrefix("_") {
                continue
            }

            do {
                let rawContent = try String(contentsOf: fileURL, encoding: .utf8)

                let relativePath = fileURL.path
                    .replacingOccurrences(of: url.path + "/", with: "")

                // Parse frontmatter
                let (frontMatter, content) = try frontMatterParser.parse(rawContent)

                // Process Hugo shortcodes
                let processedContent = processShortcodes(content)

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

    public func scanDirectoryMetadata(at url: URL) -> [String: DirectoryMetadata] {
        guard let metadataFileName = directoryMetadataFileName else {
            return [:]
        }

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

        let allURLs = enumerator.allObjects.compactMap { $0 as? URL }

        for fileURL in allURLs {
            let fileName = fileURL.lastPathComponent

            guard fileName == metadataFileName else { continue }

            do {
                let rawContent = try String(contentsOf: fileURL, encoding: .utf8)
                let (frontMatter, _) = try frontMatterParser.parse(rawContent)

                let dirPath = fileURL.deletingLastPathComponent().path
                    .replacingOccurrences(of: url.path + "/", with: "")

                metadata[dirPath] = DirectoryMetadata(
                    weight: frontMatter.weight,
                    title: frontMatter.title,
                    description: frontMatter.description
                )
            } catch {
                print("Warning: Failed to parse \(metadataFileName) at \(fileURL.path): \(error)")
            }
        }

        return metadata
    }

    public func processShortcodes(_ content: String) -> String {
        var processed = content
        processed = processAlertShortcodes(processed)
        return processed
    }

    public func buildFileTree(
        from documents: [MarkdownDocument],
        baseName: String,
        baseURL: URL,
        directoryMetadata: [String: DirectoryMetadata]
    ) -> FileTreeNode {
        var root = FileTreeNode(
            name: baseName,
            isDirectory: true,
            children: [],
            relativePath: ""
        )

        // Group documents by directory
        var directoryMap: [String: [MarkdownDocument]] = [:]

        for doc in documents {
            let components = doc.relativePath.split(separator: "/")
            if components.count == 1 {
                directoryMap[""] = (directoryMap[""] ?? []) + [doc]
            } else {
                let dirPath = components.dropLast().joined(separator: "/")
                directoryMap[dirPath] = (directoryMap[dirPath] ?? []) + [doc]
            }
        }

        root.children = buildTreeNodes(
            directoryMap: directoryMap,
            currentPath: "",
            documents: documents,
            directoryMetadata: directoryMetadata
        )

        return root
    }

    // MARK: - Private Methods

    private func buildTreeNodes(
        directoryMap: [String: [MarkdownDocument]],
        currentPath: String,
        documents: [MarkdownDocument],
        directoryMetadata: [String: DirectoryMetadata]
    ) -> [FileTreeNode] {
        var nodes: [FileTreeNode] = []

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

        // Sort by weight (Hugo convention: lower weights appear first)
        return nodes.sorted { node1, node2 in
            let weight1 = node1.weight ?? Int.max
            let weight2 = node2.weight ?? Int.max
            if weight1 != weight2 {
                return weight1 < weight2
            }
            return node1.name < node2.name
        }
    }

    // MARK: - Hugo Alert Shortcode Processing

    private func processAlertShortcodes(_ content: String) -> String {
        // Match: {{< alert icon="..." context="..." text="..." />}}
        let pattern = #"\{\{<\s*alert\s+([^>]*)/>\s*\}\}"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return content
        }

        let nsString = content as NSString
        let matches = regex.matches(in: content, options: [], range: NSRange(location: 0, length: nsString.length))

        var result = content

        for match in matches.reversed() {
            let attributesRange = match.range(at: 1)
            let attributes = nsString.substring(with: attributesRange)

            let icon = extractAttribute(name: "icon", from: attributes) ?? ""
            let context = extractAttribute(name: "context", from: attributes) ?? "info"
            let text = extractAttribute(name: "text", from: attributes) ?? ""

            let html = generateAlertHTML(icon: icon, context: context, text: text)

            if let range = Range(match.range, in: result) {
                result.replaceSubrange(range, with: html)
            }
        }

        return result
    }

    private func extractAttribute(name: String, from attributes: String) -> String? {
        let pattern = "\\b\(name)\\s*=\\s*(?:\"([^\"]*)\"|'([^']*)')"

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }

        let nsString = attributes as NSString
        let range = NSRange(location: 0, length: nsString.length)

        guard let match = regex.firstMatch(in: attributes, options: [], range: range) else {
            return nil
        }

        let doubleQuoteRange = match.range(at: 1)
        let singleQuoteRange = match.range(at: 2)

        let valueRange = doubleQuoteRange.location != NSNotFound ? doubleQuoteRange : singleQuoteRange
        guard valueRange.location != NSNotFound else {
            return nil
        }

        return nsString.substring(with: valueRange)
    }

    private func generateAlertHTML(icon: String, context: String, text: String) -> String {
        let contextClass: String
        let backgroundColor: String
        let borderColor: String
        let defaultIcon: String

        switch context.lowercased() {
        case "info":
            contextClass = "alert-info"
            backgroundColor = "#d1ecf1"
            borderColor = "#bee5eb"
            defaultIcon = "ℹ️"
        case "primary":
            contextClass = "alert-primary"
            backgroundColor = "#cce5ff"
            borderColor = "#b8daff"
            defaultIcon = "ℹ️"
        case "warning":
            contextClass = "alert-warning"
            backgroundColor = "#fff3cd"
            borderColor = "#ffeaa7"
            defaultIcon = "⚠️"
        case "danger", "error":
            contextClass = "alert-danger"
            backgroundColor = "#f8d7da"
            borderColor = "#f5c6cb"
            defaultIcon = "❗️"
        case "success":
            contextClass = "alert-success"
            backgroundColor = "#d4edda"
            borderColor = "#c3e6cb"
            defaultIcon = "✅"
        case "light":
            contextClass = "alert-light"
            backgroundColor = "#fefefe"
            borderColor = "#e9ecef"
            defaultIcon = "💡"
        case "dark":
            contextClass = "alert-dark"
            backgroundColor = "#d6d8d9"
            borderColor = "#c6c8ca"
            defaultIcon = "◾️"
        default:
            contextClass = "alert-info"
            backgroundColor = "#d1ecf1"
            borderColor = "#bee5eb"
            defaultIcon = "ℹ️"
        }

        let displayIcon = icon.isEmpty ? defaultIcon : icon
        let processedText = processInlineMarkdown(text)

        return """
        <div class="alert \(contextClass)" style="padding: 12px 16px; margin: 16px 0; border-left: 4px solid \(borderColor); background-color: \(backgroundColor); border-radius: 4px;">
            <span style="font-size: 1.2em; margin-right: 8px;">\(displayIcon)</span>
            <span>\(processedText)</span>
        </div>
        """
    }

    private func processInlineMarkdown(_ text: String) -> String {
        do {
            let down = Down(markdownString: text)
            var html = try down.toHTML(.unsafe)

            html = html.trimmingCharacters(in: .whitespacesAndNewlines)
            if html.hasPrefix("<p>") && html.hasSuffix("</p>") {
                html = String(html.dropFirst(3).dropLast(4))
            }

            return html
        } catch {
            return text
        }
    }
}
