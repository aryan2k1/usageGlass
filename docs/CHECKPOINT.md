# Resume checkpoint

Status: working local app packaged;13 backend tests pass; manager review and UI correction loops completed with narrowly scoped manual QA outstanding.

## Locations
- Working source: /Users/aryansingh/Documents/Codex/2026-10-23/i-x20/work/UsageGlass
- Delivered app: /Users/aryansingh/Documents/Codex/2026-10-23/i-x20/outputs/Usage Glass.app
- Delivered source/docs: /Users/aryansingh/Documents/Codex/2026-10-23/i-x20/outputs/UsageGlass-Source

## Team and progress
Root served supervisor+scribe/quota-monitor due four-thread hard cap. /root/manager independently reviewed and delegated fixes to /root/frontend and /root/backend. DESIGN.md was written before implementation. REVIEW.md has security/data/UI findings; UI-QA.md distinguishes actual passes from pending checks.

## Verified
Native SwiftUI glass dashboard and five pages; horizontal bars; live Codex weekly limit, account metadata and session tokens; local Claude history. Exact live Claude settings restoration through UI.13 parser/bridge/process tests passed. Compact window layout, account details, refresh, quit/relaunch tested. App ad-hoc signed and strict signature verified in outputs.

## Next safe unit
1. Open delivered app. Click its macOS menu-bar item directly and confirm both usage bars now visible (U6 fixed to320pt; previous collapse caught through computer testing, final visual retest still pending).
2. Close dashboard, wait >120seconds, reopen menu/dashboard and verify fresh Codex capture. CUA reopened window during observation, so isolation was not proven.
3. Check light appearance and Reduce Transparency if desired. Dark mode tested only.
4. Connections→Connect Claude bridge, then start/resume Claude Code and obtain a provider response to verify actual live Claude quota. Bridge was disconnected after restore test, but final UI subsequently showed it installed; preserve that newer setting. No fake quota seeded.

## Commands
swift build
python3 -m unittest discover -s Tests -p 'test_*.py' -v
zsh scripts/package.sh
python3 Sources/UsageGlass/Resources/usageglass_backend.py --diagnostics

## Limits and stopping
Latest observed Codex quota78% weekly; earlier checkpoints45/52/56/62/71/76%. Check live diagnostic before more work. At80% warn and focus remaining verification; at90% finish current safe unit and checkpoint. Hidden quota/context limits cannot be guaranteed detectable.

No billing changes, messages sent, remote hosting or credentials extracted. Private Claude configuration backup retained in Application Support; original settings restored exactly. App requires macOS26+, Apple Silicon build, installed Codex CLI and system Python/developer tools. It is locally signed, not notarized.

Final update: quota86% weekly. Stop new work here. Critical portability issue corrected and actual delivered app verified with build resources unavailable. Recheck quota before next session. Latest UI showed Claude bridge installed after earlier restore test; preserve current settings. Manual popup/lifecycle/appearance checks remain as above.
