# agy-quota-guard

Quota-aware execution guard and auto-resume runner for **Google Antigravity CLI (`agy`)**.

`agy-quota-guard` monitors your 5-hour session and 7-day weekly quota buckets via `agy -p "/usage" --output-format json` without reading or modifying any authentication/credential files. When quota thresholds are reached, it coordinates a clean checkpoint into `.agy-quota/progress.md`, sleeps until the latest triggered quota window resets, and resumes the exact conversation by ID (`--conversation <ID>`).

## Features

- **Credential-free Quota Inspection (`scripts/usage.py`)**: Reads `.command.data.groups[].buckets[]` from `agy -p "/usage" --output-format json`, computes used percentage from `remaining_fraction`, preserves the full list of quota windows, and filters relevant buckets by active `modelName` / `--model` (`Gemini Models`, `Claude and GPT models`, `Gemini 4 Argon`).
- **Native Antigravity Lifecycle Hooks (`hooks.json`, `scripts/quota_gate.py`)**:
  - `PostToolUse`: Always outputs `{}` per the Antigravity hook contract while tracking `task_boundary` / `TodoWrite` / `Task*` / `update_plan` state in `.agy-quota/todos_state.json` and detecting `.agy-quota/progress.md` checkpoint writes.
  - `PreInvocation`: Injects soft/hard stop checkpoint instructions via `injectSteps` before the model runs so the model can save its checkpoint before termination.
  - `PreToolUse`: Denies non-checkpoint tool calls (`{"decision": "deny"}`) once a quota stop is active while explicitly allowing writes to `.agy-quota/progress.md`.
  - `PostInvocation`: Terminates the loop (`"terminationBehavior": "terminate"`) after the model has had the opportunity to write a checkpoint, logging an explicit missing-checkpoint warning if a hard stop forced termination before `.agy-quota/progress.md` was updated.
- **Safe Opt-In Hard Revert**: `hard_abort_enabled` is disabled by default and can only be enabled via environment variable (`AGY_HARD_ABORT=1`). Even when enabled, it only stashes if the task started on a clean working tree (`checkpoint_clean: true`) and verifies that `refs/stash` actually changed before marking an item `reverted` / `pending`.
- **Cross-Platform Python Runner (`scripts/agy_runner.py`, `bin/agy-run`, `bin/agy-run.cmd`)**:
  - Accepts arbitrary-length prompts via positional arguments or `stdin`.
  - Captures the exact conversation ID and resumes strictly with `agy --conversation <ID> -p` (never falls back to `-c` / `--continue`).
  - Terminates the entire CLI process tree on round timeout (`AGY_ROUND_TIMEOUT`).
  - Sleeps until the latest triggered `resets_at` + `AGY_RESUME_BUFFER` and stops when `^AGY_QUOTA_DONE` appears in `.agy-quota/progress.md`.

## Installation

### Unix / macOS / Linux / Git Bash
```bash
./install.sh
```

### Windows PowerShell
```powershell
.\install.ps1
```

Or validate and install via the Antigravity CLI plugin manager:
```bash
agy plugin validate .
agy plugin install .
```

## Usage

```bash
# Positional task
agy-run "Refactor the authentication module and run unit tests"

# Multi-line specification via stdin
agy-run < spec.md

# Specify model and permission mode
agy-run --model gemini-2.5-pro --mode accept-edits < spec.md
```

## Configuration

Project-level thresholds can be placed in `.agy-quota/config.json`:
```json
{
  "session_soft_limit": 80,
  "session_hard_limit": 95,
  "weekly_soft_limit": 97,
  "weekly_hard_limit": 98,
  "language": "en"
}
```
Security-sensitive settings (`AGY_HARD_ABORT=1`, `AGY_NOTIFY_URL=https://ntfy.sh/my-topic`) are read exclusively from environment variables, never from repository config files.
