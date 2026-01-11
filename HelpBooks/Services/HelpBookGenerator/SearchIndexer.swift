import Foundation

enum SearchIndexerError: Error, LocalizedError {
    case hiutilNotFound
    case indexingFailed(output: String)

    var errorDescription: String? {
        switch self {
        case .hiutilNotFound:
            return "The hiutil tool was not found. This is a macOS system tool required for creating search indexes."
        case .indexingFailed(let output):
            return "Failed to create search index: \(output)"
        }
    }
}

class SearchIndexer {
    func createIndex(
        for bundleURL: URL,
        language: String = "en",
        progress: ((Double) -> Void)? = nil
    ) async throws {
        let lprojPath = bundleURL
            .appendingPathComponent("Contents/Resources")
            .appendingPathComponent("\(language).lproj")

        let indexPath = bundleURL
            .appendingPathComponent("Contents/Resources")
            .appendingPathComponent("search.cshelpindex")

        print("Creating search index...")
        print("  Input: \(lprojPath.path)")
        print("  Output: \(indexPath.path)")

        // Build hiutil command
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/hiutil")
        task.arguments = [
            "-I", "corespotlight",  // Core Spotlight indexing
            "-C",                   // Create index
            "-a",                   // Append (create if doesn't exist)
            "-l", language,         // Language
            "-f", indexPath.path,   // Output file
            lprojPath.path          // Input directory
        ]

        print("  Command: hiutil -I corespotlight -C -a -l \(language) -f \(indexPath.path) \(lprojPath.path)")

        // Capture output
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = errorPipe

        do {
            try task.run()
            task.waitUntilExit()

            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: outputData, encoding: .utf8) ?? ""
            let errorOutput = String(data: errorData, encoding: .utf8) ?? ""

            if !output.isEmpty {
                print("  hiutil output: \(output)")
            }
            if !errorOutput.isEmpty {
                print("  hiutil errors: \(errorOutput)")
            }

            if task.terminationStatus != 0 {
                let fullOutput = [errorOutput, output].filter { !$0.isEmpty }.joined(separator: "\n")
                throw SearchIndexerError.indexingFailed(output: "hiutil exited with status \(task.terminationStatus): \(fullOutput)")
            }

            print("  ✓ Search index created successfully")
            progress?(1.0)
        } catch let error as SearchIndexerError {
            throw error
        } catch {
            throw SearchIndexerError.indexingFailed(output: error.localizedDescription)
        }
    }

    // Optional: Create legacy LSM index
    func createLSMIndex(
        for bundleURL: URL,
        language: String = "en"
    ) async throws {
        let lprojPath = bundleURL
            .appendingPathComponent("Contents/Resources")
            .appendingPathComponent("\(language).lproj")

        let indexPath = bundleURL
            .appendingPathComponent("Contents/Resources")
            .appendingPathComponent("search.helpindex")

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/hiutil")
        task.arguments = [
            "-I", "lsm",           // Legacy LSM indexing
            "-C",
            "-a",
            "-l", language,
            "-f", indexPath.path,
            lprojPath.path
        ]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        try task.run()
        task.waitUntilExit()

        if task.terminationStatus != 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            throw SearchIndexerError.indexingFailed(output: output)
        }
    }
}
