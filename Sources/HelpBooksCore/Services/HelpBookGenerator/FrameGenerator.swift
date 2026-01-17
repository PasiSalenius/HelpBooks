import Foundation

/// Generates the main frame page with sidebar and content iframe
class FrameGenerator {
    private let sidebarGenerator: SidebarGenerator
    private let sidebarWidth = 250

    init() {
        self.sidebarGenerator = SidebarGenerator()
    }

    /// Generates the main frame page with sidebar and content iframe
    /// - Parameters:
    ///   - project: The help project
    ///   - defaultContentPath: The initial page to load in the iframe (relative path)
    /// - Returns: Complete HTML for the frame page
    func generateFramePage(project: HelpProject, defaultContentPath: String = "index.html") -> String {
        let sidebarHTML = sidebarGenerator.generateSidebar(
            project: project,
            currentPath: defaultContentPath
        )
        let sidebarJS = sidebarGenerator.generateSidebarJavaScript()

        return buildHTML(
            title: project.metadata.helpBookTitle,
            sidebarHTML: sidebarHTML,
            sidebarJS: sidebarJS,
            defaultContentPath: defaultContentPath
        )
    }

    // MARK: - HTML Structure

    private func buildHTML(
        title: String,
        sidebarHTML: String,
        sidebarJS: String,
        defaultContentPath: String
    ) -> String {
        """
        <!DOCTYPE html>
        <html lang="en">
        \(buildHead(title: title))
        <body>
            \(sidebarHTML)
            \(buildResizeHandle())
            \(buildIframe(src: defaultContentPath))
            \(sidebarJS)
            \(buildHashNavigationScript())
            \(buildNavigationScript())
            \(buildResizeScript())
        </body>
        </html>
        """
    }

    private func buildHead(title: String) -> String {
        """
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <meta name="AppleTitle" content="\(escapeHTML(title))" />
            <meta name="AppleIcon" content="../siteicon.png" />
            <meta name="robots" content="index, anchors" />
            <title>\(escapeHTML(title))</title>
            <link rel="stylesheet" href="../assets/style.css">
            \(buildCSS())
        </head>
        """
    }

    private func buildResizeHandle() -> String {
        """
        <div id="resize-handle"></div>
        """
    }

    private func buildIframe(src: String) -> String {
        """
        <iframe id="content-frame" name="content-frame" src="\(escapeHTML(src))" title="Help Content"></iframe>
        """
    }

    // MARK: - CSS

    private func buildCSS() -> String {
        """
        <style>
        /* Frame Layout */
        body {
            margin: 0;
            padding: 0;
            height: 100vh;
            overflow: hidden;
            display: flex;
        }

        /* Sidebar */
        #help-sidebar {
            flex: 0 0 \(sidebarWidth)px;
            height: 100vh;
            overflow-y: auto;
            position: relative;
            background: #f5f5f7;
        }

        @media (prefers-color-scheme: dark) {
            #help-sidebar {
                background: #1c1c1e;
            }
        }

        /* Resize Handle */
        #resize-handle {
            flex: 0 0 1px;
            cursor: col-resize;
            background: #d2d2d7;
            position: relative;
            transition: all 0.2s ease;
        }

        #resize-handle:hover,
        body.resizing #resize-handle {
            flex-basis: 3px;
            background: #007aff;
        }

        @media (prefers-color-scheme: dark) {
            #resize-handle {
                background: #38383a;
            }

            #resize-handle:hover,
            body.resizing #resize-handle {
                background: #0a84ff;
            }
        }

        /* Content Frame */
        #content-frame {
            flex: 1;
            border: none;
            height: 100vh;
            width: 100%;
        }

        /* Disable pointer events during resize */
        body.resizing #content-frame {
            pointer-events: none;
        }

        body.resizing {
            cursor: col-resize;
        }

        /* Keyboard focus styling */
        .keyboard-focused {
            outline: 2px solid #007aff;
            outline-offset: -2px;
            background: rgba(0, 122, 255, 0.1);
        }

        @media (prefers-color-scheme: dark) {
            .keyboard-focused {
                outline-color: #0a84ff;
                background: rgba(10, 132, 255, 0.15);
            }
        }
        </style>
        """
    }

    // MARK: - JavaScript

