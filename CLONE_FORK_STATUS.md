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
- Livewire-specific Blade patterns in skills (replaced — see REPLACE section below)
- Livewire-only hook content (`vendor-source-preflight` Flux/Livewire patterns — will be REPURPOSED for Reka UI / Inertia component lookups, not removed)

### To REPLACE
- `agents/laravel-livewire-specialist.md` → `agents/laravel-inertia-specialist.md` + `agents/laravel-vue3-specialist.md`
- `agents/laravel-flux-pro-specialist.md` → `agents/laravel-reka-ui-specialist.md` (analogous UI-library specialist role — Reka UI primitives instead of Flux Pro v2 components). REVISED 2026-05-17: operator initially planned "no UI library / pure Tailwind utility-first" but after Deep-Research showed Reka UI is the laravel/vue-starter-kit canonical default (v2.6.1+), reverted to Reka UI as default. shadcn-vue (built on Reka UI) and PrimeVue available as opt-in skill/preset.
- Livewire-flavored a11y patterns → Vue/Inertia patterns (with Reka UI a11y built-in, so reduced manual ARIA scope)
- Livewire code-review sub-checklists → Vue/Inertia sub-checklists (Reka UI sub-checklist analogous to Flux Pro v2 sub-checklist)
- `vendor-source-preflight.sh` → repurposed to surface Reka UI component sources + Inertia helper stubs on Vue file edits (likely rename to `inertia-vendor-preflight.sh`)

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
- `agents/laravel-inertia-specialist.md` (Inertia v3 patterns: shared data, partial reloads, modals, deferred props, `useHttp`, polling, history encryption)
- `agents/laravel-vue3-specialist.md` (Composition API + `<script setup>` + TS patterns, reactive object/ref pitfalls, listener cleanup with `onUnmounted`)
- Anti-pattern hooks per the T1 audit + 4 additional from Deep-Research:
  - HARD-BAN: `Inertia::share` validation overuse, axios in pages, no-TS props, Options API, AJAX initial state, SSR module-state
  - HARD-BAN (new): `setInterval` without `onUnmounted` cleanup, Vue 3 reactive-object-destructure pitfall (refs in arrays don't auto-unwrap)
  - WARN: useStore without need, hardcoded routes (when Wayfinder shipped), `<Link>` with external URL (silent 409), `setInterval` polling without Page-Visibility check

## Stack decisions (from T1 audit)

Default stack for `laravel-vue-superpowers`:
- Laravel 12+ / PHP 8.2+
- Inertia v3 (stable since 2026-03-26, canonical default per `laravel/vue-starter-kit`). v2 available as opt-in compat-mode. (REVISED 2026-05-17 after Deep-Research.)
- Vue 3 + Composition API + `<script setup>` + TypeScript (Options API hard-banned)
- Vite 6/7 + Tailwind CSS 4
- UI: **Reka UI ^2.6.1** (accessible Vue 3 primitives, the engine under shadcn-vue) + Tailwind CSS 4. Mirrors `laravel/vue-starter-kit` canon. shadcn-vue + PrimeVue available as opt-in. (REVISED 2026-05-17: initial "no UI library" stance reverted after Deep-Research validated Reka UI as canonical Laravel starter-kit default.)
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
