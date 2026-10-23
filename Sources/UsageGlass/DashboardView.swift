import SwiftUI
import AppKit

private enum Destination: String, CaseIterable, Identifiable {
    case overview = "Overview", codex = "Codex", claude = "Claude", sessions = "Sessions", connections = "Connections"
    var id: String { rawValue }
    var provider: ProviderID? { self == .codex ? .codex : (self == .claude ? .claude : nil) }
    var symbol: String {
        switch self { case .overview: "square.grid.2x2"; case .codex: "terminal"; case .claude: "sparkle"; case .sessions: "list.bullet.rectangle"; case .connections: "point.3.connected.trianglepath.dotted" }
    }
}

struct DashboardView: View {
    @EnvironmentObject private var store: UsageStore
    @State private var destination: Destination = .overview
    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 24) {
                HStack(spacing: 10) {
                    Image(systemName: "chart.bar.xaxis").font(.title2).foregroundStyle(LinearGradient(colors: [UsagePalette.color(0), UsagePalette.color(85), UsagePalette.color(95)], startPoint: .leading, endPoint: .trailing))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Usage Glass").font(.headline)
                        Text("A little more clarity.").font(.caption).foregroundStyle(.secondary)
                    }
                }.padding(.horizontal, 18).padding(.top, 28)
                List(Destination.allCases, selection: $destination) { item in
                    HStack(spacing: 10) {
                        if let provider = item.provider { ProviderMark(provider: provider, size: 16).frame(width: 18) }
                        else { Image(systemName: item.symbol).frame(width: 18) }
                        Text(item.rawValue)
                    }.tag(item).padding(.vertical, 6)
                }.listStyle(.sidebar)
                VStack(alignment: .leading, spacing: 6) {
                    Label("On this Mac", systemImage: "lock.shield").font(.caption.weight(.medium))
                    Text("Usage metadata stays local.").font(.caption2).foregroundStyle(.secondary)
                }.padding(20)
            }.navigationSplitViewColumnWidth(min: 185, ideal: 200, max: 230)
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    switch destination {
                    case .overview: overview
                    case .codex: providerPage(.codex)
                    case .claude: providerPage(.claude)
                    case .sessions: sessionsPage
                    case .connections: connectionsPage
                    }
                }.padding(26).frame(maxWidth: 1100, alignment: .leading).frame(maxWidth: .infinity)
            }
            .background {
                ZStack {
                    Color(nsColor: .windowBackgroundColor)
                    LinearGradient(colors: [UsagePalette.color(0).opacity(0.07), .clear, UsagePalette.color(85).opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing)
                }.ignoresSafeArea()
            }
        }
        .onChange(of: store.activeProvider) { _, active in
            // Follow the tool in use when viewing a provider page; leave other pages alone.
            guard store.followActive, let active, destination == .codex || destination == .claude else { return }
            destination = active == .codex ? .codex : .claude
        }
    }
    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 7) {
                Text(destination.rawValue).font(.system(size: 30, weight: .semibold, design: .rounded))
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
            Toggle(isOn: $store.followActive) { Label("Follow active tool", systemImage: "bolt.horizontal") }
                .toggleStyle(.button).buttonStyle(.glass).help("Switch to Codex or Claude Code automatically as you use them")
            Button { Task { await store.refresh() } } label: {
                Label(store.isRefreshing ? "Refreshing…" : "Refresh", systemImage: "arrow.clockwise")
            }.disabled(store.isRefreshing).buttonStyle(.glass).accessibilityLabel("Refresh usage from local sources")
        }.padding(.top, 12)
    }
    private var subtitle: String {
        switch destination {
        case .overview: "Your limits, with room to plan."
        case .codex, .claude: "Account windows and local session detail."
        case .sessions: "The finest usage detail available on this Mac."
        case .connections: "Read-only sources. Always in your control."
        }
    }
    private var overview: some View {
        VStack(alignment: .leading, spacing: 24) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 16) {
                    ForEach(store.orderedProviders) { provider in QuotaCard(snapshot: store.snapshot(for: provider), inUse: store.followActive && store.activeProvider == provider).frame(minWidth: 265) }
                }
                VStack(spacing: 16) { ForEach(store.orderedProviders) { provider in QuotaCard(snapshot: store.snapshot(for: provider), inUse: store.followActive && store.activeProvider == provider) } }
            }
            sectionTitle("Latest activity", detail: "Local session metadata · not account quota")
            if store.sessions.isEmpty { emptySessions }
            else {
                ForEach(Array(store.sessions.prefix(4))) { session in SessionCard(session: session) }
                Button("View all sessions", systemImage: "arrow.right") { destination = .sessions }.buttonStyle(.plain).foregroundStyle(.teal)
            }
            Label("Account limits and session token totals are different measurements.", systemImage: "info.circle")
                .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
    }
    private func providerPage(_ provider: ProviderID) -> some View {
        LazyVStack(alignment: .leading, spacing: 20) {
            QuotaCard(snapshot: store.snapshot(for: provider), inUse: store.followActive && store.activeProvider == provider)
            sectionTitle("Session breakdown", detail: "Reported fields only · missing values stay unavailable")
            let sessions = store.sessions.filter { $0.provider == provider }
            if sessions.isEmpty { emptySessions }
            ForEach(sessions) { SessionCard(session: $0) }
        }
    }
    private var sessionsPage: some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            Text("Recent local sessions are shown below. Cache and reasoning fields may be subsets of other totals; they are not added again.")
                .font(.callout).foregroundStyle(.secondary)
            if store.sessions.isEmpty { emptySessions }
            ForEach(store.sessions) { SessionCard(session: $0) }
        }
    }
    private var emptySessions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "text.badge.magnifyingglass").font(.title2).foregroundStyle(.secondary)
            Text("No session usage found yet").font(.headline)
            Text("Run a Codex or Claude Code session on this Mac, then refresh. Only recorded usage metadata appears here.").font(.callout).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(24).glassSurface()
    }
    private var connectionsPage: some View {
        VStack(alignment: .leading, spacing: 18) {
            ForEach(ProviderID.allCases) { provider in
                let snapshot = store.snapshot(for: provider)
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 10) { ProviderMark(provider: provider, size: 24); Text(provider.title).font(.title3.weight(.semibold)) }
                    Text(snapshot.status).font(.headline)
                    Text(snapshot.source).font(.callout).foregroundStyle(.secondary).textSelection(.enabled)
                    if let error = snapshot.error { Text(error).font(.caption).foregroundStyle(.secondary).textSelection(.enabled) }
                    if provider == .codex {
                        Text("Uses the installed Codex CLI’s read-only account endpoint and local usage records. Sign in with Codex to make account limits available.").font(.callout).foregroundStyle(.secondary)
                    } else {
                        Text("The optional Claude status-line bridge captures supported usage fields when Claude Code updates its status line. Your existing configuration is backed up and can be restored.").font(.callout).foregroundStyle(.secondary)
                        Text(store.bridgeStatus).font(.caption).textSelection(.enabled)
                        HStack {
                            Button("Connect Claude bridge") { Task { await store.installClaudeBridge() } }.buttonStyle(.glassProminent)
                            Button("Restore previous setup") { Task { await store.uninstallClaudeBridge() } }.buttonStyle(.glass)
                        }
                        Text("After connecting, start or resume Claude Code to populate its status-line snapshot.").font(.caption).foregroundStyle(.secondary)
                        Divider()
                        Text("claude.ai chat limits (experimental)").font(.subheadline.weight(.semibold))
                        Text("Sign in inside this app to read your normal claude.ai limits. Uses an unofficial endpoint that may change; only percentages and reset times are kept, and no browser cookies are read. ChatGPT chat limits are not supported: OpenAI exposes no endpoint for them that this app can use.").font(.caption).foregroundStyle(.secondary)
                        Text(store.webLimits.status).font(.caption)
                        HStack {
                            Button("Connect claude.ai") { store.webLimits.connect() }.buttonStyle(.glass)
                            Button("Disconnect") { Task { await store.webLimits.disconnect(); await store.refresh() } }.buttonStyle(.glass).disabled(!store.webLimits.isConnected)
                        }
                    }
                }.frame(maxWidth: .infinity, alignment: .leading).padding(22).glassSurface()
            }
            Label("No credential-store access or message content retained. Claude connection keeps a private local settings backup.", systemImage: "lock.shield")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
    private func sectionTitle(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.title3.weight(.semibold))
            Text(detail).font(.caption).foregroundStyle(.secondary)
        }
    }
}

