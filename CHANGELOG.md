# Changelog

All notable changes to `laravel-livewire-superpowers` (renamed from `laravel-superpowers` in V3) are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.0.0] — 2026-05-17 — V3 Megarelease — Stable

The V3 Megarelease consolidates 6 phased alpha releases (alpha.1 through alpha.6) into a single stable cut. The plugin transitions from `laravel-superpowers` (V2) to `laravel-livewire-superpowers` (V3), with a sibling `laravel-vue-superpowers` planned next.

### Summary

V3 ships:
- **10 specialist agents** — Livewire / Pest / Flux Pro / architect / reviewer / best-practices / echo-reverb / spatie-permission / package-evaluator / pilot-orchestrator
- **7 stack-enhanced skills** — TDD / debugging / code-review / brainstorming / a11y / mr-body-writer / perf-auditor
- **12 enforcement & context-injection hooks** — banned-token-leak-guard / no-Claude-attribution / teamcity-always / anti-silent-deferral / visual-companion-default-on / brainstorm-T1-audit / sprint-state-context-injection / stale-branch-sweep / master-roadmap-drift-detector / pilot-2-contract-enforcer / vendor-source-preflight / lang-key-existence-preflight
- **3 slash commands** — `/status`, `/audit-phase N`, `/retro`
- **Full Pilot 2.0 contract** formalization with canonical reference doc + meta-orchestrator agent + continuous enforcer hook + plan-doc Tactic-marker convention
- **Neutral marketplace** at `altraWeb/laravel-marketplace` (no longer bundled in plugin repo)

### Phase rollup

- **Phase A** (foundation): plugin renamed laravel-superpowers → laravel-livewire-superpowers, marketplace moved to neutral host repo, UPGRADING.md, 18 stale branches cleaned
- **Phase B** (quickwin hooks, 3 hooks): SessionStart sprint-state + stale-branch + PostToolUse drift-detector
- **Phase C** (specialist agents, 3 agents): echo-reverb-specialist + spatie-permission-auditor + package-evaluator
- **Phase D** (skills, 3 skills): a11y-specialist + mr-body-writer + perf-auditor
- **Phase E** (Pilot 2.0 meta-layer): orchestrator agent + enforcer hook + 2 slash commands + contract reference doc
- **Phase F** (advanced blade hooks, 2 hooks): vendor-source-preflight + lang-key-existence-preflight

### Migration

V2 users follow `UPGRADING.md` (4-command flow: uninstall old, swap marketplace, install renamed plugin).

### Self-audit

Full audit: `docs/audits/2026-05-17-v3-megarelease-self-audit.md` (no blockers; 0 should-fix / 2 nice-to-have items addressed inline).

### What's next

- `laravel-vue-superpowers` sibling plugin — Vue 3 + Inertia v2 variant — planned, gets its own brainstorming session
- Quality-of-life iterations on V3 components (operator-driven)

---

## [3.0.0-alpha.6] — 2026-05-17 — V3 Megarelease — Phase F: Advanced Blade-Edit Hooks

Phase F ships two PreToolUse hooks that fire on `Edit`/`Write` of `.blade.php` files, injecting context at edit-time rather than commit-time. Non-blocking — advisory only.

### Added

