import Foundation

enum ThemeError: Error, LocalizedError {
    case missingCustomCSSPath
    case customCSSLoadFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingCustomCSSPath:
            return "Custom theme requires a CSS file path"
        case .customCSSLoadFailed(let details):
            return "Failed to load custom CSS: \(details)"
        }
    }
}

class ThemeManager {
    /// Returns CSS for the specified theme
    /// - Parameters:
    ///   - theme: The theme to get CSS for
    /// - Returns: CSS string for the theme
    static func css(for theme: HelpBookTheme) -> String {
        switch theme {
        case .modern:
            return modernCSS
        case .mavericks:
            return mavericksCSS
        case .tiger:
            return tigerCSS
        }
    }

    // MARK: - Modern Theme (Current macOS Design)

    private static var modernCSS: String {
        """
        /* HelpAuthor Modern Help Book Stylesheet */

        html, body {
            overflow-x: hidden;
            max-width: 100%;
        }

        * {
            box-sizing: border-box;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
            line-height: 1.6;
            color: #1d1d1f;
            background: #ffffff;
            padding: 0;
            margin: 0;
        }

        img, video, iframe, embed, object {
            max-width: 100%;
            height: auto;
        }

        pre, code {
            max-width: 100%;
            overflow-x: auto;
            word-wrap: break-word;
        }

        table {
            max-width: 100%;
            overflow-x: auto;
            display: block;
        }

        @media (prefers-color-scheme: dark) {
            body {
                color: #f5f5f7;
                background: #1d1d1f;
            }
        }

        /* Sidebar Navigation */
        .help-sidebar {
            position: fixed;
            left: 0;
            top: 0;
            width: 250px;
            height: 100vh;
            overflow-y: auto;
            background: #f5f5f7;
            border-right: 1px solid #d2d2d7;
            padding: 0;
            z-index: 100;
        }

        @media (prefers-color-scheme: dark) {
            .help-sidebar {
                background: #1c1c1e;
                border-right-color: #38383a;
            }
        }

        .sidebar-header {
            padding: 16px;
            border-bottom: 1px solid #d2d2d7;
            background: #ffffff;
        }

        @media (prefers-color-scheme: dark) {
            .sidebar-header {
                background: #2c2c2e;
                border-bottom-color: #38383a;
            }
        }

        .sidebar-header h2 {
            font-size: 16px;
            font-weight: 600;
            margin: 0;
            border: none;
            padding: 0;
        }

        .sidebar-content {
            padding: 8px 0;
        }

        .toc-list {
            list-style: none;
            margin: 0;
            padding: 0;
        }

        .toc-list li {
            margin: 0;
        }

        .toc-section {
            margin: 0;
        }

        .toc-section-header {
            display: flex;
            align-items: center;
            padding: 4px 16px;
        }

        .toc-section-header[onclick] {
            cursor: pointer;
            user-select: none;
        }

        .toc-section-header[onclick]:hover {
            background: rgba(0, 0, 0, 0.05);
        }

        @media (prefers-color-scheme: dark) {
            .toc-section-header[onclick]:hover {
                background: rgba(255, 255, 255, 0.05);
            }
        }

        .disclosure-button {
            color: #6e6e73;
            margin-right: 4px;
            font-size: 10px;
            width: 16px;
            text-align: center;
            pointer-events: none;
        }

        @media (prefers-color-scheme: dark) {
            .disclosure-button {
                color: #8e8e93;
            }
        }

        .disclosure-spacer {
            display: inline-block;
            width: 20px;
        }

        .section-title {
            font-weight: 600;
            font-size: 13px;
            pointer-events: none;
        }

        .toc-section-content {
            display: block;
        }

        .toc-list a {
            display: block;
            padding: 4px 16px 4px 36px;
            font-size: 13px;
            text-decoration: none;
            color: #1d1d1f;
        }

        .toc-list a:hover {
            background: rgba(0, 0, 0, 0.05);
        }

        .toc-list a.current-page {
            background: #0071e3;
            color: #ffffff;
        }

        @media (prefers-color-scheme: dark) {
            .toc-list a {
                color: #f5f5f7;
            }
            .toc-list a:hover {
                background: rgba(255, 255, 255, 0.1);
            }
            .toc-list a.current-page {
                background: #2997ff;
            }
        }

        /* Main content with sidebar */
        .help-main-content {
            margin-left: 250px;
            transition: margin-left 0.3s ease;
        }

        .help-main-content:not(.with-sidebar) {
            margin-left: 0;
        }

        /* Page content padding */
        .page-content {
            padding: 14px 24px 24px 24px;
            max-width: 900px;
            margin: 0 auto;
        }

        /* Remove top margin from first heading in page content */
        .page-content > h1:first-child {
            margin-top: 0;
        }

        /* Breadcrumb Navigation */
        .breadcrumb {
            margin-bottom: 6px;
            padding: 8px 24px;
            border-bottom: 1px solid #d2d2d7;
        }

        @media (prefers-color-scheme: dark) {
            .breadcrumb {
                border-bottom-color: #38383a;
            }
        }

        .breadcrumb ol {
            display: flex;
            flex-wrap: wrap;
            align-items: center;
            list-style: none;
            margin: 0;
            padding: 0;
            font-size: 13px;
        }

        .breadcrumb li {
            display: flex;
            align-items: center;
            margin: 0;
        }

        .breadcrumb li:not(:last-child)::after {
            content: '/';
            margin: 0 8px;
            color: #6e6e73;
        }

        @media (prefers-color-scheme: dark) {
            .breadcrumb li:not(:last-child)::after {
                color: #8e8e93;
            }
        }

        .breadcrumb a {
            color: #0071e3;
            text-decoration: none;
        }

        .breadcrumb a:hover {
            text-decoration: underline;
        }

        @media (prefers-color-scheme: dark) {
            .breadcrumb a {
                color: #2997ff;
            }
        }

        .breadcrumb [aria-current="page"] span {
            color: #1d1d1f;
            font-weight: 500;
        }

        @media (prefers-color-scheme: dark) {
            .breadcrumb [aria-current="page"] span {
                color: #f5f5f7;
            }
        }

        /* Typography */
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

        /* Light mode alert box colors */
        .alert-info {
            background-color: #e3f2fd;
            border-color: #1976d2;
            color: #0d47a1;
        }

        .alert-primary {
            background-color: #e8eaf6;
            border-color: #3f51b5;
            color: #1a237e;
        }

        .alert-warning {
            background-color: #fff3e0;
            border-color: #f57c00;
            color: #e65100;
        }

        .alert-danger {
            background-color: #ffebee;
            border-color: #d32f2f;
            color: #b71c1c;
        }

        .alert-success {
            background-color: #e8f5e9;
            border-color: #388e3c;
            color: #1b5e20;
        }

        .alert-light {
            background-color: #fafafa;
            border-color: #bdbdbd;
            color: #424242;
        }

        .alert-dark {
            background-color: #e0e0e0;
            border-color: #616161;
            color: #212121;
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

    // MARK: - Mavericks Theme (OS X 10.9, 2013-2014)

    private static var mavericksCSS: String {
        """
        /* HelpAuthor Mavericks Help Book Stylesheet (OS X 10.9 Style) */

        html, body {
            overflow-x: hidden;
            max-width: 100%;
        }

        * {
            box-sizing: border-box;
        }

        body {
            font-family: "Lucida Grande", "Helvetica Neue", Helvetica, Arial, sans-serif;
            font-size: 13px;
            line-height: 1.5;
            color: #333333;
            background: #ffffff;
            padding: 0;
            margin: 0;
        }

        img, video, iframe, embed, object {
            max-width: 100%;
            height: auto;
        }

        pre, code {
            max-width: 100%;
            overflow-x: auto;
            word-wrap: break-word;
        }

        table {
            max-width: 100%;
            overflow-x: auto;
            display: block;
        }

        /* Sidebar Navigation */
        .help-sidebar {
            position: fixed;
            left: 0;
            top: 0;
            width: 240px;
            height: 100vh;
            overflow-y: auto;
            background: linear-gradient(to bottom, #f7f7f7 0%, #ebebeb 100%);
            border-right: 1px solid #c0c0c0;
            padding: 0;
            z-index: 100;
            box-shadow: inset -1px 0 0 #fafafa;
        }

        .sidebar-header {
            padding: 12px 14px;
            border-bottom: 1px solid #c0c0c0;
            background: linear-gradient(to bottom, #fdfdfd 0%, #f0f0f0 100%);
            box-shadow: inset 0 1px 0 #ffffff;
        }

        .sidebar-header h2 {
            font-size: 14px;
            font-weight: bold;
            margin: 0;
            border: none;
            padding: 0;
            color: #4a4a4a;
        }

        .sidebar-content {
            padding: 6px 0;
        }

        .toc-list {
            list-style: none;
            margin: 0;
            padding: 0;
        }

        .toc-list li {
            margin: 0;
        }

        .toc-section {
            margin: 0;
        }

        .toc-section-header {
            display: flex;
            align-items: center;
            padding: 3px 12px;
        }

        .toc-section-header[onclick] {
            cursor: pointer;
            user-select: none;
        }

        .toc-section-header[onclick]:hover {
            background: #dae4f0;
        }

        .disclosure-button {
            color: #666666;
            margin-right: 4px;
            font-size: 9px;
            width: 14px;
            text-align: center;
            pointer-events: none;
        }

        .disclosure-spacer {
            display: inline-block;
            width: 18px;
        }

        .section-title {
            font-weight: bold;
            font-size: 12px;
            color: #4a4a4a;
            pointer-events: none;
        }

        .toc-section-content {
            display: block;
        }

        .toc-list a {
            display: block;
            padding: 3px 12px 3px 32px;
            font-size: 12px;
            text-decoration: none;
            color: #333333;
        }

        .toc-list a:hover {
            background: #dae4f0;
        }

        .toc-list a.current-page {
            background: linear-gradient(to bottom, #5e95d6 0%, #4884cf 100%);
            color: #ffffff;
            box-shadow: inset 0 1px 2px rgba(0, 0, 0, 0.2);
        }

        /* Main content with sidebar */
        .help-main-content {
            margin-left: 240px;
            transition: margin-left 0.3s ease;
        }

        .help-main-content:not(.with-sidebar) {
            margin-left: 0;
        }

        /* Page content padding */
        .page-content {
            padding: 12px 20px 20px 20px;
            max-width: 850px;
            margin: 0 auto;
        }

        /* Remove top margin from first heading in page content */
        .page-content > h1:first-child {
            margin-top: 0;
        }

        /* Breadcrumb Navigation */
        .breadcrumb {
            margin-bottom: 4px;
            padding: 6px 20px;
            border-bottom: 1px solid #d5d5d5;
        }

        .breadcrumb ol {
            display: flex;
            flex-wrap: wrap;
            align-items: center;
            list-style: none;
            margin: 0;
            padding: 0;
            font-size: 12px;
        }

        .breadcrumb li {
            display: flex;
            align-items: center;
            margin: 0;
        }

        .breadcrumb li:not(:last-child)::after {
            content: '›';
            margin: 0 6px;
            color: #999999;
        }

        .breadcrumb a {
            color: #0078d5;
            text-decoration: none;
        }

        .breadcrumb a:hover {
            text-decoration: underline;
        }

        .breadcrumb [aria-current="page"] span {
            color: #333333;
            font-weight: bold;
        }

        /* Typography */
        h1, h2, h3, h4, h5, h6 {
            margin-top: 20px;
            margin-bottom: 12px;
            font-weight: bold;
            line-height: 1.3;
            color: #222222;
        }

        h1 {
            font-size: 24px;
            border-bottom: 1px solid #d5d5d5;
            padding-bottom: 6px;
            margin-bottom: 6px;
        }

        .subtitle {
            font-size: 13px;
            color: #666666;
            margin-top: 0;
            margin-bottom: 18px;
            font-weight: normal;
        }

        .section-description {
            font-size: 12px;
            color: #666666;
            margin-top: 0;
            margin-bottom: 10px;
            font-weight: normal;
        }

        h2 {
            font-size: 18px;
            border-bottom: 1px solid #e5e5e5;
            padding-bottom: 4px;
        }

        h3 {
            font-size: 15px;
            margin-bottom: 4px;
        }

        p {
            margin-bottom: 12px;
        }

        a {
            color: #0078d5;
            text-decoration: none;
        }

        a:hover {
            text-decoration: underline;
        }

        code {
            background: #f5f5f5;
            padding: 2px 4px;
            border-radius: 3px;
            border: 1px solid #e0e0e0;
            font-family: Monaco, "Courier New", Courier, monospace;
            font-size: 12px;
        }

        pre {
            background: #f8f8f8;
            padding: 12px;
            border-radius: 4px;
            border: 1px solid #d5d5d5;
            overflow-x: auto;
            margin: 12px 0;
        }

        pre code {
            background: none;
            padding: 0;
            border: none;
        }

        img {
            max-width: 100%;
            height: auto;
            display: block;
            margin: 12px 0;
            border: 1px solid #d5d5d5;
        }

        blockquote {
            border-left: 3px solid #d5d5d5;
            padding-left: 12px;
            color: #666666;
            margin: 12px 0;
            font-style: italic;
        }

        table {
            border-collapse: collapse;
            width: 100%;
            margin: 12px 0;
        }

        th, td {
            border: 1px solid #d5d5d5;
            padding: 6px 10px;
            text-align: left;
        }

        th {
            background: linear-gradient(to bottom, #f7f7f7 0%, #e5e5e5 100%);
            font-weight: bold;
        }

        ul, ol {
            margin: 12px 0;
            padding-left: 28px;
        }

        li {
            margin-bottom: 6px;
        }

        hr {
            border: none;
            border-top: 1px solid #d5d5d5;
            margin: 20px 0;
        }

        /* Alert boxes */
        .alert {
            display: flex;
            align-items: flex-start;
            padding: 10px 12px;
            margin: 12px 0;
            border-radius: 4px;
            border: 1px solid;
        }

        .alert > span:first-child {
            font-size: 1.1em;
            margin-right: 6px;
            flex-shrink: 0;
        }

        .alert-info {
            background-color: #e8f4fd;
            border-color: #a8d4f5;
            color: #2c5f88;
        }

        .alert-primary {
            background-color: #e0e8f5;
            border-color: #9eb8dc;
            color: #2c4a7a;
        }

        .alert-warning {
            background-color: #fffbeb;
            border-color: #f9e8a8;
            color: #8a6d3b;
        }

        .alert-danger {
            background-color: #fef0f0;
            border-color: #f5b5b5;
            color: #a94442;
        }

        .alert-success {
            background-color: #f0faf0;
            border-color: #b5e5b5;
            color: #3c763d;
        }

        .alert-light {
            background-color: #f8f8f8;
            border-color: #d5d5d5;
            color: #555555;
        }

        .alert-dark {
            background-color: #e8e8e8;
            border-color: #b0b0b0;
            color: #333333;
        }

        /* Dark Mode Support */
        @media (prefers-color-scheme: dark) {
            body {
                color: #e0e0e0;
                background: #1e1e1e;
            }

            .help-sidebar {
                background: linear-gradient(to bottom, #2a2a2a 0%, #1f1f1f 100%);
                border-right: 1px solid #0a0a0a;
                box-shadow: inset -1px 0 0 #3a3a3a;
            }

            .sidebar-header {
                border-bottom: 1px solid #0a0a0a;
                background: linear-gradient(to bottom, #323232 0%, #242424 100%);
                box-shadow: inset 0 1px 0 #3d3d3d;
            }

            .sidebar-header h2 {
                color: #c0c0c0;
            }

            .section-title {
                color: #c0c0c0;
            }

            .toc-section-header[onclick]:hover {
                background: #3a4a5a;
            }

            .disclosure-button {
                color: #999999;
            }

            .toc-list a {
                color: #e0e0e0;
            }

            .toc-list a:hover {
                background: #3a4a5a;
            }

            .toc-list a.current-page {
                background: linear-gradient(to bottom, #4a7ab6 0%, #39699f 100%);
                color: #ffffff;
            }

            .breadcrumb {
                border-bottom: 1px solid #3a3a3a;
            }

            .breadcrumb a {
                color: #5a9fd5;
            }

            .breadcrumb [aria-current="page"] span {
                color: #e0e0e0;
            }

            h1, h2, h3, h4, h5, h6 {
                color: #d0d0d0;
            }

            h1 {
                border-bottom: 1px solid #3a3a3a;
            }

            h2 {
                border-bottom: 1px solid #2a2a2a;
            }

            .subtitle, .section-description {
                color: #999999;
            }

            a {
                color: #5a9fd5;
            }

            code {
                background: #2a2a2a;
                border: 1px solid #3a3a3a;
            }

            pre {
                background: #242424;
                border: 1px solid #3a3a3a;
            }

            img {
                border: 1px solid #3a3a3a;
            }

            blockquote {
                border-left: 3px solid #3a3a3a;
                color: #999999;
            }

            th, td {
                border: 1px solid #3a3a3a;
            }

            th {
                background: linear-gradient(to bottom, #2a2a2a 0%, #1f1f1f 100%);
            }

            hr {
                border-top: 1px solid #3a3a3a;
            }

            .alert-info {
                background-color: #1a2a3a !important;
                border-color: #2a4a5a !important;
                color: #a0c0d0 !important;
            }

            .alert-primary {
                background-color: #1a1a3a !important;
                border-color: #2a2a5a !important;
                color: #a0a0d0 !important;
            }

            .alert-warning {
                background-color: #3a2a1a !important;
                border-color: #5a4a2a !important;
                color: #d0c0a0 !important;
            }

            .alert-danger {
                background-color: #3a1a1a !important;
                border-color: #5a2a2a !important;
                color: #d0a0a0 !important;
            }

            .alert-success {
                background-color: #1a3a1a !important;
                border-color: #2a5a2a !important;
                color: #a0d0a0 !important;
            }

            .alert-light {
                background-color: #2a2a2a !important;
                border-color: #3a3a3a !important;
                color: #c0c0c0 !important;
            }

            .alert-dark {
                background-color: #1a1a1a !important;
                border-color: #2a2a2a !important;
                color: #d0d0d0 !important;
            }
        }
        """
    }

    // MARK: - Tiger Theme (OS X 10.4, 2005-2007)

    private static var tigerCSS: String {
        """
        /* HelpAuthor Tiger Help Book Stylesheet (OS X 10.4 Style) */

        html, body {
            overflow-x: hidden;
            max-width: 100%;
        }

        * {
            box-sizing: border-box;
        }

        body {
            font-family: Geneva, "Lucida Grande", Helvetica, Arial, sans-serif;
            font-size: 12px;
            line-height: 1.4;
            color: #000000;
            background: #ffffff;
            padding: 0;
            margin: 0;
        }

        img, video, iframe, embed, object {
            max-width: 100%;
            height: auto;
        }

        pre, code {
            max-width: 100%;
            overflow-x: auto;
            word-wrap: break-word;
        }

        table {
            max-width: 100%;
            overflow-x: auto;
            display: block;
        }

        /* Sidebar Navigation */
        .help-sidebar {
            position: fixed;
            left: 0;
            top: 0;
            width: 220px;
            height: 100vh;
            overflow-y: auto;
            background: #e8e8e8 url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="2" height="2"><rect fill="%23e0e0e0" width="1" height="1"/><rect fill="%23ececec" width="1" height="1" x="1"/><rect fill="%23ececec" width="1" height="1" y="1"/><rect fill="%23e0e0e0" width="1" height="1" x="1" y="1"/></svg>');
            border-right: 2px solid #999999;
            padding: 0;
            z-index: 100;
        }

        .sidebar-header {
            padding: 10px 12px;
            border-bottom: 2px solid #999999;
            background: linear-gradient(to bottom, #f0f0f0 0%, #d8d8d8 100%);
            box-shadow: inset 0 1px 0 #fefefe, inset 0 -1px 0 #b0b0b0;
        }

        .sidebar-header h2 {
            font-size: 13px;
            font-weight: bold;
            margin: 0;
            border: none;
            padding: 0;
            color: #333333;
            text-shadow: 0 1px 0 #ffffff;
        }

        .sidebar-content {
            padding: 4px 0;
        }

        .toc-list {
            list-style: none;
            margin: 0;
            padding: 0;
        }

        .toc-list li {
            margin: 0;
        }

        .toc-section {
            margin: 0;
        }

        .toc-section-header {
            display: flex;
            align-items: center;
            padding: 2px 10px;
        }

        .toc-section-header[onclick] {
            cursor: pointer;
            user-select: none;
        }

        .toc-section-header[onclick]:hover {
            background: #e0e0e0;
        }

        .disclosure-button {
            color: #555555;
            margin-right: 3px;
            font-size: 8px;
            width: 12px;
            text-align: center;
            pointer-events: none;
        }

        .disclosure-spacer {
            display: inline-block;
            width: 15px;
        }

        .section-title {
            font-weight: bold;
            font-size: 11px;
            color: #333333;
            pointer-events: none;
        }

        .toc-section-content {
            display: block;
        }

        .toc-list a {
            display: block;
            padding: 2px 10px 2px 28px;
            font-size: 11px;
            text-decoration: none;
            color: #000000;
        }

        .toc-list a:hover {
            background: linear-gradient(to bottom, #d0e0f0 0%, #b8cfe8 100%);
        }

        .toc-list a.current-page {
            background: linear-gradient(to bottom, #4a8fd8 0%, #3878c0 50%, #2860a8 51%, #1858a0 100%);
            color: #ffffff;
            text-shadow: 0 -1px 0 rgba(0, 0, 0, 0.4);
            box-shadow: inset 0 1px 3px rgba(0, 0, 0, 0.3);
        }

        /* Main content with sidebar */
        .help-main-content {
            margin-left: 220px;
            transition: margin-left 0.3s ease;
        }

        .help-main-content:not(.with-sidebar) {
            margin-left: 0;
        }

        /* Page content padding */
        .page-content {
            padding: 10px 18px 18px 18px;
            max-width: 800px;
            margin: 0 auto;
        }

        /* Remove top margin from first heading in page content */
        .page-content > h1:first-child {
            margin-top: 0;
        }

        /* Breadcrumb Navigation */
        .breadcrumb {
            margin-bottom: 4px;
            padding: 5px 18px;
            border-bottom: 2px solid #cccccc;
        }

        .breadcrumb ol {
            display: flex;
            flex-wrap: wrap;
            align-items: center;
            list-style: none;
            margin: 0;
            padding: 0;
            font-size: 11px;
        }

        .breadcrumb li {
            display: flex;
            align-items: center;
            margin: 0;
        }

        .breadcrumb li:not(:last-child)::after {
            content: '▸';
            margin: 0 5px;
            color: #888888;
        }

        .breadcrumb a {
            color: #0000ee;
            text-decoration: underline;
        }

        .breadcrumb a:hover {
            color: #0000cc;
        }

        .breadcrumb [aria-current="page"] span {
            color: #000000;
            font-weight: bold;
        }

        /* Typography */
        h1, h2, h3, h4, h5, h6 {
            margin-top: 18px;
            margin-bottom: 10px;
            font-weight: bold;
            line-height: 1.2;
            color: #000000;
        }

        h1 {
            font-size: 20px;
            border-bottom: 2px solid #cccccc;
            padding-bottom: 4px;
            margin-bottom: 4px;
        }

        .subtitle {
            font-size: 12px;
            color: #555555;
            margin-top: 0;
            margin-bottom: 16px;
            font-weight: normal;
        }

        .section-description {
            font-size: 11px;
            color: #555555;
            margin-top: 0;
            margin-bottom: 8px;
            font-weight: normal;
        }

        h2 {
            font-size: 16px;
            border-bottom: 1px solid #dddddd;
            padding-bottom: 3px;
        }

        h3 {
            font-size: 14px;
            margin-bottom: 4px;
        }

        p {
            margin-bottom: 10px;
        }

        a {
            color: #0000ee;
            text-decoration: underline;
        }

        a:hover {
            color: #0000cc;
        }

        code {
            background: #f0f0f0;
            padding: 1px 3px;
            border: 1px solid #d0d0d0;
            font-family: Monaco, "Courier New", Courier, monospace;
            font-size: 11px;
        }

        pre {
            background: #f8f8f8;
            padding: 10px;
            border: 2px solid #cccccc;
            overflow-x: auto;
            margin: 10px 0;
        }

        pre code {
            background: none;
            padding: 0;
            border: none;
        }

        img {
            max-width: 100%;
            height: auto;
            display: block;
            margin: 10px 0;
            border: 1px solid #cccccc;
        }

        blockquote {
            border-left: 4px solid #cccccc;
            padding-left: 10px;
            color: #555555;
            margin: 10px 0;
            font-style: italic;
        }

        table {
            border-collapse: collapse;
            width: 100%;
            margin: 10px 0;
            border: 2px solid #999999;
        }

        th, td {
            border: 1px solid #cccccc;
            padding: 5px 8px;
            text-align: left;
        }

        th {
            background: linear-gradient(to bottom, #e8e8e8 0%, #d0d0d0 100%);
            font-weight: bold;
            border-bottom: 2px solid #999999;
        }

        ul, ol {
            margin: 10px 0;
            padding-left: 24px;
        }

        li {
            margin-bottom: 5px;
        }

        hr {
            border: none;
            border-top: 2px solid #cccccc;
            margin: 16px 0;
        }

        /* Alert boxes */
        .alert {
            display: flex;
            align-items: flex-start;
            padding: 8px 10px;
            margin: 10px 0;
            border: 2px solid;
        }

        .alert > span:first-child {
            font-size: 1.0em;
            margin-right: 5px;
            flex-shrink: 0;
        }

        .alert-info {
            background-color: #e0f0ff;
            border-color: #6699cc;
            color: #003366;
        }

        .alert-primary {
            background-color: #e0e8f0;
            border-color: #6688aa;
            color: #223344;
        }

        .alert-warning {
            background-color: #fff8e0;
            border-color: #cc9933;
            color: #664400;
        }

        .alert-danger {
            background-color: #ffe8e8;
            border-color: #cc6666;
            color: #660000;
        }

        .alert-success {
            background-color: #e8f8e8;
            border-color: #66cc66;
            color: #006600;
        }

        .alert-light {
            background-color: #f8f8f8;
            border-color: #cccccc;
            color: #444444;
        }

        .alert-dark {
            background-color: #e0e0e0;
            border-color: #999999;
            color: #222222;
        }

        /* Dark Mode Support */
        @media (prefers-color-scheme: dark) {
            body {
                color: #d0d0d0;
                background: #1a1a1a;
            }

            .help-sidebar {
                background: #252525 url('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAQAAAAECAYAAACp8Z5+AAAAGElEQVQIW2NkYGD4z8DAwMgABXAGNgGAAA8ABAECAwCq3QAAAABJRU5ErkJggg==') repeat;
                border-right: 1px solid #000000;
            }

            .sidebar-header {
                padding: 10px 12px;
                border-bottom: 2px solid #000000;
                background: #303030;
            }

            .sidebar-header h2 {
                color: #b0b0b0;
            }

            .section-title {
                color: #b0b0b0;
            }

            .toc-section-header[onclick]:hover {
                background: #3a3a3a;
            }

            .disclosure-button {
                color: #888888;
            }

            .toc-list a {
                color: #d0d0d0;
            }

            .toc-list a:hover {
                background: #3a3a3a;
                color: #ffffff;
            }

            .toc-list a.current-page {
                background: #4a4a9a;
                color: #ffffff;
            }

            .breadcrumb {
                border-bottom: 2px solid #3a3a3a;
            }

            .breadcrumb a {
                color: #6a6aff;
            }

            .breadcrumb [aria-current="page"] span {
                color: #d0d0d0;
            }

            h1, h2, h3, h4, h5, h6 {
                color: #d0d0d0;
            }

            h1 {
                border-bottom: 2px solid #3a3a3a;
            }

            h2 {
                border-bottom: 1px solid #3a3a3a;
            }

            h3 {
                border-bottom: 1px solid #2a2a2a;
            }

            .subtitle, .section-description {
                color: #999999;
            }

            a {
                color: #6a6aff;
            }

            a:hover {
                color: #8a8aff;
            }

            code {
                background: #2a2a2a;
                border: 1px solid #3a3a3a;
            }

            pre {
                background: #222222;
                border: 1px solid #3a3a3a;
            }

            img {
                border: 1px solid #3a3a3a;
            }

            blockquote {
                border-left: 3px solid #3a3a3a;
                color: #999999;
            }

            th, td {
                border: 1px solid #3a3a3a;
            }

            th {
                background: #2a2a2a;
            }

            hr {
                border-top: 2px solid #3a3a3a;
            }

            .alert-info {
                background-color: #1a2a3a !important;
                border-color: #3366aa !important;
                color: #99aacc !important;
            }

            .alert-primary {
                background-color: #1a1a3a !important;
                border-color: #3333aa !important;
                color: #9999cc !important;
            }

            .alert-warning {
                background-color: #3a3a1a !important;
                border-color: #aaaa33 !important;
                color: #cccc99 !important;
            }

            .alert-danger {
                background-color: #3a1a1a !important;
                border-color: #aa3333 !important;
                color: #cc9999 !important;
            }

            .alert-success {
                background-color: #1a3a1a !important;
                border-color: #33aa33 !important;
                color: #99cc99 !important;
            }

            .alert-light {
                background-color: #2a2a2a !important;
                border-color: #3a3a3a !important;
                color: #b0b0b0 !important;
            }

            .alert-dark {
                background-color: #1a1a1a !important;
                border-color: #2a2a2a !important;
                color: #d0d0d0 !important;
            }
        }
        """
    }
}
