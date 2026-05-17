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
Cache::tags(['posts'])->remember(...); // (requires Redis or Memcached driver — fails on file/array/database cache)
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
