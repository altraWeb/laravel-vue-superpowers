# Vue Fork Stack Audit — Pilot 2.0 T1

**Auditor:** `laravel-best-practices` Agent (background dispatch, 2026-05-17)
**Trigger:** Brainstorming session 2026-05-17 — V3 Mega-Release (Livewire) + Vue-Fork planning
**Scope:** Stack decisions for the *future* `laravel-vue-superpowers` sibling plugin (NOT for V3-Livewire scope)
**Method:** Tier-1 source review (laravel.com, inertiajs.com, vuejs.org) + Tier-2 community sources (Spatie, Tighten, advanced-inertia.com, Vue School) + 2026 year-filtered web search

> Note: This audit was generated for a *future* brainstorming session covering the Vue fork. It is archived here so that future session has full context without re-running the audit. The full audit text from the dispatched agent run is no longer accessible (background-agent transcript expired); this archive captures the two distilled outputs that survived as agent-memory.

---

## Executive Summary

For the planned `laravel-vue-superpowers` sibling plugin, the canonical 2026 stack is:

- **Laravel 12 (stable) / 13.x (latest), PHP 8.2+**
- **Inertia v2** (v3 in beta since March 2026 — opt-in as early-adopter profile, not default)
- **Vue 3 + Composition API + `<script setup>` + TypeScript** (Options API hard-banned via hook)
- **Vite 6/7 + Tailwind CSS 4**
- **UI: shadcn-vue** (built on Reka UI) — the like-for-like replacement for Flux Pro v2
- **Routing/Types: Wayfinder v1** default; Beta v2 as opt-in
- **Type DTOs: spatie/laravel-data + spatie/laravel-typescript-transformer**
- **Testing: Pest 4 + Browser Plugin (Playwright)** — exactly like the Livewire variant
- **State: NO Pinia by default** (composables-first); Pinia as opt-in skill
- **Realtime: Reverb** (not Pusher)
- **Forms: `useForm` with Precognition**

These defaults mirror the official `laravel/vue-starter-kit` AND the `inertiajs/demo-v3` reference repo — Tier-1 consensus from the Laravel core team AND the Inertia team. Deviations would be arbitrary.

## Stack Decisions (entrenched as scaffolding defaults)

| Decision | Choice | Rationale |
|---|---|---|
| Laravel version | 12 (stable) / 13.x (latest) | Match starter-kit baseline |
| PHP version | 8.2+ | Inertia v2 minimum |
| Inertia version | v2 (default), v3 (opt-in) | v3 still in beta as of 2026-03 |
| Vue version | 3.4+ | Required for `<script setup>` parity |
| Vue API style | Composition API + `<script setup>` + TS | Options API hard-banned (see anti-patterns) |
| Build tool | Vite 6/7 | Starter-kit baseline |
| Styling | Tailwind CSS 4 | Laravel default since Laravel 11 |
| UI library | shadcn-vue (on Reka UI) | Like-for-like replacement for Flux Pro v2 in Vue ecosystem |
| Routing helper | Wayfinder v1 | Beta v2 too fresh for default |
| Type DTOs | spatie/laravel-data + spatie/laravel-typescript-transformer | Tier-1 community consensus |
| Testing | Pest 4 + Browser plugin (Playwright) | Identical to Livewire variant for stack parity |
| State management | Composables-first (no Pinia default) | Premature optimization warning |
| Realtime | Reverb | Not Pusher (in-house Laravel offering) |
| Forms | `useForm` + Precognition | Tier-1 from inertiajs.com |

### Deliberately Opt-In (Not Hard-Coded)

- **Inertia SSR** — Vite plugin makes it trivial but deploy complexity remains
- **Pinia** — only when actual cross-component global state exists
- **PrimeVue Unstyled** — enterprise / data-heavy profile only
- **Wayfinder Beta v2** — full TS-gen, but too fresh for default
- **`useHttp`** — Inertia v3 only
- **Vitest Browser Mode** — parallel to Pest Browser only for pure FE components

## Anti-Patterns (planned hook bans)

### HARD BAN (hook blocks)

