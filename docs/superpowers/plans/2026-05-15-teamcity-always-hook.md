# `teamcity-always` Hook Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Ship the third plugin hook — blocks `php artisan test` invocations missing `--teamcity` flag, with retry suggestion.

**Architecture:** Same single-shell-script pattern as #16/#17. Adds a third entry to `hooks/hooks.json`. **Deviation from issue spec:** issue says "auto-append" but the hook BLOCKS with a retry suggestion instead (auto-modify is not a portable Claude Code hook feature). 90% of the value at 10% of complexity.

**Spec:** `docs/superpowers/specs/2026-05-15-teamcity-always-hook-design.md`

---

## File Structure

| File | Purpose |
|---|---|
| `hooks/hooks.json` | Modified — add third entry |
| `hooks/teamcity-always.sh` | Main hook |
| `tests/test_teamcity_always_hook.sh` | Shell test driver, 9 scenarios |
| `README.md` | Append entry |
| `docs/hooks.md` | Insert entry, update Forthcoming |

---

## Task 1: hooks.json extend

- [ ] **Add third entry** under existing PreToolUse Bash matcher
- [ ] **Commit**

## Task 2: Script

- [ ] **Create `hooks/teamcity-always.sh`** per spec §3.2
- [ ] **Make executable + syntax check**
- [ ] **Commit**

## Task 3: Tests

- [ ] **Create `tests/test_teamcity_always_hook.sh`** with 9 scenarios
- [ ] **Run, all pass**
- [ ] **Run banned-token + no-claude-attribution regression** — all still pass
- [ ] **Commit**

## Task 4: Docs

- [ ] **README**: append teamcity-always to Hooks section
- [ ] **docs/hooks.md**: insert entry, remove from Forthcoming
- [ ] **Commit**

## Task 5: Push + flip ready

- [ ] `git push -u origin feat/18-teamcity-always-hook`
- [ ] Update PR body
- [ ] `gh pr ready <PR-number>`

---

## Self-Review

All spec sections mapped. No placeholders. Limitation: deviation from spec's "auto-append" to "block-with-retry" documented in spec §2 + §9 + flagged in PR body.