    private func buildNavigationScript() -> String {
        """
        <script>
        (function() {
            'use strict';

            const contentFrame = document.getElementById('content-frame');
            const sidebar = document.getElementById('help-sidebar');

            // Build ordered list of all navigable items (sections and links)
            let orderedItems = [];
            let focusedIndex = -1;

            function buildNavigableItemsList() {
                orderedItems = [];
                // Get all section headers and links in document order
                const sections = sidebar.querySelectorAll('.toc-section-header');
                const links = sidebar.querySelectorAll('a[href]');
                const allElements = [...sections, ...links].filter(el => {
                    if (el.tagName === 'A') {
                        const href = el.getAttribute('href');
                        return href && !href.includes('_index.html');
                    }
                    return true;
                });

                // Sort by document position
                allElements.sort((a, b) => {
                    const position = a.compareDocumentPosition(b);
                    return position & Node.DOCUMENT_POSITION_FOLLOWING ? -1 : 1;
                });

                orderedItems = allElements;
            }

            // Check if an item is visible (not in a collapsed section)
            function isItemVisible(item) {
                let parent = item.parentElement;
                while (parent && parent !== sidebar) {
                    if (parent.classList.contains('toc-section-content')) {
                        const computedStyle = window.getComputedStyle(parent);
                        if (computedStyle.display === 'none') {
                            return false;
                        }
                    }
                    parent = parent.parentElement;
                }
                return true;
            }

            // Update current page highlighting when iframe navigates
            function updateCurrentPageHighlight() {
                try {
                    const iframeSrc = contentFrame.contentWindow.location.pathname;
                    const filename = iframeSrc.split('/').pop();

                    // Remove all current-page classes
                    sidebar.querySelectorAll('a.current-page').forEach(link => {
                        link.classList.remove('current-page');
                    });

                    // Add current-page class to matching link
                    let currentLink = null;
                    orderedItems.forEach((item, index) => {
                        if (item.tagName === 'A') {
                            const href = item.getAttribute('href');
                            const linkFilename = href.split('/').pop();
                            if (linkFilename === filename) {
                                item.classList.add('current-page');
                                currentLink = item;
                                focusedIndex = index;

                                // Expand parent sections if collapsed
                                let parent = item.parentElement;
                                while (parent && parent !== sidebar) {
                                    if (parent.classList.contains('toc-section-content')) {
                                        const header = parent.previousElementSibling;
                                        if (header && header.classList.contains('toc-section-header')) {
                                            const isExpanded = header.getAttribute('aria-expanded') === 'true';
                                            if (!isExpanded) {
                                                toggleSection(header);
                                            }
                                        }
                                    }
                                    parent = parent.parentElement;
                                }
                            }
                        }
                    });

                    if (currentLink) {
                        scrollToItem(currentLink);
                    }
                } catch (e) {
                    // Cross-origin access prevented - ignore
                }
            }

            // Scroll item into view
            function scrollToItem(item) {
                const sidebarRect = sidebar.getBoundingClientRect();
                const itemRect = item.getBoundingClientRect();
                const isAbove = itemRect.top < sidebarRect.top;
                const isBelow = itemRect.bottom > sidebarRect.bottom;

                if (isAbove || isBelow) {
                    item.scrollIntoView({ behavior: 'smooth', block: 'center' });
                }
            }

            // Remove keyboard focus from all items
            function clearKeyboardFocus() {
                sidebar.querySelectorAll('.keyboard-focused').forEach(el => {
                    el.classList.remove('keyboard-focused');
                });
            }

            // Set keyboard focus on an item
            function setKeyboardFocus(index) {
                if (index < 0 || index >= orderedItems.length) return;
                clearKeyboardFocus();
                focusedIndex = index;
                const item = orderedItems[index];
                item.classList.add('keyboard-focused');
                scrollToItem(item);
            }

            // Navigate to previous item
            function navigatePrevious() {
                if (focusedIndex < 0) {
                    // Find first visible item
                    for (let i = 0; i < orderedItems.length; i++) {
                        if (isItemVisible(orderedItems[i])) {
                            setKeyboardFocus(i);
                            return;
                        }
                    }
                } else {
                    // Find previous visible item
                    for (let i = focusedIndex - 1; i >= 0; i--) {
                        if (isItemVisible(orderedItems[i])) {
                            setKeyboardFocus(i);
                            return;
                        }
                    }
                }
            }

            // Navigate to next item
            function navigateNext() {
                if (focusedIndex < 0) {
                    // Find first visible item
                    for (let i = 0; i < orderedItems.length; i++) {
                        if (isItemVisible(orderedItems[i])) {
                            setKeyboardFocus(i);
                            return;
                        }
                    }
                } else {
                    // Find next visible item
                    for (let i = focusedIndex + 1; i < orderedItems.length; i++) {
                        if (isItemVisible(orderedItems[i])) {
                            setKeyboardFocus(i);
                            return;
                        }
                    }
                }
            }

            // Collapse focused section
            function collapseFocusedSection() {
                if (focusedIndex < 0) return;
                const item = orderedItems[focusedIndex];
                if (item.classList.contains('toc-section-header') && item.hasAttribute('onclick')) {
                    const isExpanded = item.getAttribute('aria-expanded') === 'true';
                    if (isExpanded) {
                        toggleSection(item);
                    }
                }
            }

            // Expand focused section
            function expandFocusedSection() {
                if (focusedIndex < 0) return;
                const item = orderedItems[focusedIndex];
                if (item.classList.contains('toc-section-header') && item.hasAttribute('onclick')) {
                    const isExpanded = item.getAttribute('aria-expanded') === 'true';
                    if (!isExpanded) {
                        toggleSection(item);
                    }
                }
            }

            // Activate focused item (open link or toggle section)
            function activateFocusedItem() {
                if (focusedIndex < 0) return;
                const item = orderedItems[focusedIndex];
                if (item.tagName === 'A') {
                    contentFrame.src = item.getAttribute('href');
                } else if (item.classList.contains('toc-section-header') && item.hasAttribute('onclick')) {
                    toggleSection(item);
                }
            }

            // Handle keyboard navigation
            function handleKeyDown(e) {
                const activeElement = document.activeElement;
                const isInputFocused = activeElement &&
                    (activeElement.tagName === 'INPUT' || activeElement.tagName === 'TEXTAREA');

                if (isInputFocused) return;

                if (e.key === 'ArrowUp') {
                    e.preventDefault();
                    navigatePrevious();
                } else if (e.key === 'ArrowDown') {
                    e.preventDefault();
                    navigateNext();
                } else if (e.key === 'ArrowLeft') {
                    e.preventDefault();
                    collapseFocusedSection();
                } else if (e.key === 'ArrowRight') {
                    e.preventDefault();
                    expandFocusedSection();
                } else if (e.key === 'Enter') {
                    e.preventDefault();
                    activateFocusedItem();
                }
            }

            // Initialize
            buildNavigableItemsList();

            // Listen for iframe navigation
            contentFrame.addEventListener('load', updateCurrentPageHighlight);

            // Update on link clicks in sidebar
            sidebar.addEventListener('click', function(e) {
                if (e.target.tagName === 'A') {
                    setTimeout(updateCurrentPageHighlight, 100);
                }
            });

            // Listen for keyboard navigation
            document.addEventListener('keydown', handleKeyDown);
        })();
        </script>
        """
    }

