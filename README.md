# HelpBooks

A native macOS application and command-line tool for creating Apple Help Books from [Lotus Docs](https://lotusdocs.dev/) content. Transform your Lotus Docs documentation into native macOS Help Books with a modern, SwiftUI-based interface.

## Features

- 📝 **Lotus Docs Compatible** - Designed specifically for Lotus Docs content structure and features
- 🎨 **Live Preview** - See your help content rendered in real-time with full dark mode support
- 📁 **Hugo-style Organization** - Supports content organization with `_index.md` files for sections
- 🔍 **Search Integration** - Automatically generates search indexes for macOS Help Viewer
- 🎯 **Weight-based Ordering** - Control the order of pages and sections using frontmatter weights
- 🖼️ **Asset Management** - Import and manage images, CSS, and other assets
- 🚀 **Export Ready** - Generates complete `.help` bundles ready to add to your Xcode project
- 🌓 **Dark Mode Support** - Full support for macOS light and dark appearances
- ⚡ **Lotus Docs Shortcodes** - Full support for Lotus Docs alert boxes and other shortcodes

## Installation

### Requirements

- macOS 14.0 or later
- Xcode 15 or later (for building from source)

### Building from Source

```bash
git clone https://github.com/yourusername/HelpBooks.git
cd HelpBooks
swift build -c release
```

The built application will be in `.build/release/HelpBooks`.

## Usage

### HelpBooks GUI App

1. **Import Content**
   - Launch the HelpBooks app
   - Drag and drop your content folder (containing `.md` files)
   - Optionally add an assets folder with images and other resources

2. **Preview & Edit**
   - Browse your content in the sidebar
   - Preview pages with live rendering
   - Edit metadata in the Metadata Editor

3. **Export**
   - Click "Export Help Book"
   - Choose an output location
   - The app generates a complete `.help` bundle

### Content Structure

HelpBooks expects your content to follow this structure:

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

**Frontmatter Fields:**

- `title` - Page or section title (required)
- `description` - Brief description shown as subtitle
- `weight` - Sort order (lower numbers appear first)
- `keywords` - Array of keywords for search indexing
- `draft` - Set to `true` to exclude from export

### Section Metadata (_index.md)

Use `_index.md` files to define metadata for folders/sections:

```yaml
---
weight: 100
title: "User Guide"
description: "Complete guide to using the application."
---
```

Files starting with underscore are not included as separate pages, only their metadata is used.

### Shortcodes

HelpBooks supports alert boxes using shortcode syntax:

```markdown
{{< alert icon="ℹ️" context="info" text="This is an informational alert." />}}

{{< alert icon="⚠️" context="warning" text="This is a warning message." />}}
```

**Supported contexts:** `info`, `primary`, `warning`, `danger`, `success`, `light`, `dark`

## Integration with Your macOS App

After exporting your Help Book:

1. **Add to Xcode Project**
   - Drag the `.help` bundle into your Xcode project
   - Make sure it's added to "Copy Bundle Resources"

2. **Update Info.plist**

   Add these keys to your app's `Info.plist`:

   ```xml
   <key>CFBundleHelpBookFolder</key>
   <string>YourApp.help</string>
   <key>CFBundleHelpBookName</key>
   <string>com.yourcompany.yourapp.help</string>
   ```

3. **Build and Run**

   Your help book will automatically appear in the Help menu.

## Command-Line Tool (helpbooks)

The CLI tool provides automation capabilities:

```bash
# Export a help book
helpbooks export --content ./content --assets ./assets --output ./output

# Validate content structure
helpbooks validate --content ./content

# List all pages and their metadata
helpbooks list --content ./content
```

### CLI Options

```
USAGE: helpbooks <command> [options]

COMMANDS:
  export      Export content to Help Book bundle
  validate    Validate content structure and frontmatter
  list        List all pages with their metadata

OPTIONS:
  --content <path>    Path to content directory (required)
  --assets <path>     Path to assets directory (optional)
  --output <path>     Output path for Help Book bundle
  --help              Show help information
```

## Project Architecture

```
HelpBooks/
├── Models/              # Data models (MarkdownDocument, HelpProject, etc.)
├── ViewModels/          # View logic and state management
├── Views/               # SwiftUI views
├── Services/
│   ├── FileSystem/      # File import and scanning
│   ├── MarkdownProcessor/  # Markdown parsing and frontmatter
│   └── HelpBookGenerator/  # Help Book export logic
└── Assets/              # App resources
```

## Features in Detail

### Dark Mode Support

All preview content automatically adapts to system appearance:
- Dark backgrounds and light text in dark mode
- Light backgrounds and dark text in light mode
- Alert boxes and code blocks with proper contrast

### Weight-Based Sorting

Control the order of pages and sections using the `weight` field:
- Lower weights appear first
- Items without weights appear last
- Files and folders can be mixed in any order based on weight

### Asset Management

- Automatically detects and copies images, CSS, and JavaScript files
- Rewrites asset paths to work correctly in the Help Book bundle
- Supports both absolute and relative paths in Markdown

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License

Copyright (c) 2025

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Resources

- [Apple Help Programming Guide](https://developer.apple.com/library/archive/documentation/Carbon/Conceptual/ProvidingUserAssitAppleHelp/)
- [Markdown Guide](https://www.markdownguide.org/)
- [YAML Specification](https://yaml.org/)

## Support

For bug reports and feature requests, please use the [GitHub Issues](https://github.com/yourusername/HelpBooks/issues) page.
