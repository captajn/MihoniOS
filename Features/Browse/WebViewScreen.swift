import SwiftUI
import WebKit
import Core

/// WKWebView wrapper for source login and cookie-based authentication
struct WebViewScreen: UIViewRepresentable {
    let url: URL
    let title: String
    var headers: [String: String] = [:]
    var onCookieReceived: (([HTTPCookie]) -> Void)?

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true

        // Inject cookies if provided
        if !headers.isEmpty {
            let store = config.websiteDataStore.httpCookieStore
            for (name, value) in headers {
                if let cookie = HTTPCookie(properties: [
                    .domain: url.host ?? "",
                    .path: "/",
                    .name: name,
                    .value: value
                ]) {
                    store.setCookie(cookie)
                }
            }
        }

        // Load URL with headers
        var request = URLRequest(url: url)
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        webView.load(request)

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCookieReceived: onCookieReceived)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var onCookieReceived: (([HTTPCookie]) -> Void)?

        init(onCookieReceived: (([HTTPCookie]) -> Void)?) {
            self.onCookieReceived = onCookieReceived
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let store = webView.configuration.websiteDataStore.httpCookieStore
            store.getAllCookies { cookies in
                self.onCookieReceived?(cookies)
            }
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(.allow)
        }
    }
}

/// SwiftUI wrapper with navigation and toolbar
struct WebViewSheet: View {
    let url: URL
    let title: String
    var headers: [String: String] = [:]
    var onCookieReceived: (([HTTPCookie]) -> Void)?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            WebViewScreen(
                url: url,
                title: title,
                headers: headers,
                onCookieReceived: onCookieReceived
            )
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "action_close")) {
                        dismiss()
                    }
                }
            }
        }
    }
}
