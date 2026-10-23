# Architecture

```
SwiftUI app (Sources/UsageGlass)            Python helper (Resources/usageglass_backend.py)
 UsageGlassApp  MenuBarExtra + Window  ──►   --collect      JSON snapshots + sessions
 UsageStore     polls every 120 s            --install / --uninstall   Claude bridge
 Providers      runs helper (25 s watchdog)  --bridge       status-line command
 MenuPanel / DashboardView                   --diagnostics  safe provider check
 WebLimits      claude.ai (opt-in WKWebView)
```

## Data sources

| Provider | Source | Gives |
|---|---|---|
| Codex | `codex app-server` over stdio (`account/rateLimits/read`, `account/usage/read`) | all quota buckets, credits, activity |
| Codex | `~/.codex/sessions` (last 7 days, bounded) | per-session tokens |
| Claude Code | status-line bridge → `~/Library/Application Support/UsageGlass/claude-usage.json` | 5h/7d limits, context, cost, cache |
| Claude Code | `~/.claude/projects/**/*.jsonl` (bounded tail reads) | session tokens; 5h/7d token activity fallback |
| claude.ai | opt-in web sign-in, same-origin usage endpoint | chat limit percentages (experimental) |

## Key behaviours

- **Allowlist everything.** `safe_bridge_payload` keeps only numeric/enum fields; prompts, paths and unknown keys are dropped.
- **Bounded work.** Files ≤ 2 MiB tail reads, ≤ 3000 directory entries, child processes killed by process group on timeout, session scan cached for 5 minutes.
- **Staleness.** Codex is stale after 5 min; Claude after 6 h because it only updates while Claude Code runs. A quota window whose reset time has passed is shown as unavailable rather than as a old percentage.
- **Bridge safety.** Settings writes are atomic (temp file + rename, mode 0600), symlinks are rejected, the original bytes are backed up, and uninstall only proceeds if the status line is still the one installed.
- **Menu.** For each provider the highest percentage across windows drives the bar; token-only windows never fake a percentage.

## Files

- `Models.swift` snapshot/session types · `Providers.swift` helper process runner · `UsageStore.swift` state and polling
- `MenuPanel.swift` menu bar label and dropdown · `DashboardView.swift` dashboard, cards, bars
- `WebLimits.swift` experimental claude.ai adapter
- `Tests/test_backend.py` backend regression tests (temp-dir sandboxed)