    private func buildHashNavigationScript() -> String {
        """
        <script>
        (function() {
            'use strict';

            const contentFrame = document.getElementById('content-frame');

            // Check for hash fragment on page load
            function checkHashNavigation() {
                const hash = window.location.hash;
                if (hash && hash.length > 1) {
                    // Remove the # symbol
                    const targetPage = hash.substring(1);
                    // Load the target page in the iframe
                    contentFrame.src = targetPage;
                    // Clean up the URL by removing the hash (optional)
                    // Using replaceState to avoid triggering a navigation event
                    if (window.history && window.history.replaceState) {
                        window.history.replaceState(null, '', window.location.pathname);
                    }
                }
            }

            // Run on page load
            checkHashNavigation();

            // Also handle hash changes (in case the user navigates back/forward)
            window.addEventListener('hashchange', checkHashNavigation);
        })();
        </script>
        """
    }

    private func buildResizeScript() -> String {
        """
        <script>
        (function() {
            'use strict';

            const sidebar = document.getElementById('help-sidebar');
            const resizeHandle = document.getElementById('resize-handle');
            const body = document.body;

            let isResizing = false;
            let startX = 0;
            let startWidth = 0;

            resizeHandle.addEventListener('mousedown', function(e) {
                isResizing = true;
                startX = e.clientX;
                startWidth = sidebar.offsetWidth;
                body.classList.add('resizing');
                e.preventDefault();
            });

            document.addEventListener('mousemove', function(e) {
                if (!isResizing) return;
                const width = startWidth + (e.clientX - startX);
                const minWidth = 180;
                const maxWidth = 500;
                const constrainedWidth = Math.max(minWidth, Math.min(maxWidth, width));
                sidebar.style.flexBasis = constrainedWidth + 'px';
            });

            document.addEventListener('mouseup', function() {
                if (isResizing) {
                    isResizing = false;
                    body.classList.remove('resizing');
                }
            });
        })();
        </script>
        """
    }

    // MARK: - Utilities

    private func escapeHTML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
