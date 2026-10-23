# Usage Glass

A native macOS dashboard and menu-bar utility for Codex and Claude Code usage. Built with SwiftUI Liquid Glass, horizontal quota bars and local usage metadata.

## Run
Open **Usage Glass.app**. Requires macOS26 or newer, Apple Silicon for the supplied build, and `/usr/bin/python3` (provided by Apple's developer tools on the tested Mac). The app is locally ad-hoc signed, not notarized for distribution.

Codex uses an installed, already signed-in CLI. Claude historical sessions are read locally. For current Claude quota, open **Connections → Connect Claude bridge**, then start/resume Claude Code so it emits its supported status-line data. Limits may remain unavailable until a provider response. The bridge preserves a previous status-line command and its options. **Restore previous setup** reverses the connection; it refuses to overwrite a status line you subsequently changed.

## Available detail
- Codex: every returned quota bucket/window, reset time, account credit/spend metadata when supplied, token activity summary and recent daily buckets. The latest local task's official billing/model/effort breakdown is attempted when supported and labelled unavailable otherwise.
- Claude: supported5-hour/7-day/gateway spend limits via status-line feed; context and cache details when emitted. Local transcript tokens expose input/output/cache reads/cache creation, with reasoning/cost only where reported.
- Session metadata has explicit scope: cumulative snapshots, unique API-message totals, or partial recent transcript. Model labels disclose mixed/last-recorded attribution.
- Menu summary shows the highest reported used percentage for each provider, with per-window detail in the popup.

Quota percentages, context percentages and token totals are different measures. An unavailable field is never treated as zero. Estimated costs are not necessarily your subscription bill. The app cannot invent finer breakdowns than the provider makes available.

## Privacy and behavior
No browser cookies or provider credential-store files are extracted. No prompt or response text is saved by the collector. Connecting Claude creates a private local backup of its settings, including any values already present in that configuration. Usage data remains on this Mac. Provider calls use the installed Codex CLI's existing authentication over stdio; there is no remote listener or analytics service.

Polling occurs every120seconds. Recent local history scanning is bounded (up to30 recent files per provider and2MiB per file; Codex date folders cover the last7days); partial reads are labelled. Claude data updates when its status line runs, so old snapshots remain visibly stale. App settings/bridge backups live in the user's Application Support UsageGlass directory. Exact paths are documented by the source. The app does not interrupt coding sessions or change billing limits.

## Build and test
```sh
swift build
python3 -m unittest discover -s Tests -p 'test_*.py' -v
zsh scripts/package.sh
```
Requires Swift6.2+ package tools and macOS26+ SDK. Output: `dist/Usage Glass.app`. No third-party Swift/Python dependencies.

Safe provider diagnostic (no credentials or message text):
```sh
python3 Sources/UsageGlass/Resources/usageglass_backend.py --diagnostics
```

## Project records
- `docs/DESIGN.md`: design language and original plan
- `docs/SOURCES.md`: provider documentation and interpretation
- `docs/REVIEW.md`: independent manager findings and fixes
- `docs/UI-QA.md`: actual computer-control results and remaining manual checks
- `docs/BUILD-LOG.md`: work log, role allocation and quota checkpoints
- `docs/CHECKPOINT.md`: next-session entry point

The four-agent environment limit meant root handled the scribe/quota-monitor role, while manager, frontend and backend stayed separate. The manager reviewed implementation and delegated corrections from both code review and interactive UI QA.
