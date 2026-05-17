# V2-MVP Self-Audit — 2026-05-15

> **Auditor:** operator-driven empirical hook verification + code-read of all 6 hooks + config helper.
> **Trigger:** post-V2.0.0 release, before declaring V2-MVP "battle-tested".
> **Method:** simulated `PreToolUse` and `PostToolUse` inputs against each hook with realistic operator commands; cross-checked against `docs/hooks.md` documented behavior and `tests/test_*_hook.sh` evidence.

---

## Summary

| Severity | Count | Tracks |
|----------|-------|--------|
| 🚫 Blocker | 1 | B1 |
| ⚠️ Should-fix | 4 | S1, S2, S3, S5 |
| 💡 Nice-to-have | 3 | N1, N2, N3 |

S5 was discovered while empirically verifying the B1 fix — the test command itself (containing `gh pr create` as a literal substring inside an `echo`) triggered the hook's broad filter and got intercepted. The same overly-broad filter pattern exists in all 4 PreToolUse-Bash hooks; a single tightening pattern fixes the issue uniformly.

**Verdict:** V2-MVP is functionally complete on 5 of 6 hooks. One hook (`no-claude-attribution`) is silently no-op for the most common invocation pattern. Patch release V2.0.1 is required before V2-MVP can be considered hardened.

---

## 🚫 Blocker — `no-claude-attribution` bypasses ALL `"`-quoted inline messages

### Symptom

The hook's primary job is to block commit messages / PR bodies / MR descriptions containing Claude attribution. Empirically, it bypasses every `git commit -m "..."`, `gh pr create --body "..."`, `glab mr create --description "..."` where the message contains a `"` character (which is **always** when the message is the operator's canonical conventional-commit format).

### Root cause

`hooks/no-claude-attribution.sh:70-95` defines `extract_flag_value()`:

```bash
extract_flag_value() {
    local flag="$1"
    local cmd="$2"
    python3 - <<EOF 2>/dev/null
import shlex, sys
flag = "$flag"
cmd = """$cmd"""    # ← $cmd expanded into triple-quoted Python string
...
EOF
}
```

The heredoc is **unquoted** (`<<EOF`, not `<<'EOF'`), so Bash expands `$cmd` into the Python source text. When `$cmd` contains a `"`, the resulting Python source is:

```python
cmd = """git commit -m "feat: x" -m "Co-Authored-By: Claude ..."""
```

The triple-quote `"""` closes prematurely at the embedded `""`, Python raises `SyntaxError`, `2>/dev/null` swallows it, the function returns empty stdout → `message=""` → hook exits 0 (fail-open).

### Empirical evidence

```bash
$ echo '{"tool_input":{"command":"git commit -m \"feat\" -m \"Co-Authored-By: Claude\""}}' \
  | bash hooks/no-claude-attribution.sh; echo "exit=$?"
exit=0   # ← should be 2
```

(Block 1H repro reproduces 100% reliably; tested via `bash -x` to confirm the python subshell returns empty.)

### Why the test suite missed it

`tests/test_no_claude_attribution_hook.sh` uses messages without embedded `"`:

```bash
# Test fixture: passes a literal string without quotes
payload='{"tool_input":{"command":"git commit -m foo"}}'
```

That happens to work because shlex sees `-m` followed by `foo` (no quote-escape needed). Real operator commits use `git commit -m "feat(x): something"` which always contains the wrapping quotes — those are the failing case the tests don't exercise.

### Fix

Pass `flag` and `cmd` via environment variables; let Python read them safely from `os.environ`:

```bash
extract_flag_value() {
    FLAG="$1" CMD="$2" python3 - <<'EOF' 2>/dev/null
import os, shlex, sys
flag = os.environ.get("FLAG", "")
cmd = os.environ.get("CMD", "")
if not flag or not cmd:
    sys.exit(0)
try:
    tokens = shlex.split(cmd)
except ValueError:
    sys.exit(0)
values = []
i = 0
while i < len(tokens):
    t = tokens[i]
    if t == flag and i + 1 < len(tokens):
        values.append(tokens[i + 1])
        i += 2
    elif t.startswith(flag + "="):
        values.append(t[len(flag) + 1:])
        i += 1
    else:
        i += 1
print("\n".join(values))
EOF
}
```

