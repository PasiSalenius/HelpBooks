# HelpBooks

A command-line tool for creating Apple Help Books from [Hugo](https://gohugo.io/) documentation. Transform your Hugo-based documentation into native macOS Help Books.

## Features

- Hugo-compatible frontmatter format and content structure
- Extensible architecture for adding support for other SSGs (Jekyll, Eleventy, etc.)
- Supports content organization with `_index.md` files for sections
- Automatically generates search indexes for macOS Help Viewer
- Weight-based ordering for pages and sections
- Multiple themes: Modern, Mavericks, or Tiger styling
- Custom CSS support for full styling control
- Lotus Docs alert box shortcode support

## Screenshot

![Exported Help Book](screenshot-export.png)

## Installation

### Requirements

- macOS 13.0 or later
- Xcode Command Line Tools (for building from source)

### Building from Source

```bash
git clone https://github.com/yourusername/HelpBooks.git
cd HelpBooks
swift build -c release
```

The built executable will be at `.build/release/helpbooks`.

### Installing

Copy the executable to a directory in your PATH:

```bash
cp .build/release/helpbooks /usr/local/bin/
```

## Usage

### Quick Start

```bash
# Create a configuration file interactively
helpbooks config

# Generate the Help Book
helpbooks generate
```

### Commands

```
USAGE: helpbooks <command> [options]

COMMANDS:
  config              Create a configuration file interactively
  generate            Generate Help Book from configuration
  help                Show help message
  version             Show version information

GENERATE OPTIONS:
  -c, --config <path>     Path to config file (default: helpbooks.json)
  --content <path>        Override content folder path
  --assets <path>         Override assets folder path
  --custom-css <path>     Override with custom CSS file (replaces theme)
  -o, --output <path>     Override output folder path
```

### Configuration File

The `helpbooks.json` configuration file supports the following fields:

```json
{
  "bundleIdentifier": "com.company.myapp.help",
  "bundleName": "MyApp",
  "helpBookTitle": "MyApp Help",
  "contentPath": "./content",
  "assetsPath": "./assets",
  "outputPath": "./build",
  "theme": "Modern"
}
```

**Fields:**

- `bundleIdentifier` - Unique bundle identifier (should match your app's Info.plist)
- `bundleName` - Name of the help bundle
- `helpBookTitle` - Title shown in the sidebar header
- `contentPath` - Path to folder containing Markdown files
- `assetsPath` - Path to folder containing images and other assets (optional)
- `outputPath` - Path where the `.help` bundle will be generated
- `theme` - Visual theme: `Modern`, `Mavericks`, `Tiger`, or `Custom`
- `customCssPath` - Path to custom CSS file (when theme is `Custom`)
- `baseURL` - Base URL for automatic link conversion (optional). Links starting with this URL are converted to relative paths. Example: `https://example.com/docs`

## Content Structure

HelpBooks expects Hugo-style content organization:

```
content/
├── _index.md          # Optional: root metadata
├── getting-started/
│   ├── _index.md      # Section metadata (title, description, weight)
│   ├── installation.md
│   └── quick-start.md
├── guides/
│   ├── _index.md
│   ├── basic-usage.md
│   └── advanced-features.md
└── overview.md
```

### Frontmatter

Each Markdown file should include YAML frontmatter:

```yaml
---
weight: 100
title: "Getting Started"
description: "Learn the basics of using the app."
keywords: ["tutorial", "guide", "basics"]
---

# Getting Started

Your content here...
```

**Fields:**

- `title` - Page or section title (required)
- `description` - Brief description shown as subtitle
- `weight` - Sort order (lower numbers appear first)
- `keywords` - Array of keywords for search indexing
- `draft` - Set to `true` to exclude from export

### Section Metadata

Use `_index.md` files to define metadata for sections:

```yaml
---
weight: 100
title: "User Guide"
description: "Complete guide to using the application."
---
```

### Alert Boxes

Lotus Docs style alert boxes are supported:

```markdown
{{< alert icon="i" context="info" text="This is an informational alert." />}}
{{< alert icon="!" context="warning" text="This is a warning message." />}}
```

Supported contexts: `info`, `primary`, `warning`, `danger`, `success`, `light`, `dark`

## Themes

Three built-in themes are available:

- **Modern** - Contemporary macOS design with San Francisco font
- **Mavericks** - OS X 10.9 era styling with Lucida Grande
- **Tiger** - Classic Aqua-inspired interface

All themes support light and dark mode.

### Custom CSS

Provide your own CSS for full styling control:

```bash
helpbooks generate --custom-css ./my-styles.css
```

Or in the configuration file:

```json
{
  "theme": "Custom",
  "customCssPath": "./my-styles.css"
}
```

## Integration with Your macOS App

After generating your Help Book:

1. **Add to Xcode Project**
   - Drag the `.help` bundle into your Xcode project
   - Ensure it's added to "Copy Bundle Resources"

2. **Update Info.plist**

   ```xml
   <key>CFBundleHelpBookFolder</key>
   <string>YourApp.help</string>
   <key>CFBundleHelpBookName</key>
   <string>com.yourcompany.yourapp.help</string>
   ```

3. **Build and Run** - Your help book will appear in the Help menu

## Extending for Other Static Site Generators

HelpBooks uses a `ContentProvider` protocol to abstract SSG-specific processing. Currently, Hugo is supported, but the architecture allows adding support for other SSGs like Jekyll, Eleventy, or others.

### Project Structure

```
Sources/
├── HelpBooksCLI/              # Command-line interface
└── HelpBooksCore/
    ├── ContentProviders/      # SSG-specific implementations
    │   ├── ContentProvider.swift      # Protocol definition
    │   └── HugoContentProvider.swift  # Hugo implementation
    ├── Models/                # Data structures
    └── Services/              # Shared services
        ├── FileSystem/        # File import
        ├── MarkdownProcessor/ # Markdown parsing
        └── HelpBookGenerator/ # Help Book generation
```

### Adding a New Content Provider

To add support for a new SSG (e.g., Jekyll):

1. Create a new file `Sources/HelpBooksCore/ContentProviders/JekyllContentProvider.swift`

2. Implement the `ContentProvider` protocol:

```swift
public class JekyllContentProvider: ContentProvider {
    public var identifier: String { "jekyll" }
    public var displayName: String { "Jekyll" }
    public var directoryMetadataFileName: String? { "index.md" }
    public var skipsUnderscoreFiles: Bool { false }

    public func scanDocuments(...) async throws -> [MarkdownDocument] {
        // Jekyll-specific document scanning
    }

    public func scanDirectoryMetadata(at url: URL) -> [String: DirectoryMetadata] {
        // Jekyll-specific metadata extraction
    }

    public func processShortcodes(_ content: String) -> String {
        // Process Jekyll/Liquid includes: {% include ... %}
    }

    public func buildFileTree(...) -> FileTreeNode {
        // Jekyll-specific file organization
    }
}
```

3. Register the provider in `ContentProviderRegistry`:

```swift
// In ContentProvider.swift, update the init:
private init() {
    register(HugoContentProvider())
    register(JekyllContentProvider())
}
```

### Key Differences Between SSGs

| Feature | Hugo | Jekyll |
|---------|------|--------|
| Section metadata | `_index.md` | `index.md` or frontmatter |
| Shortcode syntax | `{{< name >}}` | `{% include %}` |
| Weight ordering | `weight` frontmatter | Custom or alphabetical |
| Underscore files | Skipped (metadata) | Often used (`_includes/`) |

## License

MIT License - See LICENSE file for details.

## Resources

- [Apple Help Programming Guide](https://developer.apple.com/library/archive/documentation/Carbon/Conceptual/ProvidingUserAssitAppleHelp/)
- [Hugo Documentation](https://gohugo.io/documentation/)
- [Lotus Docs Theme](https://lotusdocs.dev/)
