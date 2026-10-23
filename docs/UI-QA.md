# Interactive QA ledger

First signed release tested through macOS computer-control tooling, 23 October 2026. Findings sent to /root/manager, who delegated fixes to frontend/backend.

| Check | Result |
|---|---|
| First launch | Passed: native dashboard renders, live Codex data populates |
| Overview | Passed at1060x740: bars and percentages readable; no radial gauges |
| Codex detail | Passed navigation and expansion; presentation defects U1/U2 sent for fix |
| Claude detail | Passed historical session data/unknown limit; incorrect STALE wording U3 sent for fix |
| Sessions | Passed navigation and scrolling; synthetic model labeling U5 sent for fix |
| Connections | Passed real UI connect and restore; SHA256 confirmed exact original settings bytes restored |
| Refresh | Passed UI remains responsive and live capture times advance |
| Menu bar | Source reviewed; global status item inaccessible to current CUA surface; direct click/popover pending |
| Dashboard close/reopen | CUA observation reopens dashboard; cannot isolate menu-only lifecycle through current tool |
| Minimum window | Edge drag did not resize in CUA; Window menu sizing commands disabled. Dedicated compact-size action requested |
| Appearance | Dark mode visually inspected. Light/Reduce Transparency not interactively exercised |
| Keyboard | CtrlF8 did not expose global status item; keyboard-only navigation not fully verified |
| Quit/relaunch | Pending final package |

## Manager-delegated findings
- U1: Expanded account metadata center aligned; raw camelCase names, unformatted numeric values and duration units. Frontend alignment/backend formatting fixes pending retest.
- U2: Codex quota called Primary instead of7-day duration. Backend correcting.
- U3: Never-captured Claude quota marked STALE. Frontend correcting to Awaiting data.
- U4: Menu C/A ambiguous. Frontend correcting to Cdx/Claude.
- U5: Claude synthetic/system model labels leaking into ordinary records. Backend correcting model attribution.

Backend regression suite:11 passed, independently run by root and manager. No claim that all macOS environments or all account types are verified.

## Final correction retest
- U1/U2 PASS: account details left aligned with grouped numbers/human labels; weekly quota says7-day. Verified via actual compact dashboard screenshot.
- U3 PASS: never-captured Claude quota says AWAITING DATA.
- U4 source checked: Cdx/Claude labels replace C/A. Global label itself not captured visually.
- U5 parser regression/live diagnostic passed: synthetic model handling corrected.
- Compact preset PASS:760-point-wide window stacks provider cards, preserves essential controls and scrolls.
- Quit/relaunch PASS: CmdQ via computer control; process absence verified, then computer-control relaunch succeeded.
- Actual menu popup was reached and Open dashboard worked. Its usage area collapsed visually: critical U6 delegated by manager. Frontend fixed explicit320pt height; final build/sign passed. Automated keyboard navigation could not reliably re-open this popup for a final visual retest. U6 visual retest remains a required manual check, not a claimed pass.
- Menu-only120-second polling and light-mode/reduced-transparency behavior remain unverified interactively. Source reviewed.
- Live Claude quota cannot be verified without a subsequent Claude Code provider response. Historical metrics and real bridge connect/restore tested. Bridge was disconnected after exact restore test; final UI subsequently showed it installed. Newer setting preserved.
- Standalone packaging PASS: delivered app populated live account/session data while SwiftPM release resource bundle was temporarily unavailable. Helper now resolved directly inside app Resources. Generated build bundle restored afterward.
