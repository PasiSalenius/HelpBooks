import SwiftUI
import WebKit

struct PreviewPane: View {
    let document: MarkdownDocument
    let assets: [AssetReference]
    let theme: HelpBookTheme
    @Bindable var viewModel: PreviewViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        WebView(
            html: viewModel.htmlForPreview(
                document,
                colorScheme: colorScheme,
                theme: theme
            ),
            assets: assets,
            colorScheme: colorScheme
        )
        .id(document.id.uuidString + String(viewModel.refreshTrigger) + (colorScheme == .dark ? "dark" : "light") + theme.rawValue)
    }
}

struct WebView: NSViewRepresentable {
    let html: String
    let assets: [AssetReference]
    let colorScheme: ColorScheme

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()

        // Register custom URL scheme handler for assets
        let schemeHandler = AssetURLSchemeHandler(assets: assets)
        config.setURLSchemeHandler(schemeHandler, forURLScheme: "asset")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator

        // Make the WKWebView's layer transparent so HTML background shows through
        webView.setValue(false, forKey: "drawsBackground")

        // Set the appearance based on color scheme
        let appearanceName: NSAppearance.Name = colorScheme == .dark ? .darkAqua : .aqua
        webView.appearance = NSAppearance(named: appearanceName)

        // Store the scheme handler in the coordinator to keep it alive
        context.coordinator.schemeHandler = schemeHandler

        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        // Update appearance if color scheme changed
        let appearanceName: NSAppearance.Name = colorScheme == .dark ? .darkAqua : .aqua
        if webView.appearance?.name != appearanceName {
            webView.appearance = NSAppearance(named: appearanceName)
        }

        webView.loadHTMLString(html, baseURL: nil)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var schemeHandler: AssetURLSchemeHandler?

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("⚠️ WebView navigation failed: \(error.localizedDescription)")
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("⚠️ WebView provisional navigation failed: \(error.localizedDescription)")
        }
    }
}
