import Foundation
import SwiftSoup

class AssetPathRewriter {
    func rewritePaths(
        html: String,
        documentPath: String,
        assetMap: [String: String]
    ) throws -> String {
        do {
            let document = try SwiftSoup.parse(html)

            // Rewrite image paths
            let images = try document.select("img[src]")
            for img in images.array() {
                if let src = try? img.attr("src") {
                    if let newPath = resolveAssetPath(src, documentPath: documentPath, assetMap: assetMap) {
                        try img.attr("src", newPath)
                    }
                }
            }

            // Rewrite CSS links
            let links = try document.select("link[href]")
            for link in links.array() {
                if let href = try? link.attr("href") {
                    if let newPath = resolveAssetPath(href, documentPath: documentPath, assetMap: assetMap) {
                        try link.attr("href", newPath)
                    }
                }
            }

            // Rewrite script sources
            let scripts = try document.select("script[src]")
            for script in scripts.array() {
                if let src = try? script.attr("src") {
                    if let newPath = resolveAssetPath(src, documentPath: documentPath, assetMap: assetMap) {
                        try script.attr("src", newPath)
                    }
                }
            }

            return try document.html()
        } catch {
            print("Warning: Failed to rewrite asset paths: \(error)")
            return html
        }
    }

    private func resolveAssetPath(
        _ originalPath: String,
        documentPath: String,
        assetMap: [String: String]
    ) -> String? {
        // Skip absolute URLs
        if originalPath.hasPrefix("http://") || originalPath.hasPrefix("https://") {
            return nil
        }

        // Calculate the document's directory depth
        let docComponents = documentPath.split(separator: "/").dropLast()
        let docDepth = docComponents.count

        // Resolve relative path
        var resolvedPath = originalPath

        // Handle absolute paths starting with / (like /images/foo.png)
        if originalPath.hasPrefix("/") {
            // Remove leading slash and treat as relative to root
            resolvedPath = String(originalPath.dropFirst())
        }
        // Handle ../ navigation
        else if originalPath.contains("../") {
            var pathComponents = originalPath.split(separator: "/")
            var currentDepth = docDepth

            while pathComponents.first == ".." {
                pathComponents.removeFirst()
                currentDepth = max(0, currentDepth - 1)
            }

            resolvedPath = pathComponents.joined(separator: "/")
        } else if originalPath.hasPrefix("./") {
            resolvedPath = String(originalPath.dropFirst(2))
        }

        // Build new path relative to assets folder
        // The depth determines how many ../ we need to go up to reach the root
        let upLevels = String(repeating: "../", count: docDepth)
        return "\(upLevels)assets/\(resolvedPath)"
    }

    func buildAssetMap(_ assets: [AssetReference]) -> [String: String] {
        var map: [String: String] = [:]
        for asset in assets {
            let fileName = URL(fileURLWithPath: asset.relativePath).lastPathComponent
            map[asset.relativePath] = fileName
            map[fileName] = asset.relativePath
        }
        return map
    }
}
