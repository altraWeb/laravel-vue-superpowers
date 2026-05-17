# V3 Phase G — Release Polish + v3.0.0 Stable Cut — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development.

**Goal:** Ship v3.0.0 stable — the final Megarelease cut. This is the last phase; after Phase G the V3 trajectory is complete.

**Architecture:** Two-step phase. **Step G.1** (in-repo polish): write the full self-audit, finalize CHANGELOG with consolidated v3.0.0 entry, ROADMAP update, plugin.json version bump to `3.0.0`. **Step G.2** (release): tag v3.0.0 (NOT prerelease this time), GitHub Release, update neutral marketplace repo's marketplace.json from alpha references to `3.0.0`, smoke-test install.

**Spec:** `docs/superpowers/specs/2026-05-17-v3-livewire-megarelease-design.md` Section 5 — Phase G.

---

## File Structure

### New files

| File | Purpose |
|---|---|
| `docs/audits/2026-05-17-v3-megarelease-self-audit.md` | Full self-audit covering all 6 prior phases — analog v2.0.0 pattern |

### Modified files

| File | Change |
|---|---|
| `CHANGELOG.md` | Add consolidated `## [3.0.0]` section ABOVE existing alpha entries (which stay for historical record) |
| `docs/ROADMAP.md` | V3 section marked COMPLETE; all 14 backlog issues flipped to [x]; add "what's next" placeholder for Phase G+ items (Vue fork brainstorming) |
| `.claude-plugin/plugin.json` | Version `3.0.0-alpha.6` → `3.0.0`; description finalize (drop "alpha" / "Phase X" language, present current-state as definitive) |
| `README.md` | Add v3.0.0 entry at top of Versions section; clean up "(current)" marker placement |
| **External:** `~/dev/laravel-marketplace/.claude-plugin/marketplace.json` | Plugin version `3.0.0-alpha.1` → `3.0.0` |

### Branch / release

- Feature branch: `feat/v3-phase-g-stable-cut`
- Post-merge: tag `v3.0.0` (NOT prerelease), GitHub Release v3.0.0, update marketplace repo.

---

## STEP G.1 — In-Repo Polish (single PR)

### Task 1: Pre-flight + branch

- [ ] Verify clean main + 11 alpha tags exist (`git tag --list | grep '^v3\.'` shows v3.0.0-alpha.1 through .6).
- [ ] Tests baseline: 13 shell + 33 Python all green.
- [ ] `git switch -c feat/v3-phase-g-stable-cut`

### Task 2: Write the V3 self-audit

**File:** `docs/audits/2026-05-17-v3-megarelease-self-audit.md`

Pattern: analog `docs/audits/2026-05-15-v2-mvp-self-audit.md`. Cover:

