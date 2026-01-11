import Foundation
import SwiftUI

@Observable
class ExportViewModel {
    var outputPath: String = ""
    var isExporting = false
    var isComplete = false
    var progress: Double = 0.0
    var currentPhase: BuildPhase = .preparing
    var currentTask: String = ""
    var error: Error?
    var exportedBundleURL: URL?

    private let project: HelpProject
    private let builder: HelpBookBuilder

    init(project: HelpProject) {
        self.project = project
        self.builder = HelpBookBuilder()
    }

    func chooseOutputLocation() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Choose a folder to save the Help Book bundle"
        panel.prompt = "Choose"

        if panel.runModal() == .OK, let url = panel.url {
            outputPath = url.path
        }
    }

    func export() async {
        guard !outputPath.isEmpty else { return }

        await MainActor.run {
            isExporting = true
            isComplete = false
            error = nil
        }

        do {
            let outputURL = URL(fileURLWithPath: outputPath)

            // Observe builder progress
            let bundleURL = try await builder.build(project: project, outputURL: outputURL)

            await MainActor.run {
                exportedBundleURL = bundleURL
                isComplete = true
                isExporting = false
                progress = builder.progress
                currentPhase = builder.currentPhase
            }
        } catch {
            await MainActor.run {
                self.error = error
                isExporting = false
                currentPhase = .failed(error.localizedDescription)
            }
        }
    }

    func revealInFinder() {
        guard let bundleURL = exportedBundleURL else { return }
        NSWorkspace.shared.selectFile(bundleURL.path, inFileViewerRootedAtPath: "")
    }
}
