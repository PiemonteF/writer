import AppKit
import WebKit

final class PreviewViewController: NSViewController, WKNavigationDelegate {
    private let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
    private var pendingScrollY: Double = 0
    private var renderWork: DispatchWorkItem?
    private var loadCallbacks: [() -> Void] = []
    private var isLoading = false

    override func loadView() {
        webView.navigationDelegate = self
        webView.setValue(false, forKey: "drawsBackground")
        view = webView
    }

    func render(_ markdown: String, title: String, immediately: Bool = false) {
        renderWork?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.load(markdown, title: title) }
        renderWork = work
        if immediately {
            work.perform()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
        }
    }

    func pdf(completion: @escaping (Result<Data, Error>) -> Void) {
        loadViewIfNeeded()
        afterLoad { [webView] in
            let configuration = WKPDFConfiguration()
            webView.createPDF(configuration: configuration) { completion($0) }
        }
    }

    private func load(_ markdown: String, title: String) {
        loadViewIfNeeded()
        let html = MarkdownRenderer.document(from: markdown, title: title, stylesheet: .linked("preview.css"))
        isLoading = true
        webView.evaluateJavaScript("window.scrollY") { [weak self] value, _ in
            self?.pendingScrollY = value as? Double ?? 0
            self?.webView.loadHTMLString(html, baseURL: Bundle.main.resourceURL)
        }
    }

    private func afterLoad(_ block: @escaping () -> Void) {
        if isLoading { loadCallbacks.append(block) } else { block() }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("window.scrollTo(0, \(pendingScrollY))") { [weak self] _, _ in
            guard let self else { return }
            self.isLoading = false
            let callbacks = self.loadCallbacks
            self.loadCallbacks = []
            callbacks.forEach { $0() }
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url {
            NSWorkspace.shared.open(url)
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
}
