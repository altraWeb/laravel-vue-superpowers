# V1 Phase A — Identity Rename — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Rename plugin identity end-to-end (plugin.json + slash commands + config paths + docs + branding) so `laravel-vue-superpowers` is functionally addressable as itself, not a confused leftover of the cloned-from-livewire state. Ship as v1.0.0-alpha.1 + add Vue plugin entry to marketplace.

**Architecture:** Identity rename is mechanical but pervasive — affects plugin.json, all 3 slash commands, README, agents.md + hooks.md banners, config paths (lib/config.py + config.defaults.yaml + per-project .yaml + hook error messages), CHANGELOG (init), and the external marketplace.json on `altraWeb/laravel-marketplace`. Vue fork uses Vue-named config paths from start (no V2 compat baggage since no V0 users). Historical Livewire-variant docs in `docs/superpowers/specs|plans|audits/` are NOT touched — they remain as inherited historical record (cleanup deferred to Phase E).

**Tech Stack:** Bash + git + gh CLI + Python 3. No new dependencies.

**Spec:** `docs/superpowers/specs/2026-05-17-vue-fork-adaptation-design.md` Section 5 — Phase A.

---

## File Structure

### Modified files (in `~/dev/laravel-vue-superpowers/`)

| File | Change |
|---|---|
| `.claude-plugin/plugin.json` | Version `0.1.0-cloned-from-livewire-v3.0.0` → `1.0.0-alpha.1`; description Vue-stack |
| `lib/config.py` | Config paths use `laravel-vue-superpowers` (not `laravel-superpowers`); SCHEMA_POINTER URL points to vue repo |
| `config.defaults.yaml` | Header comments + path references → vue plugin name |
| `config.schema.json` | `$id` URL + `title` → vue plugin name |
| `.laravel-superpowers.yaml` | Renamed → `.laravel-vue-superpowers.yaml` (project-local config; also update content references) |
| `hooks/*.sh` (4 files: teamcity-always, anti-silent-deferral, no-claude-attribution, banned-token-leak-guard) | Error messages reference `.laravel-vue-superpowers.yaml` |
| `hooks/sprint-state-context-injection.sh` | Internal slash command references → vue paths |
| `commands/audit-phase.md` | Slash command name in body → `/laravel-vue-superpowers:audit-phase` |
| `commands/retro.md` | Same pattern |
| `commands/status.md` | Same pattern |
| `README.md` | Full rewrite for Vue 3 + Inertia v3 + Reka UI + Tailwind 4 + Pest 4 stack; install instructions; drop WIP banner |
| `docs/agents.md` | Stack-scope banner: Vue 3 + Inertia v3 + Reka UI |
| `docs/hooks.md` | Same pattern |
| `docs/config.md` | Plugin name references + config path references |
| `docs/pilot-2-0-contract.md` | Slash command references in workflow diagrams |
| `docs/ROADMAP.md` | Replace with fresh Vue-variant roadmap (V1.0.0-alpha cycle through stable) |
| `docs/audits/2026-05-15-v2-mvp-self-audit.md` | Leave unchanged (historical Livewire reference) |
| `skills/laravel-mr-body-writer/SKILL.md` | Slash command reference in body |
| `CHANGELOG.md` | Replace entire content with fresh `[1.0.0-alpha.1]` entry; archive prior to `docs/ARCHIVE/CHANGELOG-from-livewire-source.md` (preserves clone-origin trace) |
| `UPGRADING.md` | DELETE (no V0 users for Vue fork; UPGRADING was Livewire-V2→V3 migration; irrelevant) |
| `tests/test_config.py` | Update fixture paths to `laravel-vue-superpowers` |
| `tests/test_hook_integration.sh` | Update fixture paths |
| `tests/conftest.py` | Update fixture paths |

### Moved/archived files

| Move | Destination |
|---|---|
| `CLONE_FORK_STATUS.md` | `docs/ARCHIVE/CLONE_FORK_STATUS.md` (historical clone-record) |
| `CHANGELOG.md` (old content) | `docs/ARCHIVE/CHANGELOG-from-livewire-source.md` |
| `UPGRADING.md` | DELETE (not archived — irrelevant to Vue fork) |

### External (in `~/dev/laravel-marketplace/`)

| File | Change |
|---|---|
| `.claude-plugin/marketplace.json` | ADD 2nd plugin entry `laravel-vue-superpowers v1.0.0-alpha.1`; bump metadata.version `1.1.0` → `1.2.0` |
| `README.md` | Add Vue plugin to "Available plugins" table |

