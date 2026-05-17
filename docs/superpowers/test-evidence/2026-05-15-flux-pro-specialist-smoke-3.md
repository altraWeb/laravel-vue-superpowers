# Smoke Test 3 — Non-Flux project (Bootstrap 5 / Symfony)

**Date:** 2026-05-15
**Dispatcher:** Claude Code Task tool, `general-purpose` subagent, `sonnet` model

## Input

> audit: I'm building a dropdown with Bootstrap 5 in my Symfony app, using `<div class='dropdown'><button data-bs-toggle='dropdown'>Menu</button></div>`. Check for issues.

## Captured output

```markdown
## Flux Pro Specialist Audit — Bootstrap 5 dropdown (Symfony app)

## Pre-flight: SKIPPED — no composer.json found, cannot confirm Flux Pro project

The working directory `/tmp` contains no `composer.json`. The audit input describes a Bootstrap 5 / Symfony component, not a Laravel + Flux Pro component. This agent's 5 audit checks are exclusively scoped to `<flux:*>` Blade components within a Flux Pro project.

### 1-5: All N/A

## Summary

**0 issues found.** Block implementation until: none. Other issues: Submitted snippet uses Bootstrap 5 in Symfony — outside scope. For Bootstrap/Symfony-specific review, a different auditor is appropriate. No Flux Pro findings would be valid in this context.
```

## Verdict

**PASS** — clean SKIP, explicit "outside scope" disclaimer, no hallucinated Flux findings on Bootstrap/Symfony code.

Agent correctly identified that:
- The input describes a different component library (Bootstrap)
- A different framework (Symfony, not Laravel)
- The 5 Flux Pro checks are not applicable
- Recommended a different auditor

This is the trust-critical test — a specialist that confused Bootstrap with Flux would be dangerous.
