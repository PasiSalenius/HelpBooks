import Foundation

enum InfoPlistGeneratorError: Error, LocalizedError {
    case encodingFailed(String)
    case writeFailed(String)

    var errorDescription: String? {
        switch self {
        case .encodingFailed(let details):
            return "Failed to encode Info.plist: \(details)"
        case .writeFailed(let details):
            return "Failed to write Info.plist: \(details)"
        }
    }
}

class InfoPlistGenerator {
    func generate(metadata: HelpBookMetadata, at bundleURL: URL) throws {
        let plistDict = metadata.toInfoPlist()

        do {
            let data = try PropertyListSerialization.data(
                fromPropertyList: plistDict,
                format: .xml,
                options: 0
            )

            let plistURL = bundleURL
                .appendingPathComponent("Contents")
                .appendingPathComponent("Info.plist")

            try data.write(to: plistURL)
        } catch {
            throw InfoPlistGeneratorError.writeFailed(error.localizedDescription)
        }
    }
}
