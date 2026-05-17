# Smoke Test 2 — Clean dropdown (separate position/align)

**Date:** 2026-05-15
**Dispatcher:** Claude Code Task tool, `general-purpose` subagent, `sonnet` model

## Input

> audit: planning `<flux:dropdown position='bottom' align='end'><flux:button variant='primary'>User Menu</flux:button><flux:menu><flux:menu.item href='/profile'>Profile</flux:menu.item><flux:menu.item href='/logout'>Logout</flux:menu.item></flux:menu></flux:dropdown>`

## Captured output

```markdown
## Flux Pro Specialist Audit — `<flux:dropdown>` User Menu

## Pre-flight: SKIPPED — no composer.json found

### 1. `<flux:with-tooltip>` Self-Wrap Detection
N/A — no `<flux:tooltip>` references in scope.

### 2. Position/Align Convention Scan
✅ `position="bottom" align="end"` on `<flux:dropdown>` — separate props, matches project canon (Block 1H Phase 3 audit convention). No compound `"bottom end"` space-separated value detected.

### 3. `<flux:editor.spacer/>` Semantics
N/A

### 4. `wire:ignore` Zone Reactive-Descendant Detection
N/A — no `wire:ignore` attributes in scope.

### 5. Slot Composition vs String-Prop Trade-off
N/A — uses named slots (`<flux:menu.item>`), correct composition for dropdown menus.

## Summary

**0 issues found.** Block implementation until: none. Other issues: Snippet is clean. Separate `position` + `align` props match project canon, no double-wrapping, no wire:ignore zones, no editor components. Ready to implement as-is.
```

## Verdict

**PASS** — clean dropdown correctly recognized.

- ✅ position/align separate props verified against project canon.
- All other checks correctly N/A.
- Summary cleanly says "0 issues, ready to implement".
- No false positives, no nitpicks.
