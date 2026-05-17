# V3 Mega-Release (Livewire Variant) — Design Spec

**Milestone:** V3-Megarelease
**Status:** Design draft (operator-approved 2026-05-17)
**Date:** 2026-05-17
**Brainstorm-T1 Audit:** [`docs/superpowers/audits/2026-05-17-vue-fork-stack-audit.md`](../audits/2026-05-17-vue-fork-stack-audit.md)

---

## 1. Context & Motivation

V2.0.1 (released 2026-05-15) is the stable MVP of `laravel-superpowers`: 6 specialist agents, 4 enhanced skills, 7 hooks, 1 slash command, config foundation. The plugin is implicitly Livewire 4 + Flux Pro v2 focused but never explicitly branded as such.

V3 has two parallel drivers:

1. **Explicit stack scoping.** Operator needs a Vue 3 + Inertia sibling plugin. To make the sibling-relationship clean, the existing plugin gets renamed to `laravel-livewire-superpowers` and the marketplace gets restructured around a neutral host repo.

2. **Backlog convergence.** 14 open enhancement issues (7 Tier-2 + 7 Tier-3) have accumulated since the V2-MVP cut. Mega V3 lands all of them in a coordinated release, raising the plugin from V2-MVP to a fully-realized contract-enforcement platform with full Pilot 2.0 orchestration.

The Vue sibling fork is **out of scope** for this spec — it gets its own dedicated brainstorming session after V3 ships.

## 2. Goals & Non-Goals

**Goals**
- Rename `altraWeb/laravel-superpowers` → `altraWeb/laravel-livewire-superpowers` on GitHub with redirect-preserving rename
- Introduce neutral marketplace host repo `altraWeb/laravel-marketplace` listing both Livewire (now) and Vue (later) variants
- Ship all 14 backlog issues: 4 new agents, 3 new skills, 6 new hooks, 2 new slash commands
- Formalize the Pilot 2.0 contract (T1-T6) end-to-end via orchestrator agent + enforcer hook + plan-doc tactic-markers
- Provide clean migration story for V2 users
- Cut a v3.0.0 release with full CHANGELOG + self-audit + GitHub release asset

**Non-Goals**
- Vue fork design or implementation (separate brainstorming session)
- Any breaking change to hook/config schema beyond the rename impact
- Any feature beyond the 14 issues in the open backlog
- A monorepo restructuring (operator explicitly chose clone+new-repo over subtree)

## 3. Repo Topology & Naming

```
altraWeb/
├── laravel-livewire-superpowers       (renamed from laravel-superpowers, v3.0.0)
│   └── .claude-plugin/plugin.json     name: laravel-livewire-superpowers
│
├── laravel-vue-superpowers            (future, separate brainstorming session)
│   └── .claude-plugin/plugin.json     name: laravel-vue-superpowers
│
└── laravel-marketplace                (NEW neutral marketplace host)
    ├── .claude-plugin/marketplace.json    lists both plugins as github sources
    └── README.md                          variant selection guide
```

**Naming convention:** `laravel-{stack}-superpowers` (stack in the middle), reads as "Laravel Livewire Superpowers" / "Laravel Vue Superpowers". Stack visibility is the priority over preserving the historical `laravel-superpowers` brand.

**Rename mechanics:**
- `gh repo rename altraWeb/laravel-superpowers laravel-livewire-superpowers` — GitHub automatically maintains URL redirects, all existing issues/PRs/releases/clones continue to function
- Local working tree: rename `~/dev/laravel-superpowers/` → `~/dev/laravel-livewire-superpowers/` + `git remote set-url origin` update
- All operator-memory references to the old path get refreshed in a single pass

## 4. Component Inventory (V2.0.1 → V3)

| Category | V2.0.1 | V3 New | V3 Total |
|---|---|---|---|
| Agents | 6 | +4 | 10 |
| Skills | 4 | +3 | 7 |
| Hooks | 7 | +6 | 13 |
| Slash Commands | 1 | +2 | 3 |

### New Agents (Tier-2/3)

