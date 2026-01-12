import Foundation

struct CLIConfig: Codable {
    var bundleIdentifier: String
    var bundleName: String
    var helpBookTitle: String
    var contentPath: String
    var assetsPath: String?
    var outputPath: String
    var bundleVersion: String
    var bundleShortVersionString: String
    var developmentRegion: String
    var theme: String?

    func save(to path: String) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(self)
        let url = URL(fileURLWithPath: path)
        try data.write(to: url)
    }

    static func load(from path: String) throws -> CLIConfig {
        let url = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw CLIError.configNotFound
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode(CLIConfig.self, from: data)
    }
}
