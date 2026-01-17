import Foundation
import HelpBooksCore

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

        // Try to load existing config to get defaults
        let existingConfig = try? CLIConfig.load(from: configPath)

        // Interactive wizard
        print("Help Book Configuration")
        print("======================")
        print("")
        print("Press Enter to keep the previous value (shown in brackets)")
        print("")

        let bundleId = promptWithDefault(
            "Bundle Identifier (e.g., com.example.MyApp.help): ",
            defaultValue: existingConfig?.bundleIdentifier
        )
        let bundleName = promptWithDefault(
            "Bundle Name (e.g., MyApp): ",
            defaultValue: existingConfig?.bundleName
        )
        let helpBookTitle = promptWithDefault(
            "Help Book Title (e.g., MyApp Help): ",
            defaultValue: existingConfig?.helpBookTitle
        )
        let contentPath = promptWithDefault(
            "Content folder path: ",
            defaultValue: existingConfig?.contentPath
        )
        let assetsPath = promptWithDefault(
            "Assets folder path (optional): ",
            defaultValue: existingConfig?.assetsPath
        )
        let outputPath = promptWithDefault(
            "Output folder path: ",
            defaultValue: existingConfig?.outputPath
        )

        print("")
        let baseURL = promptWithDefault(
            "Base URL to convert to relative links (optional, e.g., https://example.com/docs): ",
            defaultValue: existingConfig?.baseURL
        )

        print("")
        print("Theme Selection:")
        print("1. Modern (current macOS design)")
        print("2. Mavericks (OS X 10.9 style)")
        print("3. Tiger (OS X 10.4 style)")
        print("4. Custom (use custom CSS file)")

        let defaultThemeChoice: String?
        if let existingTheme = existingConfig?.theme {
            switch existingTheme {
            case "Mavericks": defaultThemeChoice = "2"
            case "Tiger": defaultThemeChoice = "3"
            case "Custom": defaultThemeChoice = "4"
            default: defaultThemeChoice = "1"
            }
        } else {
            defaultThemeChoice = nil
        }

        let themeChoice = promptWithDefault(
            "Choose theme (1-4, default: 1): ",
            defaultValue: defaultThemeChoice
        )

        let theme: String?
        let customCssPath: String?

        switch themeChoice {
        case "2":
            theme = "Mavericks"
            customCssPath = nil
        case "3":
            theme = "Tiger"
            customCssPath = nil
        case "4":
            theme = "Custom"
            print("")
            customCssPath = promptWithDefault(
                "Custom CSS file path: ",
                defaultValue: existingConfig?.customCssPath
            )
        default:
            theme = "Modern"
            customCssPath = nil
        }

        let config = CLIConfig(
            bundleIdentifier: bundleId,
            bundleName: bundleName,
            helpBookTitle: helpBookTitle,
            contentPath: contentPath,
            assetsPath: assetsPath.isEmpty ? nil : assetsPath,
            outputPath: outputPath,
            bundleVersion: existingConfig?.bundleVersion ?? "1.0",
            bundleShortVersionString: existingConfig?.bundleShortVersionString ?? "1.0",
            developmentRegion: existingConfig?.developmentRegion ?? "en",
            theme: theme,
            customCssPath: customCssPath,
            baseURL: baseURL.isEmpty ? nil : baseURL
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
        var customCssPath: String?

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
            case "--custom-css":
                guard i + 1 < args.count else {
                    throw CLIError.invalidArguments("Missing value for \(arg)")
                }
                customCssPath = args[i + 1]
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
        let finalCustomCssPath = customCssPath ?? config.customCssPath

        print("Building Help Book...")
        print("Content: \(finalContentPath)")
        if let assets = finalAssetsPath {
            print("Assets: \(assets)")
        }
        if let customCss = finalCustomCssPath {
            print("Custom CSS: \(customCss)")
        }
        print("Output: \(finalOutputPath)")
        print("")

        // Run the build
        try await buildHelpBook(
            config: config,
            contentPath: finalContentPath,
            assetsPath: finalAssetsPath,
            outputPath: finalOutputPath,
            customCssPath: finalCustomCssPath
        )

        print("")
        print("✓ Help Book built successfully!")
        print("Location: \(finalOutputPath)/\(config.bundleName).help")
    }

    private func buildHelpBook(
        config: CLIConfig,
        contentPath: String,
        assetsPath: String?,
        outputPath: String,
        customCssPath: String?
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

        // If custom CSS is specified, add it as an asset
        if let customCssPath = customCssPath {
            let cssURL = URL(fileURLWithPath: customCssPath)

            // Verify the file exists
            guard FileManager.default.fileExists(atPath: cssURL.path) else {
                throw CLIError.buildFailed("Custom CSS file not found: \(customCssPath)")
            }

            // Create asset reference with the file name "style.css" so it replaces the default
            let cssAsset = AssetReference(
                originalPath: cssURL,
                relativePath: "style.css",
                type: .css
            )

            // Remove any existing CSS assets and add the custom one
            project.assets.removeAll { $0.type == .css }
            project.assets.append(cssAsset)
            print("Using custom CSS: \(customCssPath)")
        }

        // Set metadata
        project.metadata.bundleIdentifier = config.bundleIdentifier
        project.metadata.bundleName = config.bundleName
        project.metadata.helpBookTitle = config.helpBookTitle
        project.metadata.bundleVersion = config.bundleVersion
        project.metadata.bundleShortVersionString = config.bundleShortVersionString
        project.metadata.developmentRegion = config.developmentRegion

        // Set base URL if specified
        if let baseURL = config.baseURL {
            project.metadata.baseURL = baseURL
        }

        // Set theme if specified
        if let themeString = config.theme, let theme = HelpBookTheme(rawValue: themeString) {
            project.metadata.theme = theme
        }

        // Build
        let builder = HelpBookBuilder()
        _ = try await builder.build(project: project, outputURL: outputURL)
    }

    private func prompt(_ message: String) -> String {
        print(message, terminator: "")
        return readLine() ?? ""
    }

    private func promptWithDefault(_ message: String, defaultValue: String?) -> String {
        if let defaultValue = defaultValue {
            print("\(message)[\(defaultValue)] ", terminator: "")
            let input = readLine() ?? ""
            return input.isEmpty ? defaultValue : input
        } else {
            print(message, terminator: "")
            return readLine() ?? ""
        }
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
            --custom-css <path>     Override with custom CSS file (replaces theme)
            -o, --output <path>     Override output folder path

        EXAMPLES:
            # Create a configuration file
            helpbooks config

            # Generate Help Book using config
            helpbooks generate

            # Generate with custom paths
            helpbooks generate --content ./docs --output ./build

            # Generate with custom CSS
            helpbooks generate --custom-css ./mystyle.css

            # Use custom config file
            helpbooks generate -c myconfig.json
        """)
    }

    private func printVersion() {
        print("HelpBooks CLI v1.0.0")
    }
}
