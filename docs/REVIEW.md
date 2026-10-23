# Independent review ledger

Reviewer: manager agent. Status: accepted as a local preview with explicit remaining manual verification.

## Acceptance criteria

- Horizontal usage bars throughout dashboard and menu; no radial gauges.
- Account quotas remain separate from local token/session measurements. Unknown values display unavailable, never zero. Every supported bucket is preserved with source, capture time and reset semantics.
- Native menu-bar entry, working popover actions, dashboard navigation, constrained resizing, accessibility labels and adaptive appearance.
- Reads never expose credential values, prompts, responses or raw provider errors. No network listener, shell interpolation or telemetry.
- Child processes have bounded lifetime and output; polling avoids overlapping work and repeated full-history scans. Malformed/oversized input fails safely.
- Claude bridge setup is explicit, preserves any existing status line, backs up exact prior bytes and provides recovery/removal instructions.
- Parser/integration checks cover missing values, invalid input, repeated cumulative usage, quota bucket preservation and unavailable states.
- Root computer-control QA checks actual packaged app and reports observed UI defects to this manager for builder correction and verification.

## Review rounds

### Round 0: design

Design reviewed: local-first native app, truthful quota semantics, horizontal indicators and explicit Claude setup are appropriate. Implementation evidence pending.

## Findings

No implementation findings yet. This does not signify approval.

## Release decision

Scoped acceptance: local preview only. Code/security review and 13 backend regressions passed. Root verified packaged build/signing, navigation, compact layout, real Claude bridge connect/restore, quit and relaunch. U6 collapsed-menu fix is implemented and included in the rebuilt package but its corrected rendering has not yet been visually verified. Dashboard-closed automatic refresh and appearance/accessibility variants remain manual checks. No claim that every UI path is verified.

### Round 1: installed schema inspection

Generated public protocol schemas with the installed Codex CLI into `../manager-schema` without reading credentials or conversation content. Confirmed the multi-bucket quota map and optional individual spend-control window, credits, model alias and permission metadata. Confirmed `account/usage/read` supports account activity or optional `threadId` with model/reasoning-effort/speed groups and token/cost estimates. Builders instructed to expose the finest optional metadata and coordinate UI models. Reset-credit consumption is outside scope; only read APIs are permitted.

### Round 2: frontend initial review

- F1 (release blocker): dashboard-owned `.task` polling stops when dashboard closes, leaving menu-only app stale. Delegated lifecycle ownership fix to frontend in coordination with backend.
- F2: menu accessibility label omits current percentages and freshness. Delegated dynamic accessible status.
- F3: cost must be identified as an estimate, and current context must not imply cumulative session scope. Context bars should not say reset time unavailable. Delegated presentation correction.
- Initial layout review: horizontal bars, unknown values, adaptive card stack and readable metric grid implemented. Actual dimensions and interaction remain subject to root UI QA.

### Round 3: backend initial review

- B1: mixed-model local session totals incorrectly attributed to the latest model. Require explicit latest-model scope or separate aggregation.
- B2: installing bridge discards prior status-line display/refresh options. Preserve options while substituting command.
- B3 (release blocker): inherited output pipes and surviving subprocess descendants can evade timeout; Swift output bound is only checked after unbounded read. Require bounded output and process-group cleanup.
- B4: malformed JSON shapes can fail whole collection. Require defensive shape checks and provider failure isolation.
- B5: preserve optional spend period and expose bounded per-thread official model/reasoning/speed groups for requested granular usage.
- B6: null fallback limit ID membership check can overwrite the existing codex bucket. Normalize key before insertion.

All findings sent directly to backend owner; correction and regression evidence pending.

### Round 4: correction verification

Source review confirms B1 latest-model/mixed-total scope, B2 option preservation, B6 normalized fallback, F2 accessible menu status, F3 estimated cost/no context reset, F4 lazy sessions. F1 polling moved to menu-label lifecycle; root must test dashboard closed for an interval. B3 now uses incremental Swift reads with a 4 MiB cap and SIGKILL deadline, plus prior statusline process-group cleanup and 64 KiB output cap; regression tests requested. B4 corrupt Claude snapshot isolated to that provider. B5 bounded latest-local-task official group detail added; truthful task identity wording requested. Manager independently ran eight backend tests: all passed (2026-10-23).

### Round 5: backend regression closure

Manager independently reran all 11 backend tests: PASS in 3.125 seconds. Regression coverage includes timed-out descendant command, 64 KiB prior-command output bound, null legacy fallback, malformed bridge shapes, usage-only allowlist, cumulative/duplicate handling, tail size bound, exact restoration, unrelated settings preservation and symlink rejection. Error-bearing retained readings now count as stale. B1–B6 closed for the implemented bounded scope. Official billing group availability is conditional; no unavailable group is invented. Build and UI acceptance remain open.

