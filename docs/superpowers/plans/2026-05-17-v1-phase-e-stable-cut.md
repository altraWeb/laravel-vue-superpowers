# V1 Phase E — Release Polish + v1.0.0 Stable Cut — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development.

**Goal:** Final V1 cut — consolidate alpha releases into v1.0.0 stable. Operator-facing UX: plugin moves from alpha to "release". Marketplace updates to 1.0.0.

**Architecture:** Two-step phase. **Step E.1** (in-repo polish): self-audit + CHANGELOG `## [1.0.0]` consolidation + ROADMAP marked COMPLETE + plugin.json `1.0.0` + README polish. **Step E.2** (release): tag v1.0.0 (NOT prerelease) + GitHub Release stable + marketplace bump from `1.0.0-alpha.4` to `1.0.0`.

**Spec:** `docs/superpowers/specs/2026-05-17-vue-fork-adaptation-design.md` Section 5 Phase E + Section 11 Success Criteria.

---

## File Structure

### New files

| File | Purpose |
|---|---|
| `docs/audits/2026-05-17-v1-stable-self-audit.md` | Full self-audit covering Phases A-D + readiness verdict for v1.0.0 |

### Modified files (in `~/dev/laravel-vue-superpowers/`)

| File | Change |
|---|---|
| `CHANGELOG.md` | Prepend `## [1.0.0]` consolidated section ABOVE the 4 alpha entries (alphas stay for historical record) |
| `docs/ROADMAP.md` | Mark V1 section COMPLETE; flip all checkboxes to `[x]`; add "What's next" section pointing to future ideas |
| `.claude-plugin/plugin.json` | Version `1.0.0-alpha.4` → `1.0.0`; description finalize (drop "alpha" / "Phase X" language) |
| `README.md` | Versions section: add `v1.0.0` entry at top, move `(current)` marker; alpha-status banner removed or rewritten as stable; install commands verified |

### External (in `~/dev/laravel-marketplace/`)

| File | Change |
|---|---|
| `.claude-plugin/marketplace.json` | Vue plugin version `1.0.0-alpha.4` → `1.0.0`; metadata.version `1.2.0` → `1.3.0` (Vue plugin reached stable — meaningful change) |
| `README.md` | Available plugins table: Vue row status `Alpha (v1.0.0-alpha.2+)` → `Released (v1.0.0+)` |

### Branch / release

- Feature branch: `feat/v1-phase-e-stable-cut`
- Post-merge: tag `v1.0.0` (NOT prerelease), GitHub Release stable, marketplace bump

---

## STEP E.1 — In-Repo Polish

### Task 1: Pre-flight + create feature branch

- [ ] Verify clean main post-Phase-D (tag `v1.0.0-alpha.4` present, 17 shell + 37 Python tests green)
- [ ] `git switch -c feat/v1-phase-e-stable-cut`

### Task 2: Write the V1 self-audit

**File:** `docs/audits/2026-05-17-v1-stable-self-audit.md`

Pattern: analog `docs/audits/2026-05-17-v3-megarelease-self-audit.md` (Livewire-variant self-audit). Cover:

