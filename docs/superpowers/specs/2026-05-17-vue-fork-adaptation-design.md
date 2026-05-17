# Vue-Fork Adaptation Design Spec

**Milestone:** V1.0.0 (Vue/Inertia variant)
**Status:** Design draft (operator-approved 2026-05-17 brainstorming)
**Date:** 2026-05-17
**Deep-Research Audit:** [`docs/superpowers/audits/2026-05-17-vue-fork-deep-research.md`](../audits/2026-05-17-vue-fork-deep-research.md)
**Source Plugin:** [`altraWeb/laravel-livewire-superpowers@v3.0.0`](https://github.com/altraWeb/laravel-livewire-superpowers/releases/tag/v3.0.0)

---

## 1. Context & Motivation

`laravel-vue-superpowers` is the Vue 3 + Inertia v3 sibling of the already-shipped `laravel-livewire-superpowers` (v3.0.0). The repo was cloned verbatim from the Livewire variant on 2026-05-17 (initial commit `17dc347`) and exists today as a placeholder with `CLONE_FORK_STATUS.md` documenting the pending adaptation work.

This spec covers the **adaptation** — turning the clone into a functional Vue/Inertia plugin. Per deep-research findings, the operator's original "~70% carryover" claim is **verified** (now ~75% after Reka UI decision reversal): backend Laravel content is stack-agnostic and carries over 1:1, only the frontend-stack-specific specialist agents, hook content, and skill sub-checklists need swapping.

The deep-research audit surfaced two material drifts from the operator's initial pinned stack; both have been reconciled:
1. **Inertia v3 default** (was v2) — Inertia v3 stable since 2026-03-26, canonical per `laravel/vue-starter-kit`
2. **Reka UI default** (was "no UI library") — Reka UI ^2.6.1 is the canonical primitive lib in `laravel/vue-starter-kit`

This is **adaptation, not a new build.** Operator's own framing: "ich wollte ja auch nie 10 neue agenten sondern nur die umschreiben."

## 2. Goals & Non-Goals

**Goals**
- Ship a functional `laravel-vue-superpowers` v1.0.0 stable Claude Code plugin for Laravel + Vue 3 + Inertia v3 + Reka UI + Tailwind 4 + Pest 4 projects
- Maintain feature parity with `laravel-livewire-superpowers` v3.0.0 where stack-agnostic (Pilot 2.0 contract, all 12 enforcement/context hooks except `vendor-source-preflight`, all 3 slash commands, 8 of 10 specialist agents)
- Swap the 2 frontend-stack-specific specialists (REMOVE livewire, REPLACE flux-pro → reka-ui)
- Add 2 new frontend-stack specialists (laravel-inertia-specialist, laravel-vue3-specialist)
- Add 4 new anti-pattern hooks specific to Vue 3 + Inertia (verified canonical 2026 anti-patterns)
- Adapt 4 skill sub-sections (a11y reduced scope, code-review §9-10, debugging items #3+#8, tdd items #3+#8)
- Repurpose `vendor-source-preflight` for Reka UI + Inertia (rename to `inertia-vendor-preflight`)
- Land each phase as a separate alpha release (analog Livewire v3.0.0 phased rollout)
- Cut v1.0.0 stable after Phase E

**Non-Goals**
- Building 10 new agents (operator explicitly: just rewrite/replace the 2 frontend-stack-specific ones)
- Net-new functionality beyond the carryover scope (no Vue-specific features that don't have a Livewire-variant counterpart)
- Wayfinder dedicated specialist agent (deferred — covered in `laravel-inertia-specialist` body for now)
- shadcn-vue / PrimeVue dedicated specialists (Reka UI is the engine; single specialist sufficient)
- Pinia / SSR dedicated specialists (opt-in patterns, no dedicated coverage)
- Tailwind 4 dedicated specialist (covered in `laravel-best-practices`)
- Bundling Livewire + Vue variants under a monorepo (operator chose clone+new-repo)
- Migrating existing users (none exist — fresh plugin)

## 3. Stack Decisions (Reconciled, Final)

| Decision | Value | Reference |
|---|---|---|
| Laravel | 12 (stable) / 13.x (latest), PHP 8.2+ | `laravel/vue-starter-kit` composer.json |
| Inertia | **v3 default** (v2 opt-in compat-mode) | inertiajs.com v3 default declaration |
| Vue | 3 + Composition API + `<script setup>` + TypeScript | Vue 3 official, Options API hard-banned |
| Vite / Tailwind | Vite 6/7 + Tailwind CSS 4 (`@theme` directive) | Laravel 13 default |
| **UI** | **Reka UI ^2.6.1** (accessible Vue 3 primitives) | `laravel/vue-starter-kit` package.json |
| Routing/Types | Wayfinder v1 default; v2 beta opt-in | `laravel/wayfinder` Tier-1 |
| DTOs | spatie/laravel-data + spatie/laravel-typescript-transformer | Spatie / Tighten consensus |
| Testing | Pest 4 + Browser plugin (Playwright) | Identical to Livewire variant |
| State | Composables-first (Pinia opt-in) | Vue School / Pinia cookbook |
| Realtime | Reverb (not Pusher) | Laravel 13 canon |
| Forms | `useForm` + Precognition (Inertia 2.3+ built-in) | Laravel News |

**Explicitly opt-in (NOT defaults):**
- Inertia v2 compat-mode
- Inertia SSR
- shadcn-vue (built on Reka UI, presentation layer)
- PrimeVue Unstyled (enterprise/data-heavy profile)
- Wayfinder v2 beta (TS-gen)
- Pinia state management

## 4. Carryover Matrix

Computed from deep-research source-file classification of `laravel-livewire-superpowers@v3.0.0`:

### Agents (10 → 11)

| Source Agent | Vue Fate | Notes |
|---|---|---|
| `laravel-livewire-specialist` | **REMOVE** | Frontend-stack-specific to Livewire |
| `laravel-flux-pro-specialist` | **REPLACE** → `laravel-reka-ui-specialist` | UI-lib-specialist slot reused; Reka UI primitives instead of Flux Pro v2 components |
| `laravel-pest-specialist` | KEEP 1:1 | Pest is stack-agnostic |
| `laravel-architect` | KEEP 1:1 | Eloquent + layering decisions are Laravel-wide |
| `laravel-reviewer` | KEEP (sub-checklists swap in linked skill) | Wraps `laravel-code-review` skill which gets sub-section swaps in Phase C |
| `laravel-best-practices` | KEEP 1:1 | Generic Laravel research; updated knowledge base via web research at runtime |
| `laravel-echo-reverb-specialist` | KEEP 1:1 | Broadcasting/realtime is Laravel-wide |
| `spatie-permission-auditor` | KEEP 1:1 | Spatie Permission is stack-agnostic |
| `laravel-package-evaluator` | KEEP 1:1 | Build-vs-buy is generic |
| `laravel-pilot-orchestrator` | KEEP 1:1 | Pilot 2.0 meta-layer is stack-agnostic |
| **NEW** `laravel-inertia-specialist` | ADD | Inertia v3 primary, v2 compat-note; Wayfinder + useForm + Precognition coverage |
| **NEW** `laravel-vue3-specialist` | ADD | Composition API + `<script setup>` + TS, reactive pitfalls, listener cleanup |

### Skills (7 → 7, 4 get sub-section swaps)

| Source Skill | Vue Fate | Sub-Section Swap Scope |
|---|---|---|
| `laravel-tdd` | KEEP with swap | Pest-specifics items #3 + #8 (Livewire-specific) → Vue/Inertia equivalents |
| `laravel-debugging` | KEEP with swap | Top-10 RED items #3 (fabricated Livewire API) + #8 (Livewire properties) → Vue/Inertia equivalents |
| `laravel-code-review` | KEEP with swap | §9 Livewire sub-checklist → Inertia/Vue sub-checklist; §10 Flux Pro v2 sub-checklist → Reka UI sub-checklist |
| `laravel-a11y-specialist` | KEEP with reduced rewrite | 3 patterns rewrite (wire:loading equivalent + reduced-motion + audio control); 4 patterns drop (modal/dropdown/form-validation/skip-link handled by Reka UI accessibility-by-default) |
| `laravel-brainstorming` | KEEP 1:1 | Stack-agnostic Laravel design guidance |
| `laravel-mr-body-writer` | KEEP 1:1 | Sprint state + git history — generic |
| `laravel-perf-auditor` | KEEP 1:1 | Eloquent + cache + N+1 — stack-agnostic |

### Hooks (12 → 16, +4 anti-pattern hooks, 1 repurposed)

| Source Hook | Vue Fate | Notes |
|---|---|---|
| `banned-token-leak-guard` | KEEP 1:1 | Stack-agnostic |
| `no-claude-attribution` | KEEP 1:1 | Stack-agnostic |
| `teamcity-always` | KEEP 1:1 | Pest is Laravel-wide |
| `anti-silent-deferral` | KEEP 1:1 | Pilot 2.0 T6, stack-agnostic |
| `visual-companion-default-on` | KEEP 1:1 | Brainstorming step 2, stack-agnostic |
| `brainstorm-t1-audit` | KEEP 1:1 | Pilot 2.0 T1, stack-agnostic |
| `sprint-state-context-injection` | KEEP 1:1 | Git + plan-doc reading, stack-agnostic |
| `stale-branch-sweep` | KEEP 1:1 | Git operations, stack-agnostic |
| `master-roadmap-drift-detector` | KEEP 1:1 | Plan-doc cross-reference, stack-agnostic |
| `pilot-2-contract-enforcer` | KEEP 1:1 | Pilot 2.0 meta, stack-agnostic |
| `vendor-source-preflight` | **REPURPOSE + RENAME** → `inertia-vendor-preflight` | Detect Reka UI imports + Inertia helpers in `.vue`/`.ts` edits |
| `lang-key-existence-preflight` | KEEP with broadened trigger | Add `.vue` to file-type filter alongside `.blade.php` |
| **NEW** `vue-setinterval-cleanup` | ADD | Warn when `setInterval` in `.vue` lacks `onUnmounted` cleanup |
| **NEW** `vue-reactive-destructure` | ADD | Warn on reactive object destructure patterns that lose reactivity (refs in arrays don't auto-unwrap) |
| **NEW** `inertia-link-external-url` | ADD | Warn when `<Link>` is used with external URL (silent 409 from Inertia) |
| **NEW** `inertia-hardcoded-route` | ADD | When Wayfinder shipped, warn on hardcoded route strings instead of Wayfinder helpers |

### Slash Commands (3 → 3, all renamed)

| Source Command | Vue Path |
|---|---|
| `/laravel-livewire-superpowers:status` | `/laravel-vue-superpowers:status` |
| `/laravel-livewire-superpowers:audit-phase N` | `/laravel-vue-superpowers:audit-phase N` |
| `/laravel-livewire-superpowers:retro` | `/laravel-vue-superpowers:retro` |

### Pilot 2.0 Meta-Layer (1:1 carryover)

- `docs/pilot-2-0-contract.md` — unchanged (stack-agnostic contract)
- `laravel-pilot-orchestrator` agent — unchanged
- `pilot-2-contract-enforcer` hook — unchanged

## 5. Phased Plan (5 Phases)

Each phase ends with merged PR + tagged alpha + GitHub Pre-Release. Final stable cut in Phase E.

### Phase A — Identity Rename (~1-2h, target `v1.0.0-alpha.1`)

- `plugin.json`: name already `laravel-vue-superpowers`; bump version `0.1.0-cloned-from-livewire-v3.0.0` → `1.0.0-alpha.1`; description finalize for Vue stack
- All 3 slash commands: `/laravel-livewire-superpowers:*` → `/laravel-vue-superpowers:*`
- README full rewrite: Vue 3 + Inertia v3 + Reka UI + Tailwind 4 stack framing; install instructions point at new marketplace entry; drop WIP banner
- `docs/agents.md` + `docs/hooks.md` stack-scope banner update
- CLONE_FORK_STATUS.md → archive to `docs/ARCHIVE/CLONE_FORK_STATUS.md` (historical record of clone-source)
- CHANGELOG.md new file (or carry over with `[1.0.0-alpha.1]` section prepended above Livewire-variant CHANGELOG history if relevant — recommended: new CHANGELOG.md, since this is a fresh plugin identity)
- Update marketplace.json on `altraWeb/laravel-marketplace` to ADD Vue plugin entry (marketplace metadata.version 1.1.0 → 1.2.0)

### Phase B — Specialists + Anti-Pattern Hooks (~6-8h, target `v1.0.0-alpha.2`)

- REMOVE `agents/laravel-livewire-specialist.md`
- REPLACE `agents/laravel-flux-pro-specialist.md` → `agents/laravel-reka-ui-specialist.md` (rewrite content for Reka primitives + composable patterns + accessibility-by-default)
- ADD `agents/laravel-inertia-specialist.md` (Inertia v3 primary; v2 opt-in compat-mode; Wayfinder route helpers; useForm + Precognition; partial reloads; deferred props; modal stack; history encryption)
- ADD `agents/laravel-vue3-specialist.md` (Composition API + `<script setup>` + TS; reactive vs ref vs computed; props typing with `defineProps<T>()`; composables; listener cleanup with `onUnmounted`; reactive-object-destructure pitfalls)
- ADD 4 new hooks per Carryover-Matrix table (each with TDD test suite, registered under PreToolUse.Edit + PreToolUse.Write matchers)
- `hooks/hooks.json` extended
- `config.defaults.yaml` 4 new `hook_enabled.*` flags
- `tests/test_config.py` 4 new tests
- `docs/hooks.md` 4 new sections
- `docs/agents.md` 3 sections updated (remove livewire, replace flux→reka, add inertia + vue3)

### Phase C — Skill Sub-Section Swaps (~6-8h, target `v1.0.0-alpha.3`)

- `skills/laravel-a11y-specialist/SKILL.md`: 3 patterns rewrite (Inertia/Vue equivalents of wire:loading aria-busy; preserved patterns: reduced-motion query + audio-control); 4 patterns dropped (skip-link, modal focus management, form validation announcements, dropdown — all delegated to Reka UI primitives)
- `skills/laravel-code-review/SKILL.md`: §9 Livewire sub-checklist replaced with Inertia/Vue sub-checklist (defineProps TS, useForm patterns, partial reload misuse); §10 Flux Pro v2 sub-checklist replaced with Reka UI sub-checklist (primitive composition, slot patterns, accessibility audit)
- `skills/laravel-debugging/SKILL.md`: Top-10 RED items #3 (fabricated Livewire API like `$this->hasLoading()`) → Vue/Inertia equivalent (fabricated `useHttp()` method names, Inertia helper typos); item #8 (Livewire properties) → Vue 3 reactivity gotchas
- `skills/laravel-tdd/SKILL.md`: Pest-specifics items #3 (Livewire-specific test helpers) → Inertia testing helpers (`assertInertia`); item #8 (Volt/Livewire browser patterns) → Pest browser + Vue component testing patterns

### Phase D — Hook Repurpose (~2-3h, target `v1.0.0-alpha.4`)

- `git mv hooks/vendor-source-preflight.sh hooks/inertia-vendor-preflight.sh` + content rewrite (detect Reka UI imports + Inertia helpers in `.vue`/`.ts` edits, surface relevant `node_modules/reka-ui/dist/` + Inertia source paths)
- `git mv tests/test_vendor_source_preflight_hook.sh tests/test_inertia_vendor_preflight_hook.sh` + content rewrite
- `hooks/lang-key-existence-preflight.sh` broaden file-type filter: `.blade.php` → `.blade.php` OR `.vue` (Vue templates can call `__()` via translations exposed through Inertia shared props)
- Update tests for lang-key hook (+1 .vue test scenario)
- `hooks/hooks.json` rename hook reference
- `config.defaults.yaml` rename `vendor_source_preflight` → `inertia_vendor_preflight`
- `docs/hooks.md` rewrite the inertia-vendor-preflight section + extend lang-key-existence-preflight section with Vue note

### Phase E — Release Polish + v1.0.0 Stable Cut (~2-3h, target `v1.0.0`)

- Self-audit (analog Livewire v3.0.0 pattern → `docs/audits/2026-XX-XX-v1-stable-self-audit.md`)
- CHANGELOG consolidate `[1.0.0]` stable section above alpha entries
- ROADMAP for Vue variant initial state (V1 marked complete; future ideas section)
- `plugin.json` → `1.0.0` (drop alpha)
- README polish: Versions section, install commands, marketplace install verified
- `altraWeb/laravel-marketplace`: bump Vue plugin entry to `1.0.0`
- v1.0.0 git tag (NOT prerelease)
- GitHub Release stable
- Operator manual smoke-test install flow

**Total: 5 phases, ~18-22h, 4 alphas + 1 stable.**

## 6. Branch / Release Strategy

Mirror Livewire-variant pattern:
- Plan PRs: `docs/v1-phase-X-plan` → squash-merge to main
- Implementation PRs: `feat/v1-phase-X-<descriptor>` → squash-merge to main
- Per-phase: tag `v1.0.0-alpha.X` + GitHub Pre-Release (notes from CHANGELOG section)
- Final: tag `v1.0.0` (NOT prerelease)

## 7. Marketplace Strategy

`altraWeb/laravel-marketplace/.claude-plugin/marketplace.json` already lists `laravel-livewire-superpowers v3.0.0`. Phase A adds the Vue plugin as 2nd entry with `1.0.0-alpha.1`. Each subsequent Vue alpha bumps the entry. v1.0.0 final cut updates to `1.0.0`.

Marketplace `metadata.version`:
- Currently: `1.1.0` (after Livewire v3.0.0 stable bump)
- After Phase A: `1.2.0` (Vue plugin added)
- After Phase E (v1.0.0 stable): `1.3.0` (Vue plugin reaches stable)

## 8. Testing & Quality Gates

No new test infrastructure. Existing patterns extend:
- Shell hook test suites: 13 (Livewire baseline) → 17 (Phase B +4 anti-pattern hooks). Each new hook follows TDD (test first, RED → hook → GREEN).
- Python config tests: 33 → 37 (+4 for new hook_enabled flags, +1 for inertia_vendor_preflight rename verification).
- Marketplace JSON validation test: already exists from Livewire variant — no change.

Quality gates per phase-end cut:
- All shell hook tests green
- All Python tests green
- New agent/skill YAML frontmatter valid (analog Phase C/D verification from Livewire variant)
- PR opened with conventional commit message + Closes #N for any tracked issues

## 9. Migration & Backward Compatibility

No migration needed — fresh plugin, no V0 users exist. `CLONE_FORK_STATUS.md` archived to `docs/ARCHIVE/` in Phase A as historical clone-record (deletion would lose origin trace).

## 10. Open Questions / Deferred

- `laravel-wayfinder-specialist` agent: deferred. If Wayfinder coverage in `laravel-inertia-specialist` body proves insufficient post-v1.0.0, file follow-up issue for v1.1.0 RFC.
- 4 new anti-pattern hooks: confirmed for Phase B bundle. Each hook gets a test suite + config flag + docs entry (follows established V3 pattern).
- CLONE_FORK_STATUS.md disposition: archive to `docs/ARCHIVE/` (recommended) vs delete (loses traceability). Implementer can choose; light preference: archive.

## 11. Success Criteria / Definition of Done

V1.0.0 ships when ALL of the following are true:

1. Plugin installable: `claude /plugin install laravel-vue-superpowers@altraweb-laravel` succeeds in fresh Claude Code session
2. `/laravel-vue-superpowers:status` renders cleanly
3. All 4 phase alpha tags exist (v1.0.0-alpha.1 through .4) on GitHub
4. v1.0.0 final tag exists (not prerelease)
5. Self-audit doc committed
6. `altraWeb/laravel-marketplace` lists Vue plugin at `1.0.0`
7. Carryover matrix verified: 11 agents, 7 skills, 16 hooks, 3 commands present and frontmatter-valid
8. All 17 shell + 37 Python tests green
9. CHANGELOG has `## [1.0.0]` stable section
10. README polished, install instructions verified

## 12. References

- Source plugin: `altraWeb/laravel-livewire-superpowers@v3.0.0`
- Deep research audit: [`docs/superpowers/audits/2026-05-17-vue-fork-deep-research.md`](../audits/2026-05-17-vue-fork-deep-research.md)
- Clone fork status: [`CLONE_FORK_STATUS.md`](../../../CLONE_FORK_STATUS.md) (archived in Phase A)
- Agent-memory stack decisions: `~/.claude/agent-memory/laravel-superpowers-laravel-best-practices/project_vue_fork_stack_decisions.md`
- Agent-memory anti-pattern hooks: `~/.claude/agent-memory/laravel-superpowers-laravel-best-practices/project_vue_fork_anti_pattern_hooks.md`