Known implementation boundaries: local history is bounded, model labels describe the latest model when local totals span models, official task breakdown covers the latest local task only, and the helper requires an available `/usr/bin/python3` runtime. These are documented limitations, not complete historical analytics.

### Round 6: root interactive QA delegated

Root reported working navigation and real UI Claude bridge connect/restore with exact original settings SHA-256 restored. UI corrections delegated:

- U1 backend: human-readable detail labels, formatted numbers/durations/boolean values; frontend: left-aligned expanded rows.
- U2 frontend: quota labels use actual window duration and retain bucket identity.
- U3 frontend: never-captured state says awaiting data; stale reserved for previously captured readings.
- U4 frontend: unambiguous compact menu provider labels.
- U5 backend: system-only synthetic records must not present a fabricated real model.

Await correction reports and root re-test. Root observed active quota at 63%; safe continuation remains under checkpoint threshold.

### Round 7: UI tooling boundaries

Root computer-control surface cannot access the global menu-bar status item; SystemUIServer selection times out, and its app queries reactivate the dashboard. Consequently the menu popover, dashboard-closed polling and global menu reopening are not claimed as UI passes. Source review confirms polling moved off dashboard lifecycle. Frontend assigned useful Compact/Comfortable window menu presets to enable reproducible small-window QA where direct window dragging is unavailable. New defensive F5: clamp finite percentages before integer conversion in menu label, matching bar behavior.

### Round 8: UI correction code verification

U1/U2/U5 backend fixes inspected: readable labels, grouped counts, explicit duration/USD/microcredit units, actual quota window duration, and zero-only synthetic records excluded. Cache version changed to invalidate prior results. Manager independently ran 13 regression tests: PASS in 3.144 seconds. Frontend U1/U3/U4/F5 fixes inspected: left-aligned expandable rows, awaiting data status, clear provider labels and bounded integer conversion. Compact/Comfortable View commands added for reproducible layout verification.

Privacy wording corrected: parsing necessarily reads transcript bytes before selecting usage fields; message content is neither retained nor displayed. Exact Claude settings backup can include sensitive user settings and is protected with mode 0600; UI must disclose the private settings backup and avoid an absolute no-credentials-saved claim. Root requested this audit correction and owns final README wording.

### Round 9: actual menu popup defect

Root subsequently reached the actual menu popup through keyboard/accessibility. This supersedes the earlier tooling block for popup interaction. Screenshot exposed U6 (release blocker): popup only 340×130 and scrolling quota body collapsed because it had only a maximum height. Frontend assigned a fixed visible scrolling body height; actual screenshot retest required before release. Dashboard-closed polling still requires its own evidence.


### Final scoped decision

Root final QA reports: compact 760-point preset stacks cards without overlap; expanded detail labels/alignment and awaiting-data states pass; Cmd-Q process exit and relaunch pass. Actual menu opening and Open dashboard action passed before U6; the 320-point scroll-body correction is source-verified and packaged, but unreliable computer-control access prevented a final popup screenshot.

Accept delivery as a local preview with these remaining checks prominently documented:

1. Open the rebuilt menu popup and verify both providers’ horizontal bars remain visible, scrolling, Refresh/Open dashboard/Quit work.
2. Close dashboard, leave app running for more than 120 seconds, then verify menu-only automatic refresh.
3. Verify light appearance, reduced transparency and VoiceOver in real macOS settings. Dark appearance was screenshot-tested throughout root UI QA.

No unresolved known code defect from the review loop remains, but U6 rendering is unverified and prevents claiming fully tested release status. No additional feature work is authorized by this review. Last root-reported quota: 78%, below the 90% safe-stop threshold; root owns final checkpoint.

### Portability release blocker reopened

Root final packaging inspection found the generated SwiftPM resource accessor searches a bundle path outside `Contents/Resources`, then an absolute build-tree fallback. Prior successful local launch therefore did not establish standalone portability. Backend assigned lazy packaged-resource lookup before any `Bundle.module` evaluation. Delivery acceptance is suspended until rebuilt app works with the build-tree resource bundle unavailable. Originals must be preserved and restored during this regression test.

### Portability blocker closed

Root rebuilt and signed the delivered outputs app, temporarily made the release build-tree resource bundle unavailable, then used computer control to launch/refresh the delivered app. It populated live Codex quota (86% weekly) and session metadata successfully. Backend app branch uses only the direct bundled Python helper and never evaluates `Bundle.module`; packaging copies that helper before signing. Root is restoring the original build resource bundle. Standalone resource resolution is verified and the portability blocker is closed.

Final decision returns to local-preview acceptance with the previously documented manual UI checks. Quota is 86%; stop feature work and preserve checkpoint/handoff before the 90% threshold. No further code changes requested.
