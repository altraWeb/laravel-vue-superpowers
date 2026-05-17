# laravel-livewire-superpowers Roadmap

> **Plugin extends [superpowers](https://github.com/anthropics/claude-plugins-official) with Laravel/Livewire/Flux/Pest expertise.**
>
> Status snapshots derived from labeled GitHub issues — see [Project board](https://github.com/altraWeb/laravel-livewire-superpowers/projects) for live status, [Milestones](https://github.com/altraWeb/laravel-livewire-superpowers/milestones) for version grouping.

This roadmap captures planned additions evidence-based from observed real-world sprint catches. Every entry links to a tracked GitHub issue with motivation, scope, and acceptance criteria.

## How V2 came to be

V1 of `laravel-superpowers` shipped 1 agent (`laravel-best-practices`) + 4 skills (`laravel-brainstorming`, `laravel-tdd`, `laravel-debugging`, `laravel-code-review`). Adequate for "ship working code".

V2 was driven by an observed gap: when operators run the plugin against real multi-phase Laravel sprints (Livewire 4 + Flux Pro v2 + Pest 4 stack), V1 catches generic anti-patterns but misses stack-specific stolperer that ship as production bugs. A test sprint (Block 1H Editor AI-Toolbar, 2026-05-14, 22 commits) running V1 + a manual Pilot 2.0 workflow contract surfaced **4 P0 bugs at audit-time** that V1 alone would have missed:

1. **Fabricated `$this->hasLoading()` Livewire API** — would have shipped a `BadMethodCallException` on first dropdown click in production
2. **`Bus::fake()` wrong mock layer** for synchronous `AiAgentRunner::*` static calls — test would have fired real Anthropic with blanked phpunit key → 401 → RED
3. **`view()->with(['this' => new class{}])`** anti-pattern — `$this` is reserved by PHP/Blade
4. **Redundant `<flux:tooltip>` outer wrapper** — would have broken `<ui-toolbar>` roving-tabindex (silent a11y regression)

V2 builds the agents + skills + hooks that catch these classes of bugs **by construction**, not by discipline.

---

## V2-MVP — Tier-1 (highest-ROI, observed-sprint catches) — ✅ COMPLETE (v2.0.0)

**Status:** All 16 V2-MVP issues shipped and released as `v2.0.0` on 2026-05-15. The 4 P0-class catches the test sprints surfaced are now caught **by construction** via the specialist-agent quintet + 6 hooks + 3 enhanced skills + plugin config foundation + status slash command.

**Goal (achieved):** ship the bug-catchers that the Block 1H + 1E sprints needed but didn't have. 1-week build, completed on schedule.

### New agents

- [x] **[#1](https://github.com/altraWeb/laravel-livewire-superpowers/issues/1) `laravel-livewire-specialist`** — deep Livewire 4 API + lifecycle knowledge. API-existence verification via reflection (catches fabricated `$this->hasLoading()` class of bug).
- [x] **[#2](https://github.com/altraWeb/laravel-livewire-superpowers/issues/2) `laravel-pest-specialist`** — Pest 4 API depth + browser-plugin recipes. Catches `toContain` variadic, `wait(N)` smell, `$this`-mock-in-view anti-pattern.
- [x] **[#3](https://github.com/altraWeb/laravel-livewire-superpowers/issues/3) `laravel-flux-pro-specialist`** — Flux Pro v2 vendor source traversal + slot composition. Catches redundant tooltip wrappers, position+align convention drift.
- [x] **[#4](https://github.com/altraWeb/laravel-livewire-superpowers/issues/4) `laravel-architect`** — Eloquent + architecture decisions (N+1, eager-loading, Actions vs Services, migration safety).
- [x] **[#5](https://github.com/altraWeb/laravel-livewire-superpowers/issues/5) `laravel-reviewer`** — wraps `laravel-code-review` skill with grep/find/MCP tool integration.

### Skill enhancements

- [x] **[#13](https://github.com/altraWeb/laravel-livewire-superpowers/issues/13) Enhance `laravel-tdd`** — Pest 4 specifics (because modifier, datasets, it vs arch, assertAttribute)
- [x] **[#14](https://github.com/altraWeb/laravel-livewire-superpowers/issues/14) Enhance `laravel-code-review`** — Livewire 4 + Flux Pro v2 sub-checklists
- [x] **[#15](https://github.com/altraWeb/laravel-livewire-superpowers/issues/15) Enhance `laravel-debugging`** — top-10 Pest 4 RED-debugging recipes

### Hooks

- [x] **[#16](https://github.com/altraWeb/laravel-livewire-superpowers/issues/16) Banned-token-leak guard** — PreToolUse on git commit
- [x] **[#17](https://github.com/altraWeb/laravel-livewire-superpowers/issues/17) No-Claude-attribution** — PreToolUse on git commit + MR create
- [x] **[#18](https://github.com/altraWeb/laravel-livewire-superpowers/issues/18) `--teamcity` always** — PreToolUse on `php artisan test`
- [x] **[#19](https://github.com/altraWeb/laravel-livewire-superpowers/issues/19) Anti-silent-deferral pre-push** — PreToolUse on git push
- [x] **[#20](https://github.com/altraWeb/laravel-livewire-superpowers/issues/20) Brainstorm-time T1 audit auto-dispatch** — PostToolUse on `superpowers:brainstorming`
- [x] **[#21](https://github.com/altraWeb/laravel-livewire-superpowers/issues/21) Visual-companion-default-on** — PostToolUse brainstorming Step 2

### Plugin infrastructure

- [x] **[#22](https://github.com/altraWeb/laravel-livewire-superpowers/issues/22) Plugin config foundation** — config.yaml with sane defaults + project-override
- [x] **[#23](https://github.com/altraWeb/laravel-livewire-superpowers/issues/23) Slash command `/laravel-livewire-superpowers:status`** — current sprint + Pilot 2.0 obligations

**V2-MVP total**: 16 issues

---

## ~~V2.1~~ — Absorbed into V3 Megarelease — ✅ COMPLETE (v3.0.0)

**Goal (achieved):** round out V2-MVP with next-most-valuable additions. All 7 issues shipped in V3.

### Agents + skills

- [x] **[#6](https://github.com/altraWeb/laravel-livewire-superpowers/issues/6) `laravel-a11y-specialist` skill** — WCAG 2.2 + ARIA + reduced-motion patterns — PR #58
- [x] **[#7](https://github.com/altraWeb/laravel-livewire-superpowers/issues/7) `laravel-echo-reverb-specialist` agent** — broadcasting + realtime decision support — PR #56
- [x] **[#8](https://github.com/altraWeb/laravel-livewire-superpowers/issues/8) `laravel-mr-body-writer` skill** — canonical MR body from sprint state — PR #58

### Hooks + slash commands

- [x] **[#24](https://github.com/altraWeb/laravel-livewire-superpowers/issues/24) Sprint-state context-injection** — SessionStart auto-resume — PR #54
- [x] **[#25](https://github.com/altraWeb/laravel-livewire-superpowers/issues/25) Master-roadmap drift detector** — PostToolUse on docs/plans commits — PR #54
- [x] **[#26](https://github.com/altraWeb/laravel-livewire-superpowers/issues/26) Stale-branch sweep** — SessionStart cleanup — PR #54
- [x] **[#27](https://github.com/altraWeb/laravel-livewire-superpowers/issues/27) Slash commands `/audit-phase N` + `/retro`** — expand command suite — PR #60

**V2.1 total**: 7 issues — all shipped

---

## ~~V2.2~~ — Absorbed into V3 Megarelease — ✅ COMPLETE (v3.0.0)

**Goal (achieved):** extensions that activate when the first project hits the relevant use case. All 5 issues shipped in V3.

### Agents + skills

- [x] **[#9](https://github.com/altraWeb/laravel-livewire-superpowers/issues/9) `spatie-permission-auditor` agent** — gate coverage + dead-permission detection — PR #56
- [x] **[#11](https://github.com/altraWeb/laravel-livewire-superpowers/issues/11) `laravel-perf-auditor` skill** — preventLazyLoading + query-count + cache patterns — PR #58
- [x] **[#12](https://github.com/altraWeb/laravel-livewire-superpowers/issues/12) `laravel-package-evaluator` agent** — build-vs-buy decision support — PR #56

### Hooks

- [x] **[#28](https://github.com/altraWeb/laravel-livewire-superpowers/issues/28) Vendor-source pre-flight** — PreToolUse on Flux/Livewire blade edits — PR #62
- [x] **[#29](https://github.com/altraWeb/laravel-livewire-superpowers/issues/29) Lang-key existence pre-flight** — PreToolUse on blade edits with `__()` calls — PR #62

**V2.2 total**: 5 issues — all shipped

---

## V3 — V3 Megarelease — ✅ COMPLETE (v3.0.0 — 2026-05-17)

**Status:** All 14 V3 backlog issues shipped across 6 phased alpha releases (alpha.1 through alpha.6). Declared stable as v3.0.0 on 2026-05-17. Full self-audit at `docs/audits/2026-05-17-v3-megarelease-self-audit.md` — no blockers.

**Goal (achieved):** workflow enforcement at the orchestrator level + 10 specialist agents + 7 skills + 12 hooks + 3 slash commands + full Pilot 2.0 contract formalization + neutral marketplace.

### Meta agents + hooks (Phase E)

- [x] **[#10](https://github.com/altraWeb/laravel-livewire-superpowers/issues/10) `laravel-pilot-orchestrator` agent** — Pilot 2.0 contract enforcer (on-demand) — PR #60
- [x] **[#30](https://github.com/altraWeb/laravel-livewire-superpowers/issues/30) Pilot 2.0 contract enforcer hook** — meta hook reading plan-doc Tactic markers (continuous) — PR #60

**V3 total**: 14 issues — all shipped

---

## What's next

- **`laravel-vue-superpowers`** — sibling plugin for Vue 3 + Inertia v2 + Pest 4 stack. Gets its own brainstorming session before design begins. Issue tracking TBD.
- Quality-of-life iterations on V3 components (operator-driven, filed as new issues).

---

## Contributing

Issues with the `good first issue` label (none yet — coming as V2-MVP design crystallizes) are good entry points.

For new proposals, please use the issue templates:
- [Agent template](.github/ISSUE_TEMPLATE/agent.yml)
- [Skill template](.github/ISSUE_TEMPLATE/skill.yml)
- [Hook / infra template](.github/ISSUE_TEMPLATE/hook.yml)

Each template ensures the proposal includes: **observed-sprint motivation** + **concrete scope** + **measurable acceptance criteria** + **tier** + **related references**.

---

## Stack assumptions

The plugin is opinionated about the Laravel ecosystem stack it targets:

- **Laravel 13** (current at plugin creation)
- **Livewire 4** + **FluxUI Pro v2** (the canonical full-stack Livewire combination)
- **Pest 4** (with browser plugin — Browser tests are first-class)
- **PHP 8.5** (using typed class constants, readonly properties, asymmetric visibility where appropriate)
- **Spatie Permission 7** for roles + permissions
- **Laravel Reverb v1** + **Echo v2** for real-time broadcasting

Projects on older Laravel + Livewire versions can still benefit from the generic skills (`laravel-brainstorming`, `laravel-tdd`, `laravel-code-review`, `laravel-debugging`) but the V2-MVP agents lean on Livewire 4 / Flux Pro v2 / Pest 4 API knowledge specifically.

---

*Last updated: 2026-05-17 — V3 Megarelease shipped as v3.0.0 (14/14 V3 issues, 30/30 total V2+V3 issues). V3 COMPLETE. Next: laravel-vue-superpowers brainstorming.*
