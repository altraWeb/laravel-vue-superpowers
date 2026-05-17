# Smoke Test 1 — Canonical bug (`<flux:tooltip>` double-wrap around `<flux:editor.button>`)

**Date:** 2026-05-15
**Dispatcher:** Claude Code Task tool, `general-purpose` subagent, `sonnet` model

## Input

> audit: planning `<flux:tooltip content='Bold formatting'><flux:editor.button icon='bold' wire:click='format'>B</flux:editor.button></flux:tooltip>` in editor toolbar at line 42 of `resources/views/livewire/editor/ai-toolbar.blade.php`

This is the EXACT bug Block 1H Phase 1 audit caught — the canonical reason this agent exists.

## Captured output (excerpt)

```markdown
## Flux Pro Specialist Audit — editor toolbar `<flux:tooltip>` wrap at `resources/views/livewire/editor/ai-toolbar.blade.php:42`

**Flux Pro version:** N/A
**Vendor source:** docs-only fallback — no composer.json found

> ## Pre-flight: SKIPPED — no composer.json found, cannot confirm Flux Pro project

### 1. `<flux:with-tooltip>` Self-Wrap Detection

❌ `<flux:tooltip content='Bold formatting'>` outer wrapper around `<flux:editor.button>` at **line 42** — **DOUBLE-WRAP** (CRITICAL)

- Vendor evidence: `vendor/livewire/flux-pro/stubs/resources/views/flux/editor/button.blade.php:26` — `<flux:editor.button>` already self-tooltips internally via `<flux:with-tooltip>`. Accepts a `tooltip` prop and wraps itself; no outer `<flux:tooltip>` is needed or correct.
- Risk: outer wrapper inserts an additional tooltip root inside `<ui-toolbar>`, breaking the roving-tabindex managed by `<ui-toolbar>` — silent a11y regression detectable only by keyboard navigation.
- Suggested:

  ```blade
  {{-- BEFORE (broken) --}}
  <flux:tooltip content='Bold formatting'>
      <flux:editor.button icon='bold' wire:click='format'>B</flux:editor.button>
  </flux:tooltip>

  {{-- AFTER (correct) --}}
  <flux:editor.button icon='bold' wire:click='format' tooltip='Bold formatting'>B</flux:editor.button>
  ```

### 2-5: N/A (no triggers in scope)

## Summary

**1 critical issue:** Remove outer `<flux:tooltip>` wrapper at line 42. `<flux:editor.button>` self-tooltips via `<flux:with-tooltip>` (`vendor/.../editor/button.blade.php:26`). Double-wrap silently breaks `<ui-toolbar>` roving-tabindex. Fix: pass `tooltip='Bold formatting'` as prop directly on `<flux:editor.button>`.
```

## Verdict

**PASS** — exact catch of the Block 1H Phase 1 canonical bug.

- Pre-flight correctly SKIPPED.
- Cited vendor `file:line` (`vendor/.../editor/button.blade.php:26`) even with vendor unavailable (used canonical knowledge from agent body).
- Explained the a11y mechanism (roving-tabindex break on `<ui-toolbar>`).
- BEFORE/AFTER Blade code suggested — concrete, not generic.
- Severity correctly classified as critical, blocks shipping.
- Other checks N/A — no false positives.
