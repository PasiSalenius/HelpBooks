import Foundation

enum CLIError: Error, LocalizedError {
    case invalidArguments(String)
    case configNotFound
    case invalidConfig(String)
    case buildFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidArguments(let msg):
            return "Invalid arguments: \(msg)"
        case .configNotFound:
            return "Configuration file not found. Run 'helpbooks config' to create one."
        case .invalidConfig(let msg):
            return "Invalid configuration: \(msg)"
        case .buildFailed(let msg):
            return "Build failed: \(msg)"
        }
    }
}

class HelpBooksCLI {
    func run(arguments: [String]) async throws {
        guard arguments.count > 1 else {
            printUsage()
            return
        }

        let command = arguments[1]
        let args = Array(arguments.dropFirst(2))

        switch command {
        case "config":
            try runConfig(args: args)
        case "generate", "build":
            try await runGenerate(args: args)
        case "help", "--help", "-h":
            printUsage()
        case "version", "--version", "-v":
            printVersion()
        default:
            throw CLIError.invalidArguments("Unknown command: \(command)")
        }
    }

    private func runConfig(args: [String]) throws {
        let configPath = args.first ?? "helpbooks.json"

        print("Creating configuration file at: \(configPath)")
        print("")

        // Interactive wizard
        print("Help Book Configuration")
        print("======================")
        print("")

        let bundleId = prompt("Bundle Identifier (e.g., com.example.MyApp.help): ")
        let bundleName = prompt("Bundle Name (e.g., MyApp): ")
        let helpBookTitle = prompt("Help Book Title (e.g., MyApp Help): ")
        let contentPath = prompt("Content folder path: ")
        let assetsPath = prompt("Assets folder path (optional): ")
        let outputPath = prompt("Output folder path: ")

        let config = CLIConfig(
            bundleIdentifier: bundleId,
            bundleName: bundleName,
            helpBookTitle: helpBookTitle,
            contentPath: contentPath,
            assetsPath: assetsPath.isEmpty ? nil : assetsPath,
            outputPath: outputPath,
            bundleVersion: "1.0",
            bundleShortVersionString: "1.0",
            developmentRegion: "en"
        )

        try config.save(to: configPath)

        print("")
        print("✓ Configuration saved to \(configPath)")
        print("")
        print("Run 'helpbooks generate' to build your Help Book")
    }

    private func runGenerate(args: [String]) async throws {
        // Parse arguments
        var configPath = "helpbooks.json"
        var contentPath: String?
        var assetsPath: String?
        var outputPath: String?

        var i = 0
        while i < args.count {
            let arg = args[i]

            switch arg {
            case "-c", "--config":
                guard i + 1 < args.count else {
                    throw CLIError.invalidArguments("Missing value for \(arg)")
                }
                configPath = args[i + 1]
                i += 2
            case "--content":
                guard i + 1 < args.count else {
                    throw CLIError.invalidArguments("Missing value for \(arg)")
                }
                contentPath = args[i + 1]
                i += 2
            case "--assets":
                guard i + 1 < args.count else {
                    throw CLIError.invalidArguments("Missing value for \(arg)")
                }
                assetsPath = args[i + 1]
                i += 2
            case "-o", "--output":
                guard i + 1 < args.count else {
                    throw CLIError.invalidArguments("Missing value for \(arg)")
                }
                outputPath = args[i + 1]
                i += 2
            default:
                throw CLIError.invalidArguments("Unknown option: \(arg)")
            }
        }

        // Load config
        let config = try CLIConfig.load(from: configPath)

        // Override with command-line arguments
        let finalContentPath = contentPath ?? config.contentPath
        let finalAssetsPath = assetsPath ?? config.assetsPath
        let finalOutputPath = outputPath ?? config.outputPath

        print("Building Help Book...")
        print("Content: \(finalContentPath)")
        if let assets = finalAssetsPath {
            print("Assets: \(assets)")
        }
        print("Output: \(finalOutputPath)")
        print("")

        // Run the build
        try await buildHelpBook(
            config: config,
            contentPath: finalContentPath,
            assetsPath: finalAssetsPath,
            outputPath: finalOutputPath
        )

        print("")
        print("✓ Help Book built successfully!")
        print("Location: \(finalOutputPath)/\(config.bundleName).help")
    }

    private func buildHelpBook(
        config: CLIConfig,
        contentPath: String,
        assetsPath: String?,
        outputPath: String
    ) async throws {
        // Import content and assets
        let contentURL = URL(fileURLWithPath: contentPath)
        let outputURL = URL(fileURLWithPath: outputPath)

        // Create project
        let importer = FileImporter()
        let project = try await importer.import(from: contentURL)

        // If assets are in a separate folder, scan and add them
        if let assetsPath = assetsPath {
            let assetsURL = URL(fileURLWithPath: assetsPath)
            let additionalAssets = try await importer.scanAssets(at: assetsURL, referencedBy: project.documents)
            print("Found \(additionalAssets.count) assets in separate folder")
            project.assets.append(contentsOf: additionalAssets)
        }

        // Set metadata
        project.metadata.bundleIdentifier = config.bundleIdentifier
        project.metadata.bundleName = config.bundleName
        project.metadata.helpBookTitle = config.helpBookTitle
        project.metadata.bundleVersion = config.bundleVersion
        project.metadata.bundleShortVersionString = config.bundleShortVersionString
        project.metadata.developmentRegion = config.developmentRegion

        // Build
        let builder = HelpBookBuilder()
        _ = try await builder.build(project: project, outputURL: outputURL)
    }

    private func prompt(_ message: String) -> String {
        print(message, terminator: "")
        return readLine() ?? ""
    }

    private func printUsage() {
        print("""
        HelpBooks CLI - Help Book Generator

        USAGE:
            helpbooks <command> [options]

        COMMANDS:
            config              Create a configuration file interactively
            generate            Generate Help Book from configuration
            help                Show this help message
            version             Show version information

        CONFIG OPTIONS:
            -c, --config <path>     Path to config file (default: helpbooks.json)

        GENERATE OPTIONS:
            -c, --config <path>     Path to config file (default: helpbooks.json)
            --content <path>        Override content folder path
            --assets <path>         Override assets folder path
            -o, --output <path>     Override output folder path

        EXAMPLES:
            # Create a configuration file
            helpbooks config

            # Generate Help Book using config
            helpbooks generate

            # Generate with custom paths
            helpbooks generate --content ./docs --output ./build

            # Use custom config file
            helpbooks generate -c myconfig.json
        """)
    }

    private func printVersion() {
        print("HelpBooks CLI v1.0.0")
    }
}