```markdown
# V1-Stable Self-Audit — 2026-05-17

> **Auditor:** operator-driven empirical verification of all Phase A-D deliverables, full test-suite run.
> **Trigger:** post-v1.0.0-alpha.4, before declaring V1 "stable".
> **Method:** Read all changed files, run all hook test suites, verify plugin manifest validates, verify install flow works.

---

## Summary

| Severity | Count | Tracks |
|---|---|---|
| 🚫 Blocker | <N> | <list or "None"> |
| ⚠️ Should-fix | <N> | <list or "None"> |
| 💡 Nice-to-have | <N> | <list or "None"> |

**Verdict:** <stable-ship / needs-patch>

---

## Phase-by-phase coverage

### Phase A — Identity Rename (v1.0.0-alpha.1)

- [x] Plugin renamed laravel-vue-superpowers (no remnant laravel-livewire / laravel-superpowers in live files)
- [x] Config paths use Vue-named locations (no V2-compat baggage)
- [x] 3 slash commands renamed (status / audit-phase / retro)
- [x] CLONE_FORK_STATUS.md archived; UPGRADING.md deleted
- [x] Fresh CHANGELOG initiated

### Phase B — Specialists + Anti-Pattern Hooks (v1.0.0-alpha.2)

- [x] laravel-livewire-specialist deleted
- [x] laravel-flux-pro-specialist replaced with laravel-reka-ui-specialist
- [x] laravel-inertia-specialist created (Inertia v3 primary; v2 compat-note in body)
- [x] laravel-vue3-specialist created (Composition API + script setup + TS)
- [x] 4 anti-pattern hooks created (vue-setinterval-cleanup, vue-reactive-destructure, inertia-link-external-url, inertia-hardcoded-route)
- [x] hooks.json registered; config defaults extended; test_config.py extended

### Phase C — Skill Sub-Section Swaps (v1.0.0-alpha.3)

- [x] laravel-a11y-specialist: 7→3 patterns + Reka-handles section
- [x] laravel-code-review §9 Inertia/Vue + §10 Reka UI sub-checklists
- [x] laravel-debugging Top-10 items #3 + #8 swap
- [x] laravel-tdd Pest-specifics items #3 + #8 swap

### Phase D — Hook Repurpose (v1.0.0-alpha.4)

- [x] vendor-source-preflight renamed + rewritten as inertia-vendor-preflight (Reka UI + Inertia detection)
- [x] lang-key-existence-preflight broadened to .vue files

---

## Findings

<concrete findings if any. Format: severity, file:line, symptom, root cause, recommended fix.>

If no findings, state explicitly: "No findings — V1 ready for stable cut."

---

## Test-suite state at audit time

- Shell hook test suites: 17 (all 🟢)
- Python config tests: 37 (all passed)
- Total scenarios across all suites: <count>
- Manual smoke tests performed: <list>

---

## Carryover verification

V1 Vue variant carryover from `laravel-livewire-superpowers@v3.0.0`:

- Agents: 11 (was 10 in source) — REMOVE livewire, REPLACE flux→reka, ADD inertia + vue3
- Skills: 7 (unchanged count, 4 of 7 got sub-section swaps in Phase C)
- Hooks: 16 (was 12 in source) — +4 anti-pattern hooks (Phase B); 1 repurposed + renamed (Phase D)
- Slash commands: 3 (renamed paths only)
- Pilot 2.0 meta-layer: 1:1 carryover

Effort delivered: ~18-22h estimated, actual: <X>h.

---

## Verdict

<stable-ship: ship v1.0.0 / needs-patch: list specific blockers>
```

Fill in findings (if any) by re-reading the alpha deliverables. If none, mark "No findings".

### Task 3: CHANGELOG consolidate `## [1.0.0]` stable section

Insert ABOVE existing `## [1.0.0-alpha.4]`:

```markdown
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

Full audit: [`docs/audits/2026-05-17-v1-stable-self-audit.md`](docs/audits/2026-05-17-v1-stable-self-audit.md) (<N> blockers / <M> should-fix / <K> nice-to-have addressed inline).

### What's next

- Wayfinder-dedicated specialist (deferred from V1, defer to v1.1.0 RFC)
- Inertia v3 specifics that may evolve as the ecosystem matures
- Pinia / SSR / shadcn-vue opt-in skills/presets if adoption grows

---

```

### Task 4: ROADMAP.md mark V1 COMPLETE

Read current ROADMAP. Update each phase section to mark all checkboxes `[x]`. Add a "V1 Complete" header. Move detailed phase work to a "Phase history" subsection. Add "What's next (post-V1)" section.

### Task 5: plugin.json version → 1.0.0

```json
{
    "name": "laravel-vue-superpowers",
    "version": "1.0.0",
    "description": "Laravel + Vue 3 (Composition API) + Inertia v3 + Reka UI + Tailwind CSS 4 + Pest 4 specialist toolkit for Claude Code. 11 specialist agents, 7 stack-enhanced skills, 16 enforcement & context hooks, 3 slash commands. Full Pilot 2.0 contract enforcement (T1-T6) with canonical reference doc, meta-orchestrator agent, and continuous enforcer hook.",
    "author": {
        "name": "altraWeb"
    },
    "keywords": ["laravel", "vue", "vue3", "inertia", "inertia-v3", "reka-ui", "tailwind", "pest", "php", "tdd", "workflow", "code-review", "agents", "hooks", "specialist-agents", "pilot-2.0"]
}
```

Drop "alpha" / "Phase X" language.

### Task 6: README update for stable

