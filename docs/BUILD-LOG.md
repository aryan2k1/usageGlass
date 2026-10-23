# Build ledger

## Roles
- Supervisor and scribe/quota monitor: root. A separate scribe spawn was attempted but rejected by the environment's four-thread limit. This role is retained explicitly, not represented as a fifth agent.
- Independent manager: /root/manager, owns review and correction assignment.
- Frontend: /root/frontend, owns SwiftUI, menu bar and packaging.
- Backend: /root/backend, owns models, provider collection, bridge and tests.

## Milestones
1. Inspected macOS/Swift/installed provider versions and official provider docs. Saved DESIGN.md before agents began.
2. Created manager and two builders with disjoint ownership. Created UI-QA.md, SOURCES.md and app icon.
3. Backend live Codex quota initially 45% weekly, then 52%. No secondary window returned. 34 metadata sessions observed. Claude bridge not yet installed.
4. First compiler invocation found macOS v26 enum requires PackageDescription 6.2; frontend raised manifest version. Second build in progress.
5. Manager first review sent lifecycle, accessible menu labels, estimate scope and lazy session rendering fixes to frontend. Backend review sent mixed-model labels, settings preservation, subprocess hard timeout, malformed JSON and null bucket ID corrections.

## Evidence policy
Tests and UI checks are pending unless explicitly marked passed. Current app is not yet packaged or launched. No service credentials extracted. No prompts or response text written into output artifacts.

## Stop protocol
Check backend safe diagnostic quota at meaningful milestones. At >=80% report remaining work; >=90% finish current safe unit and save checkpoint before starting more work. This does not cover hidden platform limits or guarantee warning. Handoff must include exact workspace, build command, failed checks and next actions.
6. Debug build passed in 34.46 seconds after manifest correction. Release packaging started. No UI pass claimed yet.
7. Manager backend correction set covers safe source parsing, timeout/process cleanup, granular optional account activity and reversible Claude configuration.
8. Eight Python backend tests passed via root: quota buckets, allowlist, token dedup/partial scope, exact bridge restore/options, later edits preservation, changed-status-line restore refusal, symlink rejection and bounded tail reads.
9. First release interrupted by concurrent source modification; second release compiled successfully. Packaging then hit generated-bundle extended attributes during ad-hoc signing; delegated to frontend for correction. Backend stale/error fix pending before final rebuild.
10. Signed release launched through computer control. All five pages, account expansion, session scrolling, refresh and real bridge install/restore tested. Exact original Claude settings SHA256 matched after restore.
11. UI findings U1-U5 sent to manager and delegated to builders. Human labels/durations, detail alignment, awaiting-data state and model attribution fixed. Backend suite expanded to13 passing tests.
12. Actual menu popup reached: collapsed usage scroll area discovered (U6). Manager delegated explicit320pt height; final release rebuilt and signed. Visual retest of that popup remains pending because global menu keyboard access was unreliable.
13. Compact window preset tested successfully; quit process exit and relaunch verified. Final live quota seen78% weekly. No additional feature work started.
14. Deliverables copied into task outputs: Usage Glass.app and UsageGlass-Source. Copied bundle's Finder metadata cleared and local signature revalidated successfully.
15. Final portability audit found SwiftPM accessor could use absolute build path; manager delegated critical fix. App now reads backend directly from Contents/Resources. Rebuilt/signed.
16. Portability PASS: temporarily made generated release bundle unavailable, launched delivered outputs app using CUA, observed live Codex86% weekly and session metrics. Restored generated bundle afterward. No user data moved.
17. Final quota86%; ending at safe packaged checkpoint. Remaining optional/manual QA explicitly documented. Final UI showed Claude bridge installed (newer than restore test); newer setting preserved.
