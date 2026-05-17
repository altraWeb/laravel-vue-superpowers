# laravel-vue-superpowers

Laravel + **Vue 3 (Composition API)** + **Inertia v3** + **Reka UI** + **Tailwind CSS 4** + **Pest 4** specialist toolkit for [Claude Code](https://claude.ai/code) — designed to complement the [superpowers](https://github.com/anthropics/claude-plugins-official) base plugin with deep stack-specific expertise.

> **Stack scope:** This plugin targets the Vue 3 + Inertia v3 + Reka UI stack. For the Livewire 4 + Flux Pro v2 variant, see the sibling plugin [`laravel-livewire-superpowers`](https://github.com/altraWeb/laravel-livewire-superpowers) (v3.0.0+).
>
> **Pre-1.0 release:** Currently shipping `v1.0.0-alpha.1` (foundation: identity rename). Full agents/skills/hooks adaptation lands in Phases B-E (v1.0.0-alpha.2 through v1.0.0 stable). Functional usage from v1.0.0-alpha.2 onwards.

📍 **[Roadmap](docs/ROADMAP.md)** — see what's planned + tracked GitHub issues
📊 **[Versions](#versions)** — phase-by-phase release history

## Install

```bash
claude /plugin marketplace add altraWeb/laravel-marketplace
claude /plugin install laravel-vue-superpowers@altraweb-laravel
```

## Configuration

Per-user and per-project settings via YAML. See [`docs/config.md`](docs/config.md) for the full reference.

```bash
# Scaffold a user-global config you can edit
python3 <plugin>/lib/config.py init

# See effective merged config with source attribution
python3 <plugin>/lib/config.py show
```

Requires Python 3.10+ with `pyyaml` and `jsonschema`. On Homebrew Python:

```bash
pip3 install --user --break-system-packages pyyaml jsonschema
```

## Skills (7)

- **laravel-brainstorming** — Architecture brainstorming for Laravel: layers, Eloquent relationships, Events, Policies, queuing decisions
- **laravel-tdd** — TDD workflow with Pest 4: factories, HTTP testing, facade faking, Feature vs Unit
- **laravel-debugging** — Debugging with Laravel-specific tools: Telescope, query logging, queue introspection
- **laravel-code-review** — Code review checklist: N+1, mass assignment, authorization, validation, security
- **laravel-a11y-specialist** — WCAG 2.2 + ARIA + reduced-motion patterns for Vue 3 + Reka UI UIs (adaption in Phase C)
- **laravel-mr-body-writer** — Canonical MR/PR body generator from sprint state (plan-doc + /status + git history)
- **laravel-perf-auditor** — Mechanical query-path safety sweep: preventLazyLoading status, N+1 patterns, cache strategy

## Agents (11 / 11)

- **laravel-best-practices** — Web research agent for current Laravel best practices (Spatie, Laracasts, Laravel News). Use when asking *"how should I implement X?"* or *"is my current approach still best practice?"*.
- **laravel-pest-specialist** — Audits Pest 4 tests for variadic-API misuse, browser-plugin smells, view-context anti-patterns, test-location mismatches. Verifies via PHP reflection against the actual Pest vendor source. Use before any test write/edit.
- **laravel-reka-ui-specialist** — *(Phase B)* Audits Vue components using Reka UI primitives for canonical composition, slot usage, controlled/uncontrolled patterns, Tailwind 4 data-attribute styling, and accessibility-by-default verification. Reads `node_modules/reka-ui/dist/` as ground truth.
- **laravel-inertia-specialist** — *(Phase B)* Audits Inertia v3 controllers + Vue page components: `Inertia::render` data passing, `useForm` + Precognition, `usePage` shared-data reactivity, partial reloads, deferred props, modal stack, history encryption, polling with `usePoll`.
- **laravel-vue3-specialist** — *(Phase B)* Audits Vue 3 components for Composition API + `<script setup>` + TypeScript patterns: ref/reactive/computed usage, defineProps TS generics, composable design, lifecycle cleanup, reactive-destructure pitfalls, watch usage.
- **laravel-architect** — Audits Eloquent + architecture decisions: N+1 detection, migration safety, performance smells, API design. Use before any plan-phase touching models/migrations/queries.
- **laravel-reviewer** — Evidence-based code review wrapping the `laravel-code-review` skill with tool access. Runs banned-token sweep, sibling-canon verification.
- **laravel-echo-reverb-specialist** — Broadcasting / realtime decision support. Scans channels, notifications, Echo callbacks to surface reuse-vs-new-channel decisions.
- **spatie-permission-auditor** — Gate-coverage + dead-permission audit. Cross-references seeded permissions vs actual `@can()` / `can()` / Policy usage.
- **laravel-package-evaluator** — Build-vs-buy decision support. Searches Packagist + GitHub for 2-5 candidates, builds trade-off matrix.
- **laravel-pilot-orchestrator** — On-demand Pilot 2.0 contract orchestrator. Reads active plan-doc Tactic Tracking sections + git log + audit history, emits per-phase T1-T4 compliance matrix.

See [`docs/agents.md`](docs/agents.md) for the full agent reference.

## Hooks (16 / 16)

- **banned-token-leak-guard** — PreToolUse hook on `git commit` that blocks commits with banned tokens in staged code/comments.
- **no-claude-attribution** — PreToolUse hook on `git commit`, `gh pr create`, `glab mr create` that blocks any Claude / AI attribution.
- **teamcity-always** — PreToolUse hook on `php artisan test` that blocks invocations missing `--teamcity`.
- **anti-silent-deferral** — PreToolUse hook on `git push` that scans plan docs for uncaptured deferred items.
- **visual-companion-default-on** — PostToolUse hook on brainstorming skill that injects a Visual Companion reminder.
- **brainstorm-t1-audit** — PostToolUse hook on brainstorming skill that dispatches `laravel-best-practices` audit (Pilot 2.0 T1).
- **sprint-state-context-injection** — SessionStart hook that injects active sprint state into session context.
- **stale-branch-sweep** — SessionStart hook that lists local branches whose upstream is gone (post-merge cleanup suggestion).
- **master-roadmap-drift-detector** — PostToolUse hook on `git commit` touching plan-docs that warns when master-roadmap entry is out of sync.
- **pilot-2-contract-enforcer** — PostToolUse hook on `git commit`/`git push` that warns on open T3/T4 Pilot 2.0 Tactic Tracking markers.
- **vendor-source-preflight** — *(Phase D: repurpose planned for inertia-vendor-preflight)* PreToolUse hook on `Edit`/`Write` of blade files; currently triggers on Flux/Livewire syntax.
- **lang-key-existence-preflight** — PreToolUse hook on `Edit`/`Write` of files with `__()` or `@lang()` that verifies each key exists in `lang/`.
- **vue-setinterval-cleanup** — *(Phase B)* PreToolUse hook on `Edit`/`Write` of `.vue` files; warns when `setInterval` is used without `onUnmounted` cleanup.
- **vue-reactive-destructure** — *(Phase B)* PreToolUse hook on `Edit`/`Write` of `.vue` files; warns on `const { ... } = reactive(...)` destructure that loses reactivity.
- **inertia-link-external-url** — *(Phase B)* PreToolUse hook on `Edit`/`Write` of `.vue` files; warns when Inertia `<Link>` is used with an external URL (silent 409).
- **inertia-hardcoded-route** — *(Phase B)* PreToolUse hook on `Edit`/`Write` of `.vue`/`.ts` files; warns on hardcoded route strings when Wayfinder is installed.

See [`docs/hooks.md`](docs/hooks.md) for the full hook reference.

## Slash Commands (3)

- **`/laravel-vue-superpowers:status`** — Read-only status panel. Surfaces current sprint state, Pilot 2.0 contract obligations, hook compliance, open obligations.
- **`/laravel-vue-superpowers:audit-phase N`** — Dispatch a Pilot 2.0 T1 audit scoped to Phase N of the active plan-doc.
- **`/laravel-vue-superpowers:retro`** — Generate an end-of-sprint retrospective report from plan-doc + git history + audit reports.

## Designed to complement [superpowers](https://github.com/anthropics/claude-plugins-official)

Each skill pairs with its superpowers counterpart:

| superpowers skill | laravel-vue-superpowers skill |
|---|---|
| `superpowers:brainstorming` | `laravel-vue-superpowers:laravel-brainstorming` |
| `superpowers:test-driven-development` | `laravel-vue-superpowers:laravel-tdd` |
| `superpowers:systematic-debugging` | `laravel-vue-superpowers:laravel-debugging` |
| `superpowers:requesting-code-review` | `laravel-vue-superpowers:laravel-code-review` |

Run the superpowers skill first for generic structure; run the laravel-vue-superpowers skill for stack-specific depth.

## Sibling plugins

| Plugin | Stack | Status |
|---|---|---|
| [`laravel-livewire-superpowers`](https://github.com/altraWeb/laravel-livewire-superpowers) | Laravel + Livewire 4 + Flux Pro v2 + Pest 4 | Released (v3.0.0+) |
| `laravel-vue-superpowers` (this repo) | Laravel + Vue 3 + Inertia v3 + Reka UI + Tailwind 4 + Pest 4 | Alpha (v1.0.0-alpha.1+) |

## Versions

- **v1.0.0-alpha.2 (2026-05-17) — Phase B: Specialists + Anti-Pattern Hooks** *(current)* — Removed Livewire + Flux Pro specialist agents; added Reka UI, Inertia v3, and Vue 3 Composition API specialists; added 4 PreToolUse anti-pattern hooks for `.vue` / `.ts` files. First functional release for Vue 3 + Inertia v3 + Reka UI workloads.
- **v1.0.0-alpha.1 (2026-05-17) — Phase A: Identity Rename** — Plugin renamed from Livewire clone → laravel-vue-superpowers. Config paths, slash commands, README, docs/banners rebranded for Vue 3 + Inertia v3 + Reka UI + Tailwind 4 + Pest 4 stack. No content adaptation yet — agents/skills/hooks still from Livewire source.

See [CHANGELOG.md](CHANGELOG.md) for full history and [docs/superpowers/specs/2026-05-17-vue-fork-adaptation-design.md](docs/superpowers/specs/2026-05-17-vue-fork-adaptation-design.md) for the 5-phase adaptation roadmap.