1. **`Inertia::share(['validationMessages' => trans('validation')])` without need** — long tasks, INP disaster
2. **Axios/fetch in Vue page-component instead of `useForm`/`router.visit`** — loses Inertia state preservation
3. **`defineProps({ user: Object })` without TS generic** — loses complete type benefit (ESLint rule rather than hook)
4. **Options API in Inertia page (`export default { data() }`)** — Composition API is starter-kit default
5. **Initial state via AJAX instead of Inertia props** — double round-trip, kills LCP
6. **Module-level state in composable + SSR active** — cross-request state leak between users (ban only when SSR config detected)

### WARN (hook warns, does not block)

7. `import useStore` without Pinia installed / without cross-component need — premature optimization
8. Routes hardcoded as string instead of Wayfinder — loses refactor safety
9. `<Link href>` with external URL instead of `<a>` — silent fallback
10. `setInterval` for polling instead of `usePoll` — loses tab-visibility throttle

### NOT BANNED (legitimate patterns exist)

11. Mixing Livewire + Inertia in same project — warn only, separated areas are fine
12. Page component imports Pinia stores directly (without composable wrapper) — style preference, not bug

## Open Questions / Actively Debated (do NOT hard-code)

- Inertia v3 adoption timing — community split between early-adoption and waiting for stable
- SSR yes/no — strong opinions both directions, depends on traffic profile and deploy infrastructure
- shadcn-vue vs Headless UI vs Reka UI direct — close race in 2026; shadcn-vue chosen as default but the others have valid niches

## Carryover Matrix (Livewire → Vue Variant)

| Component | Carryover Status | Notes |
|---|---|---|
| `laravel-pest-specialist` agent | 1:1 carryover | Pest 4 is stack-agnostic |
| `laravel-architect` agent | 1:1 carryover | Layer decisions (Actions/Services) are Laravel-wide |
| `laravel-reviewer` agent | 1:1 carryover (sub-checklists swap) | Livewire/Flux sub-checklists → Vue/Inertia sub-checklists |
| `laravel-best-practices` agent | 1:1 carryover | Generic Laravel research |
| `laravel-livewire-specialist` agent | REPLACE | → `laravel-inertia-specialist` + `laravel-vue3-specialist` |
| `laravel-flux-pro-specialist` agent | REMOVE or REPLACE | Either remove (operator builds own UI) or replace with `laravel-shadcn-vue-specialist` |
| `laravel-tdd` skill | 1:1 carryover | Pest 4 + Browser plugin applies identically |
| `laravel-debugging` skill | adapt | Vue devtools + Inertia request inspection instead of Livewire devtools |
| `laravel-code-review` skill | adapt | Sub-checklists swap |
| `laravel-brainstorming` skill | adapt | Inertia design patterns instead of Livewire |
| All 7 (V2.0.1) + 6 (V3) hooks | adapt | Banned-token / no-attribution / teamcity / anti-deferral / brainstorm-T1 / VC-default-on all stack-agnostic; vendor-source preflight is the only Flux-specific one |

## References (Tier 1 / 2)

- Tier 1: laravel.com/docs (Laravel 12), inertiajs.com (v2 docs), vuejs.org (Vue 3 + Composition API)
- Tier 1: `laravel/vue-starter-kit` reference repo
- Tier 1: `inertiajs/demo-v3` reference repo
- Tier 2: spatie.be (laravel-data, laravel-typescript-transformer)
- Tier 2: advanced-inertia.com (Inertia patterns)
- Tier 2: tighten.co blog posts
- Tier 2: Vue School (Composition API + TypeScript patterns)

## Persistence Note

The two most actionable findings (stack-decisions + anti-pattern-hooks) are stored in agent-memory and survive future Claude Code compactions:

- `~/.claude/agent-memory/laravel-superpowers-laravel-best-practices/project_vue_fork_stack_decisions.md`
- `~/.claude/agent-memory/laravel-superpowers-laravel-best-practices/project_vue_fork_anti_pattern_hooks.md`

This archive is the canonical project-tracked version for cross-session reference.
