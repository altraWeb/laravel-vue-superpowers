# `laravel-architect` Agent — Design Spec

**Issue:** [#4](https://github.com/altraWeb/laravel-superpowers/issues/4)
**Milestone:** V2-MVP
**Status:** Design draft
**Date:** 2026-05-15

---

## 1. Context & Motivation

Eloquent + architecture is where most Laravel projects accumulate technical debt invisibly — N+1 queries, model bloat, missing eager-loading, Repository-vs-Service decisions made ad-hoc, Form-Object-vs-DTO trade-offs.

Block 1H + 1E were view-layer / client-side scope, so Eloquent gaps were minimal — but Block 2 (Pages-CMS) will be model-heavy with versioning, and Block 3 (Command Palette) needs to query across multiple models efficiently. Without an architect agent dispatched at plan time, these accumulate as silent N+1 + inconsistent layering across the codebase.

This is the fourth V2-MVP specialist agent, but with a **structurally different audit approach** than #1-#3:

- **#1-#3 reflect against vendor source** (Livewire, Pest, Flux vendor files = ground truth)
- **#4 reads the user's own codebase** (`app/Actions/`, `app/Services/`, models, migrations) — its ground truth is **what the project itself already does** (sibling-canon), not a third-party framework

## 2. Goals & Non-Goals

**Goals**

- Audit plan-phases that touch models, migrations, queries, or architectural placement decisions
- **Sibling-canon check** — read existing `app/Actions/`, `app/Services/`, `app/Http/Requests/`, `app/Data/` patterns BEFORE recommending new structure; prefer consistency with what's already there
- Catch N+1 in `foreach`/`->each()` blocks BEFORE implementer dispatch
- Surface `preventLazyLoading()` status and recommend QueryCount-pinning tests
- Flag Repository pattern as anti-pattern in Laravel apps
- Emit structured markdown report (same shape as #1-#3)
- Skip cleanly when project isn't Laravel

**Non-Goals**

- Auto-dispatch on plan boundaries → #20
- Replacing `laravel-best-practices` (research-oriented) — this agent is audit-oriented and project-aware
- Schema migrations beyond static analysis (no actual migration running)
- Editing user code — read-only, suggestions only

## 3. Architecture

### 3.1 Single-file Agent

`agents/laravel-architect.md` — frontmatter + body. No supporting library.

### 3.2 Frontmatter

```yaml
---
name: laravel-architect
description: "Use in Laravel projects before/during any plan-phase that touches Eloquent models, migrations, queries, or architectural placement (Actions vs Services vs Form Objects vs Controllers). Audits for N+1 queries, missing eager-loading, preventLazyLoading status, migration safety, performance smells, and architectural-pattern drift. Reads existing app/Actions/, app/Services/, app/Http/Requests/, app/Data/ for sibling-canon check — recommends consistency with what's already in the codebase, not generic best practices. Trigger on any plan-phase that touches models, migrations, queries, or layering decisions."
model: inherit
tools: "Read, Bash, WebFetch, WebSearch"
maxTurns: 25
color: magenta
memory: user
---
```

### 3.3 Input Contract

Caller pastes inline:
- A plan-phase description ("Phase 3: add Pages model with versioning, dispatch via PagesAction")
- Code snippets — Eloquent queries, migrations, action/service classes
- A specific question framed as audit ("audit my new PagesController + PagesAction layering")
- Optionally: a model name to introspect via `php artisan model:show {Model}`

### 3.4 Pre-flight

```bash
cat composer.json 2>/dev/null | grep -E '"laravel/framework"' | head -1
ls app/ 2>/dev/null | head -5
```

Branches:
- **Both present:** capture Laravel version, continue
- **Laravel not in composer.json:** `Pre-flight: SKIPPED — not a Laravel project`, stop
- **composer.json missing:** `Pre-flight: SKIPPED — no composer.json found`, stop
- **Laravel present but `app/` missing:** `Pre-flight: WARNING — app/ directory missing; sibling-canon check unavailable. Recommendations will fall back to generic Laravel best practices.`, continue
- **Laravel version < 11:** `Pre-flight: WARNING — Laravel <version> detected; this agent is tuned for Laravel 11/12. Most checks still apply but some patterns (Form Objects, Spatie LaravelData defaults) are 11+.`, continue

### 3.5 Sibling-Canon Discovery (Step 2 of agent workflow)

Before running any check, scan project structure:

```bash
ls app/Actions/ 2>/dev/null
ls app/Services/ 2>/dev/null
ls app/Http/Requests/ 2>/dev/null
ls app/Data/ 2>/dev/null   # Spatie LaravelData convention
ls app/Models/ 2>/dev/null
grep -r "preventLazyLoading" app/Providers/ 2>/dev/null
```

Build a project profile:
- Which architectural patterns are in use (Actions, Services, both, neither)?
- Are Form Objects (`app/Http/Requests/`) the dominant validation pattern, or is `protected $rules` in Livewire components?
- Is `preventLazyLoading()` enabled in `AppServiceProvider`?
- Does the project use Spatie LaravelData (`app/Data/`)?

This profile drives every recommendation: when the project consistently uses Actions, the agent recommends Actions for new logic; when it uses Services, it recommends Services. Generic "use whatever fits" is replaced with project-aware guidance.

## 4. The Five Audit Checks

Each check runs only if input contains triggers. Absent triggers → `N/A — no [...] in scope`.

### 4.1 Eloquent N+1 Detection

**Trigger:** input contains `foreach`, `->each(`, `->map(`, `->filter(`, or `->reduce(` on a collection, OR a query that returns a collection.

**Procedure:**

1. Extract every loop-block from input
2. For each, identify relationship-access patterns inside the loop body (e.g., `$post->user->name`, `$order->lineItems->sum(...)`)
3. Check if the loop subject was loaded with `with()` / `withCount()` / `loadMissing()` — if not, N+1 is virtually guaranteed
4. Check `AppServiceProvider` for `Model::preventLazyLoading()` — if enabled, N+1 will throw `LazyLoadingViolationException` in production
5. Emit per finding:
   - `❌ N+1 risk: \`foreach ($posts as $post) { $post->user->name }\` at line N — **CRITICAL**`
     - Eager-load: `Post::with('user')->get()` at the query origin
     - If many relationships: `Post::with(['user', 'comments', 'tags'])->get()`
     - For counts only: `Post::withCount(['comments', 'tags'])->get()` (cheap aggregate, no relation hydration)
     - Add a `Pest\Tests\QueryCount` test pinning expected query count, so regressions break CI
6. Surface `preventLazyLoading` status:
   - If enabled in `AppServiceProvider`: "production protection is on — N+1 will throw, RED catches this in dev too"
   - If not enabled: "recommend enabling `Model::preventLazyLoading(! $this->app->isProduction())` in `AppServiceProvider::boot()`"

### 4.2 Architecture Pattern Sibling-Canon Check

**Trigger:** input proposes new code placement (controller / action / service / form-object / DTO / job) — any "where does this live?" decision.

**Procedure:**

1. Use the project profile from §3.5
2. Match the proposed code to existing patterns:
   - Single-action invokable that wraps a transaction → matches Action pattern
   - Multi-method coordinator class → matches Service pattern
   - Validated input object → matches Form Object or LaravelData
3. Recommend the dominant project pattern, citing 2-3 existing files as evidence:
   - "5 of your existing actions follow `app/Actions/Pages/CreatePage.php` shape (invokable + transaction + dispatchable). Recommend `app/Actions/Pages/PublishPage.php` for this work — consistent layering."
4. Flag Repository pattern explicitly as anti-pattern:
   - `⚠️ \`PagesRepository\` proposed — Repository pattern is an anti-pattern in most Laravel apps`
     - Why: Eloquent models ARE the repository. Adding a Repository layer duplicates state without isolation benefit and breaks query-builder fluency.
     - Suggested: use Eloquent scopes for query reuse (`Page::published()`), or extract to an Action for command-side complexity
5. Flag "fat controller" anti-pattern:
   - `⚠️ \`PagesController@publish\` proposed to contain 80+ lines of business logic`
     - Suggested: extract to `app/Actions/Pages/PublishPage.php`, controller becomes 3 lines: validate → dispatch action → return response

### 4.3 Migration Discipline

**Trigger:** input contains migration code — `Schema::create(`, `Schema::table(`, `->foreignId(`, `$table->X()`.

**Procedure:**

1. For `Schema::table(` (modifying existing table): verify all new columns are `->nullable()->default(...)` or have a backfill strategy — otherwise migration fails on existing rows
2. For `foreignId()`: verify `->constrained()` is followed by appropriate `->onDelete()` (cascade vs restrict vs set null) — implicit "restrict" causes silent FK violations
3. Flag `migrate:fresh` assumptions:
   - If migration relies on full table rebuild (e.g., drops + recreates), warn that production runs `migrate`, not `migrate:fresh`
4. Flag missing indexes on FK columns:
   - `foreignId('user_id')` should be followed by an implicit or explicit index (usually `constrained()` adds it, but verify)

### 4.4 Performance

**Trigger:** input contains computed values, counts, or anything that smells expensive.

**Procedure:**

1. **Uncached expensive computed values:**
   - In Livewire components: `public function getTotalAttribute() { return Order::sum('total'); }` called on every render → recommend `#[Computed(cache: true)]` or `cache()->remember()`
2. **`count()` in render loops:**
   - `@if ($posts->where('published', true)->count() > 0)` in a Blade loop → recommend pulling into a variable or using `withCount`
3. **`exists()` vs `count()` for boolean checks:**
   - `if ($user->posts()->count() > 0)` → suggest `if ($user->posts()->exists())` (faster, no full COUNT)
4. **Memory-bound iteration:**
   - `Post::all()` for thousands of records → recommend `chunk(100, fn ($posts) => ...)` or `lazy()` for memory pressure
5. **SWR cache pattern:**
   - For expensive-but-stale-OK data: recommend `Cache::flexible($key, [60, 300], fn () => ...)` (Laravel 11+)

### 4.5 API Design

**Trigger:** input contains API endpoint design — `Route::apiResource(`, `JsonResource`, pagination calls, controller methods returning JSON.

**Procedure:**

1. **Eloquent API Resources:**
   - Raw `->toJson()` or `compact()` in controllers → recommend `JsonResource` subclass for shape control
2. **Pagination strategy:**
   - `paginate()` → fine for ≤10k records, but counts the whole table
   - `simplePaginate()` → no count, just next/prev — recommend when total isn't shown
   - `cursorPaginate()` → for very large datasets (infinite scroll, feeds) — recommend when sorting by a unique indexed column
3. **API versioning:**
   - Check existing routes for version conventions (`/api/v1/`, header-based, query-param-based)
   - Match the project's convention; don't introduce a new one

## 5. Output Format

Identical structure to #1-#3:

```markdown
## Laravel Architect Audit — <scope name>

**Laravel version:** <version from composer.json>
**Project profile:** <bullet summary of detected patterns>
**Sibling-canon source:** app/Actions/, app/Services/, app/Http/Requests/, app/Data/

### 1. Eloquent N+1 Detection
<findings or N/A>

### 2. Architecture Pattern Sibling-Canon Check
<recommendation citing existing files or N/A>

### 3. Migration Discipline
<findings or N/A>

### 4. Performance
<findings or N/A>

### 5. API Design
<recommendation or N/A>

---

## Summary

**N issues found:** X critical, Y important, Z minor.
**Block implementation until:** <critical blockers or "none">
**Other issues:** <one-line guidance>
```

### Severity

- **Critical** (production-bug-class): N+1 with `preventLazyLoading` enabled (will throw in prod), missing onDelete on FK (silent integrity break), unindexed FK on million-row table
- **Important** (anti-pattern or perf-smell): Repository pattern, fat controller, uncached expensive computed, `count()` instead of `exists()`, wrong pagination strategy for scale
- **Minor** (consistency): pattern drift from sibling-canon, API versioning style mismatch

## 6. Error Handling

Same matrix as #1-#3:

| Situation | Behavior |
|---|---|
| No Laravel in composer.json | SKIPPED, exit |
| composer.json missing | SKIPPED, exit |
| `app/` missing | WARNING, sibling-canon disabled, generic recommendations |
| Wrong Laravel version | WARNING, continue best-effort |
| `php artisan model:show` fails | `⚠️ Schema introspection unavailable: <error>`, fall back to reading migration files |
| Referenced file unreadable | `⚠️ Could not read <path>`, skip checks needing it |

## 7. Testing

Three smoke tests, captured in `docs/superpowers/test-evidence/`:

1. **Canonical bug:** `audit: Phase 3 adds foreach ($pages as $page) { $page->author->name; }` — expect ❌ critical N+1 with concrete `Page::with('author')` rewrite + `preventLazyLoading` mention
2. **Architecture decision:** `audit: planning a new PagesRepository class with index/show/store/delete methods` — expect ⚠️ Repository anti-pattern flag + suggestion (Eloquent scopes / Action)
3. **Non-Laravel project:** `audit: Spring Boot + JPA architecture review` — expect Pre-flight SKIPPED

## 8. Documentation Deliverables

- `agents/laravel-architect.md`
- `README.md` — append to Agents list (NB: also need to handle pending #3 entry if #36 hasn't merged yet)
- `docs/agents.md` — insert entry; remove #4 from Forthcoming

## 9. AC Mapping

| AC from #4 | Where |
|---|---|
| Agent dispatched on plan-phases touching models/migrations/queries | §2 Non-goals (auto-dispatch is #20). Manually invokable. |
| First action: `php artisan model:show {Model}` + database-schema MCP | §3.5 sibling-canon discovery + Bash invokes when model name in input |
| Findings cite sibling-canon files before recommending new structure | §4.2 procedure step 3 (explicit "5 of your existing actions follow X" pattern) |
| Catches N+1 in foreach/each blocks | §4.1 |
| Surfaces preventLazyLoading status + recommends QueryCount tests | §4.1 procedure steps 4-6 |

## 10. Out of Scope

- Auto-dispatch → #20
- Running actual migrations (read-only by design)
- MCP database-schema integration — Bash + `php artisan` is sufficient for v1; MCP is enhancement
- Auto-rewriting violating code (read-only)

## 11. Open Questions for Implementation

- Should the agent execute `php artisan` commands during audit? (Yes, but only read-only commands: `model:show`, `route:list`, `migrate:status`. Never `migrate`, `db:seed`.)
- Should it consider Octane / Reverb concurrency in performance recommendations? (Defer: Octane is opt-in; agent assumes standard FPM unless detected)
- Sibling-canon depth — how many files to scan? (Heuristic: list dir contents, read up to 3 representative files per pattern. Don't read every action file.)
