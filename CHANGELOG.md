# Changelog

All notable changes to `laravel-vue-superpowers` are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

This plugin was cloned from [`altraWeb/laravel-livewire-superpowers@v3.0.0`](https://github.com/altraWeb/laravel-livewire-superpowers/releases/tag/v3.0.0) on 2026-05-17. The pre-clone CHANGELOG is preserved at [`docs/ARCHIVE/CHANGELOG-from-livewire-source.md`](docs/ARCHIVE/CHANGELOG-from-livewire-source.md) for origin trace.

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
