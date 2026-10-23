import SwiftUI
import WebKit

/// Experimental, opt-in reader for claude.ai "normal" chat limits.
/// The user signs in inside the app's own web view (no browser cookies are read). The page then calls
/// claude.ai's own same-origin usage endpoint, and only numeric percentages and reset times are kept.
/// The endpoint is undocumented and may change; every failure degrades to "unavailable".
@MainActor
final class ClaudeWebLimits: NSObject, ObservableObject, WKNavigationDelegate {
    @Published private(set) var windows: [QuotaWindow] = []
    @Published private(set) var status = "Not connected"
    @Published private(set) var isConnected = UserDefaults.standard.bool(forKey: "claudeWebConnected")
    private var lastFetch: Date?
    private var loginWindow: NSWindow?
    private var closeObserver: NSObjectProtocol?
    private var continuation: CheckedContinuation<Void, Error>?
    private let allowedHost = "claude.ai"

    private func makeWebView() -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default() // the app's own store, isolated from Safari/Chrome
        return WKWebView(frame: NSRect(x: 0, y: 0, width: 520, height: 720), configuration: config)
    }

    func connect() {
        let view = makeWebView()
        view.navigationDelegate = self
        view.load(URLRequest(url: URL(string: "https://claude.ai/login")!))
        let window = NSWindow(contentRect: view.frame, styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        window.title = "Sign in to claude.ai"
        window.contentView = view
        window.isReleasedWhenClosed = false
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        loginWindow = window
        closeObserver = NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: window, queue: .main) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.isConnected = true
                UserDefaults.standard.set(true, forKey: "claudeWebConnected")
                self.lastFetch = nil
                self.loginWindow = nil
                await self.refresh(force: true)
            }
        }
    }

    func disconnect() async {
        isConnected = false
        UserDefaults.standard.set(false, forKey: "claudeWebConnected")
        windows = []
        status = "Not connected"
        await WKWebsiteDataStore.default().removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: .distantPast)
    }

    /// Polls at most every 5 minutes.
    func refresh(force: Bool = false) async {
        guard isConnected, continuation == nil else { return }
        if !force, let lastFetch, Date().timeIntervalSince(lastFetch) < 300 { return }
        lastFetch = Date()
        let view = makeWebView()
        view.navigationDelegate = self
        do {
            try await load(view, URL(string: "https://claude.ai/settings/usage")!)
            guard view.url?.host == allowedHost, view.url?.path.hasPrefix("/login") == false else {
                status = "Sign-in expired · reconnect"; windows = []; return
            }
            let script = """
            const orgs = await (await fetch('/api/organizations', {credentials: 'include'})).json();
            const id = Array.isArray(orgs) && orgs[0] && orgs[0].uuid;
            if (!id) return null;
            return await (await fetch('/api/organizations/' + encodeURIComponent(id) + '/usage', {credentials: 'include'})).json();
            """
            let result = try await view.callAsyncJavaScript(script, arguments: [:], in: nil, contentWorld: .defaultClient)
            windows = Self.parse(result)
            status = windows.isEmpty ? "claude.ai limits unavailable" : "claude.ai chat limits"
        } catch {
            windows = []
            status = "claude.ai limits unavailable"
        }
    }

    private func load(_ view: WKWebView, _ url: URL) async throws {
        try await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, Error>) in
            continuation = c
            view.load(URLRequest(url: url))
        }
    }
    private func finish(_ error: Error?) {
        guard let c = continuation else { return }
        continuation = nil
        if let error { c.resume(throwing: error) } else { c.resume() }
    }
    nonisolated func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { Task { @MainActor in finish(nil) } }
    nonisolated func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { Task { @MainActor in finish(error) } }
    nonisolated func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { Task { @MainActor in finish(error) } }
    nonisolated func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(action.request.url?.scheme == "https" ? .allow : .cancel)
    }

    /// Keeps only entries shaped like {utilization | used_percentage: number, resets_at: ISO string}.
    static func parse(_ raw: Any?) -> [QuotaWindow] {
        guard let dict = raw as? [String: Any] else { return [] }
        let fractional = ISO8601DateFormatter(); fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let plain = ISO8601DateFormatter()
        return dict.keys.sorted().compactMap { key in
            guard let entry = dict[key] as? [String: Any],
                  let pct = (entry["utilization"] ?? entry["used_percentage"]) as? Double, pct.isFinite else { return nil }
            let reset = (entry["resets_at"] as? String).flatMap { fractional.date(from: $0) ?? plain.date(from: $0) }
            let name = key.replacingOccurrences(of: "_", with: " ").capitalized
            return QuotaWindow(id: "web:" + key, label: "claude.ai · " + name, usedPercent: min(max(pct, 0), 100), resetsAt: reset, windowMinutes: nil, note: nil)
        }
    }
}
