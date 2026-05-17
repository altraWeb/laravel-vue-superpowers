# Smoke Test 1 — Canonical bug (`toContain` variadic misuse)

**Date:** 2026-05-15
**Dispatcher:** Claude Code Task tool, `general-purpose` subagent, `sonnet` model

## Input

> audit: planning `expect($response->json('items'))->toContain('foo', 'response should include foo')`

## Environment

Working directory: `/Users/altrano/dev/laravel-superpowers` (plugin repo, NOT a Pest app). No `composer.json`, no `vendor/pestphp/`. Pre-flight should SKIP. Caller asked agent to surface variadic misuse as informational critical from plan text.

## Captured output

```markdown
## Pest Specialist Audit — planning: `expect($response->json('items'))->toContain('foo', 'response should include foo')`

**Pest version:** N/A
**Reflection source:** N/A — no composer.json found, cannot confirm Pest project

---

## Pre-flight: SKIPPED — no composer.json found, cannot confirm Pest project

Working directory `/Users/altrano/dev/laravel-superpowers` contains no `composer.json`. Pre-flight checks skipped. Findings below are surfaced from plan text as **informational critical** per caller instruction.

---

### 1. Variadic-API Verification

**Trigger matched:** `toContain(` present in input.

**Call extracted from plan:**

\`\`\`php
expect($response->json('items'))->toContain('foo', 'response should include foo')
\`\`\`

**Reflection:** unavailable (no vendor). Verified via known Pest 4 API surface (docs-level).

`Pest\Expectation::toContain` is **variadic** — its signature is:

\`\`\`php
public function toContain(mixed ...$needles): self
\`\`\`

Both positional arguments are treated as **needles to assert presence of**. There is no second-parameter slot for a failure message. Passing `'response should include foo'` as arg #2 does not attach a custom message — it silently becomes a second needle being asserted, which will almost certainly cause a false-positive failure.

**Finding:**

❌ `->toContain('foo', 'response should include foo')` — **VARIADIC MISUSE** (CRITICAL)
- `Pest\Expectation::toContain` is variadic; arg #2 is treated as a second needle, not a failure message
- The test will assert that both `'foo'` and `'response should include foo'` appear in `items`, producing a misleading failure
- Verified: docs-only fallback (no vendor available); classification: informational critical per caller

**Suggested fix:**

\`\`\`php
expect($response->json('items'))->toContain('foo')->because('response should include foo');
\`\`\`

`->because(string $message)` is the Pest 4 modifier for attaching a human-readable failure message to any expectation chain.

---

### 2. Browser-Plugin Smell Scan
N/A — no browser plugin references in scope.

### 3. View-Context Anti-Patterns
N/A — no view() references in scope.

### 4. Test-Location Convention
N/A — no path references in scope.

### 5. it()/arch()/dataset Block Patterns
N/A — no block references in scope.

---

## Summary

**1 issue found:** 1 critical, 0 important, 0 minor.
**Block test-write until:** variadic misuse resolved — replace `->toContain('foo', 'response should include foo')` with `->toContain('foo')->because('response should include foo')`.
**Other issues:** none.
```

## Verdict

**PASS** — exactly the catch we needed.

- Pre-flight correctly SKIPPED (no composer.json).
- Variadic-API check fired on the trigger.
- Agent correctly identified `toContain` as variadic and explained WHY arg #2 silently becomes a second needle.
- Suggested fix is concrete code with the `->because()` modifier (not generic "use the right method").
- All other sections marked N/A — no false positives.
- Severity classified correctly as critical with explicit "Block test-write until" line.

This is the exact catch that would have prevented the Block 1H Phase 4 `7f17954` commit-cycle.
