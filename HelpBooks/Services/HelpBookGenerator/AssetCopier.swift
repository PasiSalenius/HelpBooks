import Foundation

enum AssetCopierError: Error, LocalizedError {
    case copyFailed(String)
    case missingDefaultCSS

    var errorDescription: String? {
        switch self {
        case .copyFailed(let details):
            return "Failed to copy asset: \(details)"
        case .missingDefaultCSS:
            return "Default CSS stylesheet is missing."
        }
    }
}

class AssetCopier {
    func copyAssets(
        _ assets: [AssetReference],
        to bundleURL: URL,
        progress: ((Double, String) -> Void)? = nil
    ) throws {
        let assetsURL = bundleURL
            .appendingPathComponent("Contents/Resources/assets")

        let fm = FileManager.default
        let total = Double(assets.count)

        for (index, asset) in assets.enumerated() {
            let fileName = URL(fileURLWithPath: asset.relativePath).lastPathComponent
            let destURL = assetsURL.appendingPathComponent(fileName)

            do {
                // Create parent directory if needed
                let parentURL = destURL.deletingLastPathComponent()
                if !fm.fileExists(atPath: parentURL.path) {
                    try fm.createDirectory(at: parentURL, withIntermediateDirectories: true)
                }

                // Copy file (remove existing if present)
                if fm.fileExists(atPath: destURL.path) {
                    try fm.removeItem(at: destURL)
                }
                try fm.copyItem(at: asset.originalPath, to: destURL)

                progress?(Double(index + 1) / total, asset.relativePath)
            } catch {
                throw AssetCopierError.copyFailed("Failed to copy \(asset.relativePath): \(error.localizedDescription)")
            }
        }
    }

    func copyDefaultStylesheet(
        to bundleURL: URL,
        theme: HelpBookTheme
    ) throws {
        let destURL = bundleURL
            .appendingPathComponent("Contents/Resources/assets/style.css")

        // Get CSS from ThemeManager based on selected theme
        let css = ThemeManager.css(for: theme)
        try css.write(to: destURL, atomically: true, encoding: String.Encoding.utf8)
    }

    static var defaultHelpBookCSS: String {
        """
        /* HelpAuthor Default Help Book Stylesheet */

        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
            line-height: 1.6;
            color: #1d1d1f;
            background: #ffffff;
            padding: 24px;
            max-width: 900px;
            margin: 0 auto;
        }

        @media (prefers-color-scheme: dark) {
            body {
                color: #f5f5f7;
                background: #1d1d1f;
            }
        }

        h1, h2, h3, h4, h5, h6 {
            margin-top: 24px;
            margin-bottom: 16px;
            font-weight: 600;
            line-height: 1.25;
        }

        h1 {
            font-size: 2em;
            border-bottom: 1px solid #d2d2d7;
            padding-bottom: 8px;
            margin-bottom: 8px;
        }

        .subtitle {
            font-size: 15px;
            color: rgba(0, 0, 0, 0.6);
            margin-top: 0;
            margin-bottom: 24px;
            font-weight: 400;
        }

        @media (prefers-color-scheme: dark) {
            .subtitle {
                color: rgba(255, 255, 255, 0.6);
            }
        }

        .section-description {
            font-size: 14px;
            color: rgba(0, 0, 0, 0.6);
            margin-top: 0;
            margin-bottom: 12px;
            font-weight: 400;
        }

        @media (prefers-color-scheme: dark) {
            .section-description {
                color: rgba(255, 255, 255, 0.6);
            }
        }

        h2 {
            font-size: 1.5em;
            border-bottom: 1px solid #d2d2d7;
            padding-bottom: 8px;
        }

        h3 {
            font-size: 1.25em;
            margin-bottom: 4px;
        }

        p {
            margin-bottom: 16px;
        }

        a {
            color: #0071e3;
            text-decoration: none;
        }

        a:hover {
            text-decoration: underline;
        }

        @media (prefers-color-scheme: dark) {
            a {
                color: #2997ff;
            }
        }

        code {
            background: #f5f5f7;
            padding: 2px 6px;
            border-radius: 4px;
            font-family: "SF Mono", Monaco, "Courier New", Courier, monospace;
            font-size: 0.9em;
        }

        @media (prefers-color-scheme: dark) {
            code {
                background: #2d2d2d;
            }
        }

        pre {
            background: #f5f5f7;
            padding: 16px;
            border-radius: 8px;
            overflow-x: auto;
            margin: 16px 0;
        }

        @media (prefers-color-scheme: dark) {
            pre {
                background: #2d2d2d;
            }
        }

        pre code {
            background: none;
            padding: 0;
        }

        img {
            max-width: 100%;
            height: auto;
            display: block;
            margin: 16px 0;
        }

        blockquote {
            border-left: 4px solid #d2d2d7;
            padding-left: 16px;
            color: #6e6e73;
            margin: 16px 0;
        }

        @media (prefers-color-scheme: dark) {
            blockquote {
                border-left-color: #424245;
                color: #a1a1a6;
            }
        }

        table {
            border-collapse: collapse;
            width: 100%;
            margin: 16px 0;
        }

        th, td {
            border: 1px solid #d2d2d7;
            padding: 8px 12px;
            text-align: left;
        }

        @media (prefers-color-scheme: dark) {
            th, td {
                border-color: #424245;
            }
        }

        th {
            background: #f5f5f7;
            font-weight: 600;
        }

        @media (prefers-color-scheme: dark) {
            th {
                background: #2d2d2d;
            }
        }

        ul, ol {
            margin: 16px 0;
            padding-left: 32px;
        }

        li {
            margin-bottom: 8px;
        }

        hr {
            border: none;
            border-top: 1px solid #d2d2d7;
            margin: 24px 0;
        }

        @media (prefers-color-scheme: dark) {
            hr {
                border-top-color: #424245;
            }
        }

        /* Alert boxes */
        .alert {
            display: flex;
            align-items: flex-start;
            padding: 12px 16px;
            margin: 16px 0;
            border-radius: 6px;
            border-left: 4px solid;
        }

        .alert > span:first-child {
            font-size: 1.2em;
            margin-right: 8px;
            flex-shrink: 0;
        }

        /* Dark mode alert box colors */
        @media (prefers-color-scheme: dark) {
            .alert-info {
                background-color: #1a3a4a !important;
                border-color: #2a5a6a !important;
                color: #e6e6e6 !important;
            }

            .alert-primary {
                background-color: #1a2a4a !important;
                border-color: #2a4a7a !important;
                color: #e6e6e6 !important;
            }

            .alert-warning {
                background-color: #4a3a1a !important;
                border-color: #6a5a2a !important;
                color: #e6e6e6 !important;
            }

            .alert-danger {
                background-color: #4a1a1a !important;
                border-color: #6a2a2a !important;
                color: #e6e6e6 !important;
            }

            .alert-success {
                background-color: #1a4a2a !important;
                border-color: #2a6a3a !important;
                color: #e6e6e6 !important;
            }

            .alert-light {
                background-color: #2a2a2a !important;
                border-color: #3a3a3a !important;
                color: #e6e6e6 !important;
            }

            .alert-dark {
                background-color: #1a1a1a !important;
                border-color: #2a2a2a !important;
                color: #e6e6e6 !important;
            }
        }
        """
    }
}
