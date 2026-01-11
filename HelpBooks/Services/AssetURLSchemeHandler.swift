import Foundation
import WebKit

/// Custom URL scheme handler for loading assets in WKWebView preview
/// This allows the preview to load images from their actual filesystem locations
/// regardless of where they're stored relative to the markdown files
class AssetURLSchemeHandler: NSObject, WKURLSchemeHandler {
    private let assets: [AssetReference]

    init(assets: [AssetReference]) {
        self.assets = assets
        super.init()
    }

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else {
            urlSchemeTask.didFailWithError(NSError(domain: "AssetURLSchemeHandler", code: -1))
            return
        }

        // Extract the path from the URL (e.g., "asset://images/foo.webp" -> "images/foo.webp")
        let path = url.path

        // Find the asset by matching the end of the relativePath or originalPath
        if let asset = findAsset(forPath: path) {
            loadAsset(asset, for: urlSchemeTask)
        } else {
            print("⚠️ Asset not found: \(path)")
            urlSchemeTask.didFailWithError(NSError(
                domain: "AssetURLSchemeHandler",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Asset not found: \(path)"]
            ))
        }
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        // Nothing to do here
    }

    private func findAsset(forPath path: String) -> AssetReference? {
        // Remove leading slash if present
        let cleanPath = path.hasPrefix("/") ? String(path.dropFirst()) : path

        // Try to find by relative path
        if let asset = assets.first(where: { $0.relativePath == cleanPath }) {
            return asset
        }

        // Try to find by filename
        let filename = (cleanPath as NSString).lastPathComponent
        if let asset = assets.first(where: { $0.fileName == filename }) {
            return asset
        }

        // Try to find by matching end of path
        if let asset = assets.first(where: { $0.relativePath.hasSuffix(cleanPath) }) {
            return asset
        }

        return nil
    }

    private func loadAsset(_ asset: AssetReference, for task: WKURLSchemeTask) {
        do {
            let data = try Data(contentsOf: asset.originalPath)

            // Determine MIME type from file extension
            let mimeType = mimeType(for: asset.originalPath.pathExtension)

            // Create response
            let response = URLResponse(
                url: task.request.url!,
                mimeType: mimeType,
                expectedContentLength: data.count,
                textEncodingName: nil
            )

            task.didReceive(response)
            task.didReceive(data)
            task.didFinish()
        } catch {
            print("⚠️ Failed to load asset \(asset.fileName): \(error)")
            task.didFailWithError(error)
        }
    }

    private func mimeType(for pathExtension: String) -> String {
        switch pathExtension.lowercased() {
        case "webp": return "image/webp"
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "gif": return "image/gif"
        case "svg": return "image/svg+xml"
        case "css": return "text/css"
        case "js": return "application/javascript"
        default: return "application/octet-stream"
        }
    }
}
