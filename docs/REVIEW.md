# Independent review

An independent reviewer (fresh agent, no prior context, read-only) audited the Swift and Python sources for bugs and security issues. Result: no command injection or credential/prompt leakage found; the allowlist, symlink handling, permissions and bounded I/O were judged sound. Findings and outcome:

| # | Severity | Finding | Status |
|---|---|---|---|
| 1 | High | A hung claude.ai page load could freeze all refreshes | Fixed: 20 s timeout, process-termination handler, web refresh decoupled from main refresh |
| 2 | Med-High | Missing state file let the bridge record and run itself recursively | Fixed: refuse own command, recursion env guard, `-I` |
| 3 | Medium | Failed install left a stale state file blocking retry | Fixed: state removed on failure; tested |
| 4 | Medium | An early/sessionless status-line tick wiped the last good limits | Fixed: previous `rate_limits` retained |
| 5 | Medium | 3000-entry scan cap could drop newest transcripts | Fixed: cap raised to 50,000 entries, then sorted by mtime |
| 6 | Medium | Token windows undercounted streaming messages; partial flag lost | Fixed: max usage per message, `partial` shown |
| 7 | Medium | Killing the helper could orphan `codex app-server` | Fixed: SIGTERM handler, always follow with group SIGKILL |
| 8 | Med-Low | Shared delegate/continuation; login close marked connected | Fixed: login view has no shared delegate; connected only after leaving `/login`; single window |
| 9 | Low-Med | Disconnect is local only | Documented |
| 10 | Low-Med | Hidden view followed any https redirect | Fixed: restricted to `claude.ai` hosts |
| 11 | Low | No fsync; settings re-serialised compactly | Accepted; backup + exact restore mitigates |
| 12 | Low | Interpreter honoured `PYTHONPATH` | Fixed: `python3 -I` |
| 13 | Low | Duplicate web windows on retained snapshots | Fixed: rebuilt each refresh |
| 14 | Low | Huge numbers could break decoding | Fixed: values clamped to 2^53; malformed daily buckets skipped |
| 15 | Info | Settings backup kept; installed script not auto-updated; bridge needs `/usr/bin/python3` | Documented |

Verification: 19 backend tests pass; `swift build` clean. Menu-bar popover rendering and the live claude.ai endpoint were not exercised interactively in this review.