- Remove the "Pre-1.0 release" banner block (lines 6-7 area) entirely — replace with a stable-state intro paragraph or leave the title section clean
- Versions section: add `v1.0.0 (2026-05-17) — V1 Stable` *(current)* entry above alpha.4; remove `(current)` from alpha.4

### Task 7: Run all tests + verify

```bash
for t in tests/test_*.sh; do bash "$t" >/dev/null 2>&1 && echo "✓" || echo "✗ $t"; done
python3 -m pytest tests/ -q
ls hooks/*.sh | wc -l      # 16
ls agents/*.md | wc -l     # 11
ls skills/*/SKILL.md | wc -l   # 7
ls commands/*.md | wc -l   # 3
python3 -c 'import json; print(json.load(open(".claude-plugin/plugin.json"))["version"])'  # 1.0.0
```

Expected: 17 shell ✓, 37 Python passed, counts 16/11/7/3, version 1.0.0.

### Task 8: Commit + push + PR

```bash
git add -A
git -c commit.gpgsign=false commit -m "feat(v1): phase e — v1.0.0 stable cut (release polish)

Final V1 cut. Consolidates 4 phased alpha releases (alpha.1 through
alpha.4) into v1.0.0 stable.

Changes:
- docs/audits/2026-05-17-v1-stable-self-audit.md — full audit
- CHANGELOG.md — new [1.0.0] consolidated section above alphas
- docs/ROADMAP.md — V1 marked COMPLETE
- plugin.json — version 1.0.0 (drop alpha + phase language)
- README.md — Versions section v1.0.0 added; alpha banner dropped

All 17 shell + 37 Python tests green. Ready for v1.0.0 stable tag.
"
git push -u origin feat/v1-phase-e-stable-cut
gh pr create --base main --head feat/v1-phase-e-stable-cut --title "feat(v1): phase e — v1.0.0 stable cut" --body "Final V1 Vue-variant cut. Self-audit + CHANGELOG consolidate + plugin.json 1.0.0 + README polish. After merge: tag v1.0.0 (stable), GitHub Release, marketplace bump 1.2.0 → 1.3.0."
```

**STOP. Wait for operator merge.**

---

## STEP E.2 — Stable Release Cut

### Task 9: Tag v1.0.0 STABLE + GitHub Release (not prerelease)

```bash
cd ~/dev/laravel-vue-superpowers
git switch main
git pull --ff-only origin main
git tag -a v1.0.0 -m "v1.0.0 — V1 Stable. Plugin: laravel-vue-superpowers (Laravel + Vue 3 + Inertia v3 + Reka UI + Tailwind CSS 4 + Pest 4 stack). 11 agents / 7 skills / 16 hooks / 3 commands. Full Pilot 2.0 contract enforcement."
git push origin v1.0.0

gh release create v1.0.0 \
  --title "v1.0.0 — V1 Stable" \
  --notes "$(awk '/^## \[1\.0\.0\] /{flag=1; next} /^## \[/{if(flag){flag=0}} flag' CHANGELOG.md)"
```

(NO `--prerelease` flag.)

### Task 10: Marketplace bump to v1.0.0

```bash
cd ~/dev/laravel-marketplace
```

Update `.claude-plugin/marketplace.json`:
- `plugins[1].version`: `1.0.0-alpha.4` → `1.0.0`
- `metadata.version`: `1.2.0` → `1.3.0`

Update `README.md` Available plugins table: Vue row status `Alpha (v1.0.0-alpha.2+)` → `Released (v1.0.0+)`.

Commit + push:
```bash
git add -A
git -c commit.gpgsign=false commit -m "chore: laravel-vue-superpowers v1.0.0 stable

Vue variant reached stable. Marketplace bump 1.2.0 → 1.3.0 (meaningful
change: 2nd plugin reached stable)."
git push origin main
```

### Task 11: Smoke-test (operator manual)

State to operator:

"V1.0.0 stable shipped. Smoke-test in fresh Claude Code session:
```bash
claude /plugin marketplace add altraWeb/laravel-marketplace
claude /plugin install laravel-vue-superpowers@altraweb-laravel
claude /laravel-vue-superpowers:status
```

V1 Vue Megarelease COMPLETE. Plugin live at https://github.com/altraWeb/laravel-vue-superpowers."

**STOP. V1 Vue Megarelease COMPLETE.**
