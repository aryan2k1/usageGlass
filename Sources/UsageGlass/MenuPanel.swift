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
        VStack(alignment: .leading, spacing: 12) {
            ForEach(ProviderID.allCases) { provider in MenuProviderRow(provider: provider) }
            HStack(spacing: 14) {
                Button("Dashboard") { openWindow(id: "dashboard"); NSApp.activate(ignoringOtherApps: true) }
                Spacer()
                Button { Task { await store.refresh() } } label: { Image(systemName: "arrow.clockwise") }
                    .disabled(store.isRefreshing).help("Refresh").accessibilityLabel("Refresh usage")
                Button("Quit") { NSApp.terminate(nil) }
            }.buttonStyle(.plain).font(.caption).foregroundStyle(.secondary)
        }.padding(16).frame(width: 270)
    }
}

/// One provider: mark, headline percentage and gradient bar. Click to reveal every window and detail.
struct MenuProviderRow: View {
    let provider: ProviderID
    @EnvironmentObject private var store: UsageStore
    @State private var expanded = false

    var body: some View {
        let snapshot = store.snapshot(for: provider)
        let measured = snapshot.windows.filter { $0.usedPercent?.isFinite == true }
        let top = measured.max { ($0.usedPercent ?? 0) < ($1.usedPercent ?? 0) }
        let value = top?.usedPercent.map { min(max($0, 0), 100) }
        VStack(alignment: .leading, spacing: 6) {
            Button { withAnimation(.snappy(duration: 0.2)) { expanded.toggle() } } label: {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        ProviderMark(provider: provider, size: 17)
                        Text(provider.title).font(.subheadline.weight(.medium))
                        Spacer()
                        Text(value.map { "\(Int($0.rounded()))%" } ?? "—")
                            .font(.subheadline.weight(.semibold)).monospacedDigit()
                            .foregroundStyle(value.map(UsagePalette.color) ?? .secondary)
                        Image(systemName: "chevron.right").font(.caption2.weight(.semibold)).foregroundStyle(.tertiary)
                            .rotationEffect(.degrees(expanded ? 90 : 0))
                    }
                    GradientBar(value: value, height: 5)
                    Text(caption(snapshot, top)).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                }.contentShape(Rectangle())
            }.buttonStyle(.plain)
            .accessibilityLabel(provider.title + ": " + (value.map { "\(Int($0.rounded())) percent used" } ?? "unavailable"))
            .accessibilityHint(expanded ? "Hide limit details" : "Show limit details")

            if expanded { details(snapshot) }
        }
    }

    @ViewBuilder private func details(_ snapshot: ProviderSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            if snapshot.windows.isEmpty { Text(snapshot.status).font(.caption2).foregroundStyle(.secondary) }
            ForEach(snapshot.windows) { window in
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(window.label).font(.caption)
                        Spacer()
                        Text(window.usedPercent.map { "\(Int($0.rounded()))%" } ?? "—").font(.caption.weight(.medium)).monospacedDigit()
                            .foregroundStyle(window.usedPercent.map(UsagePalette.color) ?? .secondary)
                    }
                    if window.usedPercent != nil { GradientBar(value: window.usedPercent, height: 3) }
                    if let line = windowLine(window) { Text(line).font(.caption2).foregroundStyle(.secondary) }
                }
            }
            Text(snapshot.status).font(.caption2).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            if let age = snapshot.ageText { Text("Updated \(age)").font(.caption2).foregroundStyle(.tertiary) }
        }
        .padding(10).frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private func windowLine(_ window: QuotaWindow) -> String? {
        if let reset = window.resetsAt, reset > Date() {
            return "Resets " + reset.formatted(.relative(presentation: .numeric, unitsStyle: .wide))
        }
        return window.note
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
