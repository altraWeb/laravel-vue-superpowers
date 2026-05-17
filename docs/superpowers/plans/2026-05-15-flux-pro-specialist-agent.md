# `laravel-flux-pro-specialist` Agent Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans. Plan steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the third V2-MVP specialist agent — Flux Pro v2 Blade-component audit, vendor-source traversal as default ground truth, catches the double-tooltip a11y bug and 4 other Flux 2 stolperer.

**Architecture:** Single Markdown file (`agents/laravel-flux-pro-specialist.md`) with frontmatter + 5-section workflow. Reads `vendor/livewire/flux-pro/stubs/resources/views/flux/` Blade files via Read tool (no PHP reflection — Flux components are Blade templates). Mirrors pattern from `laravel-livewire-specialist` and `laravel-pest-specialist`.

**Spec:** `docs/superpowers/specs/2026-05-15-flux-pro-specialist-agent-design.md`

---

## File Structure

| File | Purpose |
|---|---|
| `agents/laravel-flux-pro-specialist.md` | The agent |
| `README.md` | Append entry to Agents list |
| `docs/agents.md` | Insert entry + remove #3 from Forthcoming |
| `docs/superpowers/test-evidence/2026-05-15-flux-pro-specialist-smoke-{1,2,3}.md` | Captured smoke outputs |

---

## Task 1: Write agent file

- [ ] **Write `agents/laravel-flux-pro-specialist.md`** with frontmatter + 5-section workflow body (full content in spec §3 + §4)
- [ ] **Verify:** `wc -l agents/laravel-flux-pro-specialist.md` shows ~200 lines, valid YAML frontmatter at top
- [ ] **Commit:** `git commit -m "feat(#3): add laravel-flux-pro-specialist agent"`

## Task 2-4: Three smoke tests (parallel dispatch via Task tool)

For each test:
1. Dispatch agent via Task tool (general-purpose, sonnet) with the agent file as system prompt + sample input
2. Capture output to `docs/superpowers/test-evidence/2026-05-15-flux-pro-specialist-smoke-N.md`
3. Verify expected behavior

**Smoke 1 — Canonical bug (double-wrap tooltip):**
Input: `"audit: planning <flux:tooltip content='Bold formatting'><flux:editor.button icon='bold' wire:click='format'>B</flux:editor.button></flux:tooltip> in toolbar"`
Expected: ❌ critical double-wrap with vendor citation, suggests removing outer + using tooltip prop

**Smoke 2 — Clean phase (separate position/align):**
Input: `"audit: planning <flux:dropdown position='bottom' align='end'><flux:button>Menu</flux:button></flux:dropdown>"`
Expected: ✅ all checks pass, position/align uses project canon

**Smoke 3 — Non-Flux project (Bootstrap audit):**
Input: `"audit: I'm using Bootstrap 5 dropdowns in my Symfony app. Check for issues."`
Expected: Pre-flight SKIPPED, no false positives

- [ ] Dispatch smoke 1, capture to evidence file
- [ ] Dispatch smoke 2, capture to evidence file
- [ ] Dispatch smoke 3, capture to evidence file
- [ ] **Commit:** `git commit -m "test(#3): three smoke tests — double-wrap catch + clean phase + non-Flux SKIP"`

## Task 5: README + docs/agents.md

- [ ] **Append** `laravel-flux-pro-specialist` entry to README Agents list (after pest-specialist)
- [ ] **Insert** full agent reference entry in `docs/agents.md` after pest-specialist, before Forthcoming
- [ ] **Remove** `laravel-flux-pro-specialist` line from Forthcoming list in docs/agents.md
- [ ] **Commit:** `git commit -m "docs(#3): README + docs/agents.md list laravel-flux-pro-specialist"`

## Task 6: Push + flip PR ready

- [ ] `git push -u origin spec/3-flux-pro-specialist-agent`
- [ ] Update PR body with smoke test summary table
- [ ] `gh pr ready <PR-number>`

---

## Self-Review

Spec coverage: all 6 spec sections mapped to tasks above. No placeholders. File paths consistent. Test naming consistent: `flux-pro-specialist-smoke-1/2/3`. Known limitation same as #1/#2: smoke tests run against plugin repo (no real Flux vendor), validates prompt structure not vendor-read end-to-end.