```markdown
# V3-Megarelease Self-Audit — 2026-05-17

> **Auditor:** operator-driven empirical verification of all 14 Phase A-F deliverables, full test-suite run, install-flow check.
> **Trigger:** post-v3.0.0-alpha.6, before declaring V3 "stable".
> **Method:** Read all new files, run all hook test suites with intentional edge inputs, verify plugin manifest validates, verify install flow in fresh Claude Code session.

---

## Summary

| Severity | Count | Tracks |
|---|---|---|
| 🚫 Blocker | <N> | <list> |
| ⚠️ Should-fix | <N> | <list> |
| 💡 Nice-to-have | <N> | <list> |

**Verdict:** <stable-ship / needs-patch-before-stable>

---

## Phase-by-phase coverage

### Phase A — Foundation
- [x] Rename complete (verify gh repo view current name)
- [x] Marketplace neutral repo live (verify marketplace.json reachable)
- [x] UPGRADING.md tested with real V2→V3 migration

### Phase B — Quickwin Hooks
- [x] sprint-state-context-injection: SessionStart fires, emits context in feat/* branches, silent on main
- [x] stale-branch-sweep: SessionStart fires, lists [gone] branches with cleanup command
- [x] master-roadmap-drift-detector: PostToolUse:Bash on git-commit-touching-plans, warns on drift

### Phase C — Specialist Agents
- [x] laravel-echo-reverb-specialist: frontmatter valid, body has Pre-flight + Steps + output template
- [x] spatie-permission-auditor: same
- [x] laravel-package-evaluator: same

### Phase D — Skills
- [x] laravel-a11y-specialist: 7 canonical patterns documented
- [x] laravel-mr-body-writer: canonical 9-section shape documented
- [x] laravel-perf-auditor: 5 mechanical checks documented

### Phase E — Pilot 2.0 Meta-Layer
- [x] laravel-pilot-orchestrator agent: reads plan-doc Tactic markers
- [x] pilot-2-contract-enforcer hook: PostToolUse:Bash on git commit/push, parses tactic markers
- [x] /audit-phase + /retro slash commands wired
- [x] docs/pilot-2-0-contract.md canonical reference present

### Phase F — Blade-Edit Hooks
- [x] vendor-source-preflight: PreToolUse:Edit/Write on .blade.php with flux:/wire: surfaces stub paths
- [x] lang-key-existence-preflight: PreToolUse:Edit/Write on .blade.php with __()/@lang() verifies key existence

---

## Findings

<concrete findings if any. Format: B/S/N severity, file:line, symptom, root cause, recommended fix.>

---

## Test-suite state at audit time

- Shell hook test suites: 13 (all 🟢)
- Python config tests: 33 (all passed)
- Total scenarios across all suites: <count>
- Manual smoke tests performed: <list>

---

## Backlog issues closed

- [x] #6 laravel-a11y-specialist — PR #58
- [x] #7 laravel-echo-reverb-specialist — PR #56
- [x] #8 laravel-mr-body-writer — PR #58
- [x] #9 spatie-permission-auditor — PR #56
- [x] #10 laravel-pilot-orchestrator — PR #60
- [x] #11 laravel-perf-auditor — PR #58
- [x] #12 laravel-package-evaluator — PR #56
- [x] #24 sprint-state-context-injection — PR #54
- [x] #25 master-roadmap-drift-detector — PR #54
- [x] #26 stale-branch-sweep — PR #54
- [x] #27 /audit-phase + /retro — PR #60
- [x] #28 vendor-source-preflight — PR #62
- [x] #29 lang-key-existence-preflight — PR #62
- [x] #30 pilot-2-contract-enforcer — PR #60

All 14 V3 backlog issues closed.

---

## Verdict

<stable-ship-now / needs-patch / blocker-found>

If stable-ship-now: tag v3.0.0, cut GitHub Release, update marketplace.
```

Fill in any actual findings as you run the verifications. If none, mark "No findings" explicitly.

### Task 3: Finalize CHANGELOG with consolidated v3.0.0 entry

**File:** `CHANGELOG.md`

Insert ABOVE the existing `## [3.0.0-alpha.6]` section (the alpha entries STAY for historical record):

```markdown
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

Full audit: `docs/audits/2026-05-17-v3-megarelease-self-audit.md` (no blockers; <N> should-fix / <M> nice-to-have items addressed inline).

### What's next

- `laravel-vue-superpowers` sibling plugin — Vue 3 + Inertia v2 variant — planned, gets its own brainstorming session
- Quality-of-life iterations on V3 components (operator-driven)

---

```

(Match the `---` separator convention.)

### Task 4: Update ROADMAP.md

**File:** `docs/ROADMAP.md`

Mark V3 section COMPLETE. Flip all 14 V3-target checkboxes to `[x]`. Add a "What's next" section pointing to Vue fork brainstorming.

(Exact edits depend on current ROADMAP structure — read it first.)

### Task 5: Update plugin.json to 3.0.0

**File:** `.claude-plugin/plugin.json`

```json
{
    "name": "laravel-livewire-superpowers",
    "version": "3.0.0",
    "description": "Laravel + Livewire 4 + Flux Pro v2 + Pest 4 specialist toolkit for Claude Code. 10 specialist agents, 7 stack-enhanced skills, 12 enforcement & context hooks, 3 slash commands. Full Pilot 2.0 contract enforcement (T1-T6) with canonical reference doc, meta-orchestrator agent, and continuous enforcer hook.",
    "author": {
        "name": "altraWeb"
    },
    "keywords": ["laravel", "livewire", "flux-pro", "pest", "php", "tdd", "workflow", "code-review", "agents", "hooks", "specialist-agents", "pilot-2.0"]
}
```

