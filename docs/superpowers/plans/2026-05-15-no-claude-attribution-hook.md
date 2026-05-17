# `no-claude-attribution` Hook Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Ship the second plugin hook — PreToolUse Bash hook that blocks `git commit`, `gh pr create`, `glab mr create` invocations whose message contains Claude attribution.

**Architecture:** Same hook pattern as #16 (`banned-token-leak-guard`). Adds a second entry to `hooks/hooks.json` and a new script + tests + docs.

**Spec:** `docs/superpowers/specs/2026-05-15-no-claude-attribution-hook-design.md`

---

## File Structure

| File | Purpose |
|---|---|
| `hooks/hooks.json` | Modified — add second PreToolUse-Bash entry |
| `hooks/no-claude-attribution.sh` | Main hook implementation |
| `tests/test_no_claude_attribution_hook.sh` | Shell test driver, 10 scenarios |
| `README.md` | Append entry to Hooks section |
| `docs/hooks.md` | Insert entry, update Forthcoming |

---

## Task 1: Extend `hooks/hooks.json`

- [ ] **Add second hook entry** under the existing PreToolUse Bash matcher:
  ```json
  { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/no-claude-attribution.sh" }
  ```
- [ ] **Commit:** `git commit -m "feat(#17): register no-claude-attribution PreToolUse hook"`

## Task 2: Write hook script

- [ ] **Create `hooks/no-claude-attribution.sh`** with full workflow per spec §3.2 + §3.3 + §4. Reuse the config-read pattern from `banned-token-leak-guard.sh`.
- [ ] **Make executable** + `bash -n` syntax check
- [ ] **Commit:** `git commit -m "feat(#17): no-claude-attribution hook script"`

## Task 3: Shell test driver

- [ ] **Create `tests/test_no_claude_attribution_hook.sh`** with 10 scenarios per spec §6
- [ ] **Make executable**, run all, all pass
- [ ] **Commit:** `git commit -m "test(#17): shell test driver — 10 scenarios pass"`

## Task 4: Docs

- [ ] **Append `no-claude-attribution` to README Hooks section**
- [ ] **Insert entry in `docs/hooks.md`** after `banned-token-leak-guard`, before Forthcoming. Remove from Forthcoming list.
- [ ] **Commit:** `git commit -m "docs(#17): README + docs/hooks.md list no-claude-attribution"`

## Task 5: Push + flip PR ready

- [ ] `git push -u origin feat/17-no-claude-attribution-hook`
- [ ] Update PR body with test summary
- [ ] `gh pr ready <PR-number>`

---

## Self-Review

Spec coverage: all spec sections mapped to tasks. No placeholders. Test naming consistent: `test_no_claude_attribution_hook.sh`. Limitation: editor-mode `git commit` (no `-m`) cannot be intercepted — documented in spec §2 Non-Goals and in the hook diagnostic.
