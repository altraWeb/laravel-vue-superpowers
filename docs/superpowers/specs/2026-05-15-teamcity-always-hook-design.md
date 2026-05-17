# `teamcity-always` Hook — Design Spec

**Issue:** [#18](https://github.com/altraWeb/laravel-superpowers/issues/18)
**Milestone:** V2-MVP
**Status:** Design draft
**Date:** 2026-05-15

---

## 1. Context & Motivation

Operator's CLAUDE.md PersonalGuidelines: "Always Use `--teamcity` for Tests". The TeamCity reporter emits IDE-friendly per-test events; without it, IDE integration falls back to plain-stdout parsing which loses test-result fidelity in tools like PhpStorm/VSCode test runners.

Block 1H + 1E had 100% compliance because plan-doc test-run steps explicitly include `--teamcity` — but ad-hoc test runs (debugging, exploratory) often skip it. Currently relies on agent discipline.

A PreToolUse hook on Bash calls matching `php artisan test` would catch this discipline-free.

This is the third hook in the plugin.

## 2. Goals & Non-Goals

**Goals**

- Catch `php artisan test` invocations that don't pass `--teamcity` and prompt to add it
- Skip silently when `--teamcity` is already present (no double-append, no nag)
- Skip when an alternative reporter is explicit (`--testdox` is operator intent — respect it)
- Honor `hook_enabled.teamcity_always: false` for project-level disable
- Honor top-level `teamcity_always: false` config flag (separate from `hook_enabled` — operator can mean "I never want this enforcement" vs "disable just the hook")

**Non-Goals**

- **Auto-modifying the command** (the issue spec says "auto-append `--teamcity`"). PreToolUse hooks can block via exit 2 reliably; modifying tool_input from a hook is not a portable Claude Code feature. **Deviation from spec:** we BLOCK with a clear retry suggestion instead. 90% of the value (operator always uses `--teamcity`) at 10% of the complexity (no hook-output-schema dependency). Documented in PR body.
- Pest/PHPUnit direct calls (`./vendor/bin/pest`, `./vendor/bin/phpunit`) — out of scope. The hook fires only on `php artisan test`. Add separate matcher in follow-up if needed.
- Editor/IDE test runs that bypass Bash — out of scope (PreToolUse hooks only see Claude Code tool calls).

## 3. Architecture

### 3.1 Hook Registration

Third entry under the existing PreToolUse Bash matcher in `hooks/hooks.json`:

```json
{ "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/teamcity-always.sh" }
```

### 3.2 Script Workflow (`hooks/teamcity-always.sh`)

1. **Read stdin JSON**, extract `tool_input.command`
2. **Filter to `php artisan test`:** match `php artisan test` (allow optional subcommand suffix `:parallel`, `:compact`) and reject `php artisan` + anything else
3. **Skip if `--teamcity` already present** → `exit 0`
4. **Skip if alternative reporter** (`--testdox`, `--printer`, `--printer-class`) → `exit 0` (operator override)
5. **Config check** — `hook_enabled.teamcity_always: false` → `exit 0`. Also check top-level `teamcity_always: false` (separate semantic flag — operator never wants this enforced) → `exit 0`
6. **No skip applies** → BLOCK with diagnostic + retry suggestion → `exit 2`

### 3.3 Match Patterns

Match (case-sensitive, allow leading/trailing whitespace and pipes/redirects):

| Allowed forms (block if no `--teamcity`) |
|---|
| `php artisan test` |
| `php artisan test --filter=X` |
| `php artisan test:parallel` |
| `php artisan test:compact` |
| `php artisan test --coverage` |
| `php artisan test tests/Feature/Foo.php` |

Reject (passthrough — don't fire):

| Non-target command |
|---|
| `php artisan` (no `test` subcommand) |
| `php artisan tests:show` |
| `php artisan migrate:fresh --seed` |
| `./vendor/bin/pest` |
| Anything not literally `php artisan test` family |

Skip (already covered):

| Already-covered cases |
|---|
| `php artisan test --teamcity` |
| `php artisan test --testdox` |
| `php artisan test --printer-class=Foo` |

## 4. Diagnostic Output

When blocked:

```
🚫 teamcity-always: test command blocked

Detected `php artisan test` invocation without `--teamcity`:

  ── command ─────────────────────────────────────────────────────
  php artisan test --filter=UserProfileTest
  ─────────────────────────────────────────────────────────────────

Project canon (CLAUDE.md PersonalGuidelines): always use `--teamcity`
for parsable test output. IDE integration (PhpStorm/VSCode) requires
the TeamCity reporter for per-test events.

Retry with --teamcity:

  ── suggested rewrite ───────────────────────────────────────────
  php artisan test --teamcity --filter=UserProfileTest
  ─────────────────────────────────────────────────────────────────

To disable globally, set in .laravel-superpowers.yaml:
    hook_enabled:
      teamcity_always: false
    # OR
    teamcity_always: false   # top-level kill switch

To explicitly use an alternate reporter, add --testdox or --printer-class.
```

Exit 2 → command blocked.

## 5. Error Handling / Fail-Open Behavior

| Scenario | Behavior |
|---|---|
| stdin empty / not JSON | `exit 0` |
| Not `php artisan test` family | `exit 0` |
| `--teamcity` present | `exit 0` |
| Alternative reporter explicit | `exit 0` |
| `hook_enabled.teamcity_always: false` | `exit 0` |
| `teamcity_always: false` (top-level) | `exit 0` |
| Config helper crashes | use `true` default, continue |
| Otherwise | `exit 2` |

## 6. Testing

Shell tests in `tests/test_teamcity_always_hook.sh`. Scenarios:

1. **Block plain `php artisan test`** — no flags → exit 2
2. **Block `php artisan test --filter=X`** → exit 2
3. **Block `php artisan test:parallel`** → exit 2
4. **Allow `php artisan test --teamcity`** → exit 0 (already present)
5. **Allow `php artisan test --testdox`** → exit 0 (alt reporter)
6. **Passthrough `php artisan migrate`** → exit 0 (not test)
7. **Passthrough `./vendor/bin/pest`** → exit 0 (not artisan)
8. **Passthrough `git status`** → exit 0 (not artisan at all)
9. **Allow when hook disabled in config** — set env to simulate config disabled (test driver tweak)

## 7. Documentation Deliverables

- `hooks/teamcity-always.sh` (new)
- `hooks/hooks.json` (modified — add third entry)
- `tests/test_teamcity_always_hook.sh` (new)
- `README.md` (modified — append to Hooks section)
- `docs/hooks.md` (modified — insert entry, update Forthcoming)

## 8. AC Mapping

| AC from #18 | Where |
|---|---|
| Hook registered for Bash matching `php artisan test` | §3.1 + §3.2 step 2 |
| Auto-appends `--teamcity` when missing | **Deviated** to BLOCK + retry suggestion (§4). Documented in spec §2 Non-Goals + PR body. |
| No-op when `--teamcity` already present | §3.2 step 3 |
| No-op when alternate reporter explicitly specified | §3.2 step 4 |
| Diagnostic emit visible in terminal | §4 stderr output via Claude Code's hook error surface |
| Project-canon-override via config: `teamcity_always: false` disables hook | §3.2 step 5 + spec §3.3 |

## 9. Out of Scope

- Auto-modifying tool_input (requires hook-output-schema features we don't depend on) → block-and-suggest instead
- Pest direct calls (`./vendor/bin/pest`) — only `php artisan test`
- Editor/IDE test runs that bypass Claude Code's Bash tool

## 10. Open Questions for Implementation

- Should the hook auto-append for `--coverage` runs where TeamCity output may interfere with coverage report? (No — operator can explicitly use `--testdox` to opt-out per spec §3.3)
- Should `teamcity_always: false` AND `hook_enabled.teamcity_always: true` be a config-validation error? (No — both are valid "off" signals, hook respects either)