### Branch / release

- Feature branch: `feat/v1-phase-a-identity-rename`
- Post-merge: tag `v1.0.0-alpha.1` + GitHub Pre-Release + marketplace.json update

---

## STEP A.1 — Foundation

### Task 1: Pre-flight + create feature branch

**Files:** None.

- [ ] **Step 1: Verify clean post-spec-merge state**

```bash
cd ~/dev/laravel-vue-superpowers
git status
git log --oneline -3
```

Expected: clean working tree, HEAD at `e1f0a9a docs(v1): adaptation design spec for laravel-vue-superpowers (#1)`.

- [ ] **Step 2: Baseline test run**

```bash
for t in tests/test_*.sh; do bash "$t" >/dev/null 2>&1 && echo "✓" || echo "✗ $t"; done
python3 -m pytest tests/ -q
```

Expected: all green (inherited from Livewire-variant baseline — 17 shell + 37 Python). If anything fails, STOP and investigate.

- [ ] **Step 3: Create feature branch**

```bash
git switch -c feat/v1-phase-a-identity-rename
git branch
```

Expected: `* feat/v1-phase-a-identity-rename` is current.

---

## STEP A.2 — Plugin Manifest + Config Helper

### Task 2: Update `plugin.json` to v1.0.0-alpha.1

**Files:**
- Modify: `.claude-plugin/plugin.json`

- [ ] **Step 1: Rewrite plugin.json**

Use Write tool with content:

```json
{
    "name": "laravel-vue-superpowers",
    "version": "1.0.0-alpha.1",
    "description": "Laravel + Vue 3 (Composition API) + Inertia v3 + Reka UI + Tailwind CSS 4 + Pest 4 specialist toolkit for Claude Code. Phase A (foundation) shipped; full counts (11 agents, 7 skills, 16 hooks, 3 slash commands with Pilot 2.0 contract enforcement) target v1.0.0 stable. Current v1.0.0-alpha.1 ships identity rename only — agents/skills/hooks content adaptation in Phases B-D.",
    "author": {
        "name": "altraWeb"
    },
    "keywords": ["laravel", "vue", "vue3", "inertia", "inertia-v3", "reka-ui", "tailwind", "pest", "php", "tdd", "workflow", "code-review", "agents", "hooks", "specialist-agents", "pilot-2.0"]
}
```

- [ ] **Step 2: Validate JSON**

```bash
python3 -c 'import json; p = json.load(open(".claude-plugin/plugin.json")); print(p["name"], p["version"])'
```

Expected: `laravel-vue-superpowers 1.0.0-alpha.1`

### Task 3: Update `lib/config.py` for Vue-named paths

**Files:**
- Modify: `lib/config.py` (docstring + path constants + SCHEMA_POINTER)

- [ ] **Step 1: Update module docstring**

Edit line 2: replace `"""laravel-superpowers config helper.` with `"""laravel-vue-superpowers config helper.`

- [ ] **Step 2: Update `_user_config_path` function (around line 85-91)**

Replace the function body to use `laravel-vue-superpowers`:

```python
def _user_config_path() -> Path:
    """Return the user-global config path.

    Path uses the Vue fork plugin name. Vue fork has no V0 users to
    preserve compat for, so config lives at the canonical
    plugin-named location.
    """
    return Path(os.environ["HOME"]) / ".claude" / "plugins" / "altraweb-laravel" / "laravel-vue-superpowers" / "config.yaml"
```

- [ ] **Step 3: Update `_project_config_path` function (around line 96-102)**

```python
def _project_config_path() -> Path:
    """Return the per-project config path.

    Filename uses the Vue fork plugin name. Vue fork has no V0 users
    to preserve compat for, so filename matches the plugin name.
    """
    return Path.cwd() / ".laravel-vue-superpowers.yaml"
```

- [ ] **Step 4: Update `SCHEMA_POINTER` (around line 189-190)**

```python
# SCHEMA_POINTER: URL uses the Vue fork plugin name.
SCHEMA_POINTER = "# yaml-language-server: $schema=https://raw.githubusercontent.com/altraWeb/laravel-vue-superpowers/main/config.schema.json\n"
```

- [ ] **Step 5: Smoke-test config helper**

```bash
python3 -c "
from lib.config import _user_config_path, _project_config_path, SCHEMA_POINTER
print('user:', _user_config_path())
print('project:', _project_config_path())
print('schema:', SCHEMA_POINTER.strip())
"
```

