# Fork Status — laravel-vue-superpowers

## What this repo is

A clone of [`altraWeb/laravel-livewire-superpowers`](https://github.com/altraWeb/laravel-livewire-superpowers) at tag `v3.0.0` (2026-05-17), intended to become the Vue 3 + Inertia v2 sibling plugin in the `laravel-{stack}-superpowers` family.

## What this repo IS NOT (yet)

- It is **not installable** in its current state. The plugin name is `laravel-vue-superpowers` but ALL content (agents, skills, hooks, docs, code) still describes the Livewire 4 + Flux Pro v2 stack from the source repo.
- It is **not listed in `altraWeb/laravel-marketplace`** yet. The marketplace only lists the Livewire variant.

## What's pending

The adaptation work is scoped via a separate brainstorming session (see `docs/superpowers/audits/2026-05-17-vue-fork-stack-audit.md` for the pre-cloned T1 audit with stack decisions and anti-pattern hooks). High-level changes:

### To REMOVE
- `agents/laravel-livewire-specialist.md`
- `agents/laravel-flux-pro-specialist.md` (no UI library in use — operator builds own Vue 3 + Tailwind 4 components)
- All Livewire-specific Blade patterns in skills (`laravel-a11y-specialist`, `laravel-code-review`, `laravel-debugging`)
- `hooks/vendor-source-preflight.sh` Flux/Livewire detection patterns (Vue stack has no equivalent vendor stub library; hook may be repurposed for Inertia component-resource lookups OR removed entirely — TBD per follow-up brainstorming)

### To REPLACE
- `laravel-livewire-specialist` → `laravel-inertia-specialist` + `laravel-vue3-specialist`
- `laravel-flux-pro-specialist` → **REMOVE entirely** (operator builds own components with pure Tailwind 4; no UI-library specialist needed)
- Livewire-flavored a11y patterns → Vue/Inertia patterns
- Livewire code-review sub-checklists → Vue/Inertia sub-checklists

### To KEEP unchanged (carryover 1:1)
- `agents/laravel-pest-specialist.md` (Pest is stack-agnostic)
- `agents/laravel-architect.md` (Eloquent + layering decisions are Laravel-wide)
- `agents/laravel-reviewer.md` (with sub-checklist swap)
- `agents/laravel-best-practices.md` (generic Laravel research)
- `agents/spatie-permission-auditor.md` (Spatie is stack-agnostic)
- `agents/laravel-package-evaluator.md` (build-vs-buy is generic)
- `agents/laravel-pilot-orchestrator.md` (meta — stack-agnostic)
- All Pilot 2.0 infrastructure (`hooks/pilot-2-contract-enforcer.sh`, `docs/pilot-2-0-contract.md`)
- Most general hooks (banned-token-leak-guard, no-claude-attribution, teamcity-always, anti-silent-deferral, brainstorm-t1-audit, visual-companion-default-on, sprint-state-context-injection, stale-branch-sweep, master-roadmap-drift-detector)
- Pest 4 testing infrastructure
- Config foundation (`lib/config.py` + schema)
- `/laravel-livewire-superpowers:status` → rename to `/laravel-vue-superpowers:status` (path-only change)

### To ADD
- `agents/laravel-inertia-specialist.md` (Inertia v2 patterns: shared data, partial reloads, modals, deferred props)
- `agents/laravel-vue3-specialist.md` (Composition API + `<script setup>` + TS patterns)
- Anti-pattern hooks per the T1 audit:
  - HARD-BAN: `Inertia::share` validation, axios in pages, no-TS props, Options API, AJAX initial state, SSR module-state
  - WARN: useStore without need, hardcoded routes, Link with external URL, setInterval polling

## Stack decisions (from T1 audit)

Default stack for `laravel-vue-superpowers`:
- Laravel 12+ / PHP 8.2+
- Inertia v2 (v3 in beta — opt-in)
- Vue 3 + Composition API + `<script setup>` + TypeScript (Options API hard-banned)
- Vite 6/7 + Tailwind CSS 4
- UI: **pure Vue 3 + Tailwind CSS 4 utility-first** — NO UI library (operator builds own components). shadcn-vue / Reka UI / PrimeVue are explicitly NOT defaults; available as opt-in skill/preset only if added later.
- Routing/Types: Wayfinder v1 default
- DTOs: spatie/laravel-data + spatie/laravel-typescript-transformer
- Testing: Pest 4 + Browser plugin (Playwright) — identical to Livewire variant
- State: composables-first (no Pinia default)
- Realtime: Reverb (not Pusher)
- Forms: `useForm` with Precognition

Reference: `docs/superpowers/audits/2026-05-17-vue-fork-stack-audit.md`

## When adaptation starts

A new brainstorming session in this repo will produce the Vue-specific design spec + Phase-A-equivalent foundation plan. Then phased rollout (analog to Livewire V3 Phases A-G).

Until then, do not file issues, do not install. The repo exists as a clean clone-and-rename baseline for the upcoming Vue brainstorming.
