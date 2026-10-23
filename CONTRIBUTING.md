# Contributing

1. Fork and branch from `main`.
2. `swift build` and `python3 -m unittest discover -s Tests -p 'test_*.py' -v` must pass.
3. Backend changes need a test that runs in a temp `HOME` (see `Tests/test_backend.py`).
4. Keep the privacy model: allowlist fields, never store prompts/responses, never read credentials or browser cookies, no new network listeners or analytics.
5. Open a PR describing what changed and how you verified it.

Report security issues privately, see [SECURITY.md](SECURITY.md).
