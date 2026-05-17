# `laravel-flux-pro-specialist` Agent — Design Spec

**Issue:** [#3](https://github.com/altraWeb/laravel-superpowers/issues/3)
**Milestone:** V2-MVP
**Status:** Design draft
**Date:** 2026-05-15

---

## 1. Context & Motivation

Block 1H Phase 1 audit (2026-05-14) caught a redundant `<flux:tooltip>` outer wrapper around `<flux:editor.button>` by reading `vendor/livewire/flux-pro/stubs/resources/views/flux/editor/button.blade.php:26` — the button already self-tooltips via `<flux:with-tooltip>`. Double-wrapping would have broken `<ui-toolbar>` roving-tabindex (silent a11y regression, only detectable via keyboard testing).

Generic Laravel agents don't traverse `vendor/livewire/flux-pro/` by default. A Flux Pro specialist with vendor-source-read defaults is the difference between "shipped silent a11y bug" and "audit caught it pre-write".

This is the third V2-MVP specialist agent, following `laravel-livewire-specialist` (#34, merged) and `laravel-pest-specialist` (#35, merged).

## 2. Goals & Non-Goals

**Goals**

- Audit Flux-Pro-touching plan-phases / Blade snippets for the most common Flux 2 stolperer-classes
- Verify component behavior via reading the actual vendor Blade source — not docs (which sometimes lag)
- Cite vendor `file:line` references in findings
- Catch the redundant-wrapper class of a11y bug before ship
- Emit structured markdown report (same shape as #1 and #2)
- Skip cleanly when project doesn't have Flux Pro

**Non-Goals**

- Auto-dispatch on plan boundaries → #20
- Free Flux Core support — opinionated about Flux Pro (paid tier with `editor`, `dropdown` extras)
- Replacing fluxui.dev docs — agent uses vendor source as truth, docs as fallback when vendor missing

## 3. Architecture

### 3.1 Single-file Agent (same pattern as #1, #2)

`agents/laravel-flux-pro-specialist.md` — frontmatter + body. No supporting library. Reads vendor Blade files directly via the `Read` tool.

### 3.2 Frontmatter

```yaml
---
name: laravel-flux-pro-specialist
description: "Use in Laravel+Flux Pro projects before/during any Flux-component-touching implementation phase. Audits double-tooltip wrapping (`<flux:tooltip>` around components that self-tooltip), position/align convention drift, slot vs string-prop trade-offs, wire:ignore-zone reactive-descendant issues on Flux components, and editor.spacer placement. Reads vendor/livewire/flux-pro/stubs/resources/views/flux/ as ground truth, cites file:line refs in findings. Trigger before any `<flux:*>` write/edit."
model: inherit
tools: "Read, Bash, WebFetch, WebSearch"
maxTurns: 25
color: cyan
memory: user
---
```

### 3.3 Input Contract

Caller pastes inline:
- Blade snippet with `<flux:*>` components
- Plan-phase description that mentions Flux components by name
- File path to a Blade template the implementer is about to write/edit

If a file path is mentioned, agent reads it.

### 3.4 Pre-flight

```bash
cat composer.json 2>/dev/null | grep -E '"livewire/flux-pro"'
ls vendor/livewire/flux-pro/stubs/resources/views/flux/ 2>/dev/null | head -5
```

Branches:
- **Both present:** capture Flux Pro version, continue
- **Flux Pro not in composer.json:** `Pre-flight: SKIPPED — not a Flux Pro project`, stop
- **composer.json missing:** `Pre-flight: SKIPPED — no composer.json found`, stop
- **Flux Pro present, vendor missing:** `Pre-flight: WARNING — vendor missing, run composer install. Falling back to docs-only verification via WebFetch.`, continue with WebFetch fallback against `https://fluxui.dev/docs/`
- **Flux version ≠ 2:** `Pre-flight: WARNING — Flux <version> detected; this agent is tuned for Flux Pro v2. Most checks still apply but slot composition is 2+.`, continue

## 4. The Five Audit Checks

### 4.1 `<flux:with-tooltip>` Self-Wrap Detection

**Trigger:** input contains `<flux:tooltip>` wrapping `<flux:button>`, `<flux:icon-button>`, `<flux:editor.button>`, `<flux:nav.item>`, or any other Flux component.

**Procedure:**

1. Locate each `<flux:tooltip>...</flux:tooltip>` wrapper
2. Identify the wrapped component's tag (e.g., `<flux:editor.button>`)
3. Read the corresponding vendor Blade: `vendor/livewire/flux-pro/stubs/resources/views/flux/{component-path}.blade.php`
4. Grep that vendor file for `<flux:with-tooltip>` or `flux:tooltip` references
5. If found = the component self-tooltips → outer `<flux:tooltip>` is redundant (double-wrap), breaks roving-tabindex on `<ui-toolbar>` parents
6. Emit per finding:
   - `❌ \`<flux:tooltip>\` outer wrapper around \`<flux:editor.button>\` at line N — **DOUBLE-WRAP**`
     - Vendor evidence: `vendor/livewire/flux-pro/stubs/resources/views/flux/editor/button.blade.php:26` already self-tooltips via `<flux:with-tooltip>`
     - Risk: breaks roving-tabindex on `<ui-toolbar>` parent (silent a11y regression, keyboard-only detectable)
     - Suggested: remove the outer `<flux:tooltip>`, pass `tooltip="Bold"` as a prop on `<flux:editor.button>` directly

### 4.2 Position/Align Convention Scan

**Trigger:** input contains `position="..."` on `<flux:dropdown>`, `<flux:tooltip>`, `<flux:menu>`, `<flux:popover>`.

**Procedure:**

1. Locate every `position="..."` attribute
2. Check if the value is compound (`"bottom end"`, `"top start"`) or separate (`position="bottom" align="end"`)
3. Project canon (per Block 1H Phase 3 audit): separate is the chosen convention
4. Emit per finding:
   - `⚠️ \`position="bottom end"\` (compound) at line N — project canon is separate props`
     - Suggested: rewrite as `position="bottom" align="end"`
     - Both work technically; consistency with sibling code is what's flagged

### 4.3 `<flux:editor.spacer/>` Semantics

**Trigger:** input contains `<flux:editor.spacer/>` or `<flux:editor.spacer>`.

**Procedure:**

1. Verify the spacer is inside an `<flux:editor.toolbar>` (or related toolbar container)
2. Verify it's positioned to push subsequent items to the right edge (typically before a trailing button cluster)
3. Read `vendor/livewire/flux-pro/stubs/resources/views/flux/editor/spacer.blade.php` to confirm it's `flex-1`
4. Emit:
   - `✅ \`<flux:editor.spacer/>\` at line N — correctly placed inside toolbar, pushes following items right`
   - `⚠️ \`<flux:editor.spacer/>\` at line N — placed outside toolbar (won't have expected push effect)`

### 4.4 `wire:ignore` Zone Reactive-Descendant Detection

**Trigger:** input contains `wire:ignore` on a `<flux:*>` component, OR `<flux:*>` descendants of any `wire:ignore` element.

**Procedure:**

1. Locate all `wire:ignore` blocks in input
2. Scan descendants for Livewire-reactive attributes on Flux components: `wire:click`, `wire:model`, `wire:change`, `wire:keydown`, etc.
3. Any match = silent failure (Livewire won't re-render the descendant)
4. Suggested: use Alpine `x-bind` on the Flux component, or `x-on:click="$wire.foo()"` for click handlers
5. Emit:
   - `⚠️ \`<flux:button wire:click="save">\` inside `<flux:editor wire:ignore>` at line N — silent failure`
     - Suggested: replace with Alpine: `<flux:button x-on:click="$wire.save()">`

### 4.5 Slot Composition vs String-Prop Trade-off

**Trigger:** input contains `<flux:editor toolbar="...">` (string prop) OR `<flux:editor><flux:editor.toolbar>...</flux:editor.toolbar></flux:editor>` (slot).

**Procedure:**

1. Classify the use-case:
   - String prop OK for: single static toolbar item, very simple buttons (1-2)
   - Slot required for: 3+ toolbar items, dynamic content, custom button groups, anything needing `<flux:editor.spacer/>`
2. Read the vendor stub `vendor/livewire/flux-pro/stubs/resources/views/flux/editor.blade.php` to confirm slot vs string handling
3. Emit recommendation:
   - `⚠️ \`<flux:editor toolbar="Bold | Italic | Save">\` — string prop limits toolbar to text-only, no event-bindings`
     - Suggested: use slot form `<flux:editor><flux:editor.toolbar>...</flux:editor.toolbar></flux:editor>` for buttons with `wire:click` or Alpine handlers

## 5. Output Format

Identical structure to #1 and #2:

```markdown
## Flux Pro Specialist Audit — <scope name>

**Flux Pro version:** <version from composer.json>
**Vendor source:** vendor/livewire/flux-pro/stubs/resources/views/flux/  (OR: docs-only fallback)

### 1. <flux:with-tooltip> Self-Wrap Detection
<findings or N/A>

### 2. Position/Align Convention Scan
<findings or N/A>

### 3. <flux:editor.spacer/> Semantics
<findings or N/A>

### 4. wire:ignore Zone Reactive-Descendant Detection
<findings or N/A>

### 5. Slot Composition vs String-Prop Trade-off
<recommendation or N/A>

---

## Summary

**N issues found:** X critical, Y important, Z minor.
**Block implementation until:** <list of critical blockers, or "none">
**Other issues:** <one-line guidance>
```

### Severity

- **Critical** (a11y break / silent failure): double-wrap tooltip (roving-tabindex break), reactive attrs in wire:ignore zones
- **Important** (visible bug or wrong behavior): editor.spacer misplaced, slot vs string mismatch with dynamic content
- **Minor** (style + maintainability): position/align convention drift

## 6. Error Handling

Same matrix as #1, #2:

| Situation | Behavior |
|---|---|
| No `livewire/flux-pro` in composer.json | `Pre-flight: SKIPPED — not a Flux Pro project`, exit |
| `vendor/livewire/flux-pro/` missing | `Pre-flight: WARNING — vendor missing, fallback to docs`, continue |
| Input has no Flux refs | All sections N/A |
| Vendor Blade file unreadable | `⚠️ Could not read <path>`, skip checks needing it |
| Wrong Flux version | WARNING, continue best-effort |

## 7. Testing

Three smoke tests (manual, captured in `docs/superpowers/test-evidence/`):

1. **Canonical bug:** `<flux:tooltip><flux:editor.button>Bold</flux:editor.button></flux:tooltip>` → expect ❌ critical double-wrap with vendor file:line citation
2. **Clean phase:** `<flux:button position="bottom" align="end">Save</flux:button>` → 0 issues
3. **Non-Flux project:** Bootstrap/Tailwind audit → expect Pre-flight SKIPPED

## 8. Documentation Deliverables

- `agents/laravel-flux-pro-specialist.md`
- `README.md` — append to Agents list
- `docs/agents.md` — insert entry; remove #3 from Forthcoming

## 9. AC Mapping

| AC from #3 | Where |
|---|---|
| Agent dispatched on Flux-touching phase | §2 Non-goals (auto-dispatch is #20) |
| First action: traverse vendor Blade | §3.4 pre-flight + §4 procedures use Read |
| Documented catches: tooltip wrapper, position/align, wire:ignore | §4.1, §4.2, §4.4 + §7 smoke 1 |
| Cites vendor file:line refs | §4.1 procedure step 6 (template) |

## 10. Out of Scope

- Auto-dispatch → #20
- Free Flux Core (no `editor`, `dropdown`) — opinionated Pro-only
- Style/visual recommendations beyond conventions
