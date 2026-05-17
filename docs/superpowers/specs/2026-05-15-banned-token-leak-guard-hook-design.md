# `banned-token-leak-guard` Hook — Design Spec

**Issue:** [#16](https://github.com/altraWeb/laravel-superpowers/issues/16)
**Milestone:** V2-MVP
**Status:** Design draft
**Date:** 2026-05-15

---

## 1. Context & Motivation

Block 1H Phase 6 close-out (2026-05-14) caught two banned-token leaks at the LAST step before push: `Phase 4 architecture test` ref in `AiAbilityMethods.php` docblock + `Phase-1 Pilot 2.0 audit, 2026-05-14` ref in `editor-ai-dropdown.blade.php`. Required cleanup commit `265c421` to strip; would have leaked otherwise.

Per memory rules: code comments must NOT reference Phase/Sprint/Track/MR-numbers/dated audit refs. They rot fast and look unprofessional in shipped code.

The `laravel-reviewer` agent (#5, just merged) flags banned tokens — but only when explicitly invoked. A **PreToolUse hook on `git commit`** catches them automatically at commit-time, eliminating the need for end-of-sprint hard-gate sweeps.

This is the **first hook** in the plugin and the first real consumer of the `#22` config foundation — full circle moment for V2-MVP infrastructure.

## 2. Goals & Non-Goals

**Goals**

- Block `git commit` when staged files contain banned tokens in code/comments
- Respect exception paths (docs that legitimately reference Phase/Sprint state)
- Honor per-project config overrides (`banned_tokens.project_extras`, `banned_tokens.exception_paths`)
- Honor `hook_enabled.banned_token_leak_guard: false` to disable (escape hatch)
- Respect line-level override marker (`banned-token-ok: <reason>`)
- Fail-open if config helper missing/broken — never block legitimate commits due to plugin bugs

**Non-Goals**

- Server-side / pre-receive enforcement (this is a Claude-Code-only hook)
- Catching banned tokens already merged to main (use the reviewer agent for that)
- Replacing the reviewer agent's banned-token sweep — they complement each other (hook prevents new ones, reviewer catches escapes)
- Configuration of which tokens to ban beyond the config schema (#22) — that's a follow-up if needed

## 3. Architecture

### 3.1 Hook Registration

Hooks live in a separate `hooks/hooks.json` file (Claude Code convention, matches `phpstorm-marketplace` plugin pattern). Registered as **PreToolUse** on the **Bash** matcher; the script itself filters to `git commit` calls.

```json
{
    "hooks": {
        "PreToolUse": [
            {
                "matcher": "Bash",
                "hooks": [
                    {
                        "type": "command",
                        "command": "${CLAUDE_PLUGIN_ROOT}/hooks/banned-token-leak-guard.sh"
                    }
                ]
            }
        ]
    }
}
```

### 3.2 Script Workflow (`hooks/banned-token-leak-guard.sh`)

1. **Read tool input from stdin** as JSON, extract `tool_input.command`
2. **Filter:** if command is not `git commit` (and not the various `git commit-tree`, `git commit --help`, etc.) → `exit 0` passthrough
3. **Read config** via `lib/config.py` (#22):
   - `hook_enabled.banned_token_leak_guard` → if `false`, `exit 0`
   - `banned_tokens.project_extras` → append to defaults
   - `banned_tokens.exception_paths` → extend defaults
   - All config reads use the `|| echo "<fallback>"` pattern → fail-open if helper crashes
4. **Get staged files:** `git diff --cached --name-only`
5. **Filter by extension:** keep `.php`, `.blade.php`, `.js`, `.ts`, `.css`, `.md`. Drop others.
6. **Filter by exception path:** drop any path matching defaults (`docs/plans/**`, `docs/superpowers/**`, `CHANGELOG.md`) or config extras
7. **For each remaining file**, grep staged content for banned tokens with line numbers
8. **Skip lines with override marker** — line containing `banned-token-ok:` is allowed (operator opt-out per legitimate reason)
9. **If matches found**: print diagnostic, `exit 2` (blocks commit per Claude Code hook convention)
10. **No matches**: `exit 0` (commit proceeds)

### 3.3 Default Banned Tokens

| Pattern (extended regex) | Why banned |
|---|---|
| `Phase [0-9]+` | Sprint-state ref, rots after phase boundary |
| `Slice [0-9]+` | Sprint-slice ref |
| `Track [0-9]+` | Sprint-track ref |
| `Sprint [0-9]+` | Direct sprint ref |
| `MR !?[0-9]+` | GitLab MR number |
| `Pilot 2\.0` | Pilot-version meta ref |
| `\b20[0-9]{2}-[0-9]{2}-[0-9]{2}\b` | Dated audit ref (ISO date) |

Each pattern is OR'd into a single extended regex: `Phase [0-9]+|Slice [0-9]+|Track [0-9]+|Sprint [0-9]+|MR !?[0-9]+|Pilot 2\.0|\b20[0-9]{2}-[0-9]{2}-[0-9]{2}\b`.

### 3.4 Default Exception Paths

| Path glob | Reason |
|---|---|
| `docs/plans/**` | Plan docs legitimately reference Phase/Sprint |
| `docs/superpowers/**` | Spec/plan docs reference dates and sprints |
| `CHANGELOG.md` | Release notes reference dates by definition |

Per-project config (`banned_tokens.exception_paths`) extends this list — user can add their own (e.g., `docs/adr/**`).

### 3.5 Override Marker

Line-level opt-out: any line containing the literal string `banned-token-ok:` (case-sensitive) is skipped during scan. This honors legitimate cases:

```php
// Status field allows: Phase 1, Phase 2, Phase 3 — banned-token-ok: domain term, not sprint ref
const STATUS_PHASES = ['Phase 1', 'Phase 2', 'Phase 3'];
```

The marker must include the reason after the colon — agent should not strip the line silently. We document the convention but don't validate the reason field (out of scope).

## 4. Diagnostic Output Format

When banned tokens found:

```
🚫 banned-token-leak-guard: commit blocked

3 banned-token references found in staged files:

  app/Http/Controllers/PostsController.php:42  → "Phase 3"
    Comment: // Phase 3 implementation
    Fix: remove Phase/Sprint refs from code comments

  app/Models/Post.php:7  → "MR !345"
    Comment: /* MR !345 added this column */
    Fix: remove MR refs — code should not reference review state

  resources/views/posts/index.blade.php:12  → "2026-05-14"
    Comment: {{-- 2026-05-14 audit fixes --}}
    Fix: remove dated refs — they age poorly

These references rot fast and look unprofessional in shipped code.
Override per-line with: `banned-token-ok: <reason>`
Disable globally in .laravel-superpowers.yaml: hook_enabled.banned_token_leak_guard: false
```

Exit 2 → commit blocked.

## 5. Error Handling / Fail-Open Behavior

| Scenario | Behavior |
|---|---|
| stdin empty / not JSON | `exit 0` passthrough — no input means no work |
| Not a `git commit` command | `exit 0` passthrough |
| Hook disabled in config | `exit 0` passthrough |
| Config helper crashes (Python missing, etc.) | Use baked-in defaults via `\|\| echo "true"` fallback, continue with scan |
| `git diff --cached --name-only` fails | Print warning to stderr, `exit 0` — don't block on git infrastructure issues |
| No staged files | `exit 0` (nothing to scan) |
| All staged files in exception paths | `exit 0` (nothing to scan) |
| Banned tokens found | `exit 2` (block) |

Principle: the hook is **defensive** — it should never block a legitimate commit due to plugin internals failing. Banned-token enforcement is best-effort, not life-critical.

## 6. Testing

Shell-level smoke tests (no subagent dispatch needed — the hook IS a shell script). Three scenarios captured in `docs/superpowers/test-evidence/`:

1. **Canonical regression (Block 1H Phase 6 case):** stage a file containing `Phase 4 architecture test` in a docblock → hook exits 2 with diagnostic
2. **Clean commit:** stage a file without banned tokens → hook exits 0
3. **Override marker:** stage a file with `Phase 3 — banned-token-ok: domain term` → hook exits 0

A fourth scenario verifies passthrough on non-commit Bash calls (`git status`, `ls`, etc.).

Test driver: a shell script that sets up a temp git repo, stages files, invokes the hook with mock stdin, captures exit code + output.

## 7. Documentation Deliverables

- `hooks/hooks.json` — registration
- `hooks/banned-token-leak-guard.sh` — implementation
- `tests/test_banned_token_hook.sh` — shell test driver
- `README.md` — add a new `## Hooks` section after Agents (first hook ships)
- `docs/hooks.md` — new reference page (analogous to `docs/agents.md`)

## 8. AC Mapping

| AC from #16 | Where |
|---|---|
| Hook registered via plugin manifest | `hooks/hooks.json` |
| Blocks commits with banned tokens | §3.2 step 9 + exit 2 |
| Allows exception paths | §3.4 + §3.2 step 6 |
| Per-project banned-token list override via config | §3.3 + `banned_tokens.project_extras` from #22 |
| Override marker `banned-token-ok:` skips line | §3.2 step 8 + §3.5 |
| Tested on Block 1H regression case | §6 test 1 |

## 9. Out of Scope

- Server-side pre-receive enforcement → never (Claude Code only)
- Token-by-token whitelist UI / config (`banned_tokens.allowed` map) → YAGNI for v1
- Linting suggestions for replacement (just remove vs. replace with what) → out of scope
- Auto-strip of banned tokens → never (read-only enforcement, dev rewrites manually)

## 10. Open Questions for Implementation

- Should the matcher in `hooks.json` be more specific (e.g., `Bash:git commit`)? (Defer: matcher syntax is per Claude Code; `Bash` plain + script-level filter is the safe default)
- Should the override marker `banned-token-ok:` require a reason after the colon? (Defer: document the convention but don't enforce; agent's `laravel-reviewer` can flag unjustified markers later if desired)
- Should the hook emit a per-line patch suggestion? (No — just file:line + match. Operator decides the fix.)
