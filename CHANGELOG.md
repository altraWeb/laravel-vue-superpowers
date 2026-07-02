# Changelog

All notable changes to `laravel-vue-superpowers` are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

This plugin was cloned from [`altraWeb/laravel-livewire-superpowers@v3.0.0`](https://github.com/altraWeb/laravel-livewire-superpowers/releases/tag/v3.0.0) on 2026-05-17. The pre-clone CHANGELOG is preserved at [`docs/ARCHIVE/CHANGELOG-from-livewire-source.md`](docs/ARCHIVE/CHANGELOG-from-livewire-source.md) for origin trace.

## [2.0.0] — 2026-07-02 — Prune the Pilot 2.0 layer + vendor-source verification everywhere

Major rework (issue #12). Prunes the stale Pilot 2.0 meta-layer, makes the
vendor-source-verification pattern universal across specialists, adds a
Scout/Meilisearch specialist, and sharpens every agent's trigger to concrete
file paths/symbols.

### Removed (BREAKING)

- **Agents:** `laravel-pilot-orchestrator` (referenced Pilot 2.0 Tactic Tracking
  sections that no longer exist in current plan docs) and `laravel-reviewer`
  (collided with the orchestrator-reviews-itself process; multi-component review
  is the orchestrator's job, not a delegated agent).
- **Hooks:** `pilot-2-contract-enforcer`, `brainstorm-t1-audit`, and
  `sprint-state-context-injection` (+ their test suites and hooks.json entries).
- **Docs:** `docs/pilot-2-0-contract.md` (the canonical T1-T6 contract).
- **Slash commands:** `/audit-phase` and `/retro` (both wholly Pilot-2.0-specific
  — a T1-audit dispatcher and a Pilot-2.0-contract-compliance report).
- **Config keys:** `pilot_version`, `audit_aggressiveness`, `tier_preference`, and
  the `hook_enabled` flags for the three removed hooks — dropped from
  `config.defaults.yaml` and `config.schema.json`.
- **Banned-token guard:** dropped the now-dead `Pilot 2\.0` default pattern.

### Added

- **`agents/laravel-scout-meilisearch-specialist.md`** — audits the search-index
  gate for the highest-cost Scout bugs: `shouldBeSearchable()` guard-blindness (a
  `runningUnitTests()` short-circuit that leaves the real gate untested in-suite,
  silently skipped by `--covered-only` mutation), gate-parity across Searchable
  models (a real production catch: an opt-out kept a user's albums out of search
  but not their own handle document), index-time-vs-query-time gate separation
  (CollectionEngine tests never route through the gate), Meilisearch
  filterable/sortable settings, and post-deploy `scout:import` hygiene. Verifies
  against `vendor/laravel/scout/src/` + `config/scout.php`.

### Changed

- **Vendor-source verification is now universal.** The pattern that is the
  plugin's proven differentiator — verify APIs by reading the installed `vendor/`
  or `node_modules/` source rather than trusting docs or training data (it caught
  a vacuous variadic `->not->toContain($a, $b)` assertion in production by
  reflecting on `vendor/pestphp` instead of the docs) — was rolled into the five
  specialists that lacked it: `laravel-best-practices` (cross-check against the
  installed source before recommending), `laravel-echo-reverb-specialist`
  (`vendor/laravel/reverb` + `node_modules/laravel-echo` + `node_modules/pusher-js`),
  `laravel-reka-ui-specialist` and `laravel-vue3-specialist` (strengthened to the
  canonical form), and `spatie-permission-auditor`
  (`vendor/spatie/laravel-permission/src`).
- **Trigger sharpening across all 10 agents** — descriptions now name concrete
  file paths and symbols instead of bare topics (mirroring
  `laravel-pest-specialist`): architect, echo-reverb, spatie-permission-auditor,
  and vue3 were tightened; pest, reka-ui, inertia, best-practices, and
  package-evaluator were already sharp.
- **Drift cleanup** — removed carryover Livewire/Flux references (pointing at
  non-existent `laravel-livewire-specialist` / `laravel-flux-pro-specialist`)
  from `laravel-architect`, `spatie-permission-auditor`, the `laravel-debugging`
  and `laravel-perf-auditor` skills. Legitimate sibling-plugin pointers to
  `laravel-livewire-superpowers` and version history are retained.
- **`/status` command** retained but stripped of Pilot 2.0 obligations and its
  stale specialist roster; now reports branch/plan state, hook compliance, open
  deferred obligations, and the current 10-agent roster.
- **`laravel-mr-body-writer` skill** — dropped the Pilot 2.0 contract section
  from the canonical MR shape.
- **Config tests** re-anchored on surviving keys (`visual_companion_default`,
  `teamcity_always`) after the Pilot keys were removed.
- **Docs** — `docs/agents.md` gains the Scout specialist section + a
  "When to route to which specialist" mapping; `docs/hooks.md` and
  `docs/config.md` scrubbed of the removed hooks/keys.
- **Manifest** — `.claude-plugin/plugin.json` version → `2.0.0`; description
  rewritten (10 agents / 7 skills / 13 hooks / 1 slash command; dropped the
  "Full Pilot 2.0 contract enforcement" claim and the `pilot-2.0` keyword).

### Migration

Projects that set `pilot_version`, `audit_aggressiveness`, or `tier_preference`
in a `.laravel-vue-superpowers.yaml` or user config must remove those keys — the
schema now rejects unknown top-level keys. The three removed hooks no longer fire;
delete any `hook_enabled` overrides for them. No data migration required.

---

## [1.0.0] — 2026-05-17 — V1 Stable

First stable release of the Vue 3 + Inertia v3 + Reka UI + Tailwind CSS 4 + Pest 4 Laravel specialist plugin. Consolidates 4 phased alpha releases (alpha.1 through alpha.4) into v1.0.0.

### Summary

V1.0.0 ships:
- **11 specialist agents** — laravel-best-practices, laravel-pest-specialist, laravel-architect, laravel-reviewer, laravel-echo-reverb-specialist, spatie-permission-auditor, laravel-package-evaluator, laravel-pilot-orchestrator (stack-agnostic carryover) + laravel-reka-ui-specialist, laravel-inertia-specialist, laravel-vue3-specialist (new Vue-stack-specific)
- **7 skills** — laravel-brainstorming, laravel-tdd, laravel-debugging, laravel-code-review, laravel-a11y-specialist (3 patterns + Reka-handles section), laravel-mr-body-writer, laravel-perf-auditor
- **16 hooks** — 11 stack-agnostic (banned-token / no-Claude-attribution / teamcity / anti-silent-deferral / visual-companion / brainstorm-T1 / sprint-state / stale-branch / master-roadmap-drift / pilot-2-contract-enforcer / lang-key-existence-preflight broadened to .vue) + 1 repurposed (inertia-vendor-preflight) + 4 Vue/Inertia anti-pattern (vue-setinterval-cleanup / vue-reactive-destructure / inertia-link-external-url / inertia-hardcoded-route)
- **3 slash commands** — `/status`, `/audit-phase N`, `/retro`
- **Full Pilot 2.0 contract** (T1-T6) with canonical reference doc + meta-orchestrator agent + continuous enforcer hook

### Phase rollup

- **Phase A** (foundation) — identity rename + Vue-named config paths + slash commands + README + docs + archives
- **Phase B** (specialists + hooks) — REMOVE livewire, REPLACE flux→reka, ADD inertia + vue3 specialists + 4 anti-pattern hooks
- **Phase C** (skill swaps) — a11y 7→3 patterns, code-review §9-10 swap, debugging #3+#8, tdd #3+#8
- **Phase D** (hook repurpose) — vendor-source-preflight → inertia-vendor-preflight, lang-key-existence-preflight broadened to .vue

### Stack pinned

Laravel 12/13, PHP 8.2+, Inertia v3 (v2 opt-in compat), Vue 3 + Composition API + `<script setup>` + TypeScript (Options API hard-banned), Vite 6/7, Tailwind CSS 4, Reka UI ^2.6.1, Wayfinder v1, spatie/laravel-data + spatie/laravel-typescript-transformer, Pest 4 + Browser plugin (Playwright), composables-first state (Pinia opt-in), Reverb, useForm + Precognition.

### Origin

Cloned from `altraWeb/laravel-livewire-superpowers@v3.0.0` on 2026-05-17 (origin record: `docs/ARCHIVE/CLONE_FORK_STATUS.md`). Adaptation effort: ~18-22h across 4 phased alphas.

### Self-audit

Full audit: [`docs/audits/2026-05-17-v1-stable-self-audit.md`](docs/audits/2026-05-17-v1-stable-self-audit.md) — 0 blockers / 0 should-fix / 0 nice-to-have. All 17 shell + 37 Python tests green.

### What's next

- Wayfinder-dedicated specialist (deferred from V1, defer to v1.1.0 RFC)
- Inertia v3 specifics that may evolve as the ecosystem matures
- Pinia / SSR / shadcn-vue opt-in skills/presets if adoption grows

---

## [1.0.0-alpha.4] — 2026-05-17 — Phase D: Hook Repurpose

Phase D repurposes the inherited `vendor-source-preflight` hook for Reka UI + Inertia detection (was: Flux Pro v2 + Livewire) and broadens `lang-key-existence-preflight` to also fire on `.vue` files.

### Changed

- `hooks/vendor-source-preflight.sh` → `hooks/inertia-vendor-preflight.sh` (`git mv` + full rewrite). Now detects Reka UI imports + Inertia helpers (useForm, usePage, router, <Link>) in `.vue` file Edit/Write, surfaces `node_modules/reka-ui/dist/`, `node_modules/@inertiajs/vue3/dist/`, and `vendor/inertiajs/inertia-laravel/src/` as canonical source references.
- `hooks/lang-key-existence-preflight.sh` — file-type filter broadened from `*.blade.php` only to `*.blade.php` OR `*.vue`. Vue templates can call `__()` via Inertia shared translation props.
- `tests/test_vendor_source_preflight_hook.sh` → `tests/test_inertia_vendor_preflight_hook.sh` (renamed + 5 scenarios rewritten for Reka/Inertia detection).
- `tests/test_lang_key_existence_preflight_hook.sh` — 1 new scenario for `.vue` file.
- `hooks/hooks.json` — hook reference renamed (2 occurrences: PreToolUse.Edit + PreToolUse.Write).
- `config.defaults.yaml` — `hook_enabled.vendor_source_preflight` → `hook_enabled.inertia_vendor_preflight` (default true).
- `tests/test_config.py` — test renamed to match.
- `docs/hooks.md` — section heading + body rewritten; lang-key section extended with `.vue` note.
- `README.md` — hook listing updated.
- `.claude-plugin/plugin.json` — version 1.0.0-alpha.3 → 1.0.0-alpha.4.

### Phase Status

Phase D (this alpha) — ✅ shipped 2026-05-17 as v1.0.0-alpha.4.

Phase E remains (release polish + v1.0.0 stable cut).

---

## [1.0.0-alpha.3] — 2026-05-17 — Phase C: Skill Sub-Section Swaps

Phase C swaps the Livewire-flavored sub-sections inside 4 skills with Vue 3 + Inertia v3 + Reka UI equivalents.

### Changed

- `skills/laravel-a11y-specialist/SKILL.md` — rewrote from 7 patterns to 3 (manual): live region for async ops + reduced-motion + audio control. Added "What Reka UI handles" section listing 4 patterns delegated to Reka primitives (modal focus / dropdown keyboard nav / form validation announcements / skip-link).
- `skills/laravel-code-review/SKILL.md` — §9 Livewire sub-checklist → Inertia + Vue 3 sub-checklist (Inertia::share, useForm, Link, usePoll, Wayfinder routes, listener cleanup); §10 Flux Pro v2 sub-checklist → Reka UI sub-checklist (Root/Trigger/Content composition, controlled/uncontrolled, data-[state=*] modifiers, asChild correctness, Portal usage).
- `skills/laravel-debugging/SKILL.md` — Top-10 item #3 swap: fabricated Livewire `$this->hasLoading()` → fabricated Inertia `useHttp().fetchAll()` / Vue Composition API typos. Item #8 swap: Livewire properties → Vue 3 reactivity gotchas (reactive destructure, refs in arrays, Maps/Sets).
- `skills/laravel-tdd/SKILL.md` — Pest-specifics item #3 swap: Livewire test helpers → Inertia `assertInertia` + chainable matchers. Item #8 swap: Volt/Livewire browser patterns → Pest 4 browser plugin + Vue component testing.
- `README.md` — removed "(adaption in Phase C)" parenthetical from a11y-specialist entry.
- `.claude-plugin/plugin.json` — version 1.0.0-alpha.2 → 1.0.0-alpha.3.

### Phase Status

Phase C (this alpha) — ✅ shipped 2026-05-17 as v1.0.0-alpha.3.

Phases D-E remain.

---

## [1.0.0-alpha.2] — 2026-05-17 — Phase B: Specialists + Anti-Pattern Hooks

Phase B swaps the frontend-stack-specific specialists and adds 4 anti-pattern hooks for Vue 3 + Inertia patterns.

### Added

- `agents/laravel-reka-ui-specialist.md` — Reka UI primitives specialist (replaces flux-pro-specialist; UI-specialist slot reused)
- `agents/laravel-inertia-specialist.md` — Inertia v3 patterns specialist (v2 opt-in compat-note); covers useForm + Precognition + usePage + partial reloads + deferred props + history encryption + polling + modal stack
- `agents/laravel-vue3-specialist.md` — Vue 3 Composition API + `<script setup>` + TS specialist; covers ref/reactive/computed, defineProps TS generics, composable design, lifecycle cleanup, reactive-destructure pitfalls
- `hooks/vue-setinterval-cleanup.sh` — PreToolUse on .vue Edit/Write; warns when setInterval lacks onUnmounted cleanup
- `hooks/vue-reactive-destructure.sh` — PreToolUse on .vue Edit/Write; warns on `const { ... } = reactive(...)` destructure (loses reactivity)
- `hooks/inertia-link-external-url.sh` — PreToolUse on .vue Edit/Write; warns when `<Link>` used with external URL (silent 409)
- `hooks/inertia-hardcoded-route.sh` — PreToolUse on .vue/.ts Edit/Write; warns on hardcoded route strings when Wayfinder shipped
- 4 new shell hook test suites
- 4 new Python config tests

### Changed

- `hooks/hooks.json` — 4 new hooks registered under PreToolUse.Edit + PreToolUse.Write
- `config.defaults.yaml` — 4 new `hook_enabled.*` flags (default true)
- `docs/agents.md` — section structure: REMOVE livewire, REPLACE flux-pro with reka-ui, ADD inertia + vue3
- `docs/hooks.md` — 4 new sections
- `README.md` — agent count 10 → 11; hook count 12 → 16; specialist listings updated
- `.claude-plugin/plugin.json` — version 1.0.0-alpha.1 → 1.0.0-alpha.2; description current-state counts updated

### Removed

- `agents/laravel-livewire-specialist.md` (Livewire-stack-specific, not part of Vue variant)
- `agents/laravel-flux-pro-specialist.md` (replaced with laravel-reka-ui-specialist)

### Phase Status

Phase B (this alpha) — ✅ shipped 2026-05-17 as v1.0.0-alpha.2.

Phases C-E remain.

---

## [1.0.0-alpha.1] — 2026-05-17 — Phase A: Identity Rename

First alpha of the Vue fork. Phase A establishes the foundation: plugin renamed `laravel-livewire-superpowers` (cloned identity) → `laravel-vue-superpowers`, all internal references updated, config paths use Vue-named locations, slash commands renamed, README + docs/banners rebranded for Vue 3 + Inertia v3 + Reka UI + Tailwind 4 + Pest 4 stack.

**Important: No content adaptation yet.** Agents, skills, and hooks still ship the Livewire-variant content from source. They are non-functional for Vue/Inertia workloads until Phase B-D adapt them. v1.0.0-alpha.1 is installable but not yet useful as a Vue specialist toolkit.

### Changed

- Plugin identity: `laravel-livewire-superpowers` → `laravel-vue-superpowers` (`plugin.json`)
- Plugin version: `0.1.0-cloned-from-livewire-v3.0.0` → `1.0.0-alpha.1`
- Config user-global path: `~/.claude/plugins/altraweb-laravel/laravel-superpowers/config.yaml` → `~/.claude/plugins/altraweb-laravel/laravel-vue-superpowers/config.yaml`
- Config project-local filename: `.laravel-superpowers.yaml` → `.laravel-vue-superpowers.yaml`
- Slash commands: `/laravel-livewire-superpowers:*` → `/laravel-vue-superpowers:*` (status + audit-phase + retro)
- README full rewrite for Vue stack
- `docs/agents.md` + `docs/hooks.md` stack-scope banners updated
- `docs/config.md` + `docs/pilot-2-0-contract.md` plugin-name references updated
- `docs/ROADMAP.md` rewritten for V1 Vue rollout
- 4 hook error messages reference new config filename
- `config.defaults.yaml` header + path references updated
- `config.schema.json` `$id` + `title` updated
- `skills/laravel-mr-body-writer/SKILL.md` slash command references updated
- `hooks/sprint-state-context-injection.sh` internal slash command reference updated

### Added

- New CHANGELOG.md (this file) for Vue-variant version history
- `docs/ARCHIVE/CHANGELOG-from-livewire-source.md` (pre-clone CHANGELOG preserved)
- `docs/ARCHIVE/CLONE_FORK_STATUS.md` (clone-record archived from repo root)
- Vue plugin entry in `altraWeb/laravel-marketplace` marketplace.json

### Removed

- `CLONE_FORK_STATUS.md` from repo root (archived to docs/ARCHIVE/)
- `UPGRADING.md` (was Livewire-V2→V3 migration; not applicable to Vue fork)

### Migration

None — fresh plugin. No V0 users exist.

### Phase Status

Phase A (this alpha) — shipped 2026-05-17 as v1.0.0-alpha.1.

Phases B-E remain.

---
