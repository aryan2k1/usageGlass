import Foundation

enum ProviderID: String, CaseIterable, Identifiable, Codable, Sendable {
    case codex, claude
    var id: String { rawValue }
    var title: String { self == .codex ? "Codex" : "Claude Code" }
}
struct QuotaWindow: Identifiable, Codable, Sendable {
    var id: String
    var label: String
    var usedPercent: Double?
    var resetsAt: Date?
    var windowMinutes: Int?
    var note: String?
}
struct ProviderSnapshot: Identifiable, Codable, Sendable {
    var id: ProviderID
    var windows: [QuotaWindow] = []
    var capturedAt: Date?
    var source: String
    var status: String
    var error: String?
    var details: [String] = []
    // Claude only refreshes while Claude Code runs, so it tolerates a longer gap before being called stale.
    var isStale: Bool { error != nil || (capturedAt.map { Date().timeIntervalSince($0) > (id == .claude ? 6 * 3600 : 300) } ?? true) }
    var ageText: String? {
        guard let capturedAt else { return nil }
        let s = Int(Date().timeIntervalSince(capturedAt))
        return s < 90 ? "just now" : s < 5400 ? "\(s / 60)m ago" : s < 172800 ? "\(s / 3600)h ago" : "\(s / 86400)d ago"
    }
    static func unavailable(_ provider: ProviderID) -> Self {
        .init(id: provider, source: provider == .codex ? "Codex app-server" : "Claude status line", status: "Not connected")
    }
}
struct SessionUsage: Identifiable, Codable, Sendable {
    var id: String
    var provider: ProviderID
    var model: String?
    var updatedAt: Date
    var inputTokens: Int?
    var outputTokens: Int?
    var cachedInputTokens: Int?
    var cacheCreationTokens: Int?
    var reasoningTokens: Int?
    var contextUsedPercent: Double?
    var contextWindow: Int?
    var costUSD: Double?
    var scope: String = "Session totals"
    // Provider input conventions differ; cached/reasoning subtotals are never added again.
    var totalTokens: Int? {
        guard let inputTokens, let outputTokens else { return nil }
        return inputTokens + outputTokens + (provider == .claude ? (cachedInputTokens ?? 0) + (cacheCreationTokens ?? 0) : 0)
    }
}
typealias UsageSession = SessionUsage
