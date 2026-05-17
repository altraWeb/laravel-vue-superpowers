# `visual-companion-default-on` Hook Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans.

**Goal:** Ship the fifth plugin hook — first PostToolUse hook. Fires on `superpowers:brainstorming` skill invocation, injects `additionalContext` reminding the agent that Visual Companion is default-on unless topic is provably text-only.

**Architecture:** Same shell-only pattern. Adds a new PostToolUse Skill matcher block to `hooks/hooks.json` (separate from the existing PreToolUse Bash matcher).

**Spec:** `docs/superpowers/specs/2026-05-15-visual-companion-default-on-hook-design.md`

---

## File Structure

| File | Purpose |
|---|---|
| `hooks/hooks.json` | Modified — add new PostToolUse Skill matcher block |
| `hooks/visual-companion-default-on.sh` | Main hook |
| `tests/test_visual_companion_default_on_hook.sh` | Shell tests, 6 scenarios |
| `README.md` | Append entry |
| `docs/hooks.md` | Insert entry, remove from Forthcoming |

---

## Task 1: hooks.json — new PostToolUse Skill block

- [ ] Add new `PostToolUse` section in `hooks/hooks.json` with `Skill` matcher pointing to the new script
- [ ] Commit

## Task 2: Script

- [ ] Create `hooks/visual-companion-default-on.sh` per spec §3.2 + §3.4
- [ ] Filters to skill === `superpowers:brainstorming`, checks args against denylist + allowlist, emits additionalContext JSON
- [ ] Make executable + syntax check
- [ ] Commit

## Task 3: Tests

- [ ] Create `tests/test_visual_companion_default_on_hook.sh` — 6 scenarios per spec §5
- [ ] Run, all pass
- [ ] Regression: previous 36 hook scenarios still pass
- [ ] Commit

## Task 4: Docs

- [ ] README: append entry
- [ ] docs/hooks.md: insert entry, remove from Forthcoming
- [ ] Commit

## Task 5: Push + flip ready

- [ ] Push
- [ ] PR body
- [ ] `gh pr ready`

---

## Self-Review

All spec sections mapped. Deviation from issue AC (reminder vs. literal offer emit) documented in spec §7. Test scenarios cover skill-filter, denylist, allowlist, disable paths. Limitation: hook fires on skill invocation (not specifically Step 2) — additionalContext stays in agent context for the duration, achieving the spec intent.
