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

    init() {
        self.fileImporter = FileImporter()
        self.markdownParser = MarkdownParser()
        self.shortcodeProcessor = ShortcodeProcessor()
        self.previewViewModel = PreviewViewModel()
    }

    func importFolder(_ url: URL) {
        Task {
            isImporting = true
            importError = nil

            do {
                // Import Hugo content folder
                var importedProject = try await fileImporter.import(from: url)
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
                var importedProject = try await fileImporter.import(from: contentURL)
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

    func addAssetsFromFolder(_ url: URL) {
        Task {
            guard var currentProject = project else { return }

            do {
                // Scan for assets in the dropped folder
                let newAssets = try await fileImporter.scanAssets(at: url, referencedBy: currentProject.documents)

                await MainActor.run {
                    // Add new assets to existing project
                    for asset in newAssets {
                        // Avoid duplicates
                        if !currentProject.assets.contains(where: { $0.originalPath == asset.originalPath }) {
                            currentProject.assets.append(asset)
                        }
                    }
                    self.project = currentProject
                    print("✅ Added \(newAssets.count) assets (Total: \(currentProject.assets.count))")
                }
            } catch {
                print("⚠️ Failed to import assets: \(error)")
            }
        }
    }
}
