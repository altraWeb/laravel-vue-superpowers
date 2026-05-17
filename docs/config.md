# Plugin Configuration Reference

`laravel-livewire-superpowers` reads YAML config from three layers (lowest to highest precedence):

| Layer | Path | When to use |
|---|---|---|
| Defaults | `<plugin>/config.defaults.yaml` | Baked in — do not edit |
| User-global | `~/.claude/plugins/altraweb-laravel/laravel-superpowers/config.yaml` | Per-machine preferences |
| Per-project | `<project>/.laravel-superpowers.yaml` | Per-repo overrides |

> **Note on path names:** both `laravel-superpowers/config.yaml` and `.laravel-superpowers.yaml` use the V2 plugin name — this is intentional. These paths are preserved across the V3 rename so existing V2 users' configs continue to apply without migration. See V3 design spec Section 8.

Override hierarchy is **deep recursive**: nested keys (e.g. `hook_enabled.banned_token_leak_guard`) can be overridden individually without repeating the surrounding block.

## Prerequisites

The helper needs Python 3.10+ with `PyYAML` and `jsonschema`:

```bash
pip3 install --user --break-system-packages pyyaml jsonschema
```

(macOS Homebrew Python uses PEP 668 — the `--break-system-packages` flag is required.)

## Quickstart

```bash
# Show effective merged config
python3 <plugin>/lib/config.py show

# Scaffold a user-global config you can edit
python3 <plugin>/lib/config.py init

# Scaffold a project-local config
python3 <plugin>/lib/config.py init --project

# Validate your config against the schema
python3 <plugin>/lib/config.py validate

# Diagnose problems
python3 <plugin>/lib/config.py doctor
```

## Keys

### `pilot_version` — integer, one of `1`, `2`, default `2`

Pilot contract version. `1` = audits optional, `2` = audits are binding hard-gates.

### `hook_enabled.<hook_name>` — boolean, default `true`

Per-hook enable/disable. Set a specific hook to `false` to no-op it without affecting others. Sub-keys here are open — future hooks can opt in without a schema update.

Currently shipped hook names:
- `banned_token_leak_guard` (#16)
- `no_claude_attribution` (#17)
- `teamcity_always` (#18)
- `anti_silent_deferral` (#19)
- `brainstorm_t1_audit` (#20)
- `visual_companion_default_on` (#21)

### `audit_aggressiveness` — string, one of `every-phase | every-commit | brainstorm-only`, default `every-phase`

How aggressively the Tier-1 audit (`laravel-best-practices` dispatch) should fire.

**Important — advisory vs. programmatic enforcement** (clarified in v2.0.1):

- `brainstorm-only` is the only mode with **programmatic enforcement** — the `brainstorm-t1-audit` hook automatically fires on every `superpowers:brainstorming` invocation. The hook fires regardless of this setting's value.
- `every-phase` and `every-commit` are **advisory metadata** that the orchestrator agent reads from `/laravel-livewire-superpowers:status` to decide when to self-dispatch the audit. There is no hook that fires at phase boundaries or per commit — Claude Code does not emit those events.

If you want strict "audit at every commit" enforcement, you'll need to manually dispatch `laravel-best-practices` via the Task tool before each commit. The configuration value advertises your preference; it does not enforce it.

See `docs/audits/2026-05-15-v2-mvp-self-audit.md` §"Should-fix S2" for the rationale.

### `banned_tokens.project_extras` — list of strings, default `[]`

Additional tokens the banned-token-leak-guard hook should reject. Example:

```yaml
banned_tokens:
  project_extras:
    - "AcmeCorp"
    - "INT-1234"
```

### `banned_tokens.exception_paths` — list of glob strings

Paths where banned tokens are tolerated. Defaults include `docs/plans/**`, `docs/superpowers/**`, `CHANGELOG.md`.

### `visual_companion_default` — string, one of `on | off | ask`, default `on`

Default for the brainstorming skill's visual companion offer.

### `tier_preference` — string, one of `T1-only | T1+T2 | all`, default `T1+T2`

Which roadmap tiers to surface in auto-suggestions.

### `teamcity_always` — boolean, default `true`

Whether to always pass `--teamcity` to `php artisan test` (and `composer test` wrappers, since v2.0.1) for parsable output. The `teamcity-always` hook blocks invocations missing the flag and emits a retry suggestion.

## IDE autocomplete

User and project configs can add a schema pointer as their first line:

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/altraWeb/laravel-livewire-superpowers/main/config.schema.json
```

VSCode with the YAML extension and Zed pick this up automatically and provide completion + inline validation.

## Examples

### Disable one hook in one project

```yaml
# ./.laravel-superpowers.yaml
hook_enabled:
  banned_token_leak_guard: false
```

All other `hook_enabled` keys inherit from user-global or defaults.

### Add project-specific banned tokens

```yaml
# ./.laravel-superpowers.yaml
banned_tokens:
  project_extras:
    - "AcmeCorp"
    - "INT-1234"
```

### Globally prefer the all-tier suggestion set

```yaml
# ~/.claude/plugins/altraweb-laravel/laravel-superpowers/config.yaml
tier_preference: all
```
