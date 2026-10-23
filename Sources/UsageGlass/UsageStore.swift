import Foundation
import Combine

@MainActor
final class UsageStore: ObservableObject {
    @Published var snapshots: [ProviderSnapshot] = ProviderID.allCases.map(ProviderSnapshot.unavailable)
    @Published var sessions: [SessionUsage] = []
    @Published var isRefreshing = false
    @Published var lastRefresh: Date?
    @Published var bridgeStatus = "Bridge not installed"
    private var isChangingBridge = false
    let webLimits = ClaudeWebLimits()

    init() {}
    func snapshot(for provider: ProviderID) -> ProviderSnapshot {
        snapshots.first(where: { $0.id == provider }) ?? .unavailable(provider)
    }
    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let result = try await Providers.collect()
            snapshots = result.snapshots.map { incoming in
                guard incoming.capturedAt == nil, let old = snapshots.first(where: { $0.id == incoming.id }), old.capturedAt != nil else { return incoming }
                var retained = old
                retained.status = "Refresh failed · last known reading"
                retained.error = incoming.error
                return retained
            }
            await webLimits.refresh()
            if let i = snapshots.firstIndex(where: { $0.id == .claude }), !webLimits.windows.isEmpty {
                snapshots[i].windows = webLimits.windows + snapshots[i].windows
            }
            sessions = result.sessions
            if !isChangingBridge { bridgeStatus = result.bridgeStatus }
            lastRefresh = Date()
        } catch {
            snapshots = snapshots.map { old in
                var retained = old
                retained.status = "Refresh failed · last known reading"
                retained.error = "Usage collection unavailable. Check the installed command-line tools."
                return retained
            }
        }
    }
    func installClaudeBridge() async {
        guard !isChangingBridge else { return }
        isChangingBridge = true
        bridgeStatus = await Providers.bridge(install: true)
        await refresh()
        isChangingBridge = false
    }
    func enableClaudeBridge() async { await installClaudeBridge() }
    func uninstallClaudeBridge() async {
        guard !isChangingBridge else { return }
        isChangingBridge = true
        bridgeStatus = await Providers.bridge(install: false)
        await refresh()
        isChangingBridge = false
    }
}
