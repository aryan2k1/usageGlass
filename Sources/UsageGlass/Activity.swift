import Foundation

/// Detects which tool is being used right now from file modification times only.
/// No file contents are read: Claude Code writes transcripts under ~/.claude/projects and its status-line
/// feed; Codex writes rollout files under ~/.codex/sessions/YYYY/MM/DD.
enum ActivityProbe {
    /// Latest modification time per provider (nil if nothing found). Bounded and cheap enough to run every few seconds.
    static func latest(now: Date = Date()) -> [ProviderID: Date] {
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser
        var result: [ProviderID: Date] = [:]

        func consider(_ provider: ProviderID, _ url: URL) {
            guard let date = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate else { return }
            if date > (result[provider] ?? .distantPast) { result[provider] = date }
        }
        func jsonl(in directory: URL, provider: ProviderID, budget: inout Int) {
            guard let items = try? fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.contentModificationDateKey, .isSymbolicLinkKey], options: [.skipsHiddenFiles]) else { return }
            for item in items where item.pathExtension == "jsonl" {
                budget -= 1
                if budget < 0 { return }
                if (try? item.resourceValues(forKeys: [.isSymbolicLinkKey]))?.isSymbolicLink == true { continue }
                consider(provider, item)
            }
        }

        // Claude Code: status-line feed written by the bridge on every update, and project transcripts.
        consider(.claude, home.appendingPathComponent("Library/Application Support/UsageGlass/claude-usage.json"))
        var budget = 4000
        let projects = home.appendingPathComponent(".claude/projects")
        if let dirs = try? fm.contentsOfDirectory(at: projects, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) {
            for dir in dirs { jsonl(in: dir, provider: .claude, budget: &budget); if budget < 0 { break } }
        }

        // Codex: today's and yesterday's rollout folders (local dates, as Codex names them).
        var calendar = Calendar.current
        calendar.timeZone = .current
        for offset in 0...1 {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: now) else { continue }
            let c = calendar.dateComponents([.year, .month, .day], from: day)
            let folder = home.appendingPathComponent(String(format: ".codex/sessions/%04d/%02d/%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0))
            var codexBudget = 1000
            jsonl(in: folder, provider: .codex, budget: &codexBudget)
        }
        return result
    }

    /// Picks the active provider: the most recently touched one within `window` seconds.
    /// Sticks with the previous choice for `hold` seconds of quiet, then returns nil (show both).
    static func choose(latest: [ProviderID: Date], previous: ProviderID?, now: Date = Date(), window: TimeInterval = 90, hold: TimeInterval = 600) -> ProviderID? {
        let fresh = latest.filter { now.timeIntervalSince($0.value) <= window }
        if let best = fresh.max(by: { $0.value < $1.value }) {
            // Avoid flapping when both are fresh: keep the previous one unless the other is clearly newer.
            if let previous, let prevDate = fresh[previous], best.key != previous, best.value.timeIntervalSince(prevDate) < 20 { return previous }
            return best.key
        }
        if let previous, let date = latest[previous], now.timeIntervalSince(date) <= hold { return previous }
        return nil
    }
}
