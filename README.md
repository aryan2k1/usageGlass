# Usage Glass

A native macOS menu-bar app that shows how much of your **Codex** and **Claude Code** limits you have used, at a glance, in a minimal Liquid Glass dropdown, with a full dashboard behind it.

![platform](https://img.shields.io/badge/macOS-26%2B-blue) ![swift](https://img.shields.io/badge/Swift-6.2-orange) ![license](https://img.shields.io/badge/license-MIT-green)

## Features

- **Menu bar summary**: one row per provider with the most-constrained limit, a thin bar, reset time and a stale marker.
- **Codex**: every quota bucket and window the installed Codex CLI returns, plus credits and token activity.
- **Claude Code**: 5-hour and 7-day limits via Claude Code's supported status-line feed, plus context, cost and prompt-cache details.
- **Always something to show for Claude**: the last known limit reading is kept (with its age), and token totals for the last 5 hours / 7 days are derived from local transcripts even before the bridge is connected.
- **claude.ai chat limits (experimental, opt-in)**: sign in inside the app to see your normal claude.ai limits.
- **Dashboard**: overview, per-provider pages, recent sessions with input/output/cache/reasoning tokens, and a Connections page.
- **Private by design**: no cloud service, no analytics, no remote listener, no prompt or response text stored.

## Requirements

- macOS 26 or newer (Apple Silicon build), `/usr/bin/python3` (Xcode Command Line Tools)
- Swift 6.2+ toolchain to build from source
- Optional: Codex CLI/app signed in (for Codex limits), Claude Code (for Claude limits)

## Install

```sh
git clone https://github.com/aryan2k1/usageGlass.git
cd usageGlass
zsh scripts/package.sh          # builds dist/Usage Glass.app (ad-hoc signed)
open "dist/Usage Glass.app"
```

The app is ad-hoc signed, not notarized. If Gatekeeper complains, right-click → Open once.

## Connecting Claude Code

1. Open the dashboard → **Connections** → **Connect Claude bridge**.
2. Start or resume a Claude Code session. Claude Code runs the status-line command after each response and the bridge records the allowlisted fields.

The bridge sets Claude Code's `statusLine` in `~/.claude/settings.json`. Any existing status line is preserved and still runs, the exact original file is backed up, and **Restore previous setup** reverses the change (it refuses if you've edited the status line since). Limits only update while Claude Code is active, so the app shows the reading's age.

### claude.ai chat limits (experimental)

**Connections → Connect claude.ai** opens a sign-in window in the app's own web view. The app then asks claude.ai's own usage endpoint for percentages and reset times and keeps nothing else. No browser cookies are read, and **Disconnect** wipes the web view's data. This endpoint is undocumented and may change or break at any time.

ChatGPT chat limits are **not supported**: OpenAI offers no endpoint for them that this app can use without reading Codex's OAuth credentials, which it deliberately doesn't. ChatGPT-plan Codex limits are shown via the Codex CLI.

## How to read the numbers

Quota percentages, context percentages and token totals are different measures. Unavailable is never shown as zero. Token windows from transcripts are **activity, not quota**. Estimated costs are list-price estimates, not your subscription bill.

## Develop

```sh
swift build
python3 -m unittest discover -s Tests -p 'test_*.py' -v
python3 Sources/UsageGlass/Resources/usageglass_backend.py --diagnostics   # safe provider check
```

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md), [SECURITY.md](SECURITY.md), [docs/SOURCES.md](docs/SOURCES.md), [docs/DESIGN.md](docs/DESIGN.md), [docs/REVIEW.md](docs/REVIEW.md) and [CONTRIBUTING.md](CONTRIBUTING.md).

## Troubleshooting

| Symptom | Fix |
|---|---|
| Claude shows "—" or only tokens | Connect the bridge, then use Claude Code once. |
| Claude marked stale | Limits update only while Claude Code runs; the last reading and its age are shown. |
| Codex unavailable | Open Codex and make sure you're signed in; run the `--diagnostics` command above. |
| claude.ai says "unavailable" | The endpoint may have changed, or sign-in expired: reconnect. |

## License

MIT, see [LICENSE](LICENSE).
