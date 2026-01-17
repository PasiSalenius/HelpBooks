import Foundation

public enum HelpBookTheme: String, Codable, CaseIterable {
    case modern = "Modern"
    case mavericks = "Mavericks"
    case tiger = "Tiger"
}

public struct HelpBookMetadata: Codable {
    // Bundle Info
    public var bundleIdentifier: String
    public var bundleName: String
    public var bundleVersion: String = "1.0"
    public var bundleShortVersionString: String = "1.0"

    // Help Book Specific
    public var helpBookTitle: String
    public var helpBookIconPath: String?
    public var accessPath: String = "en.lproj/index.html"
    public var tocPath: String = "en.lproj/toc.html"
    public var indexPath: String = "search.helpindex"
    public var csIndexPath: String = "search.cshelpindex"
    public var bookType: String = "3"

    // Optional
    public var developmentRegion: String = "en"
    public var kbProduct: String = ""
    public var kbURL: String = ""
    public var remoteURL: String = ""

    // Theme Settings
    public var theme: HelpBookTheme = .modern

    // Link Rewriting
    public var baseURL: String = ""

    public init(
        bundleIdentifier: String,
        bundleName: String,
        helpBookTitle: String
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.bundleName = bundleName
        self.helpBookTitle = helpBookTitle
    }

    func toInfoPlist() -> [String: Any] {
        var plist: [String: Any] = [
            "CFBundleIdentifier": bundleIdentifier,
            "CFBundleName": bundleName,
            "CFBundleVersion": bundleVersion,
            "CFBundleShortVersionString": bundleShortVersionString,
            "CFBundlePackageType": "BNDL",
            "CFBundleSignature": "hbwr",
            "CFBundleInfoDictionaryVersion": "6.0",
            "CFBundleDevelopmentRegion": developmentRegion,
            "HPDBookTitle": helpBookTitle,
            "HPDBookAccessPath": accessPath,
            "HPDBookTOCPath": tocPath,
            "HPDBookIndexPath": indexPath,
            "HPDBookCSIndexPath": csIndexPath,
            "HPDBookType": bookType,
        ]

        // Add optional fields if present
        if let iconPath = helpBookIconPath, !iconPath.isEmpty {
            plist["HPDBookIconPath"] = iconPath
        }
        if !kbProduct.isEmpty {
            plist["HPDBookKBProduct"] = kbProduct
        }
        if !kbURL.isEmpty {
            plist["HPDBookKBURL"] = kbURL
        }
        if !remoteURL.isEmpty {
            plist["HPDBookRemoteURL"] = remoteURL
        }

        return plist
    }
}

// MARK: - UserDefaults Persistence

extension HelpBookMetadata {
    private static let userDefaultsKey = "SavedHelpBookMetadata"

    /// Load previously saved metadata from UserDefaults
    static func loadFromUserDefaults() -> HelpBookMetadata? {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            return nil
        }

        let decoder = JSONDecoder()
        return try? decoder.decode(HelpBookMetadata.self, from: data)
    }

    /// Save metadata to UserDefaults
    func saveToUserDefaults() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(self) {
            UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
        }
    }
}
