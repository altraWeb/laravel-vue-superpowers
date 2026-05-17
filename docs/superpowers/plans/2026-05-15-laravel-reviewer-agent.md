# `laravel-reviewer` Agent Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Ship the fifth and final V2-MVP specialist agent — evidence-based code review that wraps the `laravel-code-review` skill with grep/find/Read tool access, banned-token sweep, sibling-canon verification, and specialist-agent composition recommendations.

**Architecture:** Single Markdown file (`agents/laravel-reviewer.md`) with frontmatter + workflow that reads `skills/laravel-code-review/SKILL.md` at runtime as scaffold. Same single-file pattern as #1-#4.

**Spec:** `docs/superpowers/specs/2026-05-15-laravel-reviewer-agent-design.md`

---

## File Structure

| File | Purpose |
|---|---|
| `agents/laravel-reviewer.md` | The agent |
| `README.md` | Append entry |
| `docs/agents.md` | Insert entry; **remove #5 from Forthcoming = empty Forthcoming, end of V2-MVP agent quintet** |
| `docs/superpowers/test-evidence/2026-05-15-reviewer-smoke-{1,2,3}.md` | Smoke evidence |

---

## Task 1: Write agent file

- [ ] **Write `agents/laravel-reviewer.md`** with full frontmatter + body per spec §3-§5
- [ ] **Verify:** `wc -l agents/laravel-reviewer.md` shows ~200-250 lines
- [ ] **Commit:** `git commit -m "feat(#5): add laravel-reviewer agent"`

## Task 2-4: Three parallel smoke tests

**Smoke 1 — Canonical scenario (multi-issue):**
Input: `audit review for PR changes: app/Http/Controllers/PostsController.php has foreach ($posts as $post) { $post->user->name } AND resources/views/posts/index.blade.php has <flux:tooltip><flux:button>...</flux:tooltip> AND comment "// Phase 3 implementation" in PostsController. Run banned-token sweep + propose specialist follow-ups.`
Expected: Blocker (N+1) + Should-fix (banned token + tooltip double-wrap mentioned for specialist follow-up) + Specialist recommendations (livewire + flux-pro)

**Smoke 2 — Clean PR:**
Input: `audit review for: app/Http/Controllers/PostsController.php has Post::with('user')->paginate(25) and calls $this->authorize('viewAny', Post::class). No Livewire/Flux/Pest code, no banned tokens.`
Expected: 0 issues, ready-to-merge verdict, no specialist recommendations needed

**Smoke 3 — Non-Laravel:**
Input: `review my Node.js Express controller for issues.`
Expected: Pre-flight SKIPPED, clean refusal

- [ ] Dispatch smoke 1 (parallel)
- [ ] Dispatch smoke 2 (parallel)
- [ ] Dispatch smoke 3 (parallel)
- [ ] Capture outputs
- [ ] **Commit:** `git commit -m "test(#5): three smoke tests — multi-issue + clean PR + non-Laravel SKIP"`

## Task 5: README + docs/agents.md

- [ ] **Append** `laravel-reviewer` entry to README Agents list (after architect)
- [ ] **Insert** full reviewer reference entry in `docs/agents.md` after architect, before Forthcoming
- [ ] **Remove** `laravel-reviewer` line from Forthcoming list in `docs/agents.md`
- [ ] After removal: Forthcoming section should be empty (end of V2-MVP agent quintet). Replace empty list with a one-line note: "_All V2-MVP agents shipped. See [ROADMAP.md](ROADMAP.md) for V2.1 forthcoming agents._"
- [ ] **Commit:** `git commit -m "docs(#5): README + docs/agents.md list laravel-reviewer — V2-MVP agent quintet complete"`

## Task 6: Push + flip PR ready

- [ ] `git push -u origin spec/5-laravel-reviewer-agent`
- [ ] Update PR body with smoke summary table
- [ ] `gh pr ready <PR-number>`

---

## Self-Review

Spec coverage: all spec sections mapped. No placeholders. Test naming consistent: `reviewer-smoke-1/2/3`.

Limitation: smoke tests run against plugin repo (no actual Laravel `app/` to grep, no changed files to scan). Validates prompt structure, skill-read fallback path, and stack-detection logic — not the evidence-gathering grep pipelines end-to-end. Real validation happens when the user invokes the agent in an actual Laravel project mid-PR.