Two changes vs. the original:
1. `<<'EOF'` (quoted) instead of `<<EOF` (unquoted) → Bash does NOT expand `$cmd` into the Python source. The heredoc body is a literal string.
2. `FLAG="..." CMD="..." python3 ...` → env-var pass keeps the values out of the source text entirely. `shlex.split(os.environ["CMD"])` handles arbitrary quoting safely.

### Test extension required

Add three scenarios to `tests/test_no_claude_attribution_hook.sh`:

```bash
# 11. BLOCK on git commit -m "feat" -m "Co-Authored-By: Claude" (quoted inline message)
# 12. BLOCK on gh pr create --body "feat\n\n🤖 Generated with Claude Code" (quoted body)
# 13. BLOCK on glab mr create --description "AI-assisted work" (quoted description)
```

All three currently false-green (silent fail) before the fix and must turn red, then green after the fix.

---

## ⚠️ Should-fix — S1: banned-token date pattern false-positive on Carbon literals

### Symptom

`banned-token-leak-guard` blocks any commit whose staged files contain an ISO date `YYYY-MM-DD` in code, including legitimate:

- `Carbon::parse('2026-01-01')`
- `@dataProvider with ['2026-05-15', ...]`
- Migration body constants
- Hardcoded business dates (holiday tables, fiscal-year boundaries)

### Empirical evidence

```bash
$ echo '<?php $d = Carbon::parse("2026-01-01");' > tainted.php && git add tainted.php
$ echo '{"tool_input":{"command":"git commit -m feat"}}' \
  | bash hooks/banned-token-leak-guard.sh
🚫 banned-token-leak-guard: commit blocked
  tainted.php:1  → "2026-01-01"
exit=2
```

### Root cause

`hooks/banned-token-leak-guard.sh:127`:

```bash
default_patterns='Phase [0-9]+|Slice [0-9]+|Track [0-9]+|Sprint [0-9]+|MR !?[0-9]+|Pilot 2\.0|\b20[0-9]{2}-[0-9]{2}-[0-9]{2}\b'
```

The intent was to catch sprint-state markers like `// On 2026-05-15 we deferred X`. But the pattern is context-free — it matches any ISO date anywhere in code.

### Fix (chosen approach: narrow the context)

Replace the bare date pattern with a context-anchored one:

```bash
'(?:On|Date|Sprint|Phase|Released|Shipped|Audit|Review|Deferred)[:[:space:]]+20[0-9]{2}-[0-9]{2}-[0-9]{2}\b'
```

This matches `On 2026-05-15`, `Sprint: 2026-05-15`, `Released 2026-05-15` etc. — the actual sprint-state markers — but NOT `Carbon::parse('2026-01-01')` or `@param string '2026-01-01'` or migration date literals.

### Alternative (rejected): move date pattern to project_extras

Would require every consumer to manually opt back into date-sweep. Reverses the safe default (catch sprint-state leaks) into an opt-in (most users get nothing).

### Alternative (rejected): exception path `database/migrations/**` etc.

Carbon literals appear everywhere — services, jobs, factories, tests, models. Adding exception paths becomes whack-a-mole.

---

## ⚠️ Should-fix — S2: `audit_aggressiveness` enum has values without programmatic enforcement

### Symptom

`config.schema.json` accepts `every-phase | every-commit | brainstorm-only` for `audit_aggressiveness`. Only `brainstorm-only` is actually enforced by a hook (`brainstorm-t1-audit` fires unconditionally on `superpowers:brainstorming`). The other two values are advisory hints to the orchestrator agent, but there is no programmatic enforcement and no documentation distinguishes the two states.

### Root cause

`hooks/brainstorm-t1-audit.sh:50-54`:

```bash
aggressiveness="$(config_get audit_aggressiveness every-phase)"
case "$aggressiveness" in
    every-phase|every-commit|brainstorm-only|"") : ;;
    *) exit 0 ;;
esac
```

The case statement validates the value but does **not branch behavior** on it. The hook always emits the same reminder regardless of `audit_aggressiveness`.

### Fix

Two parts:

1. **Documentation clarification** — update `docs/config.md` and `config.defaults.yaml` comments to explicitly state that `audit_aggressiveness` is **advisory metadata** that the orchestrator agent reads from `/laravel-livewire-superpowers:status` output to decide whether to dispatch the audit at phase boundaries / per commit. The brainstorm-time enforcement is automatic and constant.

2. **Status command surfaces the active level** — `/laravel-livewire-superpowers:status` already reads merged config; add one line to its output: `**Audit aggressiveness:** <value> (advisory; brainstorm-time enforced via hook)`.

