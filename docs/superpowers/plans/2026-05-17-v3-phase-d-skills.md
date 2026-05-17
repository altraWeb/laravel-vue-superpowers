# V3 Phase D — Skills — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Land Phase D of the V3 Megarelease — three Laravel-specific skills (a11y patterns, MR body writer, perf auditor). Ship as v3.0.0-alpha.4.

**Architecture:** Three skill directories with `SKILL.md` files following the established V2.0.1 skill pattern (YAML frontmatter with `name` + `description`; body with structured guidance). Skills are PROCESS skills — they describe HOW to do something, not WHAT to do. Read-only, no code execution.

**Tech Stack:** Markdown only. Skills get auto-discovered by Claude Code from `skills/<name>/SKILL.md` paths.

**Spec:** `docs/superpowers/specs/2026-05-17-v3-livewire-megarelease-design.md` Section 5 — Phase D.

**Issues:** [#6](https://github.com/altraWeb/laravel-livewire-superpowers/issues/6), [#8](https://github.com/altraWeb/laravel-livewire-superpowers/issues/8), [#11](https://github.com/altraWeb/laravel-livewire-superpowers/issues/11)

---

## File Structure

### New files

| File | Purpose |
|---|---|
| `skills/laravel-a11y-specialist/SKILL.md` | WCAG 2.2 + ARIA + reduced-motion patterns. Livewire-flavored (wire:loading + wire:target accessible patterns) |
| `skills/laravel-mr-body-writer/SKILL.md` | Canonical merge-request body generator from sprint state (plan-doc, `/status` output, git history) |
| `skills/laravel-perf-auditor/SKILL.md` | `preventLazyLoading` enforcement + N+1 query patterns + cache strategy |

### Modified files

| File | Change |
|---|---|
| `README.md` | Skills section already says "Skills (7)" (Phase A.2 target); confirm 3 new skills are listed in the comparison table |
| `CHANGELOG.md` | Prepend `## [3.0.0-alpha.4]` section |
| `.claude-plugin/plugin.json` | Bump version `3.0.0-alpha.3` → `3.0.0-alpha.4`; description current-state skill count `4` → `7` |

### Branch / release

- Feature branch: `feat/v3-phase-d-skills`
- Post-merge: tag `v3.0.0-alpha.4` + GitHub Pre-Release

---

## STEP D.1 — Foundation

### Task 1: Pre-flight + create feature branch

**Files:** None.

- [ ] **Step 1: Verify clean post-Phase-C main state**

```bash
cd ~/dev/laravel-livewire-superpowers
git status
git log --oneline -3
git tag --list | grep '^v3\.'
```

Expected: clean working tree, HEAD at Phase C merge (post-`90bd27e`). Tags v3.0.0-alpha.1, .2, .3 present.

- [ ] **Step 2: Run baseline tests**

```bash
for t in tests/test_*.sh; do bash "$t" >/dev/null 2>&1 && echo "✓ $t" || echo "✗ $t"; done
python3 -m pytest tests/ -q
```

Expected: 10 shell `✓`, 30 Python `passed`.

- [ ] **Step 3: Create branch**

```bash
git switch -c feat/v3-phase-d-skills
git branch
```

---

## STEP D.2 — Skill 1: laravel-a11y-specialist (#6)

WCAG 2.2 + ARIA + reduced-motion guidance, Livewire-flavored.

### Task 2: Write `skills/laravel-a11y-specialist/SKILL.md`

**Files:**
- Create: `skills/laravel-a11y-specialist/SKILL.md`

- [ ] **Step 1: Create directory + write skill file**

```bash
mkdir -p skills/laravel-a11y-specialist
```

Then use Write tool to create `skills/laravel-a11y-specialist/SKILL.md` with EXACTLY this content:

````markdown
---
name: laravel-a11y-specialist
description: "Use in Laravel + Livewire 4 + Flux Pro v2 projects when building any UI surface that has dynamic content, loading states, animations, audio, or user-perceptible state changes. Surfaces WCAG 2.2 + ARIA + reduced-motion patterns systematically (role/aria-live/aria-busy/wire:loading.attr/prefers-reduced-motion/Page-Visibility) instead of leaving them to per-phase audit discovery. In Livewire codebases, use this alongside superpowers:frontend-design (if available) for stack-specific depth. Trigger on any 'AI panel', 'streaming', 'loading state', 'notification', 'modal', 'animation', 'sound', 'toast', or any UI with perceivable state changes."
---

# Laravel + Livewire Accessibility Specialist

You are guiding accessibility decisions for Laravel + Livewire 4 + Flux Pro v2 UIs. Your job is to surface canonical a11y patterns BEFORE the operator implements, so accessibility is built-in rather than retrofitted via audit.

## Core principle

Every dynamic UI surface needs an explicit accessibility decision. The default behavior is usually wrong:
- Streaming content without `aria-live="off"` spams screen readers
- Loading spinners without `aria-busy` leave SR users with no progress signal
- Animations without `prefers-reduced-motion` cause motion-sickness for some users
- Sounds without operator control violate WCAG 2.2 §1.4.2

## The 7 canonical patterns

### 1. Live region for status / streaming text

For containers that update with per-token text (AI responses, streaming output):

```html
<!-- Container: announce changes politely -->
<div role="status" aria-live="polite" aria-atomic="false">
  <!-- Streaming text inside -->
  <pre aria-live="off">{{ $streamingContent }}</pre>
</div>
```

**Why:** `role="status"` is the WCAG-recommended container for transient status messages. `aria-live="polite"` queues announcements rather than interrupting. The INNER `<pre>` overrides with `aria-live="off"` because per-token updates would create SR spam.

**Anti-pattern:** `aria-live="assertive"` on streaming containers — interrupts every other SR announcement.

### 2. Livewire loading-state with aria-busy

For Livewire components that update on user action:

```html
<div wire:loading.attr="aria-busy" wire:target="sendMessage">
  <flux:button wire:click="sendMessage">Send</flux:button>
</div>
```

**Why:** `wire:loading.attr="aria-busy"` automatically sets `aria-busy="true"` on the container during the request. SR users hear "busy" announcement. `wire:target` scopes it to the specific action.

**Anti-pattern:** Building a fake server-side getter like `$this->isLoading` then binding `aria-busy="{{ $isLoading }}"` — fabricated API that doesn't exist in Livewire's contract.

### 3. Skip-to-content link

Every page needs a keyboard-only escape hatch from the header navigation:

```html
<a href="#main" class="sr-only focus:not-sr-only focus:fixed focus:top-2 focus:left-2 focus:z-50 ...">
  Skip to main content
</a>
<header>...</header>
<main id="main">...</main>
```

**Why:** WCAG 2.1 §2.4.1. Keyboard users tab through every header link before reaching content without this.

### 4. Reduced-motion suppression

For ANY animation longer than ~200ms or any animation that loops:

```css
@media (prefers-reduced-motion: reduce) {
  .animate-pulse, .animate-spin, [class*="transition-"] {
    animation: none !important;
    transition: none !important;
  }
}
```

Combine with Page-Visibility API for resource-saving:

```js
document.addEventListener('visibilitychange', () => {
  if (document.hidden) {
    // pause animations / poll loops / audio
  } else {
    // resume
  }
});
```

**Why:** Vestibular disorders, motion sickness, ADHD distraction. WCAG 2.3.3 (Animation from Interactions, AAA).

### 5. Audio Control (WCAG 2.2 §1.4.2)

Only applies to sounds **longer than 3 seconds**. Short notification sounds (<3s) are exempt. For longer audio:

```html
<audio controls preload="metadata">
  <source src="..." type="audio/mpeg">
</audio>
<!-- OR -->
<button @click="pause()" aria-label="Mute notifications">🔇</button>
```

**Why:** Auto-playing audio interferes with SR speech. User MUST have a mute/pause control accessible without skipping the rest of the content.

### 6. Modal focus management

```html
<flux:modal>
  <!-- First focusable element auto-focused on open -->
  <input type="text" autofocus>
  <!-- Trap focus inside modal until close -->
  <!-- Escape key closes (handled by Flux internally) -->
</flux:modal>
```

When implementing your own modal: ensure `<dialog>` element or focus trap + return-focus-to-trigger on close.

**Why:** WCAG 2.4.3 Focus Order. Without trap, keyboard users tab into background content while modal is "open" — confusing AND broken.

### 7. Form validation announcements

```html
<input wire:model.live="email" id="email" aria-describedby="email-error">
@error('email')
  <span id="email-error" role="alert">{{ $message }}</span>
@enderror
```

**Why:** `role="alert"` announces validation errors to SR users immediately. `aria-describedby` links the input to the error so SR users hear the error when the input is focused.

## When in doubt

If you're uncertain whether a specific UI element needs accessibility consideration, run this quick checklist:

1. Does it change without user action? → live region
2. Does it indicate progress? → aria-busy / role="progressbar"
3. Does it animate? → prefers-reduced-motion query
4. Does it produce sound > 3s? → audio control required
5. Does it trap keyboard focus? → focus trap + return-focus

If yes to any → consult the specific pattern above before implementing.

## Resources

- [WCAG 2.2 Quick Reference](https://www.w3.org/WAI/WCAG22/quickref/)
- [Livewire Loading States docs](https://livewire.laravel.com/docs/wire-loading)
- [Flux Pro v2 Modal a11y notes](vendor/livewire/flux-pro/stubs/) — check vendor source for canonical patterns
- [WAI-ARIA Authoring Practices](https://www.w3.org/WAI/ARIA/apg/)
````

- [ ] **Step 2: Verify YAML frontmatter**

```bash
python3 -c "
import re, yaml
content = open('skills/laravel-a11y-specialist/SKILL.md').read()
m = re.match(r'^---\n(.*?)\n---\n', content, re.DOTALL)
fm = yaml.safe_load(m.group(1))
assert fm['name'] == 'laravel-a11y-specialist'
print('✓ frontmatter valid')
"
```

---

## STEP D.3 — Skill 2: laravel-mr-body-writer (#8)

Canonical MR-body generator from sprint state.

### Task 3: Write `skills/laravel-mr-body-writer/SKILL.md`

**Files:**
- Create: `skills/laravel-mr-body-writer/SKILL.md`

- [ ] **Step 1: Create directory + write skill file**

```bash
mkdir -p skills/laravel-mr-body-writer
```

Use Write tool for `skills/laravel-mr-body-writer/SKILL.md` with EXACTLY this content:

````markdown
---
name: laravel-mr-body-writer
description: "Use in Laravel projects when writing a merge-request / pull-request body at sprint close-out. Generates the canonical MR shape (Summary / Decisions / Pilot 2.0 contract / Spec + Plan link / Test plan with file paths + assertion counts / Scope changes / Deferred items / Follow-up issues / Screenshots) from the project's plan-doc, /laravel-livewire-superpowers:status output, and git history. Standardizes the 15-minute manual close-out task. Trigger on 'write MR body', 'PR description', 'sprint close-out', 'ready to merge', or before pushing a feature branch."
---

# Laravel MR Body Writer

You are generating the canonical merge-request body for a finished Laravel sprint. The output goes into the MR/PR description; reviewers depend on this structure to know what shipped.

## The canonical MR body shape

```markdown
## Summary

<1-2 paragraphs: what changed, why it matters. Lead with the user-visible outcome, not the implementation.>

## Decisions locked in brainstorm

<bullet list of the 3-5 major decisions made during brainstorming. e.g.:
- Use Spatie Permission's existing user-private channel for fan-out (no new channel)
- Component-based architecture vs trait-based (component won for testability)
- Pest 4 browser plugin instead of Dusk (already in stack)>

## Pilot 2.0 contract

- T1 Best-Practices Audit: ✓ dispatched 2026-05-14 (see `docs/superpowers/audits/2026-05-14-<topic>-audit.md`)
- T2 Visual Companion: ✓ offered, used for layout mockups
- T3 Per-Commit Review: ✓ all commits reviewed by `laravel-reviewer` agent
- T4 Pre-Test-Write Audit: ✓ `laravel-pest-specialist` invoked before each test file
- T5 Banned-Token Sweep: ✓ automated via pre-push hook
- T6 Deferred-Items Check: ✓ automated via pre-push hook

(Do NOT include memory-file paths — reviewers can't resolve them. Use repo paths only.)

## Spec + Plan

- Spec: [`docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`](docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md)
- Plan: [`docs/superpowers/plans/YYYY-MM-DD-<topic>.md`](docs/superpowers/plans/YYYY-MM-DD-<topic>.md)

## Test plan

- [x] `tests/Feature/<Topic>Test.php` — N assertions
- [x] `tests/Browser/<Topic>BrowserTest.php` — M scenarios
- [x] `tests/Unit/<Service>Test.php` — K cases
- [ ] Reviewer manually verifies <UX-thing>

## Scope changes from original plan

<This section is critical for review transparency. Explicit list of:
- Audit-driven simplifications (e.g., "Removed proposed `SoundShouldPlay` event after laravel-echo-reverb-specialist showed user-private channel already fans out the data")
- SUPERSEDED tasks (e.g., "Task 4.3 originally proposed Service+Repository pattern; switched to single Action class for sibling-canon consistency")
- Any deviation from the locked plan

If NO scope changes, write: `**None — implemented as planned.**`>

## Deferred items

<Either:
**None — all tasks completed.**

Or:
- Improve X — filed as #N
- Refactor Y — filed as #M

(Every deferred item MUST have an issue link. Bare bullets without `#N` will be flagged by the anti-silent-deferral hook and block the push.)>

## Follow-up issues filed during sprint

- Related to #N — <description>
- Related to #M — <description>

(GitLab keyword: `Related to #` does NOT auto-close the issue on merge. Use `Closes #` only if THIS MR resolves the linked issue completely.)

## Screenshots

<Always include for any UI change:
- Before / after pair if modifying existing UI
- Screen recording / GIF for animations or state transitions
- Mobile + desktop if responsive
- Light + dark mode if both apply>
```

## How to generate the body

### Step 1: Gather inputs

Run in parallel:

```bash
# Plan-doc
ls docs/superpowers/plans/*.md docs/plans/*.md 2>/dev/null | head -3

# Sprint state
/laravel-livewire-superpowers:status

# Commits on the branch
git log main..HEAD --format='%h %s'

# Test files touched on the branch
git diff main..HEAD --name-only -- 'tests/' | head -20

# Spec-doc
ls docs/superpowers/specs/*.md 2>/dev/null | tail -3
```

### Step 2: Extract from plan-doc

For each `## Phase N` section:
- Status (complete / in-progress / deferred)
- Tactic markers (T1/T2/T3/T4) — pull into Pilot 2.0 section
- Deferred items section (with issue links)

### Step 3: Count test assertions

For each test file in the diff:

```bash
grep -cE "(it|test)\(|expect\(" tests/path/to/TestFile.php
```

For Pest browser tests, count `->visit()` calls as scenarios.

### Step 4: Identify scope changes

Compare the original plan-doc tasks vs what actually shipped (git diff). Flag:
- Tasks marked SUPERSEDED in the plan-doc
- Tasks in the plan but not in the diff (deferred without note)
- Tasks in the diff but not in the plan (scope creep)

### Step 5: Assemble + emit

Use the canonical shape above. Fill in concrete content from Steps 1-4. Output as final MR-body markdown.

## When in doubt

If the plan-doc is missing or the sprint didn't follow Pilot 2.0 explicitly, generate a SIMPLIFIED MR body:
- Summary
- What changed (bullet list from git log)
- Test plan
- Screenshots

Skip the Pilot 2.0 / Decisions / Spec sections rather than fabricating them. Note in the MR body: `(simplified shape — sprint did not follow Pilot 2.0 contract)`.

## Anti-patterns

- **Memory-file paths in MR body.** Reviewers can't resolve `~/.claude/agent-memory/...` paths. Use repo paths only.
- **Bare deferred-items without issue links.** The anti-silent-deferral hook will block the push.
- **`Closes #N` for partial fixes.** Only use `Closes` when the MR fully resolves the linked issue. Use `Related to #N` otherwise.
- **Forgetting screenshots for UI changes.** Reviewers need visual confirmation. A wall of code without an attached image is a slow review.
````

- [ ] **Step 2: Verify frontmatter**

```bash
python3 -c "
import re, yaml
content = open('skills/laravel-mr-body-writer/SKILL.md').read()
m = re.match(r'^---\n(.*?)\n---\n', content, re.DOTALL)
fm = yaml.safe_load(m.group(1))
assert fm['name'] == 'laravel-mr-body-writer'
print('✓ frontmatter valid')
"
```

---

## STEP D.4 — Skill 3: laravel-perf-auditor (#11)

`preventLazyLoading` + N+1 query patterns + cache strategy mechanical sweep.

### Task 4: Write `skills/laravel-perf-auditor/SKILL.md`

**Files:**
- Create: `skills/laravel-perf-auditor/SKILL.md`

- [ ] **Step 1: Create directory + write skill file**

```bash
mkdir -p skills/laravel-perf-auditor
```

Use Write tool for `skills/laravel-perf-auditor/SKILL.md` with EXACTLY this content:

````markdown
---
name: laravel-perf-auditor
description: "Use in Laravel projects when reviewing a diff for query-path safety, specifically: preventLazyLoading enforcement status, N+1 patterns, cache strategy adherence. Complements the broader laravel-architect agent (architect does deep architectural decisions; this skill does mechanical 'is this query path safe?' sweep). Trigger before merging any feature with new Eloquent queries, before shipping a controller endpoint, or on quarterly perf-debt review. Use the laravel-architect agent for design decisions; use this skill for spot-checks on existing code."
---

# Laravel Performance Auditor

You are doing a mechanical performance sweep of a Laravel diff. Focus: query-path safety. NOT scope: SQL optimization, denormalization decisions, infra (those belong to architect or DBA).

## The 5 checks

### 1. `preventLazyLoading` is on in non-prod

Open `app/Providers/AppServiceProvider.php` and verify the `boot()` method contains:

```php
public function boot(): void
{
    Model::preventLazyLoading(! $this->app->isProduction());
}
```

**Why:** in non-prod, lazy loading throws `LazyLoadingViolationException` instead of silently issuing N queries. Catches N+1 at dev time.

**Findings:**
- Not present at all → **Blocker** for any non-trivial app (every dev needs this guardrail)
- Present but `! isProduction()` removed → check rationale (it should NEVER be on in prod, but the guard should be active in dev)

### 2. N+1 patterns in the diff

Search for `foreach` / `->each(` / `->map(` blocks that access Eloquent relationships:

```bash
# Find loops that touch related models
grep -rEn 'foreach.*\$.*->.*->' app/ resources/views/ 2>/dev/null | head -20
grep -rEn '->each\(.*->.*->' app/ 2>/dev/null | head -20
```

For each match, check whether the originating query has `->with(['relation'])` or `->load(['relation'])`.

**Pattern that's safe:**

```php
$posts = Post::with('author')->get();
foreach ($posts as $post) {
    echo $post->author->name; // Eager-loaded — 1 query total
}
```

**Pattern that's a bug:**

```php
$posts = Post::all();
foreach ($posts as $post) {
    echo $post->author->name; // N+1 — 1 + N queries
}
```

**Findings:**
- N+1 pattern without eager-load → **Blocker** (in non-prod with preventLazyLoading: throws; in prod: silent perf-cliff)
- Conditional N+1 (only triggers in certain branches) → **Should-fix** (eager-load conditionally via `->loadMissing()`)

### 3. Cache strategy on hot paths

For any controller action or Livewire method that:
- Hits the database
- Is called frequently (e.g., on every page render)
- Returns data that doesn't change per-request

…check whether it uses cache:

```php
// Acceptable patterns
Cache::remember('home.featured', now()->addHours(1), fn () => Post::featured()->get());
Cache::tags(['posts'])->remember(...);
```

**Findings:**
- Hot path with no cache → **Should-fix** (consider remember-with-TTL or tags)
- Cache without invalidation strategy → **Should-fix** (every cache needs documented invalidation)
- `Cache::forever()` → **Blocker** unless explicitly justified (memory leak risk)

### 4. Query count pinning in tests

For any feature test that exercises a list-rendering controller / page:

```php
test('post list page has no N+1 queries')->expect(function () {
    DB::enableQueryLog();
    $this->get('/posts');
    return collect(DB::getQueryLog())->count();
})->toBeLessThan(5); // hard cap
```

**Findings:**
- New list-rendering endpoint without query-count test → **Should-fix** (add via Pest helper)
- Existing query-count test that doesn't include the new endpoint → **Nice-to-have** (extend)

### 5. Pagination on unbounded queries

For any controller that returns a collection:

```php
// Safe — paginated
return Post::published()->paginate(20);

// Unsafe — entire table to memory
return Post::all();
```

**Findings:**
- `->all()` / `->get()` without explicit limit on tables that can grow > 1000 rows → **Should-fix**
- API endpoint returning unbounded collection → **Blocker** (memory + client-render hazard)

## Output format

```markdown
# laravel-perf-auditor findings

## Scope of audit

- Files reviewed: N (from diff)
- Eloquent queries touched: N
- Cache call sites: N
- Test files: N

## Pre-flight

- `preventLazyLoading` status: ✓ enabled in non-prod | ✗ disabled (Blocker) | ⚠️ not configured

## Findings

### Blocker
- [list with file:line refs]

### Should-fix
- [list]

### Nice-to-have
- [list]

## Recommendations

<concrete next steps prioritized by severity>
```

## When in doubt

If the diff has < 10 lines of Eloquent code, skip the deep N+1 scan and just verify preventLazyLoading status (1-line check).

If the diff is large but mostly view changes (no controller / model touches), report `Scope: insufficient query-path code to audit; no findings.`

Don't fabricate findings. If everything looks fine, say so. "No issues found" is a legitimate output.
````

- [ ] **Step 2: Verify frontmatter**

```bash
python3 -c "
import re, yaml
content = open('skills/laravel-perf-auditor/SKILL.md').read()
m = re.match(r'^---\n(.*?)\n---\n', content, re.DOTALL)
fm = yaml.safe_load(m.group(1))
assert fm['name'] == 'laravel-perf-auditor'
print('✓ frontmatter valid')
"
```

---

## STEP D.5 — Shared updates

### Task 5: Confirm README skills section reflects all 7 skills

**Files:**
- Modify (potentially): `README.md`

The README already says `## Skills (7)` (Phase A.2 used the V3-target count). Verify the comparison table at line ~100-109 lists all 7 skills (4 V2 + 3 Phase D). If the 3 new skills are missing from the table, add them.

- [ ] **Step 1: Read the current Skills section**

```bash
sed -n '/^## Skills/,/^## /p' README.md | head -50
```

- [ ] **Step 2: If the Phase D skills are missing from any list/table, add them**

Use Edit to extend the skill comparison table with:

```markdown
| (none — Laravel-only) | laravel-a11y-specialist | WCAG 2.2 + ARIA + reduced-motion patterns (Livewire-flavored) |
| (none) | laravel-mr-body-writer | Canonical MR body generator from sprint state |
| (none) | laravel-perf-auditor | preventLazyLoading + N+1 + cache mechanical sweep |
```

(Or adapt to existing table headers — read the actual table structure first.)

- [ ] **Step 3: Verify count is correct (post Phase D = 7)**

```bash
grep -nE 'Skills? \([0-9]+\)' README.md
```

Should show `Skills (7)` — already correct from Phase A.2 target.

### Task 6: Prepend v3.0.0-alpha.4 CHANGELOG entry

**Files:**
- Modify: `CHANGELOG.md`

- [ ] **Step 1: Insert above `## [3.0.0-alpha.3]`**

```markdown
## [3.0.0-alpha.4] — 2026-05-17 — V3 Megarelease — Phase D: Skills

Phase D adds three Laravel-specific skills (process guidance, not code execution). All three are read-only.

### Added

- **[#6](https://github.com/altraWeb/laravel-livewire-superpowers/issues/6) `laravel-a11y-specialist` skill.** WCAG 2.2 + ARIA + reduced-motion patterns surfaced systematically before implementation. Livewire-flavored (wire:loading.attr accessible patterns, aria-live for streaming content, prefers-reduced-motion + Page-Visibility). 7 canonical patterns + checklist.
- **[#8](https://github.com/altraWeb/laravel-livewire-superpowers/issues/8) `laravel-mr-body-writer` skill.** Canonical MR / PR body generator from sprint state. Reads plan-doc + `/laravel-livewire-superpowers:status` output + git history + test files to assemble the standard MR shape (Summary / Decisions / Pilot 2.0 contract / Spec + Plan / Test plan with assertion counts / Scope changes / Deferred items / Follow-up issues / Screenshots).
- **[#11](https://github.com/altraWeb/laravel-livewire-superpowers/issues/11) `laravel-perf-auditor` skill.** Mechanical query-path safety sweep. Checks preventLazyLoading status, N+1 patterns, cache strategy, query-count test coverage, unbounded-query pagination. Complements `laravel-architect` agent (agent does design decisions; this skill does spot-checks).

### Changed

- `.claude-plugin/plugin.json` version `3.0.0-alpha.3` → `3.0.0-alpha.4`. Description current-state skill count `4` → `7`.
- README skills comparison table extended with 3 new entries (if not already present from Phase A.2 placeholders).

### Phase Status

Phase D (this alpha) — ✅ shipped 2026-05-17 as v3.0.0-alpha.4.

Phases E-G remain.

---

```

### Task 7: Bump plugin.json version + skill count

**Files:**
- Modify: `.claude-plugin/plugin.json`

- [ ] **Step 1: Bump version**

Edit: `"version": "3.0.0-alpha.3"` → `"version": "3.0.0-alpha.4"`.

- [ ] **Step 2: Update description current-state count**

Find the description's `4 skills` or `4 enhanced skills` reference and update to `7 skills`. Adapt to actual phrasing.

- [ ] **Step 3: Validate**

```bash
python3 -c 'import json; p = json.load(open(".claude-plugin/plugin.json")); print(p["name"], p["version"])'
```

Expected: `laravel-livewire-superpowers 3.0.0-alpha.4`

### Task 8: Test verification

```bash
for t in tests/test_*.sh; do bash "$t" >/dev/null 2>&1 && echo "✓ $t" || echo "✗ $t"; done
python3 -m pytest tests/ -q
ls skills/ | wc -l
```

Expected: 10 shell `✓`, 30 Python `passed`, `skills/` directory has 7 entries.

Verify 3 new skill frontmatters one more time:
```bash
for s in laravel-a11y-specialist laravel-mr-body-writer laravel-perf-auditor; do
    python3 -c "
import re, yaml
c = open('skills/$s/SKILL.md').read()
m = re.match(r'^---\n(.*?)\n---\n', c, re.DOTALL)
fm = yaml.safe_load(m.group(1))
assert fm['name'] == '$s'
print('✓ $s')
"
done
```

### Task 9: Commit + PR

```bash
git add skills/laravel-a11y-specialist skills/laravel-mr-body-writer skills/laravel-perf-auditor \
        README.md CHANGELOG.md .claude-plugin/plugin.json
git commit -m "$(cat <<'EOF'
feat(v3): phase d — skills (a11y, mr-body-writer, perf-auditor)

Phase D of the V3 Megarelease ships three Laravel-specific skills
that surface guidance systematically rather than via per-phase audits.
All read-only process skills.

Skills:
- laravel-a11y-specialist (#6): WCAG 2.2 + ARIA + reduced-motion
  patterns. 7 canonical patterns covering live regions, loading
  states (Livewire wire:loading.attr), skip-links, reduced-motion,
  audio control, modal focus, form validation announcements.
- laravel-mr-body-writer (#8): Canonical MR-body generator from
  sprint state. Reads plan-doc + status output + git history to
  assemble the standard MR shape (Summary / Decisions / Pilot 2.0
  / Spec + Plan / Test plan / Scope changes / Deferred / Follow-ups
  / Screenshots).
- laravel-perf-auditor (#11): Mechanical query-path safety sweep.
  preventLazyLoading status, N+1 patterns, cache strategy,
  query-count pinning, pagination. Complements laravel-architect
  agent for spot-checks.

Shared:
- plugin.json version 3.0.0-alpha.4, skill count 4 -> 7.
- CHANGELOG [3.0.0-alpha.4] entry.
- README skills section reflects 7 total.

All 10 shell + 30 Python tests still green.
EOF
)"

git push -u origin feat/v3-phase-d-skills

gh pr create \
  --base main \
  --head feat/v3-phase-d-skills \
  --title "feat(v3): phase d — skills (a11y, mr-body-writer, perf-auditor)" \
  --body "$(cat <<'EOF'
## Summary

Phase D of the V3 Megarelease — see [spec](docs/superpowers/specs/2026-05-17-v3-livewire-megarelease-design.md) Section 5 + [plan](docs/superpowers/plans/2026-05-17-v3-phase-d-skills.md).

Three Laravel-specific skills. Read-only process guidance.

### Skills added

- **\`laravel-a11y-specialist\`** — closes [#6](https://github.com/altraWeb/laravel-livewire-superpowers/issues/6)
- **\`laravel-mr-body-writer\`** — closes [#8](https://github.com/altraWeb/laravel-livewire-superpowers/issues/8)
- **\`laravel-perf-auditor\`** — closes [#11](https://github.com/altraWeb/laravel-livewire-superpowers/issues/11)

### Shared

- \`.claude-plugin/plugin.json\` — version 3.0.0-alpha.4, skill count 4 → 7
- \`CHANGELOG.md\` — new \`[3.0.0-alpha.4]\` section
- \`README.md\` — skills section updated (count already at 7 from A.2 target)

### Test plan

- [x] All 10 shell + 30 Python tests still green
- [x] All 3 new SKILL.md frontmatters valid
- [ ] Reviewer skims each skill body for actionable guidance vs filler

### After merge

Cut v3.0.0-alpha.4 + Pre-Release. Move to Phase E (Pilot 2.0 meta-layer: orchestrator agent + enforcer hook + audit-phase/retro commands).
EOF
)"
```

**STOP. Wait for operator review + merge.**

---

## STEP D.6 — Post-Merge

### Task 10: Tag v3.0.0-alpha.4 + Pre-Release

- [ ] **Step 1: Pull merged main**

```bash
git switch main
git pull --ff-only origin main
```

- [ ] **Step 2: Tag + push**

```bash
git tag -a v3.0.0-alpha.4 -m "v3.0.0-alpha.4 — V3 Megarelease Phase D: Skills (a11y, mr-body-writer, perf-auditor)"
git push origin v3.0.0-alpha.4
```

- [ ] **Step 3: GitHub Pre-Release**

```bash
gh release create v3.0.0-alpha.4 \
  --title "v3.0.0-alpha.4 — V3 Megarelease Phase D: Skills" \
  --prerelease \
  --notes "$(awk '/^## \[3\.0\.0-alpha\.4\]/{flag=1; next} /^---$/{if(flag){flag=0}} flag' CHANGELOG.md)"
```

- [ ] **Step 4: Report Phase D complete**

State to operator: "Phase D complete. v3.0.0-alpha.4 pre-released. Ready for Phase E (Pilot 2.0 meta-layer) when you give the go."

**STOP. Phase D complete.**
