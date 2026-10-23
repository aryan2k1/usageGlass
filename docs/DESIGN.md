# Usage Glass: design and build plan

## Product
A native, local-first macOS menu-bar utility and resizable dashboard for Codex and Claude Code. Display the finest supported account quota buckets and local session metrics, retaining source, capture time and unavailable states. Account quota is never inferred from token counts. No circular gauges.

## Design language: Quiet instrumentation
Use native SwiftUI Liquid Glass on macOS 26+, system materials as fallback. Sidebar 200pt, dashboard ideal 1060x740, minimum 760x560. Background softly tinted graphite in dark mode and pearl in light mode; adaptive system foregrounds. Rounded surfaces 18pt, 24pt page spacing, 16pt card spacing. SF system text, monospaced numbers, large restrained headings. Codex teal and Claude warm amber accents. Horizontal capsule bars 7pt high with numerical used percentages and reset labels. Warning >=80%, critical >=95%, always accompanied by text. Unknown renders an empty neutral track labelled unavailable, never 0%. Respect reduced transparency/motion and accessibility labels.

## Screens
Overview: title, freshness and refresh; two provider quota cards; session token breakdown. Provider navigation filters detail. Sessions: local session list with model, timestamp and input/output/cache/reasoning metrics where available, clearly labelled scope. Connections: read-only source status and Claude bridge setup instructions. Menu popover: compact provider bars, refresh, open dashboard, quit. Menu title remains compact with both providers and unknown markers.

## Integration and security
Codex: installed CLI app-server stdio, read-only account/rateLimits/read with bounded process lifetime, plus local JSONL usage metadata when needed. Preserve all returned buckets. Claude: supported status-line JSON bridge, local session JSONL metadata. Never scrape browser cookies or read credential values. No prompts or response bodies persisted. Read only usage fields; sanitize any errors. No external analytics, shell interpolation or remote listener. Poll asynchronously, avoid scanning entire history every minute. Settings modifications must preserve existing status line, back up exact prior bytes and be reversible; prefer explicit in-app connect action.

## Build sequence and review
1. Design and capability research (this document).
2. Manager independently reviews frontend and backend work; builders own disjoint files and report evidence to manager.
3. Dedicated scribe records changes and handoff after a worker slot frees; supervisor maintains checkpoint until then. Four concurrent slots constrain simultaneous roles, not total team size.
4. Compile and focused parser/integration tests; manager sends findings to owners, verifies fixes.
5. Launch packaged app, computer-control test dashboard, menu bar, navigation, resize and connection states. Send observed defects to manager for delegation, retest fixes.
6. Deliver app, source, build instructions, review ledger and honest limitations.

## Continuity
Write CHECKPOINT.md after every milestone. Observe available Codex quota snapshots at stage boundaries. At >=90% used in a relevant active quota, finish the current safe unit, record remaining tasks and verification, then stop new work. Unknown quota is unknown, never a guarantee. No agent can promise advance notice for hidden platform/context limits.

## References checked 2026-10-23
- https://learn.chatgpt.com/docs/app-server (account/rateLimits/read and account/usage/read)
- https://code.claude.com/docs/en/statusline (rate_limits, context, cost and session metadata)
- https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views