No hook code change. The enum stays — it's not broken, it's underdocumented.

---

## ⚠️ Should-fix — S3: `teamcity-always` misses `composer test` wrapper

### Symptom

Operator's standard test invocation per CLAUDE.md is `php artisan test --teamcity` directly. But many Laravel projects wrap it via `composer test` (which runs `php artisan test` through `composer.json`'s `scripts.test`). The hook's filter `*"php artisan test"*` does not match `composer test`, so wrapped invocations bypass the `--teamcity` enforcement.

### Empirical evidence

```bash
$ echo '{"tool_input":{"command":"composer test"}}' | bash hooks/teamcity-always.sh
exit=0   # ← passes through silently; should warn or block
```

### Fix

Extend the filter pattern in `hooks/teamcity-always.sh:35`:

```bash
case "$command_str" in
    *"php artisan test"*|*"php artisan test:parallel"*|*"php artisan test:compact"*\
    |*"composer test"*|*"composer run test"*|*"composer run-script test"*)
        if printf '%s' "$command_str" | grep -qE \
           '\b(php artisan test(\b|:parallel\b|:compact\b)|composer (run-script |run )?test\b)'; then
            : # proceed
        else
            exit 0
        fi
        ;;
    *)
        exit 0
        ;;
esac
```

And amend the block diagnostic to recognize the wrapper case — the retry suggestion should append `-- --teamcity` (composer passes extra args after `--`) when the original was `composer test`:

```bash
# In Step 6 — Build retry suggestion:
if printf '%s' "$command_str" | grep -q '^composer '; then
    # composer test passes args via --
    suggested="$(printf '%s' "$command_str" | sed -E 's|(composer (run-script |run )?test)( |$)|\1 -- --teamcity\3|')"
else
    # Existing python-based artisan injection
    ...
fi
```

### Test extension required

Add to `tests/test_teamcity_always_hook.sh`:

```bash
# 10. BLOCK on `composer test` (no --teamcity) with rewrite suggestion `composer test -- --teamcity`
# 11. ALLOW `composer test -- --teamcity` (already present)
# 12. ALLOW `composer install` (not test command)
```

---

## ⚠️ Should-fix — S5: all PreToolUse-Bash hooks use overly broad substring filters

### Symptom

The four PreToolUse-Bash hooks (`banned-token-leak-guard`, `no-claude-attribution`, `teamcity-always`, `anti-silent-deferral`) all use shell `case` glob patterns like `*"git commit"*` or `*"gh pr create"*` to detect their target command. This matches the target as a **substring anywhere** in the bash invocation, not as a **command-position word**.

### Consequence

Any bash command that mentions the target command as a literal substring — inside an `echo`, `cat <<EOF`, `grep`, `man`, code-comments in an inline script — gets intercepted. The hook then attempts to extract flag values via `shlex.split`, which usually fails gracefully (no top-level flag tokens) so the hook still exits 0. But occasionally `shlex` does find a matching token and the hook produces a false-positive block.

Confirmed reproducer during the B1 verification session: an `echo` containing `"gh pr create --title foo --body \"...\""` inside a debug pipeline was intercepted by `no-claude-attribution` because the `--body` token was visible to `shlex.split` once it parsed past the outer single-quoted JSON. Hook diagnostic claimed an attribution match on the outer Bash command, not on a real `gh pr create` invocation.

### Fix

Replace each `case` substring glob with a `grep -E` that anchors the target at command-position — start of string, or after a separator (`;`, `&&`, `||`, `|`), optionally preceded by env-var assignments:

```bash
# Reusable detection (inline per hook):
is_command_position() {
    local cmd="$1"
    local target_regex="$2"   # e.g. 'git commit', 'gh pr (create|edit)'
    printf '%s' "$cmd" | grep -qE '(^|[;&|][[:space:]]*)([A-Z_][A-Za-z0-9_]*=\S+[[:space:]]+)*'"$target_regex"'(\s|$)'
}
```

Apply per hook:

| Hook | Target regex |
|------|--------------|
| `banned-token-leak-guard` | `git commit` (excluding `git commit-tree`) |
| `no-claude-attribution` | `git commit` OR `gh pr (create\|edit)` OR `glab mr (create\|update)` |
| `teamcity-always` | `(php artisan\|composer (run-script \|run )?)test(:parallel\|:compact)?` (incl. S3) |
| `anti-silent-deferral` | `git push` |

