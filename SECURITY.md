# Security

## Model
Everything runs locally. There is no server, analytics or listener. Data is written only to `~/Library/Application Support/UsageGlass` (directory 0700, files 0600).

| Area | What the app does | What it never does |
|---|---|---|
| Claude bridge | Edits `statusLine` in `~/.claude/settings.json` after an explicit click; backs up the exact original; stores only allowlisted numeric/enum fields | store prompts, responses, working directories, transcript paths or API keys |
| Previous status line | Re-runs your own pre-existing command (same trust as Claude Code itself) with a 3 s limit and 64 KB output cap; refuses to run itself recursively | interpolate JSON into a shell command |
| Codex | Talks to the installed CLI's `app-server` over stdio, read-only requests | read Codex credentials or consume reset credits |
| Transcripts | Bounded tail reads (2 MiB) of usage counters | keep message text |
| claude.ai (experimental) | In-app sign-in; hidden view limited to `claude.ai` over https; keeps only percentages and reset times | read Safari/Chrome cookies |

Caveats: `settings.before-usageglass.json` is a copy of your Claude settings (including any values in it) and is kept after restore; delete it if you don't want it. **Disconnect claude.ai** clears local web data but does not log you out server-side; sign out on claude.ai to revoke the session.

## Reviews
An independent review found 15 issues (see [docs/REVIEW.md](docs/REVIEW.md)); the reliability and security ones are fixed and covered by tests.

## Reporting
Open a private security advisory on the GitHub repository, or email the maintainer. Please don't file public issues for vulnerabilities.