struct QuotaCard: View {
    let snapshot: ProviderSnapshot
    var inUse = false
    @State private var showsDetails = false
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                ProviderMark(provider: snapshot.id, size: 24)
                Text(snapshot.id.title).font(.title3.weight(.semibold))
                if inUse {
                    HStack(spacing: 5) { Circle().fill(UsagePalette.color(0)).frame(width: 7, height: 7); Text("IN USE") }
                        .font(.caption2.weight(.bold)).foregroundStyle(.secondary)
                        .padding(.horizontal, 8).padding(.vertical, 3).background(Color.primary.opacity(0.07), in: Capsule())
                }
                Spacer()
                if snapshot.capturedAt == nil { Text("AWAITING DATA").font(.caption2.weight(.medium)).foregroundStyle(.secondary) }
                else if snapshot.isStale { Text("STALE").font(.caption2.weight(.bold)).foregroundStyle(.orange) }
            }
            if snapshot.windows.isEmpty {
                QuotaBar(label: "Account limits", value: nil, reset: nil, tint: snapshot.id.tint)
            } else {
                ForEach(snapshot.windows) { window in
                    QuotaBar(label: window.label, value: window.usedPercent, reset: window.resetsAt, tint: snapshot.id.tint, note: window.note)
                }
            }
            if let stats = snapshot.tokenStats, !stats.isEmpty {
                Divider().opacity(0.5)
                Text("Token activity").font(.subheadline.weight(.semibold))
                TokenStatsView(stats: stats)
            }
            Divider().opacity(0.5)
            VStack(alignment: .leading, spacing: 6) {
                Text(snapshot.status).font(.caption.weight(.medium))
                if !snapshot.details.isEmpty {
                    DisclosureGroup("Account detail", isExpanded: $showsDetails) {
                        VStack(alignment: .leading, spacing: 7) {
                            ForEach(snapshot.details, id: \.self) { Text($0).font(.caption).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading) }
                        }.frame(maxWidth: .infinity, alignment: .leading).padding(.top, 6)
                    }.font(.caption)
                }
                Text(snapshot.source).font(.caption2).foregroundStyle(.secondary)
                if let date = snapshot.capturedAt { Text("Updated \(date.formatted(date: .abbreviated, time: .shortened))").font(.caption2).foregroundStyle(.secondary) }
                if let error = snapshot.error { Text(error).font(.caption2).foregroundStyle(.secondary).lineLimit(4).help(error) }
            }.fixedSize(horizontal: false, vertical: true)
        }.padding(22).frame(maxWidth: .infinity, alignment: .leading).glassSurface()
    }
}

