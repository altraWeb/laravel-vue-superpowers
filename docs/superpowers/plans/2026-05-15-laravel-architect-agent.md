# `laravel-architect` Agent Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Ship the fourth V2-MVP specialist agent — Eloquent + architecture audit, sibling-canon-aware (reads existing `app/Actions/`, `app/Services/`, etc. and recommends consistency).

**Architecture:** Single Markdown file (`agents/laravel-architect.md`). Unlike #1-#3 which reflect on vendor source, #4 reads the user's own codebase as ground truth. Same 5-section output shape.

**Spec:** `docs/superpowers/specs/2026-05-15-laravel-architect-agent-design.md`

---

## File Structure

| File | Purpose |
|---|---|
| `agents/laravel-architect.md` | The agent (frontmatter + body) |
| `README.md` | Append architect entry to Agents list |
| `docs/agents.md` | Insert architect entry, remove #4 from Forthcoming |
| `docs/superpowers/test-evidence/2026-05-15-architect-smoke-{1,2,3}.md` | Smoke evidence |

---

## Task 1: Write agent file

- [ ] **Write `agents/laravel-architect.md`** with full frontmatter + body per spec §3-§5
- [ ] **Verify:** `wc -l agents/laravel-architect.md` shows ~200-230 lines
- [ ] **Commit:** `git commit -m "feat(#4): add laravel-architect agent"`

## Task 2-4: Three parallel smoke tests

**Smoke 1 — N+1 catch:**
Input: `audit: Phase 3 implementation adds: foreach ($pages as $page) { echo $page->author->name; } in PagesController@index. $pages comes from Page::all().`
Expected: ❌ critical N+1, concrete `Page::with('author')` rewrite, `preventLazyLoading` mention

**Smoke 2 — Repository anti-pattern:**
Input: `audit: planning a new app/Repositories/PagesRepository with index() / show($id) / store(array $data) / delete($id) methods to wrap Page model queries.`
Expected: ⚠️ Repository anti-pattern flag with explanation + suggested alternative (Eloquent scopes / Action)

**Smoke 3 — Non-Laravel project:**
Input: `audit: Spring Boot + JPA architecture review for our microservice.`
Expected: Pre-flight SKIPPED, no false positives

- [ ] Dispatch smoke 1 (parallel)
- [ ] Dispatch smoke 2 (parallel)
- [ ] Dispatch smoke 3 (parallel)
- [ ] Capture outputs to evidence files
- [ ] **Commit:** `git commit -m "test(#4): three smoke tests — N+1 catch + Repository flag + non-Laravel SKIP"`

## Task 5-6: Docs + PR

**Important:** Branch was created BEFORE PR #36 (flux) merged. By the time #4 reaches docs-update step, check if #36 has landed:

- If yes: rebase #4 onto new main, then add architect entries (flux entries already there)
- If no: add ONLY architect entries; later rebase will resolve

- [ ] Check `git fetch && git log origin/main --oneline -3` for PR #36 (`feat(#3): laravel-flux-pro-specialist`)
- [ ] If merged: rebase
- [ ] Append `laravel-architect` entry to README Agents list (after pest-specialist or flux-specialist)
- [ ] Insert architect entry in `docs/agents.md` (after pest-specialist or flux-specialist)
- [ ] Remove `laravel-architect` line from Forthcoming list in `docs/agents.md`
- [ ] **Commit:** `git commit -m "docs(#4): README + docs/agents.md list laravel-architect"`
- [ ] `git push -u origin spec/4-laravel-architect-agent`
- [ ] Update PR body with smoke summary table
- [ ] `gh pr ready <PR-number>`

---

## Self-Review

Spec coverage: all spec sections mapped. No placeholders. Test naming consistent: `architect-smoke-1/2/3`. Limitation: smoke tests run in plugin repo without an actual Laravel app, so sibling-canon discovery falls back to "no app/ directory detected, generic recommendations" — that's still a valid test of the SKIP/WARNING paths.