Expected output (paths reflect macOS user altrano):
```
user: /Users/altrano/.claude/plugins/altraweb-laravel/laravel-vue-superpowers/config.yaml
project: /Users/<cwd>/.laravel-vue-superpowers.yaml
schema: # yaml-language-server: $schema=https://raw.githubusercontent.com/altraWeb/laravel-vue-superpowers/main/config.schema.json
```

### Task 4: Update `config.defaults.yaml` + `config.schema.json`

**Files:**
- Modify: `config.defaults.yaml` (header comments)
- Modify: `config.schema.json` (`$id` + `title`)

- [ ] **Step 1: Update `config.defaults.yaml` header (first 10 lines)**

Replace lines 1-9 with:

```yaml
# laravel-vue-superpowers — plugin default config.
# This file is the canonical schema source. Every key here is recognized;
# unknown top-level keys in user/project configs will be rejected.
#
# To override these defaults, create one of:
#   ~/.claude/plugins/altraweb-laravel/laravel-vue-superpowers/config.yaml   (user-global)
#   ./.laravel-vue-superpowers.yaml                                           (per-project, takes precedence)
# Run: python3 lib/config.py init [--project]   to scaffold either file.
```

(Drop the V2-compat preservation comments — Vue fork doesn't have that history.)

- [ ] **Step 2: Update `config.schema.json` $id + title**

Edit lines 3-4:
```json
{
    "$schema": "http://json-schema.org/draft-07/schema#",
    "$id": "https://raw.githubusercontent.com/altraWeb/laravel-vue-superpowers/main/config.schema.json",
    "title": "laravel-vue-superpowers config",
    ...
}
```

- [ ] **Step 3: Validate config.defaults.yaml against schema**

```bash
python3 -c '
import json, yaml
from jsonschema import validate
schema = json.load(open("config.schema.json"))
cfg = yaml.safe_load(open("config.defaults.yaml"))
validate(instance=cfg, schema=schema)
print("✓ schema validates config.defaults.yaml")
'
```

Expected: `✓ schema validates config.defaults.yaml`.

### Task 5: Rename project-local config + update content

**Files:**
- Rename: `.laravel-superpowers.yaml` → `.laravel-vue-superpowers.yaml`
- Modify content to update plugin-name references

- [ ] **Step 1: Rename via git mv**

```bash
git mv .laravel-superpowers.yaml .laravel-vue-superpowers.yaml
```

- [ ] **Step 2: Update header comment in renamed file**

Read the file first. The header references `laravel-livewire-superpowers` or `laravel-superpowers`. Update to:

```yaml
# laravel-vue-superpowers per-project config overlay.
# Overrides config.defaults.yaml for this development repository.
#
# skills/**, agents/**, commands/**, docs/*.md, README.md added to
# exception_paths because plugin documentation legitimately references
# terms like "Pilot 2.0", phase names, etc. Without this, the
# banned-token-leak-guard blocks commits to those files.
banned_tokens:
  exception_paths:
    - "docs/plans/**"
    - "docs/superpowers/**"
    - "skills/**"
    - "agents/**"
    - "commands/**"
    - "docs/*.md"
    - "README.md"
    - "CHANGELOG.md"
```

(Adapt to the actual previous content; the goal is plugin-name reference removal + content preservation.)

### Task 6: Update hook error messages (4 hooks reference `.laravel-superpowers.yaml`)

**Files:**
- Modify: `hooks/teamcity-always.sh` (line ~137 per Livewire pattern)
- Modify: `hooks/anti-silent-deferral.sh` (line ~281)
- Modify: `hooks/no-claude-attribution.sh` (line ~208)
- Modify: `hooks/banned-token-leak-guard.sh` (line ~176)

- [ ] **Step 1: Find references**

```bash
grep -n '\.laravel-superpowers\.yaml\|laravel-superpowers' hooks/teamcity-always.sh hooks/anti-silent-deferral.sh hooks/no-claude-attribution.sh hooks/banned-token-leak-guard.sh
```

- [ ] **Step 2: Update each occurrence**

For each match: replace `.laravel-superpowers.yaml (filename preserved from V2 for config compatibility)` with `.laravel-vue-superpowers.yaml`. Drop the V2-compat parenthetical (Vue fork has no V2 history).

Use Edit per file. Verify after each:

```bash
grep -n '\.laravel-vue-superpowers\.yaml' hooks/teamcity-always.sh hooks/anti-silent-deferral.sh hooks/no-claude-attribution.sh hooks/banned-token-leak-guard.sh
```

Expected: 1 hit per file.

```bash
grep -n '\.laravel-superpowers\.yaml' hooks/teamcity-always.sh hooks/anti-silent-deferral.sh hooks/no-claude-attribution.sh hooks/banned-token-leak-guard.sh
```

Expected: 0 hits.

---

## STEP A.3 — Slash Command Path Renames

### Task 7: Rename slash command paths (live invocations only — historical refs untouched)

**Files:**
- Modify: `commands/status.md` (slash command name in `# header`)
- Modify: `commands/audit-phase.md` (same)
- Modify: `commands/retro.md` (same)
- Modify: `hooks/sprint-state-context-injection.sh` (internal slash command reference)
- Modify: `README.md` (install + usage examples)
- Modify: `docs/agents.md`, `docs/hooks.md`, `docs/config.md`, `docs/pilot-2-0-contract.md`
- Modify: `skills/laravel-mr-body-writer/SKILL.md` (body references slash commands)

**Scope note:** DO NOT rename in `docs/superpowers/specs/`, `docs/superpowers/plans/`, `docs/superpowers/audits/`, `docs/superpowers/test-evidence/`, or `docs/ARCHIVE/` — those are historical Livewire-variant docs that should preserve their original `/laravel-livewire-superpowers:` references for trace.

- [ ] **Step 1: List files in scope**

```bash
grep -rln '/laravel-livewire-superpowers:' . --include='*.md' --include='*.sh' --include='*.py' --include='*.yaml' --include='*.json' | grep -vE 'docs/superpowers/(specs|plans|audits|test-evidence)|docs/ARCHIVE|\.git/'
```

Expected: ~10-12 files including the ones listed in the Files section above.

- [ ] **Step 2: For each listed file, use Edit with `replace_all: true`**

`old_string: /laravel-livewire-superpowers:` → `new_string: /laravel-vue-superpowers:`

Apply per file. Do NOT use bulk `sed -i`.

- [ ] **Step 3: Verify**

```bash
grep -rln '/laravel-livewire-superpowers:' . --include='*.md' --include='*.sh' --include='*.py' --include='*.yaml' --include='*.json' | grep -vE 'docs/superpowers/(specs|plans|audits|test-evidence)|docs/ARCHIVE|\.git/'
```

Expected: empty (no live invocations remain).

```bash
grep -rln '/laravel-vue-superpowers:' . --include='*.md' --include='*.sh' --include='*.py' --include='*.yaml' --include='*.json' | grep -vE 'docs/superpowers/(specs|plans|audits|test-evidence)|docs/ARCHIVE|\.git/' | head -5
```

Expected: ≥10 files (the ones we just edited).

---

## STEP A.4 — README + Banners

### Task 8: Rewrite README.md for Vue stack

**Files:**
- Modify: `README.md` (full rewrite)

- [ ] **Step 1: Read current README to see what carries over**

```bash
head -50 README.md
```

- [ ] **Step 2: Write replacement README**

Use Write tool to produce a new README.md following the structure:

```markdown
# laravel-vue-superpowers

Laravel + **Vue 3 (Composition API)** + **Inertia v3** + **Reka UI** + **Tailwind CSS 4** + **Pest 4** specialist toolkit for [Claude Code](https://claude.ai/code) — designed to complement the [superpowers](https://github.com/anthropics/claude-plugins-official) base plugin with deep stack-specific expertise.

> **Stack scope:** This plugin targets the Vue 3 + Inertia v3 + Reka UI stack. For the Livewire 4 + Flux Pro v2 variant, see the sibling plugin [`laravel-livewire-superpowers`](https://github.com/altraWeb/laravel-livewire-superpowers) (v3.0.0+).
>
> ⚠️ **Pre-1.0 release:** Currently shipping `v1.0.0-alpha.1` (foundation: identity rename). Full agents/skills/hooks adaptation lands in Phases B-E (v1.0.0-alpha.2 through v1.0.0 stable). Functional usage from v1.0.0-alpha.2 onwards.

📍 **[Roadmap](docs/ROADMAP.md)** — see what's planned + tracked GitHub issues
📊 **[Versions](#versions)** — phase-by-phase release history

## Install

```bash
claude /plugin marketplace add altraWeb/laravel-marketplace
claude /plugin install laravel-vue-superpowers@altraweb-laravel
```

## Agents (11 planned for v1.0.0 stable)

[List agents — at alpha.1, only the inherited 10 from Livewire variant work, +1 placeholder for laravel-pilot-orchestrator. The 2 frontend specialists (livewire, flux-pro) are inherited but not functional for Vue stack until Phase B removes/replaces them.]

## Skills (7)

[List skills — inherited from Livewire variant, 4 of 7 get sub-section swaps in Phase C.]

## Hooks (12 currently / 16 planned for v1.0.0 stable)

[List hooks — 12 inherited; +4 anti-pattern hooks in Phase B.]

## Slash commands (3)

- `/laravel-vue-superpowers:status` — sprint state + Pilot 2.0 obligations
- `/laravel-vue-superpowers:audit-phase N` — phase-scoped audit dispatch
- `/laravel-vue-superpowers:retro` — sprint retrospective

## Sibling plugins

| Plugin | Stack | Status |
|---|---|---|
| [`laravel-livewire-superpowers`](https://github.com/altraWeb/laravel-livewire-superpowers) | Laravel + Livewire 4 + Flux Pro v2 + Pest 4 | Released (v3.0.0+) |
| `laravel-vue-superpowers` (this repo) | Laravel + Vue 3 + Inertia v3 + Reka UI + Tailwind 4 + Pest 4 | Alpha (v1.0.0-alpha.1+) |

## Versions

- **v1.0.0-alpha.1 (2026-05-17) — Phase A: Identity Rename** *(current)* — plugin renamed laravel-livewire-superpowers (cloned) → laravel-vue-superpowers; config paths updated; slash commands renamed; README + docs/banners rebranded. No content adaptation yet — agents/skills/hooks still from Livewire source.

See [CHANGELOG.md](CHANGELOG.md) for full history and [docs/superpowers/specs/2026-05-17-vue-fork-adaptation-design.md](docs/superpowers/specs/2026-05-17-vue-fork-adaptation-design.md) for the 5-phase adaptation roadmap.
```

(Adapt to actual structure — preserve any operator-specific conventions from the cloned README.)

### Task 9: Update `docs/agents.md` banner

**Files:** `docs/agents.md`

- [ ] **Step 1: Update banner at top**

Replace the existing stack-scope banner with:

```markdown
> **Stack:** Laravel + Vue 3 (Composition API) + Inertia v3 + Reka UI + Tailwind CSS 4 + Pest 4. For the Livewire 4 + Flux Pro v2 variant see the sibling plugin [`laravel-livewire-superpowers`](https://github.com/altraWeb/laravel-livewire-superpowers).
```

### Task 10: Update `docs/hooks.md` banner

**Files:** `docs/hooks.md`

- [ ] **Step 1:** Same pattern as Task 9 — banner replacement.

### Task 11: Update `docs/config.md` references

**Files:** `docs/config.md`

- [ ] **Step 1:** Find and replace plugin name + config path references throughout.

```bash
grep -n 'laravel-livewire-superpowers\|laravel-superpowers' docs/config.md
```

Update each occurrence. Live references → `laravel-vue-superpowers`. Drop V2-compat narrative (Vue fork has no V2 history).

---

## STEP A.5 — Roadmap, CHANGELOG, Archive

### Task 12: Rewrite `docs/ROADMAP.md` for Vue variant

**Files:** `docs/ROADMAP.md`

- [ ] **Step 1: Rewrite for Vue variant phase plan**

Use Write tool to replace with fresh Vue-variant roadmap covering V1.0.0-alpha cycle through stable:

```markdown
# laravel-vue-superpowers Roadmap

This roadmap tracks the V1.0.0 phased rollout — adaptation of the cloned-from-livewire repo into a functional Vue 3 + Inertia v3 + Reka UI + Tailwind 4 plugin.

## V1.0.0 (Vue Variant Megarelease)

5 phases analog to the Livewire variant V3 rollout. Per deep-research (`docs/superpowers/audits/2026-05-17-vue-fork-deep-research.md`), ~75% of Livewire-variant content carries over 1:1 or with cosmetic sub-checklist swaps.

### Phase A — Identity Rename (v1.0.0-alpha.1)

- [x] plugin.json + config paths + slash commands + README + banners renamed
- [x] CLONE_FORK_STATUS.md archived to docs/ARCHIVE/
- [x] Marketplace entry added (laravel-marketplace metadata.version 1.1.0 → 1.2.0)

### Phase B — Specialists + Anti-Pattern Hooks (v1.0.0-alpha.2)

- [ ] REMOVE laravel-livewire-specialist
- [ ] REPLACE laravel-flux-pro-specialist → laravel-reka-ui-specialist
- [ ] ADD laravel-inertia-specialist (Inertia v3 primary, v2 compat-note)
- [ ] ADD laravel-vue3-specialist (Composition API + script setup + TS)
- [ ] ADD 4 new anti-pattern hooks (setInterval-cleanup, reactive-destructure, Link-external-URL, hardcoded-routes)

### Phase C — Skill Sub-Section Swaps (v1.0.0-alpha.3)

- [ ] laravel-a11y-specialist: 3 patterns rewrite (4 dropped — Reka UI handles)
- [ ] laravel-code-review: §9 swap (Inertia/Vue) + §10 swap (Reka UI)
- [ ] laravel-debugging: Top-10 items #3 + #8 swap
- [ ] laravel-tdd: Pest-specifics items #3 + #8 swap

### Phase D — Hook Repurpose (v1.0.0-alpha.4)

- [ ] vendor-source-preflight RENAME + REWRITE → inertia-vendor-preflight
- [ ] lang-key-existence-preflight broaden trigger to .vue files

### Phase E — Release Polish + Stable Cut (v1.0.0 STABLE)

- [ ] Self-audit
- [ ] CHANGELOG consolidate
- [ ] v1.0.0 tag (stable)
- [ ] Marketplace bumps to 1.0.0

## Future ideas (post-v1.0.0)

- `laravel-wayfinder-specialist` agent (deferred from V1)
- `laravel-pinia-specialist` (if Pinia adoption grows)
- `laravel-ssr-specialist` (if SSR adoption decided)

Last updated: 2026-05-17
```

### Task 13: Initialize fresh `CHANGELOG.md`

**Files:**
- Move: `CHANGELOG.md` → `docs/ARCHIVE/CHANGELOG-from-livewire-source.md`
- Create: new `CHANGELOG.md` with `[1.0.0-alpha.1]` entry

- [ ] **Step 1: Archive old CHANGELOG**

```bash
mkdir -p docs/ARCHIVE
git mv CHANGELOG.md docs/ARCHIVE/CHANGELOG-from-livewire-source.md
```

- [ ] **Step 2: Create new CHANGELOG.md**

Use Write tool with content:

```markdown
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
- `docs/ROADMAP.md` rewritten for V1 Vue rollout
- 4 hook error messages reference new config filename

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

Phase A (this alpha) — ✅ shipped 2026-05-17 as v1.0.0-alpha.1.

Phases B-E remain.

---
```

### Task 14: Archive `CLONE_FORK_STATUS.md` + delete `UPGRADING.md`

**Files:**
- Move: `CLONE_FORK_STATUS.md` → `docs/ARCHIVE/CLONE_FORK_STATUS.md`
- Delete: `UPGRADING.md`

- [ ] **Step 1: Move CLONE_FORK_STATUS.md**

```bash
git mv CLONE_FORK_STATUS.md docs/ARCHIVE/CLONE_FORK_STATUS.md
```

- [ ] **Step 2: Delete UPGRADING.md**

```bash
git rm UPGRADING.md
```

---

## STEP A.6 — Update tests + verify

### Task 15: Update test fixtures to use Vue-named config paths

**Files:**
- Modify: `tests/test_config.py` (all fixture paths)
- Modify: `tests/test_hook_integration.sh` (fixture paths)
- Modify: `tests/conftest.py` (fixture path constants)

- [ ] **Step 1: Find references**

```bash
grep -nE 'laravel-superpowers|laravel-livewire' tests/test_config.py tests/test_hook_integration.sh tests/conftest.py
```

- [ ] **Step 2: Update each occurrence**

`laravel-superpowers` → `laravel-vue-superpowers` (in paths)
`.laravel-superpowers.yaml` → `.laravel-vue-superpowers.yaml` (in fixture file paths)

Use Edit per file with `replace_all: true` carefully scoped to fixture paths.

- [ ] **Step 3: Run tests**

```bash
python3 -m pytest tests/ -v
```

Expected: all 37 passed (or whatever the baseline count is — same green state). If failures, investigate.

### Task 16: Full test suite + manual sanity

- [ ] **Step 1: Shell hook test suite**

```bash
for t in tests/test_*.sh; do bash "$t" >/dev/null 2>&1 && echo "✓ $t" || echo "✗ $t  FAIL"; done
```

Expected: 17 shell tests ✓ (inherited baseline).

- [ ] **Step 2: Python config tests**

```bash
python3 -m pytest tests/ -q
```

Expected: 37 passed.

- [ ] **Step 3: Verify file inventory**

```bash
test -f .claude-plugin/plugin.json && echo "✓ plugin.json"
test -f .laravel-vue-superpowers.yaml && echo "✓ project config"
test ! -f .laravel-superpowers.yaml && echo "✓ old project config removed"
test -f docs/ARCHIVE/CLONE_FORK_STATUS.md && echo "✓ CLONE_FORK_STATUS archived"
test ! -f CLONE_FORK_STATUS.md && echo "✓ CLONE_FORK_STATUS removed from root"
test -f docs/ARCHIVE/CHANGELOG-from-livewire-source.md && echo "✓ old CHANGELOG archived"
test -f CHANGELOG.md && echo "✓ new CHANGELOG"
test ! -f UPGRADING.md && echo "✓ UPGRADING removed"
```

Expected: all 8 lines start with ✓.

---

## STEP A.7 — Commit, PR, post-merge tag

### Task 17: Commit Phase A changes

**Files:** All Phase A modifications staged.

- [ ] **Step 1: Review what will be committed**

```bash
git status
git diff --stat
```

- [ ] **Step 2: Stage all + commit**

```bash
git add -A
git -c commit.gpgsign=false commit -m "$(cat <<'EOF'
feat(v1): phase a — identity rename (laravel-livewire-superpowers clone → laravel-vue-superpowers)

Phase A of the V1 Vue-variant rollout. Identity rename end-to-end:

Plugin:
- plugin.json: name laravel-vue-superpowers, version 1.0.0-alpha.1
- description finalized for Vue 3 + Inertia v3 + Reka UI + Tailwind 4 stack

Config:
- lib/config.py paths: laravel-vue-superpowers (no V2-compat baggage since
  Vue fork has no V0 users)
- config.defaults.yaml header rewrites
- config.schema.json $id + title updated
- .laravel-superpowers.yaml renamed to .laravel-vue-superpowers.yaml
- 4 hook error messages reference new config filename

Slash commands:
- /laravel-livewire-superpowers:status → /laravel-vue-superpowers:status
- /laravel-livewire-superpowers:audit-phase → /laravel-vue-superpowers:audit-phase
- /laravel-livewire-superpowers:retro → /laravel-vue-superpowers:retro
- Renames applied to commands/, agents/, hooks/, skills/, README, docs/
  (NOT to docs/superpowers/specs|plans|audits|test-evidence/ which are
  historical Livewire-variant records preserving original references)

Docs:
- README full rewrite for Vue stack with alpha-status banner
- docs/agents.md + docs/hooks.md banners updated
- docs/config.md plugin-name references updated
- docs/pilot-2-0-contract.md slash command references updated
- docs/ROADMAP.md rewritten for V1 Vue rollout (5 phases)

Archived:
- CLONE_FORK_STATUS.md → docs/ARCHIVE/CLONE_FORK_STATUS.md
- old CHANGELOG.md (Livewire-source history) → docs/ARCHIVE/CHANGELOG-from-livewire-source.md
- UPGRADING.md deleted (Livewire V2→V3 migration, irrelevant for Vue fork)

Added:
- New CHANGELOG.md (this entry, fresh for Vue variant)

Test fixtures updated to Vue-named config paths.

No content adaptation in this phase — agents/skills/hooks still Livewire-
sourced. Adaptation in Phases B-E.

All 17 shell + 37 Python tests green.

Spec: docs/superpowers/specs/2026-05-17-vue-fork-adaptation-design.md
EOF
)" 2>&1 | tail -3
```

Expected: commit succeeds. If banned-token-leak-guard blocks because the message contains "Phase A" or "Pilot 2.0" — these are NOT prefixed with date so should pass. If it does block, read message and report.

### Task 18: Push + open PR

- [ ] **Step 1: Push branch**

```bash
git push -u origin feat/v1-phase-a-identity-rename
```

- [ ] **Step 2: Open PR**

```bash
gh pr create --base main --head feat/v1-phase-a-identity-rename --title "feat(v1): phase a — identity rename" --body "$(cat <<'EOF'
## Summary

Phase A of the V1 Vue-variant rollout. Identity rename only — see spec [`docs/superpowers/specs/2026-05-17-vue-fork-adaptation-design.md`](docs/superpowers/specs/2026-05-17-vue-fork-adaptation-design.md) Section 5 Phase A.

### Changed

- Plugin identity: laravel-livewire-superpowers (cloned) → laravel-vue-superpowers
- Plugin version 0.1.0-cloned-from-livewire-v3.0.0 → 1.0.0-alpha.1
- Config paths use Vue-named locations (no V2 compat)
- All 3 slash commands renamed
- README + docs/agents.md + docs/hooks.md + ROADMAP rewritten for Vue stack

### Archived / Removed

- CLONE_FORK_STATUS.md → docs/ARCHIVE/
- old CHANGELOG → docs/ARCHIVE/
- UPGRADING.md deleted (Livewire-only migration doc)

### Test plan

- [x] All 17 shell + 37 Python tests green
- [x] Config helper smoke-test (paths resolve correctly)
- [ ] Reviewer pulls branch and verifies no `/laravel-livewire-superpowers:` live references remain
- [ ] Reviewer verifies CLONE_FORK_STATUS archived, UPGRADING deleted

### After merge

- Cut v1.0.0-alpha.1 tag + GitHub Pre-Release
- Add Vue plugin entry to altraWeb/laravel-marketplace (metadata.version 1.1.0 → 1.2.0)
- Phase B planning starts
EOF
)" 2>&1 | tail -2
```

**STOP. Wait for operator merge.**

---

## STEP A.8 — Post-merge: tag + marketplace

### Task 19: Tag v1.0.0-alpha.1 + GitHub Pre-Release

- [ ] **Step 1: Pull merged main**

```bash
cd ~/dev/laravel-vue-superpowers
git switch main
git pull --ff-only origin main
git log --oneline -2
```

- [ ] **Step 2: Tag + push**

```bash
git tag -a v1.0.0-alpha.1 -m "v1.0.0-alpha.1 — V1 Vue Variant Phase A: Identity Rename"
git push origin v1.0.0-alpha.1
```

- [ ] **Step 3: GitHub Pre-Release**

```bash
gh release create v1.0.0-alpha.1 \
  --title "v1.0.0-alpha.1 — V1 Vue Variant Phase A: Identity Rename" \
  --prerelease \
  --notes "$(awk '/^## \[1\.0\.0-alpha\.1\]/{flag=1; next} /^---$/{if(flag){flag=0}} flag' CHANGELOG.md)"
```

Expected: pre-release URL returned.

### Task 20: Add Vue plugin to `altraWeb/laravel-marketplace`

**Files (in `~/dev/laravel-marketplace/`):**
- Modify: `.claude-plugin/marketplace.json` (add 2nd plugin entry)
- Modify: `README.md` (update Available plugins table)

- [ ] **Step 1: Switch to marketplace repo**

```bash
cd ~/dev/laravel-marketplace
git status
```

- [ ] **Step 2: Update marketplace.json**

Read current marketplace.json. Add 2nd plugin entry to `plugins` array:

```json
"plugins": [
    {
        "name": "laravel-livewire-superpowers",
        "source": "github:altraWeb/laravel-livewire-superpowers",
        "description": "Laravel + Livewire 4 + Flux Pro v2 + Pest 4 specialist toolkit: 10 agents, 7 skills, 12 hooks, 3 slash commands. Full Pilot 2.0 contract enforcement.",
        "version": "3.0.0",
        "keywords": ["laravel", "livewire", "flux-pro", "pest", "php", "tdd", "workflow", "code-review", "agents", "hooks"],
        "category": "productivity"
    },
    {
        "name": "laravel-vue-superpowers",
        "source": "github:altraWeb/laravel-vue-superpowers",
        "description": "Laravel + Vue 3 (Composition API) + Inertia v3 + Reka UI + Tailwind CSS 4 + Pest 4 specialist toolkit. ⚠️ Alpha — Phase A (identity rename) shipped; content adaptation in Phases B-E. Functional from v1.0.0-alpha.2 onwards.",
        "version": "1.0.0-alpha.1",
        "keywords": ["laravel", "vue", "vue3", "inertia", "inertia-v3", "reka-ui", "tailwind", "pest", "php", "tdd", "workflow", "code-review", "agents", "hooks", "specialist-agents"],
        "category": "productivity"
    }
]
```

Bump `metadata.version` from `1.1.0` to `1.2.0`.

- [ ] **Step 3: Update marketplace README**

Update the Available plugins table to include the Vue row.

- [ ] **Step 4: Commit + push**

```bash
git add -A
git -c commit.gpgsign=false commit -m "chore: add laravel-vue-superpowers plugin entry (v1.0.0-alpha.1)

Vue fork ships Phase A (identity rename). Plugin added to marketplace
with alpha status note in description. Marketplace metadata.version
bumped 1.1.0 → 1.2.0 (meaningful change: 2nd plugin listed)."
git push origin main
```

### Task 21: Report Phase A completion

State to operator:

"Phase A complete. v1.0.0-alpha.1 pre-released at <URL>. Vue plugin now in marketplace. Ready for Phase B (specialists + 4 anti-pattern hooks) when you give the go."

**STOP. Phase A complete.**
