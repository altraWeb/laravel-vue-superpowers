# Smoke Test 2 — Repository anti-pattern flag

**Date:** 2026-05-15
**Dispatcher:** Claude Code Task tool, `general-purpose` subagent, `sonnet` model

## Input

> audit: planning a new `app/Repositories/PagesRepository` class with index/findById/store/update/delete methods to wrap Page model queries. PagesController will inject PagesRepository instead of using Page model directly.

## Captured output (key sections)

```markdown
## Laravel Architect Audit — PagesRepository (new class)

**Project profile:** sibling-canon UNAVAILABLE — no app/ directory

### 2. Architecture Pattern Sibling-Canon Check

⚠️ `PagesRepository` proposed — Repository pattern is an anti-pattern in most Laravel apps — IMPORTANT

**Why this is wrong:**
1. Duplicates what Eloquent already provides (every method is a thin re-wrap)
2. Breaks query-builder fluency (callers can't chain ->where/->with/->paginate)
3. Provides zero isolation benefit unless swapping persistence (almost never happens)
4. Pushes N+1 risk to callers (index(): Collection hides eager-loading intent)

**Concrete alternative — replace entire class:**

Query reuse → Eloquent scopes:
- `scopePublished()` + `scopeOrderedByTitle()` on Page model
- Caller: `Page::published()->orderedByTitle()->paginate(20)`

Command-side → single-purpose Actions:
- `StorePage`, `UpdatePage`, `DeletePage` — each invokable, single execute() method, wraps DB::transaction

Resulting Controller: 3 lines per method, no Repository.

For findById: route model binding eliminates it entirely (Laravel resolves Page via implicit binding).

### 4. Performance

⚠️ `index(): Collection` — unbounded full-table fetch
- Suggested: `paginate(25)` or `cursorPaginate(50)` at point of use

### Summary
**2 issues found: 0 critical, 2 important, 0 minor.**
Block: PagesRepository should not be built. Replace with Eloquent scopes + Actions + route model binding.
```

## Verdict

**PASS with thorough alternative.**

- Repository pattern correctly flagged as anti-pattern (matches AC).
- Explanation covers all 4 reasons (duplication, fluency loss, no isolation, N+1 leak).
- **Concrete code** for every alternative shown: Eloquent scopes, Action class skeletons, full PagesController rewrite, route model binding.
- Pagination concern flagged as secondary architectural smell.
- Severity correctly classified as important (anti-pattern, not production-bug-class).
- Note: without sibling-canon (no app/ dir), recommendations fall back to generic best practices — agent correctly signals this in the project profile header.

When invoked in a real Laravel project, the sibling-canon check would additionally cite specific existing files (`app/Actions/Posts/PublishPost.php:1-30` shape applies here, etc.).
