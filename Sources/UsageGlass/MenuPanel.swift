import SwiftUI
import AppKit

struct MenuLabel: View {
    @EnvironmentObject private var store: UsageStore
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "chart.bar.xaxis")
            ForEach(ProviderID.allCases) { provider in
                let percentage = store.snapshot(for: provider).windows.compactMap(\.usedPercent).filter(\.isFinite).map { min(max($0, 0), 100) }.max()
                Text("\(provider == .codex ? "Cdx" : "Claude") \(percentage.map { String(Int($0.rounded())) + "%" } ?? "—")")
                    .monospacedDigit()
            }
        }.accessibilityLabel(accessibilitySummary)
    }
    private var accessibilitySummary: String {
        "Usage Glass. " + ProviderID.allCases.map { provider in
            let snapshot = store.snapshot(for: provider)
            let percentage = snapshot.windows.compactMap(\.usedPercent).filter(\.isFinite).map { min(max($0, 0), 100) }.max()
            return provider.title + ": " + (percentage.map { String(Int($0.rounded())) + " percent used" } ?? "unavailable") + (snapshot.capturedAt == nil ? ", awaiting data" : (snapshot.isStale ? ", stale" : ""))
        }.joined(separator: ". ")
    }
}

struct MenuPanel: View {
    @EnvironmentObject private var store: UsageStore
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(ProviderID.allCases) { provider in row(provider) }
            HStack(spacing: 14) {
                Button("Dashboard") { openWindow(id: "dashboard"); NSApp.activate(ignoringOtherApps: true) }
                Spacer()
                Button { Task { await store.refresh() } } label: { Image(systemName: "arrow.clockwise") }
                    .disabled(store.isRefreshing).help("Refresh").accessibilityLabel("Refresh usage")
                Button("Quit") { NSApp.terminate(nil) }
            }.buttonStyle(.plain).font(.caption).foregroundStyle(.secondary)
        }.padding(16).frame(width: 250)
    }

    @ViewBuilder private func row(_ provider: ProviderID) -> some View {
        let snapshot = store.snapshot(for: provider)
        // Most constrained quota window drives the bar; token-only windows (no percent) are ignored here.
        let top = snapshot.windows.filter { $0.usedPercent?.isFinite == true }.max { ($0.usedPercent ?? 0) < ($1.usedPercent ?? 0) }
        let value = top?.usedPercent.map { min(max($0, 0), 100) }
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                Text(provider.title).font(.subheadline.weight(.medium))
                Spacer()
                Text(value.map { "\(Int($0.rounded()))%" } ?? "—").font(.subheadline.weight(.semibold)).monospacedDigit()
            }
            Capsule().fill(Color.primary.opacity(0.1)).frame(height: 4).overlay(alignment: .leading) {
                GeometryReader { geo in
                    if let value { Capsule().fill(value >= 95 ? .red : value >= 80 ? .orange : provider.tint).frame(width: geo.size.width * value / 100) }
                }
            }.accessibilityHidden(true)
            Text(caption(snapshot, top)).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(provider.title + ": " + (value.map { "\(Int($0.rounded())) percent used" } ?? "unavailable"))
    }

    private func caption(_ snapshot: ProviderSnapshot, _ top: QuotaWindow?) -> String {
        var parts: [String] = []
        if let top {
            parts.append(top.label.components(separatedBy: " · ").last ?? top.label)
            if let reset = top.resetsAt, reset > Date() { parts.append("resets " + reset.formatted(.relative(presentation: .numeric, unitsStyle: .abbreviated))) }
        } else if let token = snapshot.windows.first?.note { parts.append(token) }
        else { parts.append(snapshot.status) }
        if snapshot.capturedAt == nil { parts.append("no data") }
        else if snapshot.isStale { parts.append("stale" + (snapshot.ageText.map { " · \($0)" } ?? "")) }
        return parts.joined(separator: " · ")
    }
}