struct QuotaBar: View {
    let label: String
    let value: Double?
    let reset: Date?
    let tint: Color
    var showsReset: Bool = true
    var note: String? = nil
    private var safeValue: Double? { value.flatMap { $0.isFinite ? min(max($0, 0), 100) : nil } }
    private var color: Color { UsagePalette.color(safeValue ?? 0) }
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .firstTextBaseline) {
                Text(label).font(.subheadline.weight(.medium))
                Spacer(minLength: 10)
                Text(safeValue.map { "\($0.formatted(.number.precision(.fractionLength(0))))% used" } ?? (note != nil ? "—" : "Unavailable"))
                    .font(.subheadline.weight(.semibold)).monospacedDigit().foregroundStyle(safeValue == nil ? Color.secondary : color)
            }
            GradientBar(value: safeValue, height: 8)
            HStack {
                if showsReset, let reset { Text("Resets \(reset.formatted(date: .abbreviated, time: .shortened))") }
                else if let note { Text(note) }
                else if showsReset { Text("Reset time unavailable") }
                Spacer()
                if let value = safeValue, value >= 80 { Text(value >= 90 ? "Near limit" : "High usage").foregroundStyle(color) }
            }.font(.caption2).foregroundStyle(.secondary)
        }.accessibilityElement(children: .combine)
    }
}

struct SessionCard: View {
    let session: SessionUsage
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) { ProviderMark(provider: session.provider, size: 18); Text(session.provider.title).font(.headline) }
                    Text(session.scope).font(.caption2).foregroundStyle(.secondary)
                    Text(session.model ?? "Model unavailable").font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
                }
                Spacer()
                Text(session.updatedAt.formatted(date: .abbreviated, time: .shortened)).font(.caption2).foregroundStyle(.secondary)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 115), alignment: .leading)], alignment: .leading, spacing: 15) {
                metric("Input", session.inputTokens)
                metric("Output", session.outputTokens)
                metric("Cached input", session.cachedInputTokens)
                metric("Cache creation", session.cacheCreationTokens)
                metric("Reasoning", session.reasoningTokens)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Estimated cost").font(.caption2).foregroundStyle(.secondary)
                    Text(session.costUSD.map { $0.formatted(.currency(code: "USD").precision(.fractionLength(4))) } ?? "Unavailable").font(.subheadline.weight(.medium)).monospacedDigit()
                }
            }
            if let context = session.contextUsedPercent {
                QuotaBar(label: "Context window", value: context, reset: nil, tint: session.provider.tint, showsReset: false)
                if let size = session.contextWindow { Text("\(size.formatted()) token context capacity").font(.caption2).foregroundStyle(.secondary) }
            }
            Text("Session \(session.id)").font(.system(size: 10, design: .monospaced)).foregroundStyle(.tertiary).lineLimit(1).truncationMode(.middle).help(session.id)
        }.padding(20).frame(maxWidth: .infinity, alignment: .leading).glassSurface()
    }
    private func metric(_ name: String, _ value: Int?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name).font(.caption2).foregroundStyle(.secondary)
            Text(value.map { $0.formatted() } ?? "Unavailable").font(.subheadline.weight(.medium)).monospacedDigit()
        }
    }
}
