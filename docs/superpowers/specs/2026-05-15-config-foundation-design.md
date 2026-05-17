# Plugin Config Foundation — Design Spec

**Issue:** [#22](https://github.com/altraWeb/laravel-superpowers/issues/22)  
**Milestone:** V2-MVP  
**Status:** Design draft — pending review  
**Author:** altraWeb + collaborator  
**Date:** 2026-05-15

---

## 1. Context & Motivation

V2-MVP introduces 6 hooks (#16–21) and 1 slash command (#23) that all need per-project + per-user config knobs (hook enable/disable, banned-token lists, audit aggressiveness, etc.).

Without a config foundation, hooks would be all-or-nothing and non-overridable — operators couldn't disable a single misfiring hook without forking the plugin, and project-specific banned tokens would have to be hardcoded.

#22 is a blocker for #16–21 and #23. It is the foundation that all later V2-MVP infrastructure builds on.

## 2. Goals & Non-Goals

**Goals**

- Single source of truth for plugin defaults
- Per-user override (`~/.claude/plugins/altraweb-laravel/laravel-superpowers/config.yaml`)
- Per-project override (`.laravel-superpowers.yaml` in cwd)
- Lazy reads at hook fire-time (no daemon)
- Schema-validated YAML (catches typos before hooks fire)
- IDE autocomplete via JSON Schema
- Defensive: hook failures from missing/broken config never block user operations

**Non-Goals**

- Hot reload / file watching (lazy read per call is fine)
- Slash-command wrapper (`/laravel-livewire-superpowers:config`) — that is #23
- Per-hook config integration — each hook issue (#16–21) handles its own
- Migration tooling between config schema versions (handled later if/when schema breaks)

## 3. Architecture

### 3.1 File Layout (plugin repo)

```
laravel-superpowers/
├── .claude-plugin/
│   ├── marketplace.json
│   └── plugin.json
├── lib/
│   └── config.py                # Helper CLI: get / show / validate / init / doctor
├── config.defaults.yaml         # Plugin defaults (canonical, self-documenting via comments)
├── config.schema.json           # JSON Schema for validation + IDE autocomplete
├── tests/
│   └── test_config.py           # Pytest suite for the helper
├── agents/...                   # (existing)
├── skills/...                   # (existing)
├── hooks/...                    # (added per #16–21)
└── docs/
    └── config.md                # User-facing config reference
```

### 3.2 Config Paths & Precedence

| Layer | Path | Precedence |
|---|---|---|
| Defaults | `$PLUGIN_DIR/config.defaults.yaml` | lowest |
| User-global | `~/.claude/plugins/altraweb-laravel/laravel-superpowers/config.yaml` | middle |
| Per-project | `<cwd>/.laravel-superpowers.yaml` | highest |

Merge strategy: **deep recursive**. Nested keys can be overridden individually without repeating the surrounding block.

Example: user enables Pilot 2.0 globally but disables one hook in one project:

```yaml
# user-global config.yaml
pilot_version: 2
hook_enabled:
  banned_token_leak_guard: true
  no_claude_attribution: true
  # ... etc

# project .laravel-superpowers.yaml
hook_enabled:
  banned_token_leak_guard: false   # only this overridden
```

Effective: `pilot_version=2`, `banned_token_leak_guard=false`, all other `hook_enabled` keys inherited from user-global.

## 4. Helper API (`lib/config.py`)

CLI verbs:

```bash
# Get a single value (dot-notation), prints to stdout
python3 lib/config.py get pilot_version
python3 lib/config.py get hook_enabled.banned_token_leak_guard
python3 lib/config.py get banned_tokens.project_extras --type list   # JSON-array output

# Show merged effective config with source attribution
python3 lib/config.py show
# YAML output, each key annotated with [defaults|user|project]

# Validate a config file against schema
python3 lib/config.py validate <path>
# All three layers if no path given
python3 lib/config.py validate

# First-install scaffolding
python3 lib/config.py init           # user-global (refuses if exists)
python3 lib/config.py init --project # ./.laravel-superpowers.yaml
python3 lib/config.py init --force   # overwrite

# Diagnostics
python3 lib/config.py doctor
# Shows: which configs found + last 20 lines of errors.log + schema validation status
```

### 4.1 Hook Integration Pattern

```bash
PLUGIN_DIR="${CLAUDE_PLUGIN_ROOT}"   # set by Claude Code at hook fire-time
enabled=$(python3 "$PLUGIN_DIR/lib/config.py" get hook_enabled.banned_token_leak_guard 2>/dev/null || echo "true")
[ "$enabled" = "true" ] || exit 0    # hook disabled, no-op
```

Hooks always provide a fallback default in the `|| echo` clause so a broken helper never blocks the user.

### 4.2 Exit Codes

| Code | Meaning |
|---|---|
| 0 | success — value returned to stdout |
| 1 | key not found or value is falsy (`false`, empty) |
| 2 | config file unreadable or `init` collision without `--force` |
| 3 | YAML parse error or schema violation |

## 5. Schema & Validation

`config.schema.json` is the canonical truth for legal keys and types. `config.defaults.yaml` MUST validate against it (CI check eventually, manual `validate` for now).

### 5.1 Initial Schema

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "laravel-superpowers config",
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "pilot_version": { "type": "integer", "enum": [1, 2] },
    "hook_enabled": {
      "type": "object",
      "additionalProperties": { "type": "boolean" }
    },
    "audit_aggressiveness": {
      "type": "string",
      "enum": ["every-phase", "every-commit", "brainstorm-only"]
    },
    "banned_tokens": {
      "type": "object",
      "properties": {
        "project_extras": { "type": "array", "items": { "type": "string" } },
        "exception_paths": { "type": "array", "items": { "type": "string" } }
      }
    },
    "visual_companion_default": { "type": "string", "enum": ["on", "off", "ask"] },
    "tier_preference": { "type": "string", "enum": ["T1-only", "T1+T2", "all"] },
    "teamcity_always": { "type": "boolean" }
  }
}
```

`hook_enabled` uses `additionalProperties: { "type": "boolean" }` to allow future hooks without a schema update. Top-level keys are closed (`additionalProperties: false`) — typos at top level are caught.

### 5.2 IDE Autocomplete

User and project configs ship with an optional header line:

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/altraWeb/laravel-superpowers/main/config.schema.json
pilot_version: 2
# ...
```

VSCode (with YAML extension) and Zed (built-in) pick this up automatically.

## 6. Error Handling & First-Install

### 6.1 First Install (no config files exist)

- Helper merges `defaults + nothing + nothing` and returns defaults
- No auto-creation of user-global file
- User customizing for the first time runs `python3 lib/config.py init` which writes commented defaults to the user-global path

### 6.2 Runtime Failure Modes

| Scenario | Helper exit | Hook behavior |
|---|---|---|
| Key found | 0 + value | normal |
| Key missing from all layers | 1 + stderr "key not defined" | hook uses its own fallback |
| YAML parse error in user/project | 3 + stderr file + line | hook falls back to defaults + writes WARN to errors.log |
| Schema validation fail | 3 + stderr details | as above |
| Python / PyYAML / jsonschema missing | helper crashes | hook fails open with stderr WARN — never blocks user |

### 6.3 Logging

Helper writes diagnostic warnings to `~/.claude/plugins/altraweb-laravel/laravel-superpowers/errors.log` (created on first write). The `doctor` subcommand tails this file.

## 7. Testing & Documentation

### 7.1 Tests (`tests/test_config.py`)

Pytest-based. Required coverage:

- Defaults load when no overlay configs exist
- User config deep-merges into defaults
- Project config takes precedence over user (precedence chain)
- Unknown top-level key → ERROR
- Unknown sub-key in `hook_enabled` → allowed
- YAML parse error → exit 3 with helpful message
- `get` with dot-notation on nested keys
- `get` with non-existent key → exit 1
- `init` refuses to overwrite without `--force`
- `show` annotates each key's source layer
- `doctor` lists found configs + schema status

Run: `cd tests && python3 -m pytest -v`. GitHub Action CI is out of scope for #22 — to be added in a follow-up.

### 7.2 Documentation Deliverables

- `docs/config.md` — every key explained, override hierarchy, example configs for common use cases
- `README.md` gains a "Configuration" section linking to `docs/config.md` and noting the JSON Schema pointer for IDE autocomplete
- `config.defaults.yaml` is self-documenting via inline comments on every key

## 8. Acceptance Criteria Mapping

| AC from #22 | Where covered |
|---|---|
| Default config baked in (works without .yaml) | `config.defaults.yaml` + §3.1 |
| User config overrides defaults | §3.2 paths + §3.2 merge |
| Project config overrides user | §3.2 paths + §3.2 merge |
| Hooks read at fire-time | §4.1 hook pattern |
| Schema documented + JSON Schema for IDE | §5.1 + §5.2 + §7.2 |
| CLI inspect of effective config | §4 `show` subcommand |

## 9. Out of Scope (Follow-Up Issues)

- Slash command `/laravel-livewire-superpowers:config` → #23
- Per-hook config integration → each of #16–21
- GitHub Action CI for the test suite → tracked separately when CI infra is set up
- Project-specific config templates (Laravel + Livewire vs plain Laravel) → no issue yet, captured in roadmap brainstorm

## 10. Open Questions for Implementation Plan

These move into the implementation plan once this spec is approved:

- Should the helper detect `claude` plugin install path automatically, or always read `$CLAUDE_PLUGIN_ROOT`?
- Where does the `errors.log` get rotated/truncated? (Maybe `doctor` offers a `--clear` flag.)
- Should `validate` walk both YAML files even if one fails, or short-circuit?

---

*Spec ready for review. Next step: user reviews this file, requests changes if needed, then implementation plan is drafted via `superpowers:writing-plans`.*
