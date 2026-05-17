# V3 Phase A — Foundation, Deprecation, Rename — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Land Phase A of the V3 Megarelease — cut a v2.0.2 deprecation release on the still-named repo, then rename to `laravel-livewire-superpowers`, restructure the marketplace into a neutral host repo, update all branding, and ship the foundation that unblocks Phases B–G.

**Architecture:** Two-step phase to preserve V2 users' upgrade path. Step A.1 ships a no-code-change v2.0.2 release whose only delta is a CHANGELOG entry pointing to the coming V3 + new name + new marketplace — this notice lands on the existing `altraweb-laravel` marketplace BEFORE the GitHub rename so V2 users see it through their current install. Step A.2 then performs the GitHub repo rename, creates the neutral `altraWeb/laravel-marketplace` host repo, updates all `/laravel-superpowers:*` slash-command paths to `/laravel-livewire-superpowers:*`, rebrands README/agents.md/hooks.md as the Livewire variant, writes UPGRADING.md, and cleans up 18 stale branches. All Phase A.2 changes ship as a single feature-branch PR (`feat/v3-phase-a-foundation`).

**Tech Stack:** Bash + git + gh CLI + Python 3 (pytest + jsonschema) for marketplace validation test. No application-runtime code in this phase.

**Spec:** `docs/superpowers/specs/2026-05-17-v3-livewire-megarelease-design.md`

---

## File Structure

### Step A.1 (v2.0.2 deprecation cut on still-named repo)

| File | Action | Purpose |
|---|---|---|
| `CHANGELOG.md` | Modify | Prepend `## [2.0.2]` section with deprecation notice |
| `.claude-plugin/plugin.json` | Modify line 3 | `"version": "2.0.1"` → `"version": "2.0.2"` |
| `.claude-plugin/marketplace.json` | Modify lines 9 + 16 | `"version": "2.0.0"` → `"version": "2.0.2"` (metadata + plugin entry) |

### Step A.2 (rename + foundation + marketplace + branding + cleanup)

