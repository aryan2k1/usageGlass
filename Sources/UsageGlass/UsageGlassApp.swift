import SwiftUI
import AppKit

@main
struct UsageGlassApp: App {
    @StateObject private var store = UsageStore()
    var body: some Scene {
        Window("Usage Glass", id: "dashboard") {
            DashboardView().environmentObject(store)
                .frame(minWidth: 760, minHeight: 560)

        }
        .defaultSize(width: 1060, height: 740)
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Refresh Usage") { Task { await store.refresh() } }.keyboardShortcut("r")
            }
            CommandGroup(after: .sidebar) {
                Divider()
                Button("Compact window") { resizeDashboard(width: 760, height: 560) }
                Button("Comfortable window") { resizeDashboard(width: 1060, height: 740) }
            }
        }
        MenuBarExtra {
            MenuPanel().environmentObject(store)
        } label: {
            MenuLabel().environmentObject(store)
                .task {
                    await store.refresh()
                    await store.refreshWebLimits()
                    while !Task.isCancelled {
                        try? await Task.sleep(for: .seconds(120))
                        if !Task.isCancelled { await store.refresh(); await store.refreshWebLimits() }
                    }
                }
        }
        .menuBarExtraStyle(.window)
    }
    @MainActor private func resizeDashboard(width: CGFloat, height: CGFloat) {
        guard let window = NSApp.windows.first(where: { $0.title == "Usage Glass" && !($0 is NSPanel) }) else { return }
        let oldFrame = window.frame
        window.setContentSize(NSSize(width: width, height: height))
        var frame = window.frame
        frame.origin.x = oldFrame.origin.x
        frame.origin.y = oldFrame.maxY - frame.height
        if let screen = window.screen {
            frame.origin.x = min(max(frame.minX, screen.visibleFrame.minX), max(screen.visibleFrame.minX, screen.visibleFrame.maxX - frame.width))
            frame.origin.y = max(frame.minY, screen.visibleFrame.minY)
        }
        window.setFrame(frame, display: true, animate: false)
    }
}

extension ProviderID {
    var tint: Color { self == .codex ? Color(red: 0.12, green: 0.66, blue: 0.60) : Color(red: 0.80, green: 0.44, blue: 0.25) }
    var symbol: String { self == .codex ? "terminal" : "sparkle" }
}

struct GlassSurface: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    func body(content: Content) -> some View {
        if reduceTransparency {
            content.background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 20))
        } else {
            content.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
        }
    }
}
extension View { func glassSurface() -> some View { modifier(GlassSurface()) } }
