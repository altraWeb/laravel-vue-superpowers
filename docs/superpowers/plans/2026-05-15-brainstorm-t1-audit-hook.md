# `brainstorm-t1-audit` Hook Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans.

**Goal:** Ship the sixth and final V2-MVP hook — PostToolUse on `superpowers:brainstorming` that emits a reminder for the parent agent to dispatch `laravel-best-practices` as a parallel T1-audit task.

**Architecture:** Same shell-only pattern as the other 5 hooks. Adds entry to existing PostToolUse Skill matcher in `hooks/hooks.json`.

**Spec deviation:** issue asks for "auto-dispatch Agent in background". Hooks cannot invoke agents (architecture constraint). Hook injects a REMINDER + canonical dispatch prompt template via `additionalContext`. Parent agent does the Task-tool dispatch. 80% of spec value at 10% of complexity.

**Spec:** `docs/superpowers/specs/2026-05-15-brainstorm-t1-audit-hook-design.md`

---

## File Structure

| File | Purpose |
|---|---|
| `hooks/hooks.json` | Modified — add second PostToolUse Skill entry |
| `hooks/brainstorm-t1-audit.sh` | Main hook |
| `tests/test_brainstorm_t1_audit_hook.sh` | Shell tests, 5 scenarios |
| `README.md` | Append entry |
| `docs/hooks.md` | Insert entry + remove all from Forthcoming (last V2-MVP hook) |

---

## Tasks

1. Add entry to hooks.json under existing PostToolUse Skill block
2. Write `hooks/brainstorm-t1-audit.sh` per spec §3.2 + §4
3. Write `tests/test_brainstorm_t1_audit_hook.sh` with 5 scenarios per spec §6
4. Update README + docs/hooks.md
5. Push + merge + delete branch

---

## Self-Review

All spec sections mapped. Test scenarios cover skill-filter, disable paths, malformed-input safety. Limitation: deviation from auto-dispatch documented in spec §2 + §8 — preserved in PR body.
