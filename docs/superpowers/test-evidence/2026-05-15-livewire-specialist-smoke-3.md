# Smoke Test 3 — Non-Livewire project

**Date:** 2026-05-15
**Dispatcher:** Claude Code Task tool, `general-purpose` subagent, `sonnet` model

## Input

> audit: I'm adding a new Vue.js component to my non-Laravel TypeScript SPA. Check for issues.

## Environment

Working directory: `/tmp` (deliberately not a Laravel/Livewire context — no `composer.json`, no vendor, no PHP files, no Livewire references anywhere in the input).

## Captured output

```markdown
## Livewire Specialist Audit — Vue.js TypeScript SPA component (non-Laravel context)

**Livewire version:** N/A
**Reflection source:** N/A

## Pre-flight: SKIPPED — no composer.json found, cannot confirm Livewire project

The working directory `/tmp` contains no `composer.json` and no Livewire vendor source. The audit input explicitly describes a **Vue.js TypeScript SPA** — this is not a Laravel/Livewire project.

All five audit checks are suppressed. Running them against unrelated context would produce fabricated findings.

---

### 1. API Verification
N/A — pre-flight did not confirm a Livewire project; audit skipped.

### 2. wire:ignore Zone Scan
N/A — pre-flight did not confirm a Livewire project; audit skipped.

### 3. Form-Object Pattern
N/A — pre-flight did not confirm a Livewire project; audit skipped.

### 4. Echo / Broadcasting
N/A — pre-flight did not confirm a Livewire project; audit skipped.

### 5. Lifecycle Hooks
N/A — pre-flight did not confirm a Livewire project; audit skipped.

---

## Summary

**N issues found:** 0 critical, 0 important, 0 minor.
**Block implementation until:** none — this agent has no jurisdiction here.
**Other issues:** The submitted audit scope is a Vue.js TypeScript SPA, not a Laravel/Livewire project. Re-invoke this agent inside a Laravel project root that has `livewire/livewire` in `composer.json`.
```

## Verdict

**PASS.**

- Pre-flight correctly SKIPPED with explicit reason.
- All 5 sections marked N/A — no fabricated findings, no hallucinated Livewire bugs in Vue context.
- Summary explicitly says "this agent has no jurisdiction here" — clear, correct disclaimer.
- Suggests re-invoking in a Laravel project with `livewire/livewire` — actionable guidance for the caller.
- No crash, no false positives, no wasted Bash/WebFetch calls.

This is the most important smoke test — it proves the agent fails CLEAN when invoked out of scope. A specialist agent that hallucinates Livewire findings in non-Livewire projects would be dangerous.
