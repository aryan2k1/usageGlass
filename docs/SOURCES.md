# Provider sources and interpretation

Checked 23 October 2026. Installed versions at initial inspection: macOS 27.0, Swift 6.3.2, macOS SDK 26.5, Codex CLI 0.155.0-alpha.16.3, Claude Code 2.1.251.

## Codex
Official protocol: https://learn.chatgpt.com/docs/app-server

The app-server exposes read-only account limit and usage requests. Preserve separately metered limit IDs rather than collapsing their usage into a fictional combined percentage. Window duration and reset timestamps come from the service. Additional credit/spend/activity fields depend on the installed CLI schema and account response. Local transcript token metrics are observed activity, not a conversion into subscription allowance. Requests must not consume reset credits or change billing.

## Claude Code
Official status-line schema: https://code.claude.com/docs/en/statusline

The locally executed status-line command receives JSON containing supported rate-limit windows after a provider response. Availability depends on account and version. The bridge receives data as Claude Code updates its status line, rather than making an independent authenticated usage request. Therefore its capture time matters. A stale bridge snapshot cannot establish present remaining allowance.

The context_window total input/output fields describe current context from the latest response, not lifetime session totals. Local assistant usage records can provide separate observed token totals. Cache-read and cache-write counts must be interpreted according to the provider's token convention. Displayed estimated list-price cost is not necessarily the subscription bill.

## Native design
Apple API: https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views

Native SwiftUI glass effects are used where the available SDK permits, with material fallback and accessibility treatment. All quota visualisations use horizontal bars with textual values and timestamps.

## Boundaries
No browser cookies, raw credentials, message bodies, analytics service or remote listener are needed. This utility cannot reveal a provider breakdown the service does not expose. Missing data is unavailable, not zero. See REVIEW.md and UI-QA.md for verified capability and remaining limitations.
