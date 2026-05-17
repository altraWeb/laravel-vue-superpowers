# laravel-vue-superpowers Roadmap

This roadmap tracks the V1.0.0 phased rollout — adaptation of the cloned-from-livewire repo into a functional Vue 3 + Inertia v3 + Reka UI + Tailwind 4 plugin.

> **Plugin extends [superpowers](https://github.com/anthropics/claude-plugins-official) with Laravel/Vue/Inertia/Reka/Pest expertise.**

## V1.0.0 (Vue Variant Megarelease) — COMPLETE

5 phases analog to the Livewire variant V3 rollout. Per deep-research (`docs/superpowers/audits/2026-05-17-vue-fork-deep-research.md`), ~75% of Livewire-variant content carries over 1:1 or with cosmetic sub-checklist swaps. All 5 phases shipped 2026-05-17.

### Phase A — Identity Rename (v1.0.0-alpha.1)

- [x] plugin.json + config paths + slash commands + README + banners renamed
- [x] CLONE_FORK_STATUS.md archived to docs/ARCHIVE/
- [x] Marketplace entry added (laravel-marketplace metadata.version 1.1.0 → 1.2.0)

### Phase B — Specialists + Anti-Pattern Hooks (v1.0.0-alpha.2)

- [x] REMOVE laravel-livewire-specialist
- [x] REPLACE laravel-flux-pro-specialist → laravel-reka-ui-specialist
- [x] ADD laravel-inertia-specialist (Inertia v3 primary, v2 compat-note)
- [x] ADD laravel-vue3-specialist (Composition API + script setup + TS)
- [x] ADD 4 new anti-pattern hooks (setInterval-cleanup, reactive-destructure, Link-external-URL, hardcoded-routes)

### Phase C — Skill Sub-Section Swaps (v1.0.0-alpha.3)

- [x] laravel-a11y-specialist: 3 patterns rewrite (4 dropped — Reka UI handles)
- [x] laravel-code-review: §9 swap (Inertia/Vue) + §10 swap (Reka UI)
- [x] laravel-debugging: Top-10 items #3 + #8 swap
- [x] laravel-tdd: Pest-specifics items #3 + #8 swap

### Phase D — Hook Repurpose (v1.0.0-alpha.4)

- [x] vendor-source-preflight RENAME + REWRITE → inertia-vendor-preflight
- [x] lang-key-existence-preflight broaden trigger to .vue files

### Phase E — Release Polish + Stable Cut (v1.0.0 STABLE)

- [x] Self-audit (docs/audits/2026-05-17-v1-stable-self-audit.md — 0 blockers)
- [x] CHANGELOG consolidate (## [1.0.0] above alphas)
- [x] v1.0.0 tag (stable, not prerelease)
- [x] Marketplace bumps to 1.0.0

---

## What's next (post-V1)

- `laravel-wayfinder-specialist` agent (deferred from V1)
- `laravel-pinia-specialist` (if Pinia adoption grows)
- `laravel-ssr-specialist` (if SSR adoption decided)
- shadcn-vue opt-in skills/presets if adoption grows

Last updated: 2026-05-17