### Test extension required

Add to each hook's test suite one scenario along the lines of:

```bash
# pass-through: the target command appears inside an echo, not as command-position
'{"tool_input":{"command":"echo \"info: run git commit when ready\""}}'  # expect exit 0
'{"tool_input":{"command":"grep \"gh pr create\" docs/workflow.md"}}'     # expect exit 0
```

---

## 💡 Nice-to-have — N1: editor-mode `git commit` cannot be intercepted

**Status:** documented as "Known limitation" in `docs/hooks.md`. Acceptable — the `laravel-reviewer` agent post-commit catches the rare editor-mode case. No fix needed.

## 💡 Nice-to-have — N2: per-project `.laravel-superpowers.yaml` not required for altraBoard

**Status:** investigated separately. All V2 defaults are operator-aligned (`pilot_version: 2`, `visual_companion_default: on`, `teamcity_always: true`, all hooks enabled). A per-project config becomes useful only if S1 is rejected and the operator wants to locally override `banned_tokens.project_extras` to exclude the date pattern. Once S1 lands upstream, no per-project config is needed.

## 💡 Nice-to-have — N3: `/laravel-livewire-superpowers:status` does not understand `## Tier N` headings

`commands/status.md` Step 2 says to extract phase progress via `## Phase \d+` headings. The operator's `master-roadmap-2026-q2.md` uses `## Tier 0 — HOTFIX SPRINT`, `## Tier 1 — STABILIZATION`, etc. Status command emits "n/a" for phase progress on these docs.

**Fix:** extend the regex to `## (Phase|Tier|Block|Slice) \d+`. Update `commands/status.md` workflow Step 2 accordingly. Low priority — operator can rename `Tier` → `Phase` in plan-docs OR live with the n/a marker.

---

## V2.0.1 release scope

This audit motivates a V2.0.1 patch release bundling:

1. **B1** — `no-claude-attribution` extract_flag_value fix + 3 new test scenarios
2. **S1** — `banned-token-leak-guard` date pattern narrowed to context-anchored form
3. **S2** — `audit_aggressiveness` documentation clarification (no code change)
4. **S3** — `teamcity-always` composer-wrapper support + 3 new test scenarios
5. **S5** — all 4 PreToolUse-Bash hooks tighten command-position filter + 4 test scenarios

N1, N2, N3 remain backlog. N3 to be filed as a new GitHub issue against the V2.1 milestone.

### Release-note draft for CHANGELOG.md

```markdown
## [2.0.1] — 2026-05-15 — Self-audit hotfix

Patch release driven by post-V2.0.0 self-audit (docs/audits/2026-05-15-v2-mvp-self-audit.md).

### Fixed

- **`no-claude-attribution` hook silently bypassed quoted inline messages** ([#?]) — `extract_flag_value()` embedded the command string into an unquoted Python heredoc; any `"` in the message broke the triple-quote and the Python subshell errored silently, returning empty. ALL `git commit -m "..."`, `gh pr create --body "..."`, `glab mr create --description "..."` patterns were bypassed. Fix: pass values via environment variables and read with `os.environ`.
- **`banned-token-leak-guard` blocked legitimate Carbon date literals** ([#?]) — the default date pattern `\b20[0-9]{2}-[0-9]{2}-[0-9]{2}\b` matched ISO dates anywhere in code, including `Carbon::parse('2026-01-01')`. Fix: narrowed to context-anchored form `(?:On|Sprint|Phase|...)[:space:]+YYYY-MM-DD`.
- **`teamcity-always` did not catch `composer test` wrapper** ([#?]) — extends the filter to detect `composer test` / `composer run test` invocations; emits a `composer test -- --teamcity` rewrite suggestion when blocking.

### Documentation

- `docs/config.md` clarifies that `audit_aggressiveness` is **advisory metadata** for the orchestrator agent, not hook-enforced beyond brainstorm-time. Status command surfaces the active level.
- `docs/audits/2026-05-15-v2-mvp-self-audit.md` — full audit transcript.

### Tests

- `+3` scenarios in `tests/test_no_claude_attribution_hook.sh` (quoted inline, gh-pr body, glab-mr description)
- `+3` scenarios in `tests/test_teamcity_always_hook.sh` (composer test family)
- `+1` scenario in `tests/test_banned_token_hook.sh` (Carbon date literal must NOT block)

### No breaking changes
```
