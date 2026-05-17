# Smoke Test 2 — Clean expectation chain (`toBe + and + toHaveKey`)

**Date:** 2026-05-15
**Dispatcher:** Claude Code Task tool, `general-purpose` subagent, `sonnet` model

## Input

> audit: planning `expect($response->status())->toBe(200)->and($response->json())->toHaveKey('user')`

## Environment

Working directory: `/Users/altrano/dev/laravel-superpowers` (not a Pest app). Pre-flight should SKIP. Even with SKIP, agent should informationally confirm the expectation chain is clean (single-arg variadic usage + correct `->and()` chaining).

## Captured output

```markdown
## Pest Specialist Audit — planning: `expect($response->status())->toBe(200)->and($response->json())->toHaveKey('user')`

**Pest version:** N/A
**Reflection source:** N/A

## Pre-flight: SKIPPED — no composer.json found, cannot confirm Pest project

---

### 1. Variadic-API Verification

The snippet uses:
- `->toBe(200)` — single argument, non-variadic, correct usage
- `->toHaveKey('user')` — single argument, correct usage

Neither call passes a second argument, so there is no variadic misuse to flag.

✅ `->toBe(200)` — correct single-arg usage
✅ `->toHaveKey('user')` — correct single-arg usage

The chaining pattern is also structurally sound:
- `expect($response->status())->toBe(200)` — standalone expectation on the status integer
- `->and($response->json())` — opens a new expectation scope on a different value
- `->toHaveKey('user')` — applied to the new scope from `->and()`

✅ `->and()` receives a new subject and chains cleanly — correct Pest 4 pattern.

### 2. Browser-Plugin Smell Scan
N/A — no browser references in scope.

### 3. View-Context Anti-Patterns
N/A — no view() references in scope.

### 4. Test-Location Convention

N/A — no explicit path references, `uses(...)`, or `pest()->use(...)` declarations in scope.

*Informational note:* The snippet performs an HTTP-style assertion (`$response->status()`, `$response->json()`). If this test lives in `tests/Unit/`, it should be moved to `tests/Feature/`, as HTTP response objects require full app boot. No path was provided, so this is not flagged as a finding.

### 5. it()/arch()/dataset Block Patterns
N/A — no block references in scope. Audit input is expectation chain only.

---

## Summary

**0 issues found:** 0 critical, 0 important, 0 minor.
**Block test-write until:** none
**Other issues:** Snippet is clean. If placed inside a Feature test file with a valid `$response` from `$this->getJson(...)` or similar, this expectation chain is ready to use as-is.
```

## Verdict

**PASS** — all three single-arg expectations recognized as correct, `->and()` chaining validated, no false-positive variadic flags. Bonus: informational note about Unit-vs-Feature placement based on `$response` usage pattern. Exactly the helpful-without-alarmist behavior we want for clean inputs.
