# `anti-silent-deferral` Hook Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans.

**Goal:** Ship the fourth plugin hook — PreToolUse Bash hook that blocks `git push` when any plan-doc on the branch has uncaptured Deferred Items sections.

**Architecture:** Same shell-only pattern as #16/#17/#18. Parses markdown sections with awk. New file: `hooks/anti-silent-deferral.sh`.

**Spec:** `docs/superpowers/specs/2026-05-15-anti-silent-deferral-hook-design.md`

---

## File Structure

| File | Purpose |
|---|---|
| `hooks/hooks.json` | Modified — add 4th entry |
| `hooks/anti-silent-deferral.sh` | Main hook |
| `tests/test_anti_silent_deferral_hook.sh` | Shell test driver, 11 scenarios |
| `README.md` | Append entry |
| `docs/hooks.md` | Insert entry, update Forthcoming |

---

## Task 1: hooks.json extend

- [ ] Add 4th entry under existing PreToolUse Bash matcher
- [ ] Commit

## Task 2: Script

- [ ] Create `hooks/anti-silent-deferral.sh` — workflow per spec §3.2 + parsing per §3.3 + validation per §3.4
- [ ] Awk-based section parsing handles both `—` (em-dash) and `-` (hyphen) header forms
- [ ] Make executable + syntax check
- [ ] Commit

## Task 3: Tests

- [ ] Create `tests/test_anti_silent_deferral_hook.sh` — 11 scenarios per spec §6
- [ ] Test driver sets up a tmp git repo with `main` branch + feature branch + plan-doc fixtures
- [ ] All 11 scenarios pass
- [ ] Regression: #16/#17/#18 still pass
- [ ] Commit

## Task 4: Docs

- [ ] README append entry
- [ ] docs/hooks.md insert entry, remove from Forthcoming
- [ ] Commit

## Task 5: Push + flip ready

- [ ] Push branch
- [ ] PR body update
- [ ] `gh pr ready`

---

## Self-Review

All spec sections mapped. Test scenarios cover happy path, all failure modes, override mechanism, multi-section docs. Limitation: requires `main` ref to exist (otherwise hook exits 0 — can't determine branch scope); document in spec §5.