Drop the "alpha" / "Phase X" language from the description.

### Task 6: Update README

- Add `## v3.0.0 (2026-05-17) — V3 Megarelease STABLE` entry at TOP of Versions section
- Move `(current)` marker from alpha.5 to v3.0.0
- Optionally collapse the alpha entries into a single line: "V3 alphas (alpha.1 through alpha.6) — see CHANGELOG for phase-by-phase breakdown"

### Task 7: Run all tests + verify state

```bash
for t in tests/test_*.sh; do bash "$t" >/dev/null 2>&1 && echo "✓" || echo "✗ $t"; done
python3 -m pytest tests/ -q
ls hooks/*.sh | wc -l  # 12
ls agents/*.md | wc -l  # 10
ls skills/*/SKILL.md | wc -l  # 7
ls commands/*.md | wc -l  # 3
```

Expected: 13 shell ✓, 33 Python passed, counts 12/10/7/3.

### Task 8: Commit + PR

Single commit with all G.1 changes:

```
feat(v3): phase g — v3.0.0 stable cut (release polish)

Final V3 Megarelease cut. Consolidates 6 phased alpha releases
into v3.0.0 stable.

Changes:
- docs/audits/2026-05-17-v3-megarelease-self-audit.md — full audit
  covering all 6 phases
- CHANGELOG.md — new [3.0.0] consolidated section
- docs/ROADMAP.md — V3 marked COMPLETE, all 14 backlog issues [x]
- plugin.json — version 3.0.0 (drop alpha)
- README.md — v3.0.0 in Versions list

All 13 shell + 33 Python tests green. Ready for v3.0.0 stable tag.
```

PR to main with body summarizing v3.0.0 readiness.

**STOP. Operator merges PR.**

---

## STEP G.2 — Stable Release Cut

### Task 9: Tag v3.0.0 + GitHub Release STABLE (not prerelease)

```bash
cd ~/dev/laravel-livewire-superpowers
git switch main
git pull --ff-only origin main
git tag -a v3.0.0 -m "v3.0.0 — V3 Megarelease (Stable). Plugin: laravel-livewire-superpowers (Laravel + Livewire 4 + Flux Pro v2 + Pest 4 stack). 10 agents / 7 skills / 12 hooks / 3 commands. Full Pilot 2.0 contract enforcement."
git push origin v3.0.0

gh release create v3.0.0 \
  --title "v3.0.0 — V3 Megarelease (Stable)" \
  --notes "$(awk '/^## \[3\.0\.0\]/{flag=1; next} /^## \[/{if(flag){flag=0}} flag' CHANGELOG.md)"
```

(Note: NO `--prerelease` flag — this is the stable cut.)

### Task 10: Update neutral marketplace to point at v3.0.0

```bash
cd ~/dev/laravel-marketplace
# Edit .claude-plugin/marketplace.json: change plugins[0].version from "3.0.0-alpha.X" to "3.0.0"
```

Use Edit tool with `old_string: "version": "3.0.0-alpha.1"` (or whatever current is) → `new_string: "version": "3.0.0"`.

Also bump `metadata.version` from `1.0.0` to `1.1.0` (marketplace itself has a meaningful change now — points at stable).

Commit + push:
```bash
git add .claude-plugin/marketplace.json
git commit -m "chore: bump laravel-livewire-superpowers reference to v3.0.0 (stable)"
git push origin main
```

### Task 11: Smoke-test install flow (operator manual)

Operator runs in a fresh Claude Code session:

```bash
claude /plugin marketplace add altraWeb/laravel-marketplace
claude /plugin install laravel-livewire-superpowers@altraweb-laravel
claude /laravel-livewire-superpowers:status
```

Expected: marketplace adds clean, plugin installs at v3.0.0, /status renders.

### Task 12: Report V3 complete

State to operator: "🎉 V3.0.0 STABLE released. Plugin live at https://github.com/altraWeb/laravel-livewire-superpowers, marketplace pointing at stable, install flow smoke-tested. V3 Megarelease is complete. Next: `laravel-vue-superpowers` sibling brainstorming when you give the go."

**STOP. V3 Megarelease COMPLETE.**