| File | Action | Purpose |
|---|---|---|
| `.claude-plugin/plugin.json` | Modify | `name`, `description`, `version` → `3.0.0-alpha.1`; description marks Livewire stack explicitly |
| `.claude-plugin/marketplace.json` | Delete | Marketplace moves to neutral host repo |
| `commands/status.md` | Modify | Internal slash-command refs `/laravel-superpowers:` → `/laravel-livewire-superpowers:` |
| `README.md` | Rewrite | Stack-explicit Livewire branding, new install URL, link to new marketplace |
| `docs/agents.md` | Modify | Mark plugin as Livewire variant in header |
| `docs/hooks.md` | Modify | Mark plugin as Livewire variant in header |
| `UPGRADING.md` | Create | V2 → V3 migration steps |
| `CHANGELOG.md` | Modify | Prepend `## [3.0.0-alpha.1]` section |
| `tests/test_marketplace_json.py` | Create | Schema validation for marketplace.json (will live on in repo for future marketplace edits) |
| External: `altraWeb/laravel-marketplace` repo | Create | New neutral marketplace host repo with `.claude-plugin/marketplace.json` + `README.md` |
| External: 16 remote branches | Delete | Already-merged feat/* + spec/* + chore/* branches |
| External: 2 local branches | Delete | feat/17-no-claude-attribution-hook + spec/3-flux-pro-specialist-agent |
| External: GitHub repo rename | Action | `altraWeb/laravel-superpowers` → `altraWeb/laravel-livewire-superpowers` |
| External: Local directory rename | Action | `~/dev/laravel-superpowers/` → `~/dev/laravel-livewire-superpowers/` |

---

## STEP A.1 — v2.0.2 Deprecation Cut (BEFORE rename)

The v2.0.2 release ships on the still-named repo so V2 users on the existing `altraweb-laravel` marketplace get a deprecation notice through their current install. **Do not start Step A.2 until v2.0.2 is tagged AND released on GitHub.**

### Task 1: Pre-flight checks

**Files:** None (read-only verification).

- [ ] **Step 1: Verify clean working tree on main, in sync with origin**

```bash
cd ~/dev/laravel-superpowers
git status
git log --oneline -3
git rev-list --left-right --count origin/main..HEAD
```

Expected output of `git status`:
```
On branch main
Your branch is up to date with 'origin/main'.

nothing to commit, working tree clean
```

Expected output of `git log --oneline -3` (current `HEAD` at `550624a`):
```
550624a fix: V2.0.1 self-audit hotfix — quote-bypass, date false-positives, composer-test, command-position filter (#50)
6b5584e chore: bump to v2.0.0 — V2-MVP release (#49)
43c8a80 feat(#20): brainstorm-t1-audit PostToolUse hook + tests + docs (5/5 pass) (#48)
```

Expected output of `git rev-list ... ..HEAD`: `0 0` (no divergence).

If working tree is dirty or branch is ahead of origin/main, STOP and reconcile before proceeding.

- [ ] **Step 2: Verify v2.0.1 tag exists and matches HEAD**

```bash
git tag --list | grep '^v2\.'
git rev-list -n 1 v2.0.1
git rev-parse HEAD
```

Expected: `v2.0.1` appears in tag list. The SHA from `git rev-list -n 1 v2.0.1` matches `git rev-parse HEAD` (both should be `550624a...`).

If `v2.0.1` tag does not exist, STOP — Phase A.1 assumes v2.0.1 is already released.

- [ ] **Step 3: Run full test suite, confirm green baseline**

```bash
for t in tests/test_*.sh; do bash "$t" >/dev/null 2>&1 && echo "✓ $t" || echo "✗ $t"; done
python3 -m pytest tests/test_config.py -q
```

Expected: All 7 shell tests prefixed with `✓`. Pytest output ends with `23 passed`.

If anything fails, STOP and investigate before proceeding — Phase A starts from a known-green baseline.

### Task 2: Add v2.0.2 deprecation CHANGELOG entry

**Files:**
- Modify: `CHANGELOG.md` (prepend new section above existing `## [2.0.1]` line)

- [ ] **Step 1: Read current CHANGELOG header to confirm format**

```bash
head -10 CHANGELOG.md
```

Expected: Starts with `# Changelog`, then blank line, then format/SemVer paragraph, then blank line, then `## [2.0.1] — ...`.

- [ ] **Step 2: Insert v2.0.2 deprecation section above the v2.0.1 section**

Use the Edit tool to insert the following block immediately before the line `## [2.0.1] — 2026-05-15 — V2-MVP self-audit hotfix`:

```markdown
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

```

(Note the trailing `---` separator line that visually separates v2.0.2 from v2.0.1 — match the existing convention used between v2.0.1 and v2.0.0.)

- [ ] **Step 3: Verify the insertion is clean**

```bash
head -50 CHANGELOG.md
```

Expected: `# Changelog` header, format paragraph, then the new `## [2.0.2] — 2026-05-17 — Deprecation notice...` section starts at the top of the version list, followed by `---`, then the unchanged `## [2.0.1] — 2026-05-15 — V2-MVP self-audit hotfix` section.

### Task 3: Bump version in plugin.json and marketplace.json

**Files:**
- Modify: `.claude-plugin/plugin.json:3` (version field)
- Modify: `.claude-plugin/marketplace.json:9` (metadata.version) and `.claude-plugin/marketplace.json:16` (plugins[0].version)

- [ ] **Step 1: Bump `.claude-plugin/plugin.json` version 2.0.1 → 2.0.2**

Use the Edit tool with:
- `old_string`: `"version": "2.0.1"`
- `new_string`: `"version": "2.0.2"`

- [ ] **Step 2: Verify plugin.json is still valid JSON**

```bash
python3 -c 'import json; print(json.load(open(".claude-plugin/plugin.json"))["version"])'
```

Expected output: `2.0.2`

- [ ] **Step 3: Bump `.claude-plugin/marketplace.json` metadata.version 2.0.0 → 2.0.2**

Use the Edit tool with:
- `old_string`: `"version": "2.0.0"`
- `new_string`: `"version": "2.0.2"`

Note: there are TWO occurrences of `"version": "2.0.0"` in this file — one in metadata (line 9) and one in plugins[0] (line 16). Run Edit with `replace_all: true` to bump both.

- [ ] **Step 4: Verify marketplace.json is still valid JSON and both versions are now 2.0.2**

```bash
python3 -c 'import json; m = json.load(open(".claude-plugin/marketplace.json")); print(m["metadata"]["version"], m["plugins"][0]["version"])'
```

Expected output: `2.0.2 2.0.2`

### Task 4: Commit v2.0.2 deprecation release

**Files:** All modified files staged.

- [ ] **Step 1: Run full test suite again, confirm still green**

```bash
for t in tests/test_*.sh; do bash "$t" >/dev/null 2>&1 && echo "✓ $t" || echo "✗ $t"; done
python3 -m pytest tests/test_config.py -q
```

Expected: All 7 shell tests `✓`. Pytest `23 passed`.

- [ ] **Step 2: Stage the three modified files**

```bash
git add CHANGELOG.md .claude-plugin/plugin.json .claude-plugin/marketplace.json
git status
```

Expected `git status` shows exactly these three files staged.

- [ ] **Step 3: Commit with deprecation notice message**

Note: this commit must land on `main` directly (this is a release-cut commit equivalent to the v2.0.0 release commit `6b5584e`). The auto-mode classifier may block direct push to main; if it does, the operator authorizes this specific release-cut commit-and-push manually.

```bash
git commit -m "$(cat <<'EOF'
chore(v2.0.2): deprecation notice — V3 megarelease coming under new name

V2.0.2 ships with no code changes. Only deltas:
- CHANGELOG entry announcing the V3 megarelease + plugin rename
  (laravel-superpowers → laravel-livewire-superpowers) + marketplace
  move to neutral host repo (altraWeb/laravel-marketplace).
- plugin.json + marketplace.json version 2.0.1 → 2.0.2.

Purpose: ensure V2 users on the existing altraweb-laravel marketplace
see the deprecation notice through their current install BEFORE the
GitHub repo rename in Phase A.2 of the V3 megarelease.

Design spec: docs/superpowers/specs/2026-05-17-v3-livewire-megarelease-design.md
EOF
)"
```

Expected: Commit succeeds, no hook blocks. (`banned-token-leak-guard` should pass because dated patterns inside `docs/` paths are documentation, not code; `no-claude-attribution` should pass because the message has no Claude attribution.)

If a hook blocks, READ THE BLOCK REASON CAREFULLY and adjust — do not bypass with `--no-verify`.

- [ ] **Step 4: Verify the commit landed correctly**

```bash
git log --oneline -2
git show --stat HEAD
```

Expected: HEAD is the new v2.0.2 commit, parent is `550624a` (v2.0.1). `git show --stat` shows exactly 3 files changed (CHANGELOG.md ~30 insertions, plugin.json 1 insertion 1 deletion, marketplace.json 2 insertions 2 deletions).

### Task 5: Tag and push v2.0.2

**Files:** None (git operations only).

- [ ] **Step 1: Create signed annotated tag v2.0.2**

```bash
git tag -a v2.0.2 -m "v2.0.2 — Deprecation notice: V3 megarelease coming under new name (laravel-livewire-superpowers)"
git tag --list | grep '^v2\.'
```

Expected: `v2.0.0`, `v2.0.1`, `v2.0.2` all listed.

- [ ] **Step 2: Push main + tag to origin**

```bash
git push origin main
git push origin v2.0.2
```

Expected: Both pushes succeed. If `git push origin main` is blocked by the auto-mode classifier, the operator must explicitly authorize this release-cut push (it is intentional and consistent with the v2.0.0 release pattern where chore commits also went directly to main as part of release cuts).

- [ ] **Step 3: Verify origin is up to date**

```bash
git fetch origin
git log origin/main --oneline -2
```

Expected: `origin/main` HEAD is the v2.0.2 commit just pushed.

### Task 6: Create GitHub Release for v2.0.2

**Files:** None (gh CLI operation only).

- [ ] **Step 1: Create the GitHub Release with full CHANGELOG section as body**

```bash
gh release create v2.0.2 \
  --title "v2.0.2 — Deprecation notice: V3 megarelease coming" \
  --notes "$(cat <<'EOF'
**No code changes.** This release exists solely to give V2 users on the existing `altraweb-laravel` marketplace advance notice of the V3 Megarelease, which ships under a renamed plugin and a new neutral marketplace host repo.

## Coming in V3

- **Plugin renamed** `laravel-superpowers` → `laravel-livewire-superpowers` to make the Livewire 4 + Flux Pro v2 stack scope explicit (a sibling `laravel-vue-superpowers` for Vue 3 + Inertia projects is planned next).
- **Marketplace moved** to a new neutral host repo `altraWeb/laravel-marketplace`. The existing `altraweb-laravel` marketplace (currently bundled inside this plugin repo) will be deprecated.
- **Scope:** all 14 open Tier-2 + Tier-3 backlog issues land in V3, plus full Pilot 2.0 contract enforcement via the new `laravel-pilot-orchestrator` agent and `pilot-2-contract-enforcer` hook.

## Migration (when V3 ships)

```bash
claude /plugin uninstall laravel-superpowers
claude /plugin marketplace remove altraweb-laravel
claude /plugin marketplace add altraWeb/laravel-marketplace
claude /plugin install laravel-livewire-superpowers@altraweb-laravel
```

A full `UPGRADING.md` will ship with V3.

## No breaking changes in this release

v2.0.2 is byte-identical to v2.0.1 except for the CHANGELOG entry and the version bump in `plugin.json` + `marketplace.json`. All hooks, agents, skills, and the `/laravel-livewire-superpowers:status` slash command continue to behave exactly as in v2.0.1.

## Design spec

The full V3 design lands on the renamed repo at `docs/superpowers/specs/2026-05-17-v3-livewire-megarelease-design.md`.
EOF
)"
```

Expected: gh CLI returns the release URL (https://github.com/altraWeb/laravel-superpowers/releases/tag/v2.0.2).

- [ ] **Step 2: Verify the release appears in the GitHub UI**

```bash
gh release view v2.0.2
```

Expected: Release shows title "v2.0.2 — Deprecation notice: V3 megarelease coming", body matches the notes above.

**Step A.1 complete.** V2 users on the existing marketplace now see the deprecation notice through their current install. Safe to proceed to Step A.2.

---

## STEP A.2 — Rename + Foundation + Marketplace + Branding

This step performs the GitHub repo rename, creates the new neutral marketplace host repo, updates all internal slash-command paths, rebrands README/docs/agents.md/hooks.md as the Livewire variant, writes UPGRADING.md, and cleans up 18 stale branches. All changes ship as a single feature-branch PR.

### Task 7: Clean up 18 stale branches

**Files:** None (git operations only).

This task is grouped with the rename because doing it before the rename means the deletions land on the still-named remote (slightly cleaner audit trail).

- [ ] **Step 1: Verify that each branch to be deleted is fully merged into main**

```bash
cd ~/dev/laravel-superpowers
git fetch --all --prune
for b in chore/gitignore-ide chore/v2-mvp-release-prep \
         feat/13-laravel-tdd-pest4-enhancement feat/14-laravel-code-review-stack-sub-checklists \
         feat/15-laravel-debugging-red-recipes feat/16-banned-token-leak-guard-hook \
         feat/17-no-claude-attribution-hook feat/18-teamcity-always-hook \
         feat/19-anti-silent-deferral-hook feat/20-brainstorm-t1-audit-hook \
         feat/21-visual-companion-default-on-hook feat/23-status-slash-command \
         spec/1-livewire-specialist-agent spec/2-pest-specialist-agent \
         spec/3-flux-pro-specialist-agent spec/4-laravel-architect-agent \
         spec/5-laravel-reviewer-agent; do
  if git merge-base --is-ancestor "origin/$b" origin/main 2>/dev/null; then
    echo "✓ merged: $b"
  else
    echo "✗ NOT MERGED: $b  ← DO NOT DELETE without manual review"
  fi
done
```

Expected: All 17 lines prefixed with `✓ merged`. If any show `✗ NOT MERGED`, STOP and investigate before proceeding.

- [ ] **Step 2: Delete all 17 stale remote branches**

```bash
for b in chore/gitignore-ide chore/v2-mvp-release-prep \
         feat/13-laravel-tdd-pest4-enhancement feat/14-laravel-code-review-stack-sub-checklists \
         feat/15-laravel-debugging-red-recipes feat/16-banned-token-leak-guard-hook \
         feat/17-no-claude-attribution-hook feat/18-teamcity-always-hook \
         feat/19-anti-silent-deferral-hook feat/20-brainstorm-t1-audit-hook \
         feat/21-visual-companion-default-on-hook feat/23-status-slash-command \
         spec/1-livewire-specialist-agent spec/2-pest-specialist-agent \
         spec/3-flux-pro-specialist-agent spec/4-laravel-architect-agent \
         spec/5-laravel-reviewer-agent; do
  git push origin --delete "$b"
done
```

Note: `origin/docs/v3-megarelease-spec` is NOT in this list — it has an open PR (#51) and must be preserved.

Expected: Each delete prints `- [deleted]   <branch>`. If the auto-mode classifier blocks bulk remote branch deletion, the operator must explicitly authorize this batch cleanup (all branches verified merged in Step 1).

- [ ] **Step 3: Delete 2 stale local branches**

```bash
git branch -d feat/17-no-claude-attribution-hook
git branch -d spec/3-flux-pro-specialist-agent
git branch
```

Expected output of `git branch`: only `main` and `docs/v3-megarelease-spec` remain.

If `git branch -d` refuses because a branch is "not fully merged" (it is, but locally diverged), use `git branch -D` after confirming via `git log <branch> --not main` that the unique commits are already on `main` under different SHAs (squash-merged PRs).

- [ ] **Step 4: Verify the cleanup**

```bash
git fetch --all --prune
git branch -a
```

Expected: Only `main`, `docs/v3-megarelease-spec`, `origin/main`, `origin/docs/v3-megarelease-spec`, and `origin/HEAD -> origin/main` remain. No stale branches.

### Task 8: (moved) Marketplace host repo creation deferred to post-merge Task 23

The neutral marketplace host repo `altraWeb/laravel-marketplace` can only sensibly point at a published `v3.0.0-alpha.1` tag — if it points at a non-existent tag the `claude /plugin install` command fails. Creating the marketplace before the tag would either:
- ship a marketplace with a broken `source` reference, or
- require referencing the old `v2.0.2` (which has the old plugin name and would not work post-rename), or
- temporarily point at a branch (non-standard and breaks the install version contract).

**Resolution:** Marketplace creation moves to **Task 23 (post-merge, post-tag)** below. All in-repo Phase A.2 work proceeds first; the alpha tag gets cut after merge; THEN the marketplace repo is created pointing at the freshly-published tag.

Skip directly to Task 9.

### Task 9: GitHub repo rename + local directory rename

**Files:** None (gh CLI + filesystem operation).

**Operator confirmation required** — this is a destructive rename even though GitHub maintains the URL redirect indefinitely.

- [ ] **Step 1: Confirm with operator**

State to the operator: "About to rename GitHub repo `altraWeb/laravel-superpowers` → `altraWeb/laravel-livewire-superpowers` and the local directory `~/dev/laravel-superpowers/` → `~/dev/laravel-livewire-superpowers/`. GitHub maintains the redirect indefinitely so all existing URLs continue to work. Proceed?"

Wait for explicit OK before proceeding.

- [ ] **Step 2: Rename the GitHub repo**

```bash
gh repo rename --repo altraWeb/laravel-superpowers laravel-livewire-superpowers --yes
```

Expected output: `https://github.com/altraWeb/laravel-livewire-superpowers`

- [ ] **Step 3: Verify the rename**

```bash
gh repo view altraWeb/laravel-livewire-superpowers --json name,url
gh repo view altraWeb/laravel-superpowers --json name,url 2>&1 | head -5
```

Expected: First call returns `{"name":"laravel-livewire-superpowers", "url":"https://github.com/altraWeb/laravel-livewire-superpowers"}`. Second call either redirects to the same response, or returns it directly via GitHub's redirect.

- [ ] **Step 4: Rename the local working directory**

```bash
cd ~/dev
mv laravel-superpowers laravel-livewire-superpowers
cd laravel-livewire-superpowers
pwd
```

Expected: `/Users/altrano/dev/laravel-livewire-superpowers`

- [ ] **Step 5: Update local remote URL to match the renamed remote**

```bash
git remote set-url origin git@github.com:altraWeb/laravel-livewire-superpowers.git
git remote -v
```

Expected: Both `fetch` and `push` URLs show `git@github.com:altraWeb/laravel-livewire-superpowers.git`.

If the previous URL used HTTPS (`https://github.com/altraWeb/laravel-superpowers.git`), use the HTTPS form for the new URL too — match the existing protocol:

```bash
# Check old URL format first
git remote get-url origin
# Then use matching protocol for new URL
```

- [ ] **Step 6: Verify fetch + push round-trip works under the new URL**

```bash
git fetch --all
git status
```

Expected: `git fetch` succeeds (no auth errors). `git status` confirms we're on `main` with no divergence.

### Task 10: Create feature branch for Phase A.2 changes

**Files:** None (git branch operation).

All subsequent Phase A.2 changes accumulate on this branch and ship as one PR.

- [ ] **Step 1: Create and check out `feat/v3-phase-a-foundation`**

```bash
git switch -c feat/v3-phase-a-foundation
git branch
```

Expected: `* feat/v3-phase-a-foundation` is the current branch, alongside `main` and `docs/v3-megarelease-spec`.

### Task 11: Update plugin.json (name + description + version)

**Files:**
- Modify: `.claude-plugin/plugin.json` (all fields)

- [ ] **Step 1: Read the current plugin.json**

```bash
cat .claude-plugin/plugin.json
```

Expected: The v2.0.2 content from Step A.1 — name `laravel-superpowers`, version `2.0.2`, the long v2-era description.

- [ ] **Step 2: Rewrite plugin.json with V3 metadata**

Use the Write tool to replace `.claude-plugin/plugin.json` with:

```json
{
    "name": "laravel-livewire-superpowers",
    "version": "3.0.0-alpha.1",
    "description": "Laravel + Livewire 4 + Flux Pro v2 + Pest 4 specialist toolkit for Claude Code. 10 agents (livewire / pest / flux-pro / architect / reviewer / best-practices / echo-reverb / spatie-permission-auditor / pilot-orchestrator / package-evaluator), 7 skills (TDD / debugging / code-review / brainstorming / a11y / mr-body-writer / perf-auditor), 13 hooks (banned-token / no-Claude-attribution / teamcity-always / anti-silent-deferral / visual-companion-default-on / brainstorm-T1-audit / sprint-state-context-injection / master-roadmap-drift-detector / stale-branch-sweep / vendor-source-preflight / lang-key-existence-preflight / pilot-2-contract-enforcer), 3 slash commands (status / audit-phase / retro). Full Pilot 2.0 contract enforcement (T1-T6).",
    "author": {
        "name": "altraWeb"
    },
    "keywords": ["laravel", "livewire", "flux-pro", "pest", "php", "tdd", "workflow", "code-review", "agents", "hooks", "specialist-agents", "pilot-2.0"]
}
```

- [ ] **Step 3: Validate the new plugin.json**

```bash
python3 -c 'import json; p = json.load(open(".claude-plugin/plugin.json")); print(p["name"], p["version"])'
```

Expected output: `laravel-livewire-superpowers 3.0.0-alpha.1`

### Task 12: Delete the in-repo marketplace.json

**Files:**
- Delete: `.claude-plugin/marketplace.json`

The marketplace has moved to `altraWeb/laravel-marketplace`. The in-repo file is now obsolete.

- [ ] **Step 1: Delete the file via git rm**

```bash
git rm .claude-plugin/marketplace.json
```

Expected: `rm '.claude-plugin/marketplace.json'`. Confirm with `ls .claude-plugin/` — only `plugin.json` should remain.

### Task 13: Write the test_marketplace_json.py validation test

**Files:**
- Create: `tests/test_marketplace_json.py`

This test ensures the in-repo `plugin.json` is structurally valid and (in future PRs) can be extended to validate the external marketplace.json shape.

- [ ] **Step 1: Write the failing test first (TDD)**

Use the Write tool to create `tests/test_marketplace_json.py` with:

```python
"""Schema validation for plugin.json and marketplace.json.

The in-repo plugin.json must always be valid + match v3+ shape.
The external marketplace.json (in altraWeb/laravel-marketplace) is
validated in CI on that repo; this test only asserts the local
plugin.json conforms.
"""

import json
import pathlib

import pytest

PLUGIN_DIR = pathlib.Path(__file__).parent.parent / ".claude-plugin"


def test_plugin_json_is_valid_json():
    """plugin.json parses as JSON."""
    data = json.loads((PLUGIN_DIR / "plugin.json").read_text())
    assert isinstance(data, dict)


def test_plugin_json_has_required_fields():
    """plugin.json has name + version + description + author + keywords."""
    data = json.loads((PLUGIN_DIR / "plugin.json").read_text())
    for field in ("name", "version", "description", "author", "keywords"):
        assert field in data, f"missing field: {field}"


def test_plugin_json_name_is_livewire_stack():
    """V3 plugin name explicitly identifies Livewire stack."""
    data = json.loads((PLUGIN_DIR / "plugin.json").read_text())
    assert data["name"] == "laravel-livewire-superpowers"


def test_plugin_json_version_is_semver():
    """version field is semver (X.Y.Z or X.Y.Z-prerelease)."""
    import re
    data = json.loads((PLUGIN_DIR / "plugin.json").read_text())
    pattern = r"^\d+\.\d+\.\d+(-[a-zA-Z0-9.]+)?$"
    assert re.match(pattern, data["version"]), f"not semver: {data['version']}"


def test_in_repo_marketplace_json_removed():
    """In V3 the marketplace lives in altraWeb/laravel-marketplace, not in-repo."""
    assert not (PLUGIN_DIR / "marketplace.json").exists(), \
        ".claude-plugin/marketplace.json should be removed in V3 — marketplace moved to altraWeb/laravel-marketplace"
```

- [ ] **Step 2: Run the test, confirm it passes (the implementation already exists from Tasks 11 + 12)**

```bash
python3 -m pytest tests/test_marketplace_json.py -v
```

Expected: All 5 tests pass.

- [ ] **Step 3: If any test fails, fix the plugin.json or marketplace.json state and re-run**

Common failure modes:
- `test_plugin_json_name_is_livewire_stack` fails → re-do Task 11 Step 2
- `test_in_repo_marketplace_json_removed` fails → re-do Task 12 Step 1
- `test_plugin_json_version_is_semver` fails → check for typo in version string

### Task 14: Find and replace all `/laravel-superpowers:` slash-command path refs

**Files:**
- Modify: All files containing the literal string `/laravel-superpowers:` (slash-prefix, colon-suffix matters — narrow match to avoid hitting plain `laravel-superpowers` in docs prose)

- [ ] **Step 1: List all files containing the old slash-command prefix**

```bash
grep -rln '/laravel-superpowers:' --include='*.md' --include='*.sh' --include='*.py' --include='*.yaml' --include='*.json' .
```

Expected output: a handful of files including `commands/status.md`, possibly `docs/agents.md`, `docs/hooks.md`, `README.md`, and any hook scripts that emit slash-command refs.

- [ ] **Step 2: For each listed file, use the Edit tool with `replace_all: true`**

For each file, run an Edit with:
- `old_string`: `/laravel-superpowers:`
- `new_string`: `/laravel-livewire-superpowers:`
- `replace_all`: `true`

Do not use a bulk `sed -i` — the Edit tool is preferred per project tool conventions and gives per-file diff visibility.

- [ ] **Step 3: Verify no `/laravel-superpowers:` references remain**

```bash
grep -rln '/laravel-superpowers:' --include='*.md' --include='*.sh' --include='*.py' --include='*.yaml' --include='*.json' .
```

Expected: empty output (no matches).

- [ ] **Step 4: Run the full test suite to catch any breakage**

```bash
for t in tests/test_*.sh; do bash "$t" >/dev/null 2>&1 && echo "✓ $t" || echo "✗ $t"; done
python3 -m pytest tests/ -q
```

Expected: All shell tests `✓`. Pytest: 28 passed (23 old + 5 new from `test_marketplace_json.py`).

### Task 15: Rewrite README.md with Livewire stack branding

**Files:**
- Modify: `README.md` (full rewrite)

- [ ] **Step 1: Read the current README to understand existing structure**

```bash
head -80 README.md
```

Note key sections (title, install instructions, feature list, Versions section, links) so the rewrite preserves them.

- [ ] **Step 2: Rewrite README.md**

Use the Write tool to produce a new `README.md` that:

1. Title becomes `# laravel-livewire-superpowers`
2. Subtitle / tagline calls out the Livewire 4 + Flux Pro v2 + Pest 4 stack explicitly
3. Install instructions use the new marketplace:
   ```bash
   claude /plugin marketplace add altraWeb/laravel-marketplace
   claude /plugin install laravel-livewire-superpowers@altraweb-laravel
   ```
4. A "Related plugins" or "Sibling variants" section mentions the future `laravel-vue-superpowers` (status: planned)
5. Version table updated: `v3.0.0-alpha.1` current, link to CHANGELOG for full history
6. Migrating from v2: brief paragraph pointing to `UPGRADING.md`
7. All existing feature lists (agents / skills / hooks / commands) updated to V3 counts: 10 agents / 7 skills / 13 hooks / 3 commands
8. All `/laravel-livewire-superpowers:` refs already updated by Task 14

Preserve the existing section anchors and link conventions so external bookmarks from V2-era blog posts continue to resolve to roughly equivalent content.

- [ ] **Step 3: Verify no `/laravel-livewire-superpowers:` slipped back in**

```bash
grep -c '/laravel-livewire-superpowers:' README.md
grep -c '/laravel-livewire-superpowers:' README.md
```

Expected: `0` for the first, ≥1 for the second.

### Task 16: Update docs/agents.md stack-explicit header

**Files:**
- Modify: `docs/agents.md` (header section only)

- [ ] **Step 1: Read current header**

```bash
head -20 docs/agents.md
```

- [ ] **Step 2: Edit the header to add a stack-scope banner**

Use Edit tool to insert (or modify the existing tagline into) a banner at the top of the file:

```markdown
> **Stack:** Laravel + Livewire 4 + Flux Pro v2 + Pest 4. For the Vue 3 + Inertia v2 variant see the planned sibling plugin [`laravel-vue-superpowers`](https://github.com/altraWeb/laravel-vue-superpowers).
```

Place this banner immediately after the `# Agents` title and before the existing intro paragraph.

- [ ] **Step 3: Verify the change**

```bash
head -10 docs/agents.md
```

Expected: Title + the new stack-scope banner blockquote + the original intro paragraph.

### Task 17: Update docs/hooks.md stack-explicit header

**Files:**
- Modify: `docs/hooks.md` (header section only)

Same pattern as Task 16, applied to `docs/hooks.md`.

- [ ] **Step 1: Read current header**

```bash
head -20 docs/hooks.md
```

- [ ] **Step 2: Insert the same stack-scope banner immediately after the title**

```markdown
> **Stack:** Laravel + Livewire 4 + Flux Pro v2 + Pest 4. For the Vue 3 + Inertia v2 variant see the planned sibling plugin [`laravel-vue-superpowers`](https://github.com/altraWeb/laravel-vue-superpowers).
```

- [ ] **Step 3: Verify**

```bash
head -10 docs/hooks.md
```

### Task 18: Write UPGRADING.md

**Files:**
- Create: `UPGRADING.md` (new file at repo root)

- [ ] **Step 1: Write the migration guide**

Use the Write tool to create `UPGRADING.md` with:

````markdown
# UPGRADING

## V2 → V3

V3 is a major release that renames the plugin and moves the marketplace to a neutral host repo. The plugin functionality is fully backward compatible — only the install URL changes.

### What changed

- **Plugin name:** `laravel-superpowers` → `laravel-livewire-superpowers`
- **Marketplace:** moved from inside the plugin repo to a new neutral host repo `altraWeb/laravel-marketplace`
- **Slash commands:** `/laravel-superpowers:*` → `/laravel-livewire-superpowers:*`
- **No config schema changes** — your `~/.claude/plugins/altraweb-laravel/laravel-superpowers/config.yaml` (if any) continues to apply unchanged after migration

### Why

The plugin was always implicitly Livewire 4 + Flux Pro v2 focused. With a Vue 3 + Inertia v2 sibling plugin (`laravel-vue-superpowers`) now planned, the rename makes the stack scope explicit and the two variants symmetric.

### Migration steps

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

### Updating muscle memory

Replace any habitual `/laravel-superpowers:status` invocations with `/laravel-livewire-superpowers:status`. The plugin name in CLAUDE.md files, project notes, or shell history that referenced `laravel-superpowers` should be updated to `laravel-livewire-superpowers` (no functional break — just hygiene).

### Verifying the migration

After the four steps above, run:

```bash
claude /laravel-livewire-superpowers:status
```

Expected: `/status` panel renders cleanly with current sprint state. If the slash command is "not found", the install step did not complete — re-run step 4.

### Troubleshooting

- **Marketplace `altraweb-laravel` already exists after the remove step.** The marketplace name `altraweb-laravel` is reused intentionally by the new host repo. After `marketplace remove altraweb-laravel + marketplace add altraWeb/laravel-marketplace`, the marketplace re-registers under the same name but pointing at the new repo.
- **Old `claude /laravel-superpowers:status` still works.** This means the V2 plugin is still installed in parallel. Run `claude /plugin list` to confirm and `claude /plugin uninstall laravel-superpowers` to remove.
- **Config not applied to V3 plugin.** The config helper reads `~/.claude/plugins/altraweb-laravel/laravel-superpowers/config.yaml` — V3 keeps the V2 plugin name in the path for backward compatibility (see design spec section 8). If your config seems ignored, run `python3 lib/config.py doctor` to diagnose.
````

### Task 19: Prepend v3.0.0-alpha.1 entry to CHANGELOG.md

**Files:**
- Modify: `CHANGELOG.md` (prepend new section above the v2.0.2 section from Step A.1)

- [ ] **Step 1: Insert v3.0.0-alpha.1 section at the top of the version list**

Use the Edit tool to insert immediately before the line `## [2.0.2] — 2026-05-17 — Deprecation notice...`:

```markdown
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

```

(Match the existing `---` separator convention between version sections.)

- [ ] **Step 2: Verify the insertion**

```bash
head -80 CHANGELOG.md
```

Expected: `# Changelog` header, format paragraph, then the new `## [3.0.0-alpha.1] — 2026-05-17 — V3 Megarelease — Phase A...` section at top, followed by `## [2.0.2]`, then `## [2.0.1]`, etc.

### Task 20: Run all tests + manual smoke check

**Files:** None (verification only).

- [ ] **Step 1: Run all shell hook tests**

```bash
for t in tests/test_*.sh; do bash "$t" >/dev/null 2>&1 && echo "✓ $t" || echo "✗ $t  FAIL"; done
```

Expected: All 7 shell tests `✓`.

- [ ] **Step 2: Run all Python tests**

```bash
python3 -m pytest tests/ -v
```

Expected: 28 passed (23 config tests + 5 new marketplace.json tests). Zero failures.

- [ ] **Step 3: Validate JSON files manually**

```bash
python3 -c 'import json; print("plugin.json:", json.load(open(".claude-plugin/plugin.json"))["name"])'
python3 -c 'import json; print("hooks.json:", len(json.load(open("hooks/hooks.json"))["hooks"]), "event types")'
```

Expected:
- `plugin.json: laravel-livewire-superpowers`
- `hooks.json: 2 event types` (PreToolUse + PostToolUse)

- [ ] **Step 4: Verify the in-repo state matches Phase A.2 goals**

```bash
ls .claude-plugin/
test -f UPGRADING.md && echo "✓ UPGRADING.md exists" || echo "✗ UPGRADING.md missing"
test -f tests/test_marketplace_json.py && echo "✓ test_marketplace_json.py exists" || echo "✗ missing"
grep -q "Stack:.*Livewire 4" docs/agents.md && echo "✓ agents.md banner present" || echo "✗ agents.md banner missing"
grep -q "Stack:.*Livewire 4" docs/hooks.md && echo "✓ hooks.md banner present" || echo "✗ hooks.md banner missing"
grep -q "laravel-livewire-superpowers" README.md && echo "✓ README rebranded" || echo "✗ README not rebranded"
```

Expected: `ls .claude-plugin/` shows only `plugin.json` (no marketplace.json). All 5 checks `✓`.

### Task 21: Commit Phase A.2 changes on the feature branch

**Files:** All Phase A.2 modifications staged.

- [ ] **Step 1: Review what will be committed**

```bash
git status
git diff --stat
```

Expected `git status`: ~10-15 modified/created/deleted files on `feat/v3-phase-a-foundation`. Key files: `.claude-plugin/plugin.json` modified, `.claude-plugin/marketplace.json` deleted, `commands/status.md` modified (slash path), `README.md` modified (rebranded), `docs/agents.md` + `docs/hooks.md` modified (banners), `UPGRADING.md` created, `tests/test_marketplace_json.py` created, `CHANGELOG.md` modified.

- [ ] **Step 2: Stage all Phase A.2 changes**

```bash
git add .claude-plugin/plugin.json
git rm --cached .claude-plugin/marketplace.json 2>/dev/null || git rm .claude-plugin/marketplace.json
git add commands/status.md README.md docs/agents.md docs/hooks.md UPGRADING.md tests/test_marketplace_json.py CHANGELOG.md
```

If any other files were modified by Task 14 (slash-command find/replace) that aren't in the explicit list above, add them too:

```bash
git status
git add <any additional files listed>
```

- [ ] **Step 3: Commit with descriptive message**

```bash
git commit -m "$(cat <<'EOF'
feat(v3): phase a.2 — rename + foundation + marketplace + branding

Phase A.2 of the V3 Megarelease (see
docs/superpowers/specs/2026-05-17-v3-livewire-megarelease-design.md).

Changed:
- Plugin renamed laravel-superpowers → laravel-livewire-superpowers
  (.claude-plugin/plugin.json name + version 3.0.0-alpha.1).
- Marketplace.json deleted from .claude-plugin/ — canonical marketplace
  now lives in altraWeb/laravel-marketplace neutral host repo.
- All internal /laravel-superpowers: slash-command paths updated to
  /laravel-livewire-superpowers:.
- README, docs/agents.md, docs/hooks.md rebranded with Livewire stack
  scope banner + link to planned laravel-vue-superpowers sibling.

Added:
- UPGRADING.md (V2 → V3 migration steps).
- tests/test_marketplace_json.py (5 schema validation tests for
  plugin.json, replaces in-repo marketplace.json checks).
- CHANGELOG [3.0.0-alpha.1] section documenting Phase A.2.

Removed:
- .claude-plugin/marketplace.json (moved to neutral host repo).
- 17 stale remote branches + 2 stale local branches (already-merged
  V1/V2 feature branches).

No new features in this alpha — Phases B-G ship the 14 backlog issues
that complete V3.
EOF
)"
```

Expected: Commit succeeds, all hooks pass.

If `banned-token-leak-guard` blocks because the message contains "Phase A.2" + "2026-05-17" inline, it should NOT block (per v2.0.1 S1 fix the date pattern requires a `Sprint/Phase/Audit/...` keyword PREFIX immediately before the date — `Phase A.2 of the V3 Megarelease (see docs/superpowers/specs/2026-05-17-...)` has `docs/superpowers/specs/` between the keyword and the date, so it should pass). If it does block anyway, READ THE BLOCK REASON CAREFULLY and either adjust the message or, if the hook has a bug, file an issue — do not `--no-verify`.

### Task 22: Push the feature branch, open the PR, AWAIT MERGE

**Files:** None.

- [ ] **Step 1: Push the branch to origin**

```bash
git push -u origin feat/v3-phase-a-foundation
```

Expected: Branch pushed successfully under the new repo name (origin URL was updated in Task 9 Step 5).

- [ ] **Step 2: Open the PR via gh CLI**

```bash
gh pr create \
  --base main \
  --head feat/v3-phase-a-foundation \
  --title "feat(v3): phase a.2 — rename + foundation + marketplace + branding" \
  --body "$(cat <<'EOF'
## Summary

Phase A.2 of the V3 Megarelease — see [the design spec](docs/superpowers/specs/2026-05-17-v3-livewire-megarelease-design.md) Section 5.

This PR is the foundation phase that unblocks Phases B-G. No new features yet — those land in subsequent alpha/beta cuts.

### Changed

- Plugin renamed: `laravel-superpowers` → `laravel-livewire-superpowers`
- Marketplace moved out of the plugin repo to neutral host `altraWeb/laravel-marketplace`
- All `/laravel-superpowers:*` internal slash-command paths → `/laravel-livewire-superpowers:*`
- README, `docs/agents.md`, `docs/hooks.md` rebranded with Livewire stack scope banner

### Added

- `UPGRADING.md` (V2 → V3 migration steps)
- `tests/test_marketplace_json.py` (5 schema validation tests for plugin.json)
- CHANGELOG `[3.0.0-alpha.1]` section

### Removed

- `.claude-plugin/marketplace.json` (moved to neutral host repo)
- 17 stale remote branches + 2 stale local branches

### Prerequisites

- ✅ Phase A.1 (v2.0.2 deprecation cut) shipped earlier today as `v2.0.2`
- ✅ Neutral marketplace repo `altraWeb/laravel-marketplace` created with initial `marketplace.json` listing this plugin (`v3.0.0`)
- ✅ GitHub repo renamed from `laravel-superpowers` to `laravel-livewire-superpowers`; GitHub URL redirect verified

### Test plan

- [ ] Reviewer pulls the branch, runs `bash tests/run_all.sh` (or per-suite equivalents), confirms all green
- [ ] Reviewer reads `UPGRADING.md` and mentally walks through the migration steps
- [ ] Reviewer confirms `README.md` install instructions correctly reference the new marketplace
- [ ] Reviewer skims `docs/agents.md` + `docs/hooks.md` for the new stack-scope banner

### After merge

- Cut `v3.0.0-alpha.1` tag + GitHub Release with this CHANGELOG section as release notes
- Update `altraWeb/laravel-marketplace`'s `marketplace.json` to point at the released alpha (currently set to `3.0.0`; bump to `3.0.0-alpha.1` once tagged)
- Move on to Phase B (Quickwin Hooks: #24 sprint-state-context-injection, #26 stale-branch-sweep, #25 master-roadmap-drift-detector) with its own implementation plan
EOF
)"
```

Expected: gh CLI returns the PR URL.

- [ ] **Step 3: Report PR URL to operator and pause for review + merge**

State to the operator: "Phase A.2 PR open at <URL>. Tests green. Ready for your review + merge. After merge I will execute Task 23 (tag v3.0.0-alpha.1 + GitHub Release + create the neutral marketplace repo + smoke-test the install flow), then start Phase B planning."

**STOP. Wait for operator to merge the PR before proceeding to Task 23.**

---

## STEP A.3 — Post-Merge Release Work (tag + marketplace)

This step runs AFTER the operator merges the Phase A.2 PR. It cuts the v3.0.0-alpha.1 tag (which makes the renamed plugin installable), creates the neutral marketplace host repo pointing at that tag, and smoke-tests the full install flow.

### Task 23: Tag v3.0.0-alpha.1 + create marketplace + smoke-test install

**Files:**
- External: git tag `v3.0.0-alpha.1`
- External: GitHub Release for v3.0.0-alpha.1
- External: new repo `altraWeb/laravel-marketplace`
- Create: `~/dev/laravel-marketplace/.claude-plugin/marketplace.json`
- Create: `~/dev/laravel-marketplace/README.md`

- [ ] **Step 1: Pull the merged Phase A.2 commit into local main**

```bash
cd ~/dev/laravel-livewire-superpowers
git switch main
git pull --ff-only origin main
git log --oneline -2
```

Expected: HEAD is now the squash-merge commit of the Phase A.2 PR.

- [ ] **Step 2: Tag v3.0.0-alpha.1**

```bash
git tag -a v3.0.0-alpha.1 -m "v3.0.0-alpha.1 — V3 Megarelease Phase A.2: rename + foundation + marketplace + branding"
git push origin v3.0.0-alpha.1
```

Expected: Tag pushed successfully.

- [ ] **Step 3: Create GitHub Release for v3.0.0-alpha.1**

```bash
gh release create v3.0.0-alpha.1 \
  --title "v3.0.0-alpha.1 — V3 Megarelease Phase A: Foundation, Deprecation, Rename" \
  --prerelease \
  --notes "$(awk '/^## \[3\.0\.0-alpha\.1\]/,/^---$/' CHANGELOG.md | head -n -1)"
```

Expected: Release URL returned. Verify with `gh release view v3.0.0-alpha.1`.

- [ ] **Step 4: Confirm with operator before creating the new marketplace repo**

State to the operator: "v3.0.0-alpha.1 tagged + released. About to create new public repo `altraWeb/laravel-marketplace` and push initial `marketplace.json` + `README.md` pointing at the just-released alpha. OK?"

Wait for explicit OK before proceeding.

- [ ] **Step 5: Create the GitHub repo for the marketplace**

```bash
gh repo create altraWeb/laravel-marketplace \
  --public \
  --description "Neutral marketplace host for the laravel-{stack}-superpowers Claude Code plugin family (laravel-livewire-superpowers + future laravel-vue-superpowers)" \
  --clone
mv laravel-marketplace ~/dev/laravel-marketplace
cd ~/dev/laravel-marketplace
mkdir -p .claude-plugin
```

Expected: `pwd` is `/Users/altrano/dev/laravel-marketplace`.

- [ ] **Step 6: Write marketplace.json pointing at the released tag**

Use Write tool to create `.claude-plugin/marketplace.json` with content:

```json
{
    "name": "altraweb-laravel",
    "owner": {
        "name": "altraWeb",
        "email": "altrano@quickline.ch"
    },
    "metadata": {
        "description": "Laravel-specific Claude Code plugin family — pick your stack: laravel-livewire-superpowers (Livewire 4 + Flux Pro v2) or the upcoming laravel-vue-superpowers (Vue 3 + Inertia).",
        "version": "1.0.0"
    },
    "plugins": [
        {
            "name": "laravel-livewire-superpowers",
            "source": "github:altraWeb/laravel-livewire-superpowers",
            "description": "Laravel + Livewire 4 + Flux Pro v2 + Pest 4 specialist toolkit: 10 agents, 7 skills, 13 hooks, 3 slash commands. Full Pilot 2.0 contract enforcement.",
            "version": "3.0.0-alpha.1",
            "keywords": ["laravel", "livewire", "flux-pro", "pest", "php", "tdd", "workflow", "code-review", "agents", "hooks"],
            "category": "productivity"
        }
    ]
}
```

Note: the Vue plugin slot is NOT included as a commented entry (JSON does not support comments). The Vue plugin gets added as a second `plugins` array entry when `laravel-vue-superpowers` ships.

- [ ] **Step 7: Validate marketplace.json**

```bash
python3 -c 'import json; m = json.load(open(".claude-plugin/marketplace.json")); print("plugins:", len(m["plugins"]), "marketplace version:", m["metadata"]["version"], "plugin version:", m["plugins"][0]["version"])'
```

Expected output: `plugins: 1 marketplace version: 1.0.0 plugin version: 3.0.0-alpha.1`

- [ ] **Step 8: Write README.md for the marketplace repo**

Use Write tool to create `README.md` with content:

````markdown
# altraWeb Laravel Plugin Marketplace

Neutral host repo for the `laravel-{stack}-superpowers` Claude Code plugin family.

## Available plugins

| Plugin | Stack | Status |
|---|---|---|
| `laravel-livewire-superpowers` | Laravel + Livewire 4 + Flux Pro v2 + Pest 4 | Released (v3.0.0-alpha.1+) |
| `laravel-vue-superpowers` | Laravel + Vue 3 (Composition API) + Inertia v2 + Pest 4 | Planned |

## Install

```bash
claude /plugin marketplace add altraWeb/laravel-marketplace
claude /plugin install laravel-livewire-superpowers@altraweb-laravel
```

For the Vue variant when it ships:

```bash
claude /plugin install laravel-vue-superpowers@altraweb-laravel
```

## Why a separate marketplace repo?

Previously the marketplace lived inside the `laravel-superpowers` plugin repo (now renamed `laravel-livewire-superpowers`). When the Vue variant was planned, that arrangement would have made the Livewire repo the implicit "primary" host. Splitting the marketplace into a neutral repo keeps the two plugin variants symmetric.

## Migrating from v2 of laravel-superpowers

See [`UPGRADING.md`](https://github.com/altraWeb/laravel-livewire-superpowers/blob/main/UPGRADING.md) on the renamed plugin repo for the migration steps.
````

- [ ] **Step 9: Commit and push the marketplace repo's initial content**

```bash
cd ~/dev/laravel-marketplace
git add .claude-plugin/marketplace.json README.md
git commit -m "chore: initial marketplace.json + README listing laravel-livewire-superpowers v3.0.0-alpha.1"
git push origin main
```

Expected: Push succeeds. (Auto-mode classifier should accept this as a first-commit-on-fresh-repo with explicit operator confirmation already given in Step 4.)

- [ ] **Step 10: Smoke-test the full install flow**

Open a fresh Claude Code session (or use a clean test session) and run:

```bash
claude /plugin marketplace add altraWeb/laravel-marketplace
claude /plugin install laravel-livewire-superpowers@altraweb-laravel
claude /laravel-livewire-superpowers:status
```

Expected: The marketplace adds without error. The plugin installs without error. The `/status` slash command renders cleanly.

- [ ] **Step 11: Report Phase A completion to operator**

State to the operator: "Phase A complete. v3.0.0-alpha.1 tagged + released, marketplace repo live at https://github.com/altraWeb/laravel-marketplace, install flow smoke-tested green. Ready to start Phase B (Quickwin Hooks) planning whenever you give the go."

**STOP. Phase A complete. Phase B planning begins on operator signal.**
