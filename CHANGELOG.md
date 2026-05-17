# Changelog

All notable changes to `laravel-vue-superpowers` are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

This plugin was cloned from [`altraWeb/laravel-livewire-superpowers@v3.0.0`](https://github.com/altraWeb/laravel-livewire-superpowers/releases/tag/v3.0.0) on 2026-05-17. The pre-clone CHANGELOG is preserved at [`docs/ARCHIVE/CHANGELOG-from-livewire-source.md`](docs/ARCHIVE/CHANGELOG-from-livewire-source.md) for origin trace.

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