- **`laravel-echo-reverb-specialist`** (#7) — Broadcasting / Realtime architectural guidance. Echo client config, Reverb server config, presence/private channel authentication, scaling considerations, Pusher fallback.
- **`spatie-permission-auditor`** (#9) — Gate coverage audit + dead-permission detection across the codebase. Reads policies/, gates/, middleware/, blade-can-checks. Flags routes without policy mapping and permissions never checked.
- **`laravel-pilot-orchestrator`** (#10) — Meta-agent. On-demand Pilot 2.0 contract enforcement: reads current plan-doc + git log + audit history, outputs structured Tactic-status, optionally dispatches missing specialists.
- **`laravel-package-evaluator`** (#12) — Build-vs-buy decision support. Given a feature requirement, evaluates 2-3 community packages plus a "build it yourself" baseline on dimensions: maintenance, license, test coverage, last commit, community size, Laravel-version compatibility.

### New Skills (Tier-2/3)

- **`laravel-a11y-specialist`** (#6) — WCAG 2.2 + ARIA + reduced-motion patterns. Livewire-flavored: `wire:loading` accessible patterns, focus management around `wire:navigate`, screen-reader announcements for Livewire state changes.
- **`laravel-mr-body-writer`** (#8) — Canonical merge-request / pull-request body generator. Reads sprint-state via `/status` output, generates structured MR body with sections (Summary, Issue Links, Test Plan, Migration Notes, Pilot 2.0 Tactic Tracking).
- **`laravel-perf-auditor`** (#11) — `preventLazyLoading` enforcement, query-count budgets per route, cache-strategy patterns, eager-loading recipe library.

### New Hooks (Tier-2/3)

- **`sprint-state-context-injection`** (#24, SessionStart) — Injects current plan-doc phase / owner / open Pilot-2.0 obligations as session context. Reduces "what was I doing?" friction at session start.
- **`master-roadmap-drift-detector`** (#25, PostToolUse on Edit/Write to `docs/plans/*` or `docs/ROADMAP.md`) — Detects when a plan-doc change diverges from `docs/ROADMAP.md` and warns to update both.
- **`stale-branch-sweep`** (#26, SessionStart) — Lists merged-but-not-deleted local + remote branches at session start. Read-only; never deletes automatically.
- **`vendor-source-preflight`** (#28, PreToolUse on Edit/Write to `*.blade.php`) — When editing a blade file that contains `<flux:*>` or `wire:*` directives, surfaces relevant `vendor/livewire/flux-pro/stubs/` and `vendor/livewire/livewire/src/` files as additional context.
- **`lang-key-existence-preflight`** (#29, PreToolUse on Edit/Write to `*.blade.php`) — When editing a blade file with `__('key')` or `@lang('key')` calls, verifies each key exists in `lang/*/` and warns about missing ones before the write completes.
- **`pilot-2-contract-enforcer`** (#30, PostToolUse on Bash filtered to `git commit` / `git push`) — Reads plan-doc Tactic-markers, warns/blocks on missing T3/T4 evidence per `audit_aggressiveness` config.

### New Slash Commands

- **`/laravel-livewire-superpowers:audit-phase N`** (#27) — Triggers a phase-scoped Pilot 2.0 audit. Reads `## Phase N` from active plan-doc, dispatches `laravel-best-practices` (T1) and `laravel-reviewer` (T3) against the phase scope, outputs structured audit-result.
- **`/laravel-livewire-superpowers:retro`** (#27) — Generates a sprint retrospective from plan-doc + git history + audit reports. Outputs Wins / Misses / Action-Items / Pilot-2.0-Compliance-Score.

### Renamed (Rename Impact)

- `/laravel-superpowers:status` → `/laravel-livewire-superpowers:status`

## 5. Release Phases & Sequencing

7 phases. Each phase opens with a `laravel-best-practices` phase-start audit (T1) and closes with a `laravel-reviewer` phase-end audit (T3-equivalent at phase scope).

**Phase A — Foundation, Deprecation, Rename** (blocks all subsequent phases; must execute in order)

*Step A.1 — Deprecation cut BEFORE rename:*
- Cut `v2.0.2` on the current `laravel-superpowers` URL with no code changes, only a CHANGELOG entry: "V3 Mega-Release coming under new name `laravel-livewire-superpowers` on new marketplace `altraWeb/laravel-marketplace`. See UPGRADING.md for migration steps." This ensures V2 users on the existing `altraweb-laravel` marketplace see the deprecation notice *before* the GitHub URL changes.
- Tag and release `v2.0.2`.

*Step A.2 — Rename + Foundation:*
- `gh repo rename altraWeb/laravel-superpowers laravel-livewire-superpowers` (GitHub auto-creates URL redirect)
- Local directory rename `~/dev/laravel-superpowers/` → `~/dev/laravel-livewire-superpowers/` + `git remote set-url origin`
- `plugin.json`: name + description + version → `3.0.0-alpha.1`
- New `altraWeb/laravel-marketplace` repo with `marketplace.json` (lists Livewire plugin via github source; Vue slot prepared but commented out)
- All `/laravel-superpowers:*` slash command paths → `/laravel-livewire-superpowers:*`
- README + `docs/agents.md` + `docs/hooks.md` stack-explicit branding ("Livewire 4 + Flux Pro v2 stack")
- Cleanup 13 stale remote branches + 2 stale local branches (all already merged via PRs)
- `UPGRADING.md` (V2 → V3 migration: uninstall old, add new marketplace, install new plugin)

**Phase B — Quickwin Hooks** (high daily-value, low complexity, parallelizable)
- #24 `sprint-state-context-injection` (SessionStart)
- #26 `stale-branch-sweep` (SessionStart)
- #25 `master-roadmap-drift-detector` (PostToolUse on docs/plans/)

**Phase C — New Specialist Agents** (parallelizable)
- #7 `laravel-echo-reverb-specialist`
- #9 `spatie-permission-auditor`
- #12 `laravel-package-evaluator`

**Phase D — New Skills** (parallelizable)
- #6 `laravel-a11y-specialist`
- #8 `laravel-mr-body-writer`
- #11 `laravel-perf-auditor`

**Phase E — Pilot 2.0 Meta-Layer** (sequential, depends on Phases B-D)
- #10 `laravel-pilot-orchestrator` Meta-Agent
- #30 `pilot-2-contract-enforcer` Hook
- #27 `/audit-phase N` + `/retro` Slash Commands
- New `docs/pilot-2-0-contract.md` canonical reference doc
- All existing spec/plan files extended with Tactic-Marker section (template-driven, scripted)

**Phase F — Advanced Blade-Edit Hooks** (more complex, file-glob + vendor-source lookup)
- #28 `vendor-source-preflight`
- #29 `lang-key-existence-preflight`

**Phase G — Release Polish & Cut**
- Self-Audit (analog v2.0.0 pattern → `docs/audits/2026-XX-XX-v3-megarelease-self-audit.md`)
- Complete `CHANGELOG.md` for v3.0.0
- v3.0.0 tag signed
- GitHub Release with plugin-tarball asset + release notes
- `altraWeb/laravel-marketplace` updated with v3.0.0 plugin reference
- (v2.0.2 deprecation release happened in Phase A.1 — not duplicated here)

**Realistic Duration:** ~3-5 weeks solo + parallel theme work. Phases B-D ideal for `superpowers:subagent-driven-development`. Phase E sequential.

**Branch Strategy:** Feature branches `feat/<issue#>-<slug>` per item, PR per branch, squash-merge to `main`. No long-lived V3 branch — trunk-based with feature flags if necessary.

## 6. Testing & Quality Gates

### Test Inventory after V3

| Test Type | V2.0.1 | V3 Target | Per-Item |
|---|---|---|---|
| Hook shell test suites | 7 | 13 (+6) | `tests/test_<hook>_hook.sh` per new hook |
| Python config tests | 23 | 28-30 (+5-7) | per new config section |
| Hook integration test | 1 | 1 (extended) | extended for new hook interactions |
| Agent smoke tests | ad-hoc | 10 (+10) | new `tests/agents/test_<agent>_smoke.sh` |
| Skill smoke tests | 0 | 7 (+7) | new `tests/skills/test_<skill>_smoke.sh` |
| Pilot 2.0 contract E2E | 0 | 1 (+1) | end-to-end orchestrator → enforcer → audit-phase → retro |
| Marketplace validation | 0 | 1 (+1) | `tests/test_marketplace_json.py` schema-validates both plugins |
| **Runner** | per-file | `tests/run_all.sh` (NEW) | wraps all suites, single exit code |

### Quality Gates per Phase-End Cut

- All shell hook tests green
- All Python config tests green
- `bash tests/run_all.sh` exit 0
- At least one manual smoke test per new agent in a fresh Laravel sandbox project
- Self-audit doc only at Phase G

### Quality Gates for V3 Release Cut (Phase G)

- All phase-cut gates green
- `UPGRADING.md` validated with real migration (clean uninstall → add new marketplace → install new plugin → `/status` reports clean state)
- `claude /plugin install laravel-livewire-superpowers@altraweb-laravel` cold-installs cleanly in a fresh Claude Code session
- All 14 backlog issues closed with PR references
- `CHANGELOG.md` complete and accurate
- Self-audit report committed
- v3.0.0 tag signed
- GitHub Release with asset + release notes published

### Test Pattern for New Hooks (established v2.0.0)

1. Trigger-match scenario (hook fires as expected)
2. No-match scenario (hook silent)
3. Malformed JSON input → silent passthrough
4. Edge cases derived from anti-pattern audit
5. v2.0.1-S5-pattern command-position filter check (substring-in-echo passthrough)

## 7. Pilot 2.0 Contract Formalisierung

V3 makes Pilot 2.0 a first-class contract instead of scattered convention. The full 6-Tactic table:

| Tactic | Name | When | Mechanism (V3) | V2.0.1 Status |
|---|---|---|---|---|
| T1 | Phase-Start Best-Practices Audit | Brainstorming Step 2 | `brainstorm-t1-audit` hook → agent dispatches `laravel-best-practices` parallel | enforced |
| T2 | Visual-Companion Offer | Brainstorming Step 2 | `visual-companion-default-on` hook → agent offers VC or justifies skip | enforced (V3 formalizes as T2) |
| T3 | Per-Commit Code Review | After each commit | V3: `pilot-2-contract-enforcer` warns/blocks if `laravel-reviewer` not invoked | on-demand |
| T4 | Pre-Test-Write Specialist Audit | Before any test-write | V3: enforcer warns if `laravel-pest-specialist` not invoked | on-demand |
| T5 | Pre-Push Banned-Token Sweep | `git push` | `banned-token-leak-guard` PreToolUse hook | automated |
| T6 | Pre-Push Deferred-Items Check | `git push` | `anti-silent-deferral` PreToolUse hook | automated |

### Plan-Doc Tactic-Marker Convention (V3 standardization)

Every `## Phase N` block in `docs/plans/*.md` includes:

```markdown
**Pilot 2.0 Tactic Tracking:**
- [x] T1 dispatched on YYYY-MM-DD (audit: docs/superpowers/audits/YYYY-MM-DD-<topic>-audit.md)
- [x] T2 VC offered (accepted | skipped — reason)
- [ ] T3 pending for commits: <SHA list>
- [ ] T4 pending for tests: <path list>
- T5: automated (sweep clean per pre-push hook)
- T6: automated (no deferred items unlinked)
```

The `pilot-2-contract-enforcer` reads these markers to determine compliance state.

### Two New V3 Components Make T3+T4 Enforceable

**`laravel-pilot-orchestrator` (agent, #10)** — On-demand meta-agent. Reads current plan-doc + git log + audit history. Identifies for each uncommitted/unaudited item which Tactic is outstanding. Outputs structured Tactic-status. Optionally dispatches missing specialists. Invoked via `@laravel-pilot-orchestrator` or `/laravel-livewire-superpowers:audit-phase N`.

**`pilot-2-contract-enforcer` (hook, #30)** — Continuous meta-hook. Event: PostToolUse on Bash, filtered to `git commit` and `git push`. Reads plan-doc Tactic-markers, warns/blocks based on `audit_aggressiveness` config (`brainstorm-only` silent / `every-phase` warn / `every-commit` block).

## 8. Migration & Backward Compatibility

V2 users must reinstall because the plugin name changes.

**Migration steps (documented in `UPGRADING.md`):**

```bash
# 1. Uninstall the V2 plugin
claude /plugin uninstall laravel-superpowers

# 2. Remove the old marketplace
claude /plugin marketplace remove altraweb-laravel

# 3. Add the new neutral marketplace
claude /plugin marketplace add altraWeb/laravel-marketplace

# 4. Install the renamed V3 plugin
claude /plugin install laravel-livewire-superpowers@altraweb-laravel
```

**Deprecation strategy on the V2 side (executed in Phase A.1, BEFORE the GitHub rename):**
- A `v2.0.2` release on the still-named `laravel-superpowers` repo with no code changes, only a CHANGELOG entry pointing users to the new name + new marketplace + UPGRADING.md. This guarantees V2 users on the existing `altraweb-laravel` marketplace see the deprecation notice while the old URL still resolves directly.
- After the rename in Phase A.2, GitHub maintains the URL redirect indefinitely. V2 users who somehow miss the v2.0.2 notice and still query the old URL get redirected to the new repo where the CHANGELOG explains the situation.
- The old `altraweb-laravel` marketplace (currently lives inside the plugin repo at `.claude-plugin/marketplace.json`) gets replaced by the new neutral `altraWeb/laravel-marketplace` repo when V3 ships in Phase G.

**Config compatibility:** User-config schema (`~/.claude/plugins/altraweb-laravel/laravel-superpowers/config.yaml`) is unchanged. After migration the user's config continues to apply to the renamed plugin (the helper reads the same path — the V2 plugin name is preserved in the path intentionally for backward compatibility).

## 9. Success Criteria / Definition of Done

V3 ships when ALL of the following are true:

1. `altraWeb/laravel-livewire-superpowers` is the canonical URL (rename complete + redirect verified)
2. `altraWeb/laravel-marketplace` exists and lists the Livewire plugin
3. All 14 backlog issues are closed with merged PR references
4. `tests/run_all.sh` exits 0
5. Self-audit doc committed (`docs/audits/2026-XX-XX-v3-megarelease-self-audit.md`)
6. CHANGELOG complete with v3.0.0 section
7. `UPGRADING.md` validated by a real migration
8. v3.0.0 git tag signed
9. GitHub Release with asset published
10. `claude /plugin install laravel-livewire-superpowers@altraweb-laravel` cold-installs cleanly

## 10. Out of Scope

- **Vue sibling fork** (`laravel-vue-superpowers`) — separate brainstorming session after V3 ships. The T1 audit covering Vue stack decisions is archived at [`docs/superpowers/audits/2026-05-17-vue-fork-stack-audit.md`](../audits/2026-05-17-vue-fork-stack-audit.md) for that future session.
- **Monorepo restructure** — explicitly rejected; clone+new-repo chosen for Vue fork.
- **Shared-infra extraction** — each plugin owns its full copy of hooks/config tooling for V3. Extraction to a shared core plugin is a possible future RFC if maintenance pain warrants it.
- **CI/CD changes** — out of scope; existing GitHub Actions workflows continue unchanged.
- **Marketing / announcement** — operator owns; not in design scope.

## 11. Open Questions

None at design-cut. All major decisions resolved interactively during brainstorming session 2026-05-17.

## 12. References

- T1 audit findings (Vue stack decisions): `docs/superpowers/audits/2026-05-17-vue-fork-stack-audit.md`
- V2-MVP self-audit pattern: `docs/audits/2026-05-15-v2-mvp-self-audit.md`
- Backlog issues:
  - Tier-2: #6, #7, #8, #24, #25, #26, #27
  - Tier-3: #9, #10, #11, #12, #28, #29, #30
- Agent-memory (Vue stack decisions, survives compaction):
  - `~/.claude/agent-memory/laravel-superpowers-laravel-best-practices/project_vue_fork_stack_decisions.md`
  - `~/.claude/agent-memory/laravel-superpowers-laravel-best-practices/project_vue_fork_anti_pattern_hooks.md`
