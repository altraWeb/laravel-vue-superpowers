# Smoke Test 1 — Canonical bug (`$this->hasLoading`)

**Date:** 2026-05-15
**Dispatcher:** Claude Code Task tool, `general-purpose` subagent, `sonnet` model

## Input

> audit: Phase 5 plan adds aria-busy resolver via `$this->hasLoading($method)` — Livewire computed getter on `Editor\AiToolbar` component (file: `app/Livewire/Editor/AiToolbar.php` which doesn't actually exist here)

## Environment

Working directory: `/Users/altrano/dev/laravel-superpowers` (the plugin repo, NOT a Livewire app). No `composer.json`, no `vendor/livewire/`. Pre-flight should SKIP.

## Captured output

```markdown
## Livewire Specialist Audit — Phase 5 plan: aria-busy resolver via `$this->hasLoading($method)` on `Editor\AiToolbar`

**Livewire version:** N/A — no composer.json found
**Reflection source:** N/A — no composer.json found, cannot confirm Livewire project

---

## Pre-flight: SKIPPED — no composer.json found, cannot confirm Livewire project

No `composer.json` exists at `/Users/altrano/dev/laravel-superpowers/`. This is confirmed: the working directory is the `laravel-superpowers` plugin/tooling repository itself, not a Livewire application. The file `app/Livewire/Editor/AiToolbar.php` referenced in the plan also does not exist here.

Because the pre-flight termination condition has been met, the five audit checks below are marked accordingly. However, the fabricated-API finding (`$this->hasLoading()`) is directly named in the audit input and is a critical issue regardless of project context — it is included here as an informational finding for the plan author.

---

### 1. API Verification

**Pre-flight terminated — reflection unavailable.** Informational finding from plan input:

❌ `$this->hasLoading($method)` — **NOT FOUND on `Livewire\Component`**

- This method does not exist in Livewire 4's `Component` base class. No such computed getter is part of the Livewire 4 public API. It appears to be a fabricated method name.
- **Suggested (concrete):** Replace the PHP-side resolver entirely. Livewire's loading state is a *template concern*, not a component concern. Use `wire:loading.attr="aria-busy"` directly in the Blade template, scoped with `wire:target`:

  ```blade
  <button wire:click="generateSuggestion" wire:loading.attr="aria-busy" wire:target="generateSuggestion">
      Generate
  </button>
  ```

  If you need `aria-busy` on a *different* element than the trigger, scope explicitly:

  ```blade
  <div wire:loading.attr="aria-busy" wire:target="generateSuggestion">
      ...
  </div>
  ```

  No PHP method needed. `$this->hasLoading()` would crash at runtime with a `BadMethodCallException`.

### 2. wire:ignore Zone Scan

N/A — no `wire:ignore` references in scope.

### 3. Form-Object Pattern

N/A — no form code in scope.

### 4. Echo / Broadcasting

N/A — no Echo/broadcast references in scope.

### 5. Lifecycle Hooks

N/A — no lifecycle hooks in scope.

---

## Summary

**Pre-flight terminated:** No `composer.json` at project root — confirmed not a Livewire application. Full reflection-based audit cannot proceed.

**1 informational critical finding identified from plan text:**

| # | Severity | Finding |
|---|----------|---------|
| 1 | **Critical** | `$this->hasLoading($method)` — fabricated method, does not exist on `Livewire\Component`. Would crash at runtime. |

**Block implementation until:** `$this->hasLoading()` is removed from the plan and replaced with `wire:loading.attr="aria-busy" wire:target="<methodName>"` in the Blade template.

**Other issues:** None — all other checks N/A.
```

## Verdict

**PASS** with bonus.

- Pre-flight correctly detected no-composer.json scenario and SKIPPED.
- Report structure matches spec (Livewire version line, reflection source line, 5 sections + summary).
- **Bonus behavior** beyond spec: agent surfaced the fabricated API as an "informational" critical finding because the plan text directly named it, even though full reflection couldn't run. This is graceful judgment — the audit text contained enough information to make the call without needing to read vendor source. Output explicitly labels it as informational so the caller knows the limitation.
- Suggested alternative is concrete (template-side `wire:loading.attr="aria-busy" wire:target="..."`), with multi-element variant explained.
- Block-shipping summary is clear and actionable.

## Limitation (for real-world testing)

This test does NOT exercise the PHP reflection path — for that, the agent would need to run inside an actual Laravel+Livewire project. That's a real-world validation that happens when a user invokes the agent in a Livewire app.
