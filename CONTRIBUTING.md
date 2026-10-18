# Contributing to agy-quota-guard

Issues and pull requests are welcome. This document explains how to set up the development environment, run tests, and adhere to Antigravity CLI plugin conventions and core design principles.

## Setup

The runtime codebase requires only Python's standard library:

- Python 3.10+
- `git` (for testing hard-revert and repository status checks)
- `pytest` (`python -m pip install pytest`)
- Google Antigravity CLI (`agy`) for live plugin validation

## Running Tests

Run the test suite and plugin validation locally before pushing:

```bash
# Unit and integration test suite
python -m pytest -q

# Antigravity strict plugin manifest and hook validation
agy plugin validate . --strict
```

The test matrix runs across Ubuntu, macOS, and Windows via GitHub Actions (`.github/workflows/ci.yml`).

## Design Principles

If your change touches quota detection, lifecycle hooks, or the runner:

1. **Fail Open:**
   If quota cannot be determined (CLI timeout, network drop, or unexpected JSON structure), hooks and the runner must never crash Antigravity or block user tool execution.

2. **Antigravity Hook Contracts:**
   - **PostToolUse:** Must strictly return `{}` per the Antigravity hook schema. Never return decision or denial objects from PostToolUse. State tracking (`.agy-quota/todos_state.json`) and checkpoint observation happen silently.
   - **PreInvocation:** Injects soft or hard stop instructions via `{"injectSteps": [{"userMessage": ...}]}` before the model runs, giving the model an opportunity to save its checkpoint.
   - **PreToolUse:** Denies tool calls (`{"decision": "deny", "reason": ...}`) once a quota stop is active, but explicitly allows writes to `.agy-quota/progress.md`.
   - **PostInvocation:** Terminates the round (`"terminationBehavior": "terminate"`) only after a checkpoint opportunity has been provided or on forced hard stop.

3. **Opt-in for Destructive Actions:**
   Hard abort automatic revert (`git stash`) is disabled by default and requires explicit user opt-in via environment variable (`AGY_HARD_ABORT=1`). Automatic revert must only trigger if the task started on a clean working tree (`checkpoint_clean: true`), and must verify that `refs/stash` actually changed before marking an item `reverted` / `pending`.

4. **Credential-Free Quota Inspection:**
   Never read tokens, session keys, or credential files from disk (`~/.gemini/` or environment tokens). Quota is read exclusively via `agy -p "/usage" --output-format json`.

5. **Exact Conversation Resumption:**
   The runner (`agy-run`) must capture the exact conversation ID and resume strictly with `agy --conversation <ID> -p`. Never fall back to `-c` or `--continue` to avoid resuming the wrong session.

## Adding a Language

Adding a new language is as simple as creating `locales/<lang_code>.json` following the keys in `locales/en.json`. No Python code changes are required.

## License

By contributing, you agree that your contributions are licensed under the [MIT License](LICENSE).
