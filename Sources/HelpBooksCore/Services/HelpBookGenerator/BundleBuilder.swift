import Foundation

enum BundleBuilderError: Error, LocalizedError {
    case directoryCreationFailed(String)
    case invalidBundleName

    var errorDescription: String? {
        switch self {
        case .directoryCreationFailed(let details):
            return "Failed to create bundle directory: \(details)"
        case .invalidBundleName:
            return "Invalid bundle name. Please provide a valid bundle name in the metadata."
        }
    }
}

class BundleBuilder {
    func createBundle(at url: URL, project: HelpProject) throws -> URL {
        let bundleName = "\(project.metadata.bundleName).help"

        guard !bundleName.isEmpty else {
            throw BundleBuilderError.invalidBundleName
        }

        let bundleURL = url.appendingPathComponent(bundleName)

        // Create directory structure
        try createDirectoryStructure(at: bundleURL)

        return bundleURL
    }

    private func createDirectoryStructure(at bundleURL: URL) throws {
        let fm = FileManager.default

        // Remove existing bundle if it exists
        if fm.fileExists(atPath: bundleURL.path) {
            try fm.removeItem(at: bundleURL)
        }

        // Create: MyApp.help/Contents/Resources/en.lproj/
        let contentsURL = bundleURL.appendingPathComponent("Contents")
        let resourcesURL = contentsURL.appendingPathComponent("Resources")
        let enURL = resourcesURL.appendingPathComponent("en.lproj")

        do {
            try fm.createDirectory(at: enURL, withIntermediateDirectories: true)
        } catch {
            throw BundleBuilderError.directoryCreationFailed(error.localizedDescription)
        }

        // Create assets folder at Resources level
        let assetsURL = resourcesURL.appendingPathComponent("assets")
        do {
            try fm.createDirectory(at: assetsURL, withIntermediateDirectories: true)
        } catch {
            throw BundleBuilderError.directoryCreationFailed(error.localizedDescription)
        }
    }
}
