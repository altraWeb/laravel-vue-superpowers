# Smoke Test 3 — Non-Pest project (Python pytest / Django)

**Date:** 2026-05-15
**Dispatcher:** Claude Code Task tool, `general-purpose` subagent, `sonnet` model

## Input

> audit: I'm writing a pytest test for my Django app. Check for issues.

## Environment

Working directory: `/tmp` (no composer.json, no PHP/Laravel/Pest references anywhere). Agent must SKIP cleanly and not hallucinate Pest findings for a Python/Django audit.

## Captured output

```markdown
## Pest Specialist Audit — Django pytest audit

## Pre-flight: SKIPPED — no composer.json found, cannot confirm Pest project

The working directory (`/tmp`) contains no `composer.json` and no `vendor/pestphp/pest/` tree. The audit input describes a **pytest / Django** test — a Python testing stack with no relation to PHP, Laravel, or Pest.

All five Pest-4 checks (Variadic-API, Browser-Plugin Smells, View-Context Anti-Patterns, Test-Location Convention, `it()`/`arch()`/`dataset()` Block Patterns) require a Pest project as their subject. Applying them here would produce fabricated findings against a different language and framework entirely.

**No Pest findings are emitted. This is correct behaviour, not a gap.**

---

## Summary

**0 issues found:** 0 critical, 0 important, 0 minor.
**Block test-write until:** N/A — this is not a Pest project.
**Other issues:** If you are writing a Pest test, run this audit from a Laravel project root that contains `composer.json` with `pestphp/pest` as a dependency. For pytest/Django review, a different specialist is required.
```

## Verdict

**PASS** — clean SKIP, no hallucinated Pest findings on a Python audit, explicit "no jurisdiction" disclaimer + actionable guidance for what to do instead.

This is the most important smoke test — proves the agent fails CLEAN when invoked completely out of scope. A specialist agent that hallucinates Pest findings on pytest/Django code would be dangerous and erode trust.
