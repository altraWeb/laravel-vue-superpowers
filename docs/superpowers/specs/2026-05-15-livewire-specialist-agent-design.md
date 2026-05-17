# `laravel-livewire-specialist` Agent — Design Spec

**Issue:** [#1](https://github.com/altraWeb/laravel-superpowers/issues/1)
**Milestone:** V2-MVP
**Status:** Design draft — pending review
**Author:** altraWeb + collaborator
**Date:** 2026-05-15

---

## 1. Context & Motivation

In the Block 1H Editor AI-Toolbar sprint (2026-05-14, Phase 5 audit), an implementation plan included a `$this->hasLoading($method)` computed getter on Livewire hosts as the aria-busy resolver. `hasLoading()` is a **fabricated API** — it does not exist on `Livewire\Component`. PHP reflection on the vendor source confirms zero public methods matching `*load*`. Shipping this would have thrown `BadMethodCallException` on the first dropdown click in production.

The generic `laravel-best-practices` agent caught this *only because* the audit prompt explicitly asked to verify the API. A dedicated Livewire-4 specialist would catch this category proactively as a **default-first-check** on every Livewire-touching phase.

This spec defines that agent.

## 2. Goals & Non-Goals

**Goals**

- Audit Livewire-touching plan-phases / code snippets for the 5 most common Livewire-4 stolperer
- Verify API existence via PHP reflection against the actual vendor source (`vendor/livewire/livewire/src/Component.php`) — not docs, not training data
- Emit a structured markdown report that humans read and downstream tooling (e.g. #20 hook) can parse
- Be invokable manually by the user OR by a future dispatch hook (#20)
- Skip cleanly when the project isn't Livewire-based (no false positives, no crashes)

**Non-Goals**

- Auto-dispatch on plan-phase boundaries — that's #20 (`brainstorm-time T1 audit auto-dispatch`)
- Full Livewire 3 ↔ 4 migration guidance — the agent is opinionated about Livewire 4 only
- Editing user code — agent is read-only, emits suggestions, never patches
- Replacing `laravel-best-practices` — that agent handles broader Laravel research; this one is Livewire-specific depth

## 3. Architecture

### 3.1 Single-file Agent

The agent is one Markdown file with YAML frontmatter at `agents/laravel-livewire-specialist.md`. The frontmatter declares metadata + tool permissions; the body is the prompt that drives the agent's behavior.

This mirrors the existing `agents/laravel-best-practices.md` structure. No supporting library, no helper scripts — the PHP reflection snippets the agent runs are trivial inline `php -r '...'` invocations.

### 3.2 Frontmatter

```yaml
---
name: laravel-livewire-specialist
description: "Use in Laravel+Livewire projects before/during any Livewire-touching implementation phase. Audits API existence (catches fabricated methods like $this->hasLoading), wire:ignore zones, Form-Object patterns, Echo/broadcasting integration, and lifecycle-hook usage. Verifies via PHP reflection against vendor/livewire/livewire/src/Component.php — ground truth, not docs. Trigger automatically before any plan-phase that mentions Livewire components, $this->X() methods, wire:* directives, or #[On]/#[Computed]/#[Locked] attributes."
model: inherit
tools: "Read, Bash, WebFetch, WebSearch"
maxTurns: 25
color: blue
memory: user
---
```

### 3.3 Input Contract

The caller pastes inline one of:
- A plan-phase description (`"Phase 5: add aria-busy via $this->hasLoading()"`)
- Code snippets — PHP class body, Blade template, JS callback
- A specific question framed as audit (`"audit my dropdown component at app/Livewire/Editor/DropdownAi.php"`)

If a file path is mentioned, the agent reads it itself via the `Read` tool.

### 3.4 Pre-flight (Step 1 of agent workflow)

The agent's first action on every invocation:

1. `cat composer.json | grep -E '"livewire/livewire"'` — confirm Livewire installed; capture version
2. `ls vendor/livewire/livewire/src/Component.php` — confirm reflection-source available
3. Branch on result:
    - **Both present:** continue to full audit
    - **Livewire not installed:** emit `## Pre-flight: SKIPPED — not a Livewire project`, exit clean
    - **Vendor missing:** emit `## Pre-flight: WARNING — vendor/ missing, run composer install. Falling back to docs-only verification.`, continue with `WebFetch` against `https://livewire.laravel.com/docs/...` for API checks

## 4. The Five Audit Checks

Each check runs only if the input contains relevant triggers. When no triggers found, the agent emits `N/A — no [...] references in scope` for that section (explicit, never silent skip).

### 4.1 API Verification

Triggered when input contains `$this->...` references.

**Procedure:**
1. Extract every `$this->methodName()` / `$this->propertyName` from input
2. For each: run PHP reflection script:
   ```bash
   php -r 'echo (new ReflectionClass("Livewire\\Component"))->hasMethod("methodName") ? "yes" : "no";'
   ```
3. Reflection covers traits + parents automatically — no manual walking needed
4. For methods on the **user's own** component: read the referenced component file and verify the method is declared there

**Output per method:** ✅ exists / ❌ NOT FOUND + suggested alternative.

### 4.2 wire:ignore Zone Scan

Triggered when input contains `wire:ignore`.

**Procedure:**
1. Locate all `wire:ignore` block boundaries in template input
2. For each block: scan descendant elements for any `wire:*` directive
3. Any hit = silent failure: descendants in ignored subtrees don't reactively update
4. Suggested pattern: bridge via Alpine `x-on:click="$wire.foo()"`

### 4.3 Form-Object Pattern

Triggered when input contains form code: `Livewire\Form` import, `rules()` method, `validate()` call, or `protected $rules` property.

**Procedure:**
- Read the component / form code, classify the use-case
- Recommend `Livewire\Form` if: multi-step wizard, separate state from component lifecycle, reusable across components
- Recommend `property + rules()` if: simple form, single-use, lifecycle-coupled
- Recommend Spatie LaravelData if: read-only DTO, nested structures, type-strict serialization
- Flag if both patterns are mixed (anti-pattern)

### 4.4 Echo / Broadcasting

Triggered when input contains `Echo.private(`, `Echo.channel(`, `.notification(`, `.whisper(`, or PHP `#[On]` attribute with broadcast event.

**Procedure:**
- Scan callbacks for direct DOM mutation (`document.getElementById(...).innerHTML = ...`, `el.classList.add(...)`)
- Flag race-condition risk: callback runs before Livewire next morph → mutations may be wiped
- Suggested pattern: callback dispatches a Livewire action (`$wire.fooFromEcho(data)`); the component re-renders via Livewire's normal path

### 4.5 Lifecycle Hooks

Triggered when input contains `mount(`, `boot(`, `hydrate(`, `dehydrate(`, `updating(`, `updated(`, `rendering(`, `rendered(`.

**Procedure:**
- Verify hook names against `Livewire\Component` via reflection (catches typos like `mountup` or `hydrated`)
- Flag common mistakes:
   - `mount()` doing work that should also run on subsequent requests → should be in `hydrate()` or a `#[Computed]` property
   - `updated()` without `$property` filtering or named suffix when only one property is tracked → declare `updatedFooBar()` for clarity
   - `boot()` with side-effects (runs on every request, including hydration) → make sure that's intended

## 5. Output Format

Single markdown report following this structure:

```markdown
## Livewire Specialist Audit — <scope name>

**Livewire version:** 4.x (from composer.json)
**Reflection source:** vendor/livewire/livewire/src/Component.php

### 1. API Verification
[per-method results with ✅/❌/⚠️, or N/A line]

### 2. wire:ignore Zone Scan
[findings or N/A]

### 3. Form-Object Pattern
[recommendation or N/A]

### 4. Echo / Broadcasting
[findings or N/A]

### 5. Lifecycle Hooks
[findings or N/A]

---

## Summary

**N issues found:** X critical, Y important, Z minor.
**Block implementation until:** [list of critical blockers, or "none"]
**Other issues:** [one-line guidance]
```

### Severity classification

- **Critical** (blocks ship): fabricated API, would crash at runtime
- **Important** (should fix before merge): wire:ignore zones with reactive children, Echo morphing race, lifecycle hook typos
- **Minor** (nice to fix): pattern recommendations, missing property filters

## 6. Error Handling / Edge Cases

| Situation | Behavior |
|---|---|
| No `livewire/livewire` in composer.json | `## Pre-flight: SKIPPED — not a Livewire project`, exit clean |
| `vendor/livewire/` missing | `## Pre-flight: WARNING — vendor missing, run composer install. Falling back to docs-only verification.` Then continue with WebFetch fallback for the API check section |
| Input has no Livewire references at all | Each section: `N/A`. Final summary: `Audit scope clean — no Livewire touchpoints detected.` |
| PHP reflection script fails (syntax, permissions, php missing) | Per check, emit `⚠️ Verification unavailable: <error>`, do not crash the whole audit |
| Referenced user-component file unreadable | `⚠️ Could not read <path>: <error>`, skip checks that need that file |
| Livewire version ≠ 4 (older project) | `## Pre-flight: WARNING — Livewire <version> detected; this agent is tuned for Livewire 4. Most checks still apply but some attributes (#[Computed], #[Locked]) are 3+. Reading vendor regardless.` |

The principle: the agent should never crash and should never silently skip. Every situation gets an explicit line in the report so the caller knows what was verified vs. what wasn't.

## 7. Testing & Validation

### 7.1 Smoke test — the canonical bug

After the agent file is written, manually invoke it with the exact Block 1H Phase 5 scenario:

```
"audit: Phase 5 plan adds aria-busy resolver via $this->hasLoading($method) — Livewire computed getter on Editor\AiToolbar component"
```

**Expected output:** API Verification section flags `$this->hasLoading()` as ❌ NOT FOUND with reflection evidence, severity `critical`, summary blocks shipping.

### 7.2 Smoke test — clean phase

Invoke with a phase that has no issues:

```
"audit: Phase 2 adds $this->mount(User $user) for initial state binding"
```

**Expected output:** API Verification: ✅ `$this->mount()`. Other sections N/A. Summary: 0 issues.

### 7.3 Smoke test — non-Livewire project

Invoke from a Laravel project without Livewire installed.

**Expected output:** `## Pre-flight: SKIPPED — not a Livewire project`. No crash.

These three smoke tests are the acceptance criteria for the implementation plan. They're not automated (agent-as-prose isn't pytest-runnable) but the dev runs them manually and pastes outputs into the PR description as evidence.

## 8. Documentation Deliverables

- `agents/laravel-livewire-specialist.md` — the agent itself (frontmatter + body)
- `README.md` — add `laravel-livewire-specialist` to the agents list with one-line description + when to use
- `docs/agents.md` (create if not present) — short reference page listing all agents shipped by the plugin, what each is for, when to invoke. Forward-looking — #2-5 will append to this.

## 9. Acceptance Criteria Mapping

| AC from #1 | Where covered |
|---|---|
| Agent dispatched on Livewire-touching plan-phase BEFORE implementer | §2 Non-goals (auto-dispatch is #20). Agent itself is dispatchable; the WHEN is separate. |
| Output: API-verification section, wire:ignore scan, Alpine recommendations | §4.1 + §4.2 + §5 (output format) |
| Reads vendor source for ground truth | §3.4 pre-flight + §4.1 reflection procedure |
| Documented example: catches `$this->hasLoading()` | §7.1 smoke test |

## 10. Out of Scope (Follow-up issues)

- Auto-dispatch on plan-phase boundaries → #20
- Pest specialist (similar pattern for Pest 4) → #2
- Flux Pro specialist → #3
- Pulling Livewire docs into a local cache for offline reflection → no issue, would be performance optimization

## 11. Open Questions for Implementation Plan

These move into the implementation plan once this spec is approved:

- Should the agent emit JSON in addition to markdown for tooling consumption, or is markdown sufficient for #20 to grep? (Defer: markdown is fine for v1; #20 can parse it.)
- Should pre-flight check be cached across invocations in the same session? (Defer: agent invocations are stateless; recheck is cheap.)
- Should the agent ship with a snapshot of the Livewire vendor source so it works without `composer install`? (Defer: vendor-snapshot approach is heavy; rely on user having composer install, fall back to docs.)

---

*Spec ready for review. Next step: implementation plan via `superpowers:writing-plans`.*
