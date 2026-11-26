import Combine
import SwiftUI
import UIKit
import WebKit

@MainActor
final class LiveWebViewStore: ObservableObject {
    static let startMeURL = URL(string: "https://start.me/p/L1rEYQ/osint4all")!

    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var isLoading = false

    weak var webView: WKWebView?
    var onOpenExternal: ((URL) -> Void)?

    func loadStartMe() {
        webView?.load(URLRequest(url: Self.startMeURL))
    }

    func goBack() {
        webView?.goBack()
    }

    func goForward() {
        webView?.goForward()
    }

    func reload() {
        if webView?.url == nil {
            loadStartMe()
        } else {
            webView?.reload()
        }
    }
}

struct LiveWebViewRepresentable: UIViewRepresentable {
    @ObservedObject var store: LiveWebViewStore

    func makeCoordinator() -> Coordinator {
        Coordinator(store: store)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.defaultWebpagePreferences.allowsContentJavaScript = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = false
        let bg = UIColor(red: 0.06, green: 0.09, blue: 0.14, alpha: 1.0)
        webView.backgroundColor = bg
        webView.scrollView.backgroundColor = bg

        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = UIColor(red: 0.137, green: 0.584, blue: 0.929, alpha: 1.0)
        refreshControl.addTarget(
            context.coordinator,
            action: #selector(Coordinator.handleRefresh(_:)),
            for: .valueChanged
        )
        webView.scrollView.refreshControl = refreshControl

        context.coordinator.observe(webView)
        store.webView = webView
        webView.load(URLRequest(url: LiveWebViewStore.startMeURL))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        private let store: LiveWebViewStore
        private var observations: [NSKeyValueObservation] = []

        init(store: LiveWebViewStore) {
            self.store = store
        }

        deinit {
            observations.forEach { $0.invalidate() }
        }

        func observe(_ webView: WKWebView) {
            observations = [
                webView.observe(\.canGoBack, options: [.initial, .new]) { [weak self] wv, _ in
                    Task { @MainActor in self?.store.canGoBack = wv.canGoBack }
                },
                webView.observe(\.canGoForward, options: [.initial, .new]) { [weak self] wv, _ in
                    Task { @MainActor in self?.store.canGoForward = wv.canGoForward }
                },
                webView.observe(\.isLoading, options: [.initial, .new]) { [weak self] wv, _ in
                    Task { @MainActor in self?.store.isLoading = wv.isLoading }
                }
            ]
        }

        @objc func handleRefresh(_ sender: UIRefreshControl) {
            Task { @MainActor in
                store.reload()
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.scrollView.refreshControl?.endRefreshing()
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            webView.scrollView.refreshControl?.endRefreshing()
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            webView.scrollView.refreshControl?.endRefreshing()
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }
            let host = url.host?.lowercased() ?? ""
            if host.contains("start.me") || host.contains("challenges.cloudflare.com") || url.scheme == "about" {
                decisionHandler(.allow)
                return
            }
            if (url.scheme == "http" || url.scheme == "https"), navigationAction.navigationType == .linkActivated {
                Task { @MainActor in
                    store.onOpenExternal?(url)
                }
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }

        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            if let url = navigationAction.request.url,
               let scheme = url.scheme?.lowercased(),
               scheme == "http" || scheme == "https"
            {
                Task { @MainActor in
                    store.onOpenExternal?(url)
                }
            }
            return nil
        }
    }
}

struct LiveWebTabView: View {
    @ObservedObject var directoryStore: DirectoryStore
    @StateObject private var webStore = LiveWebViewStore()
    @Binding var showAbout: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    LiveWebViewRepresentable(store: webStore)
                    if webStore.isLoading {
                        ProgressView()
                            .progressViewStyle(.linear)
                            .tint(Color("AccentColor"))
                    }
                }

                Divider()

                HStack(spacing: 28) {
                    Button {
                        webStore.goBack()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(!webStore.canGoBack)

                    Button {
                        webStore.goForward()
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(!webStore.canGoForward)

                    Spacer()

                    Button {
                        webStore.loadStartMe()
                    } label: {
                        Image(systemName: "house.fill")
                    }

                    Button {
                        webStore.reload()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .font(.system(size: 17, weight: .medium))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color(red: 0.08, green: 0.11, blue: 0.17))
            }
            .navigationTitle("Live start.me")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAbout = true
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }
            }
            .onAppear {
                webStore.onOpenExternal = { url in
                    directoryStore.openURL(url)
                }
            }
        }
    }
}