- **[#28](https://github.com/altraWeb/laravel-livewire-superpowers/issues/28) `vendor-source-preflight` hook.** PreToolUse:Edit + PreToolUse:Write hook. When a `.blade.php` file is edited/written with `<flux:*>` or `wire:*` directives, surfaces relevant Flux Pro v2 stub paths (`vendor/livewire/flux-pro/stubs/resources/views/flux/`) and Livewire source paths (`vendor/livewire/livewire/src/Component.php` + `src/Features/`) as `additionalContext`. Catches the Block-1H bug class where an agent composes from memory and gets the API slightly wrong.
- **[#29](https://github.com/altraWeb/laravel-livewire-superpowers/issues/29) `lang-key-existence-preflight` hook.** PreToolUse:Edit + PreToolUse:Write hook. When a `.blade.php` file is edited/written with `__()` or `@lang()` calls, extracts each key reference, resolves the project `lang/` directory by walking up from the blade file, and warns about missing keys. Prevents missing-translation-key bugs (raw key string rendered at runtime) from reaching save.

### Changed

- `hooks/hooks.json` — two new `PreToolUse` matcher blocks added: `Edit` and `Write`, each registering both new hooks. Now 3 PreToolUse matcher blocks (Bash + Edit + Write).
- `config.defaults.yaml` — two new flags: `hook_enabled.vendor_source_preflight: true`, `hook_enabled.lang_key_existence_preflight: true`.
- `tests/test_config.py` — 2 new tests: `test_get_vendor_source_preflight_default`, `test_get_lang_key_existence_preflight_default` (33 tests total, up from 31).
- `docs/hooks.md` — two new reference sections: `vendor-source-preflight`, `lang-key-existence-preflight`. Phase status updated to Phase F.
- `README.md` — hook count `10 → 12`, versions section updated with alpha.6 entry.
- `.claude-plugin/plugin.json` version `3.0.0-alpha.5` → `3.0.0-alpha.6`. Hook count `10 → 12`.

### Phase Status

Phase F (this alpha) — shipped 2026-05-17 as v3.0.0-alpha.6.

Phase G remains.

---

## [3.0.0-alpha.5] — 2026-05-17 — V3 Megarelease — Phase E: Pilot 2.0 Meta-Layer

Phase E formalizes the Pilot 2.0 contract from convention to automation. Ships the meta-orchestrator agent + continuous enforcer hook + two new slash commands + canonical contract reference doc.

### Added

- **[#10](https://github.com/altraWeb/laravel-livewire-superpowers/issues/10) `laravel-pilot-orchestrator` agent.** On-demand Pilot 2.0 contract orchestrator. Reads the active plan-doc's Tactic Tracking sections + git log + audit history, emits a structured per-phase T1/T2/T3/T4 compliance matrix, and optionally dispatches missing specialists (`laravel-reviewer` for T3, `laravel-pest-specialist` for T4). Always asks before dispatching.
- **[#30](https://github.com/altraWeb/laravel-livewire-superpowers/issues/30) `pilot-2-contract-enforcer` hook.** PostToolUse:Bash hook that filters to `git commit`/`git push`, reads the active plan-doc Pilot 2.0 Tactic Tracking section, and warns on open T3/T4 markers. Behavior controlled by `audit_aggressiveness` config (`brainstorm-only` silent, `every-phase` warns, `every-commit` warns with intent to block when PostToolUse-block support is universal). T5/T6 remain in their existing dedicated hooks.
- **[#27](https://github.com/altraWeb/laravel-livewire-superpowers/issues/27) `/laravel-livewire-superpowers:audit-phase N` slash command.** Phase-scoped Pilot 2.0 T1 audit dispatch. Detects active plan-doc from branch name, extracts Phase N scope, dispatches `laravel-best-practices` in parallel, archives output to `docs/superpowers/audits/`, suggests T1 marker update in plan-doc.
- **`/laravel-livewire-superpowers:retro` slash command.** End-of-sprint retrospective generator. Reads plan-doc + git history + audit reports. Outputs per-phase Pilot 2.0 compliance matrix, drift instances, test-suite delta (files touched + assertion count), screenshot artifacts list. Read-only — never mutates state.
- **`docs/pilot-2-0-contract.md`** — Canonical Pilot 2.0 contract reference doc. Defines the full T1-T6 Tactic table, plan-doc marker convention, `audit_aggressiveness` mode semantics, component interaction diagram, and operator decision guide (when to bind / skip the contract). Single source of truth cited by the orchestrator agent, enforcer hook, and commands.

### Changed

- `hooks/hooks.json` — `pilot-2-contract-enforcer` registered under `PostToolUse.Bash` alongside `master-roadmap-drift-detector` (2 hooks under that matcher, up from 1).
- `config.defaults.yaml` — `hook_enabled.pilot_2_contract_enforcer: true` added. `audit_aggressiveness` comment extended to document the new wiring into the enforcer hook.
- `tests/test_config.py` — 1 new test `test_get_pilot_2_contract_enforcer_default` (31 tests total, up from 30).
- `docs/hooks.md` — new `pilot-2-contract-enforcer` reference section.
- `docs/agents.md` — new `laravel-pilot-orchestrator` reference section.
- `README.md` — hook count `9 → 10`, agent count `9 → 10`, slash command descriptions updated (1 → 3 shipped).
- `.claude-plugin/plugin.json` version `3.0.0-alpha.4` → `3.0.0-alpha.5`. Counts updated: 10 agents, 7 skills, 10 hooks, 3 commands.

### Phase Status

Phase E (this alpha) — shipped 2026-05-17 as v3.0.0-alpha.5.

Phases F-G remain.

---

## [3.0.0-alpha.4] — 2026-05-17 — V3 Megarelease — Phase D: Skills

Phase D adds three Laravel-specific skills (process guidance, not code execution). All three are read-only.

### Added

- **[#6](https://github.com/altraWeb/laravel-livewire-superpowers/issues/6) `laravel-a11y-specialist` skill.** WCAG 2.2 + ARIA + reduced-motion patterns surfaced systematically before implementation. Livewire-flavored (wire:loading.attr accessible patterns, aria-live for streaming content, prefers-reduced-motion + Page-Visibility). 7 canonical patterns + checklist.
- **[#8](https://github.com/altraWeb/laravel-livewire-superpowers/issues/8) `laravel-mr-body-writer` skill.** Canonical MR / PR body generator from sprint state. Reads plan-doc + `/laravel-livewire-superpowers:status` output + git history + test files to assemble the standard MR shape (Summary / Decisions / Pilot 2.0 contract / Spec + Plan / Test plan with assertion counts / Scope changes / Deferred items / Follow-up issues / Screenshots).
- **[#11](https://github.com/altraWeb/laravel-livewire-superpowers/issues/11) `laravel-perf-auditor` skill.** Mechanical query-path safety sweep. Checks preventLazyLoading status, N+1 patterns, cache strategy, query-count test coverage, unbounded-query pagination. Complements `laravel-architect` agent (agent does design decisions; this skill does spot-checks).

### Changed

- `.claude-plugin/plugin.json` version `3.0.0-alpha.3` → `3.0.0-alpha.4`. Description current-state skill count `4` → `7`.
- README skills comparison table extended with 3 new entries (if not already present from Phase A.2 placeholders).

### Phase Status

Phase D (this alpha) — ✅ shipped 2026-05-17 as v3.0.0-alpha.4.

Phases E-G remain.

---

## [3.0.0-alpha.3] — 2026-05-17 — V3 Megarelease — Phase C: Specialist Agents

Phase C adds three Laravel-codebase-aware specialist agents that fill canonical decision-support gaps. All three are read-only — they emit structured markdown reports, never mutate code.

### Added

- **[#7](https://github.com/altraWeb/laravel-livewire-superpowers/issues/7) `laravel-echo-reverb-specialist` agent.** Broadcasting / realtime decision support. Scans `routes/channels.php`, `app/Notifications/`, `app/Events/`, and Echo callbacks in `resources/js/` to identify reuse-vs-new-channel opportunities. Catches the canonical "the user-private channel already broadcasts both X and Y — no new channel needed" pattern from Block 1E brainstorm-time audits.
- **[#9](https://github.com/altraWeb/laravel-livewire-superpowers/issues/9) `spatie-permission-auditor` agent.** Gate-coverage + dead-permission audit. Cross-references seeded permissions in `RolePermissionSeeder.php` against actual `@can()` / `$user->can()` / `middleware('can:...')` / Policy usage. Catches dead permissions, unprotected routes, typo'd Blade refs, per-role drift.
- **[#12](https://github.com/altraWeb/laravel-livewire-superpowers/issues/12) `laravel-package-evaluator` agent.** Build-vs-buy decision support. Searches Packagist + GitHub for 2-5 candidate packages, builds trade-off matrix (license, stars, last-commit, Laravel compat, maintenance, docs, test coverage), compares against build-yourself baseline.

### Changed

- `.claude-plugin/plugin.json` version `3.0.0-alpha.2` → `3.0.0-alpha.3`. Description's current-state agent count `6` → `9`.
- `docs/agents.md` — 3 new agent reference sections.
- `README.md` — agent count bumped `6 → 9`.

### Phase Status

Phase C (this alpha) — shipped 2026-05-17 as v3.0.0-alpha.3.

Phases D-G remain.

---

## [3.0.0-alpha.2] — 2026-05-17 — V3 Megarelease — Phase B: Quickwin Hooks

Phase B adds three context-aware hooks that surface daily sprint state without operator action. None block; all are config-controlled with sensible defaults.

### Added

- **[#24](https://github.com/altraWeb/laravel-livewire-superpowers/issues/24) `sprint-state-context-injection` hook (SessionStart).** Detects active sprint via current branch + optional resume-anchor file + plan-doc, injects compact sprint-state summary (branch, plan-doc path, current phase, last commit) into session system prompt. Skips on `main`/`master`. Disable via `LARAVEL_SUPERPOWERS_SKIP_AUTO_RESUME=1` env or `hook_enabled.sprint_state_context_injection: false` config.
- **[#26](https://github.com/altraWeb/laravel-livewire-superpowers/issues/26) `stale-branch-sweep` hook (SessionStart).** Runs `git fetch --prune` silently, lists local branches whose upstream is `[gone]` with cleanup suggestion. Does NOT auto-delete by default. Auto-delete opt-in via `LARAVEL_SUPERPOWERS_AUTO_PRUNE=1` env or `stale_branch_sweep.auto_prune: true` config.
- **[#25](https://github.com/altraWeb/laravel-livewire-superpowers/issues/25) `master-roadmap-drift-detector` hook (PostToolUse:Bash, filters to git commits touching `docs/plans/*.md`).** Cross-references plan-doc state vs master-roadmap entry, warns on drift (e.g., plan-doc archived but master-roadmap still says pending). Non-blocking. Disable via `hook_enabled.master_roadmap_drift_detector: false` config.

### Changed

- `.claude-plugin/plugin.json` version `3.0.0-alpha.1` → `3.0.0-alpha.2`. Description's current-state hook count bumped 6 → 9 (3 new context-injection hooks added).
- `hooks/hooks.json` — new top-level `SessionStart` event registration + new `PostToolUse.Bash` matcher block for the drift detector.
- `config.defaults.yaml` — 3 new `hook_enabled.*` flags (default true) + new top-level `stale_branch_sweep.auto_prune` flag (default false).
- `config.schema.json` — extended for the new config keys.
- `tests/test_config.py` — 2 new tests for the new defaults (30 total Python config tests now).
- `docs/hooks.md` — 3 new hook reference sections.

### Phase Status

Phase B (this alpha) — shipped 2026-05-17 as v3.0.0-alpha.2.

Phases C-G remain.

---

## [3.0.0-alpha.1] — 2026-05-17 — V3 Megarelease — Phase A: Foundation, Deprecation, Rename

First alpha of the V3 Megarelease. Phase A establishes the foundation: plugin renamed to `laravel-livewire-superpowers`, marketplace moved to neutral host repo `altraWeb/laravel-marketplace`, internal slash-command paths updated, README + docs rebranded as the Livewire variant, 18 stale branches cleaned up. **No new features yet** — Phases B-G ship the 14 backlog issues.

### Changed

- **Plugin renamed** `laravel-superpowers` → `laravel-livewire-superpowers`. Reflected in `.claude-plugin/plugin.json` `name` field, in README title and install instructions, in all internal slash-command paths, in `docs/agents.md` + `docs/hooks.md` stack-scope banners.
- **Marketplace moved** to `altraWeb/laravel-marketplace`. The in-repo `.claude-plugin/marketplace.json` is removed; the canonical marketplace.json now lives in the neutral host repo.
- **Slash commands renamed** `/laravel-superpowers:*` → `/laravel-livewire-superpowers:*`. Only `/laravel-livewire-superpowers:status` exists in this alpha; `/audit-phase` and `/retro` ship in Phase E.

### Added

- `UPGRADING.md` documenting the V2 → V3 migration steps.
- `tests/test_marketplace_json.py` — schema validation for plugin.json (will extend to marketplace.json in future PRs).
- Stack-scope banner in `docs/agents.md` and `docs/hooks.md` marking the plugin as Livewire variant with a link to the planned `laravel-vue-superpowers` sibling.

### Removed

- `.claude-plugin/marketplace.json` (moved to `altraWeb/laravel-marketplace`).
- 17 stale remote branches (already-merged feat/* + spec/* + chore/* from V1/V2).
- 2 stale local branches (`feat/17-no-claude-attribution-hook`, `spec/3-flux-pro-specialist-agent`).

### Migration

See [`UPGRADING.md`](UPGRADING.md) for V2 → V3 migration steps.

### Phase A Status

Phase A.1 (v2.0.2 deprecation cut on still-named repo) — ✅ shipped 2026-05-17 as v2.0.2.
Phase A.2 (this alpha) — ✅ shipped 2026-05-17 as v3.0.0-alpha.1.

Phases B-G land in subsequent alpha/beta cuts before the v3.0.0 stable release.

---

## [2.0.2] — 2026-05-17 — Deprecation notice: V3 Megarelease coming under new name

**No code changes.** This release exists solely to give V2 users on the existing `altraweb-laravel` marketplace advance notice of the V3 Megarelease, which ships under a renamed plugin and a new neutral marketplace host repo.

### Coming in V3

- **Plugin renamed** `laravel-superpowers` → `laravel-livewire-superpowers` to make the Livewire 4 + Flux Pro v2 stack scope explicit (a sibling `laravel-vue-superpowers` for Vue 3 + Inertia projects is planned next).
- **Marketplace moved** to a new neutral host repo `altraWeb/laravel-marketplace`. The existing `altraweb-laravel` marketplace (currently bundled inside this plugin repo) will be deprecated.
- **Scope:** all 14 open Tier-2 + Tier-3 backlog issues land in V3, plus full Pilot 2.0 contract enforcement via the new `laravel-pilot-orchestrator` agent and `pilot-2-contract-enforcer` hook.

### Migration

A `UPGRADING.md` ships with V3 documenting the steps. The short version:

```bash
claude /plugin uninstall laravel-superpowers
claude /plugin marketplace remove altraweb-laravel
claude /plugin marketplace add altraWeb/laravel-marketplace
claude /plugin install laravel-livewire-superpowers@altraweb-laravel
```

### Design spec

The full V3 design is at [`docs/superpowers/specs/2026-05-17-v3-livewire-megarelease-design.md`](docs/superpowers/specs/2026-05-17-v3-livewire-megarelease-design.md) (lands on the renamed repo as part of the V3 cut).

### No breaking changes in this release

v2.0.2 is byte-identical to v2.0.1 except for this CHANGELOG entry and the version bump in `plugin.json` + `marketplace.json`. All hooks, agents, skills, and the `/laravel-livewire-superpowers:status` slash command continue to behave exactly as in v2.0.1.

---

## [2.0.1] — 2026-05-15 — V2-MVP self-audit hotfix

Patch release driven by the post-V2.0.0 self-audit ([`docs/audits/2026-05-15-v2-mvp-self-audit.md`](docs/audits/2026-05-15-v2-mvp-self-audit.md)). Empirical hook verification surfaced one functional blocker and four should-fix items; this release bundles all five together.

### Fixed

- **Blocker — `no-claude-attribution` silently bypassed `"`-quoted inline messages.** `extract_flag_value()` embedded the command string into an unquoted Python heredoc; any `"` character in the message broke the triple-quoted string, Python raised `SyntaxError`, `2>/dev/null` swallowed it, and the hook exited 0. All `git commit -m "feat: x"`, `gh pr create --body "..."`, `glab mr create --description "..."` patterns were affected. Fix: values now pass via environment variables and `shlex.split(os.environ["CMD"])`. ([B1 in audit](docs/audits/2026-05-15-v2-mvp-self-audit.md))
- **`banned-token-leak-guard` blocked legitimate ISO date literals.** The default date pattern `\b20[0-9]{2}-[0-9]{2}-[0-9]{2}\b` matched Carbon literals (`Carbon::parse('2026-01-01')`), fixture arrays, migration date constants, and any other in-code date. Narrowed to context-anchored form requiring a preceding sprint-state keyword (`On`, `Audit`, `Sprint`, `Phase`, `Released`, `Shipped`, `Review`, `Deferred`, `Date`). ([S1 in audit](docs/audits/2026-05-15-v2-mvp-self-audit.md))
- **`teamcity-always` did not catch `composer test` wrapper.** Many Laravel projects expose the test runner via `composer.json` scripts; pre-2.0.1 these bypassed the hook. Filter extended to `composer test` / `composer run test` / `composer run-script test`. Retry suggestion uses composer's `-- --teamcity` arg-pass convention. Word-boundary tightened to avoid false-positive matching `composer test-coverage`. ([S3 in audit](docs/audits/2026-05-15-v2-mvp-self-audit.md))
- **All 4 PreToolUse-Bash hooks tightened command-position detection.** Substring-glob filters (`*"git commit"*`, `*"gh pr create"*`, etc.) intercepted commands where the target appeared as a literal substring inside `echo`, `grep`, `cat <<EOF`, etc. Replaced with regex anchoring at start-of-line or after a separator (`;`, `&&`, `||`, `|`), with optional env-var prefix support. Affects `banned-token-leak-guard`, `no-claude-attribution`, `teamcity-always`, `anti-silent-deferral`. ([S5 in audit](docs/audits/2026-05-15-v2-mvp-self-audit.md))

### Documentation

- `docs/config.md` and `config.defaults.yaml` clarify that `audit_aggressiveness` is **advisory metadata** for the orchestrator agent — only `brainstorm-only` mode is programmatically enforced (via the existing `brainstorm-t1-audit` hook). `every-phase` and `every-commit` are hints for the agent's self-dispatch decisions; Claude Code emits no phase or commit events for hooks to attach to. ([S2 in audit](docs/audits/2026-05-15-v2-mvp-self-audit.md))
- `docs/config.md` notes that `teamcity_always` now covers `composer test` wrappers in addition to `php artisan test`.
- New: `docs/audits/2026-05-15-v2-mvp-self-audit.md` — full audit transcript with empirical evidence, root-cause analysis, and fix plans per finding.

### Tests

- `+5` scenarios in `tests/test_no_claude_attribution_hook.sh` (Tests 11–15: quoted inline `-m`, gh pr `--body` with `"`, glab mr `--description` with `"`, and S5 substring-passthrough cases).
- `+3` scenarios in `tests/test_banned_token_hook.sh` (Test 6 updated to context-anchored form, +Test 7 Carbon-literal passthrough, +Test 8 S5 substring-passthrough).
- `+5` scenarios in `tests/test_teamcity_always_hook.sh` (Tests 10–14: composer wrappers, `composer test-coverage` word-boundary, S5 substring-passthrough).
- `+1` scenario in `tests/test_anti_silent_deferral_hook.sh` (Test 12: S5 substring-passthrough).
- All 7 hook-test suites + 23 Python config tests green at release time.

### No breaking changes

V2.0.1 is fully additive over V2.0.0. The narrowed `banned-token-leak-guard` date pattern is a behavior change for users who relied on bare ISO date matching, but no operator-facing config or API breaks. Users who want the broader pattern back can add it via `banned_tokens.project_extras` in their config.

---

## [2.0.0] — 2026-05-15 — V2-MVP

**Major release.** Extends V1's "ship working code" baseline (1 agent + 4 skills) into a comprehensive stack-aware toolkit for Laravel 11/12 + Livewire 4 + Flux Pro v2 + Pest 4 projects. Driven by real-world catches from Block 1H + 1E test sprints (4 P0-class bugs that V1 missed).

### Added — Specialist Agents (5)

- **`laravel-livewire-specialist`** ([#1]) — audits Livewire-touching plans/code for fabricated APIs (catches the canonical `$this->hasLoading()` class of bug), `wire:ignore` zone reactivity, Form-Object patterns, Echo morphing race-conditions, lifecycle-hook misuse. Verifies via PHP reflection against `vendor/livewire/livewire/src/Component.php`.
- **`laravel-pest-specialist`** ([#2]) — audits Pest 4 tests for variadic-API misuse (`toContain('foo', 'msg')` gotcha), browser-plugin smells (`wait(N)` abuse), view-context anti-patterns (reserved-name keys), test-location mismatches, `it()`/`arch()`/dataset block correctness. Multi-namespace reflection against `vendor/pestphp/pest/src/`.
- **`laravel-flux-pro-specialist`** ([#3]) — audits Flux Pro v2 Blade components for double-tooltip wrapping (a11y break on `<ui-toolbar>` roving-tabindex), position/align convention drift, `<flux:editor.spacer/>` misplacement, `wire:ignore` reactive descendants, slot-vs-string-prop trade-offs. Cites vendor `file:line` refs from `vendor/livewire/flux-pro/stubs/resources/views/flux/`.
- **`laravel-architect`** ([#4]) — audits Eloquent + architecture decisions. Sibling-canon-aware: reads `app/Actions/`, `app/Services/`, `app/Http/Requests/`, `app/Data/` and recommends consistency with existing project patterns. Catches N+1, surfaces `preventLazyLoading` status, recommends QueryCount-pinning tests, flags Repository anti-pattern + fat controllers.
- **`laravel-reviewer`** ([#5]) — evidence-based code review wrapping the `laravel-code-review` skill with grep/find/`php artisan` tool access. Banned-token sweep default, sibling-canon verification, **composes** specialist agents (recommends them when stack-specific code in scope, never re-implements). Output: Blocker / Should-fix / Nice-to-have with `file:line` citations.

Plus existing `laravel-best-practices` (V1) — kept as the web-research general-Laravel advisor.

### Added — Skill Enhancements (3)

- **`laravel-tdd`** ([#13]) — appended Pest 4 specifics module: variadic-expectation trap (`->because()` modifier), `wait(N)` smell + 5s implicit timeout, `$this` reserved in views, `it()`/`arch()`/dataset decision tree, test-file location convention (Unit/Feature/Architecture/Browser), `actingAs()` placement, `assertAttribute` API availability check.
- **`laravel-code-review`** ([#14]) — appended Livewire 4 sub-checklist (API existence, reactivity modifiers, `#[Computed]` cache modes, `#[Locked]` for non-rehydratable props, `wire:ignore` Alpine bridges, Echo callback patterns, Form Objects, lifecycle hooks) + Flux Pro v2 sub-checklist (tooltip double-wrap, position/align convention, editor.spacer placement, wire:ignore + Flux components, slot vs string, Floating UI auto-flip). Each sub-checklist invokes the corresponding specialist agent for deep audit.
- **`laravel-debugging`** ([#15]) — appended top-10 RED-recipes table covering Pest 4 / Livewire 4 / Flux Pro v2 stolperer (variadic, `$this`, fabricated APIs, `Bus::fake` mock-layer, route mismatch, hasOne/hasMany juggle, FK constraints, Livewire properties, lang keys, browser flake). Plus specialist-dispatch matrix.

### Added — Enforcement Hooks (6)

- **`banned-token-leak-guard`** ([#16]) — PreToolUse on `git commit`. Blocks commits containing Phase/Sprint/Track/MR/dated refs in staged code/comments. Exception paths (`docs/plans/**`, `docs/superpowers/**`, `CHANGELOG.md`), per-line override marker (`banned-token-ok: <reason>`), configurable extras via `banned_tokens.project_extras`.
- **`no-claude-attribution`** ([#17]) — PreToolUse on `git commit`, `gh pr create`, `glab mr create`. Blocks any Claude / AI attribution variant in commit messages or MR bodies. Reads from `-m`, `-F`, `--body`, `--body-file`, `--description`, `--description-file`. Shows offending line + sanitized rewrite suggestion.
- **`teamcity-always`** ([#18]) — PreToolUse on `php artisan test`. Blocks when `--teamcity` missing, shows retry suggestion with flag inserted in correct position. Respects alternate reporters (`--testdox`, `--printer-class`) and config kill-switches.
- **`anti-silent-deferral`** ([#19]) — PreToolUse on `git push`. Scans `docs/plans/*.md` files on the branch for `## Phase N — Deferred Items` sections. Blocks when free-form prose or bullets without `#N` issue refs. Allows explicit `**None — all tasks completed**` markers. Emergency override env var + per-doc skip marker.
- **`visual-companion-default-on`** ([#21]) — PostToolUse on `superpowers:brainstorming`. Injects `additionalContext` reminder that Visual Companion is default-on unless topic is provably text-only (naming votes, semver, config-flips). Configurable denylist + allowlist override.
- **`brainstorm-t1-audit`** ([#20]) — PostToolUse on `superpowers:brainstorming`. Injects `additionalContext` with canonical dispatch prompt template for `laravel-best-practices` agent (Pilot 2.0 Tactic 1 — Phase-Start Agent-Audit). Topic interpolated from skill args.

### Added — Plugin Infrastructure (2)

- **Plugin config foundation** ([#22]) — `config.defaults.yaml` + `config.schema.json` + Python helper (`lib/config.py`) with 5 subcommands: `get`, `validate`, `show`, `init`, `doctor`. Three-layer merge: defaults < user-global (`~/.claude/plugins/altraweb-laravel/laravel-superpowers/config.yaml`) < per-project (`<project>/.laravel-superpowers.yaml`). All hooks read config at fire-time. Fail-open architecture — broken config helper never blocks user operations.
- **`/laravel-livewire-superpowers:status` slash command** ([#23]) — read-only status panel surfacing current sprint state (active plan-doc + phase progress), Pilot 2.0 obligations (T1/T3/T4 dispatch evidence; T5/T6 automated via hooks), hook compliance per config, open obligations. Target: ≤2s response time.

### Documentation

- New: `docs/agents.md`, `docs/hooks.md`, `docs/config.md`
- Enhanced: `README.md` with full Skills / Agents / Hooks / Slash Commands sections + Configuration section
- Updated: `docs/ROADMAP.md` — V2-MVP marked complete, V2.1/V2.2/V3 milestones remain
- New: 16 design specs + 16 implementation plans under `docs/superpowers/specs/` + `docs/superpowers/plans/`
- New: 15 specialist-agent smoke-test evidence files under `docs/superpowers/test-evidence/`

### Tests

- **45 shell-test scenarios** covering all 6 hooks (6 + 10 + 9 + 11 + 9 + 5)
- **23 Python unit tests** for the config foundation helper (`tests/test_config.py`)
- **1 shell smoke test** for hook integration pattern (`tests/test_hook_integration.sh`)
- All green at release time

### Notable design decisions documented in PR bodies

- **Hooks cannot invoke agents directly** (#20) — implemented as REMINDER + dispatch prompt template via `additionalContext`. Parent agent does the Task-tool dispatch.
- **Teamcity-always BLOCKS with retry** (#18) — issue asked for auto-append; hook output schema for tool_input modification is not portable. Block-with-suggestion gets 90% of value at 10% of complexity.
- **Visual-companion hook injects reminder, not literal offer** (#21) — skill spec requires offer as "own message" which `additionalContext` can't strictly guarantee. Reminder nudges the agent to offer at Step 2.

### Breaking changes

None. V2.0.0 is fully additive over V1.

### Stack assumptions (unchanged from V1)

Laravel 11/12 + Livewire 4 + Flux Pro v2 + Pest 4 + PHP 8.4+. Older Laravel/Livewire versions can still use the generic skills (`laravel-brainstorming`, `laravel-tdd`, `laravel-code-review`, `laravel-debugging`) but the V2-MVP specialists lean on Livewire 4 / Flux Pro v2 / Pest 4 specifically.

[#1]: https://github.com/altraWeb/laravel-superpowers/issues/1
[#2]: https://github.com/altraWeb/laravel-superpowers/issues/2
[#3]: https://github.com/altraWeb/laravel-superpowers/issues/3
[#4]: https://github.com/altraWeb/laravel-superpowers/issues/4
[#5]: https://github.com/altraWeb/laravel-superpowers/issues/5
[#13]: https://github.com/altraWeb/laravel-superpowers/issues/13
[#14]: https://github.com/altraWeb/laravel-superpowers/issues/14
[#15]: https://github.com/altraWeb/laravel-superpowers/issues/15
[#16]: https://github.com/altraWeb/laravel-superpowers/issues/16
[#17]: https://github.com/altraWeb/laravel-superpowers/issues/17
[#18]: https://github.com/altraWeb/laravel-superpowers/issues/18
[#19]: https://github.com/altraWeb/laravel-superpowers/issues/19
[#20]: https://github.com/altraWeb/laravel-superpowers/issues/20
[#21]: https://github.com/altraWeb/laravel-superpowers/issues/21
[#22]: https://github.com/altraWeb/laravel-superpowers/issues/22
[#23]: https://github.com/altraWeb/laravel-superpowers/issues/23

---

## [1.0.0] — 2026-05-13 — Initial release

- 1 agent: `laravel-best-practices`
- 4 skills: `laravel-brainstorming`, `laravel-tdd`, `laravel-debugging`, `laravel-code-review`
- Marketplace registration: `altraweb-laravel` on GitHub via `altraWeb/laravel-superpowers`
- Plugin discoverable via `claude plugin marketplace add altraWeb/laravel-superpowers`
