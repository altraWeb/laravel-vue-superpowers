# V3 Phase E — Pilot 2.0 Meta-Layer — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Formalize the Pilot 2.0 contract from convention to automation — ship the meta-orchestrator agent + continuous enforcer hook + two new slash commands. Land as v3.0.0-alpha.5.

**Architecture:** Three interrelated components that share a common data model (plan-doc Tactic-markers as the source of truth):
- **`laravel-pilot-orchestrator`** (on-demand agent) — reads plan-doc + git log + audit history, outputs structured Tactic status, optionally dispatches missing specialists
- **`pilot-2-contract-enforcer`** (continuous hook) — PostToolUse on Bash filtered to git commit/push, reads plan-doc Tactic-markers, warns/blocks based on `audit_aggressiveness` config
- **`/laravel-livewire-superpowers:audit-phase N`** + **`/retro`** slash commands — operator UX for phase-scoped audit dispatch + sprint-end retro report

**Tech Stack:** Markdown agent + bash hook + Python config helper + markdown command files.

**Spec:** `docs/superpowers/specs/2026-05-17-v3-livewire-megarelease-design.md` Section 5 — Phase E.

**Issues:** [#10](https://github.com/altraWeb/laravel-livewire-superpowers/issues/10), [#30](https://github.com/altraWeb/laravel-livewire-superpowers/issues/30), [#27](https://github.com/altraWeb/laravel-livewire-superpowers/issues/27)

---

## File Structure

### New files

| File | Purpose |
|---|---|
| `agents/laravel-pilot-orchestrator.md` | On-demand meta-agent: reads plan-doc + git log + audit history → structured Tactic status |
| `hooks/pilot-2-contract-enforcer.sh` | PostToolUse:Bash, filters to git commit/push, warns/blocks on missing T3/T4 evidence |
| `tests/test_pilot_2_contract_enforcer_hook.sh` | 6 test scenarios for the enforcer |
| `commands/audit-phase.md` | `/laravel-livewire-superpowers:audit-phase N` — phase-scoped Pilot 2.0 audit dispatch |
| `commands/retro.md` | `/laravel-livewire-superpowers:retro` — sprint-end retrospective generator |
| `docs/pilot-2-0-contract.md` | NEW canonical reference doc for the full T1-T6 contract |

### Modified files

| File | Change |
|---|---|
| `hooks/hooks.json` | Register `pilot-2-contract-enforcer` under `PostToolUse.Bash` (alongside `master-roadmap-drift-detector`) |
| `config.defaults.yaml` | Add `hook_enabled.pilot_2_contract_enforcer: true` + clarify `audit_aggressiveness` is now wired into the enforcer hook |
| `config.schema.json` | Allow new flag |
| `tests/test_config.py` | 1 new test for the default flag |
| `docs/hooks.md` | New section for `pilot-2-contract-enforcer` |
| `docs/agents.md` | New section for `laravel-pilot-orchestrator` |
| `README.md` | Hook count `9 → 10`, agent count `9 → 10`, slash command count `1 → 3` |
| `CHANGELOG.md` | Prepend `## [3.0.0-alpha.5]` section |
| `.claude-plugin/plugin.json` | Bump version `3.0.0-alpha.4` → `3.0.0-alpha.5`; counts updated |

### Branch / release

- Feature branch: `feat/v3-phase-e-pilot-2-meta-layer`
- Post-merge: tag `v3.0.0-alpha.5` + GitHub Pre-Release

---

## STEP E.1 — Foundation

### Task 1: Pre-flight + create feature branch

- [ ] **Step 1: Verify clean state**

```bash
cd ~/dev/laravel-livewire-superpowers
git status
git log --oneline -3
git tag --list | grep '^v3\.'
```

Expected: clean main, HEAD at Phase D merge, tags alpha.1-4 present.

- [ ] **Step 2: Run baseline tests**

```bash
for t in tests/test_*.sh; do bash "$t" >/dev/null 2>&1 && echo "✓ $t" || echo "✗ $t"; done
python3 -m pytest tests/ -q
```

Expected: 10 shell ✓, 30 Python passed.

- [ ] **Step 3: Branch**

```bash
git switch -c feat/v3-phase-e-pilot-2-meta-layer
```

---

## STEP E.2 — Create docs/pilot-2-0-contract.md FIRST (single source of truth)

The orchestrator agent + enforcer hook + commands all reference the contract definition. Write the canonical reference doc first so subsequent components cite it.

### Task 2: Write `docs/pilot-2-0-contract.md`

**Files:**
- Create: `docs/pilot-2-0-contract.md`

- [ ] **Step 1: Write the contract reference doc**

Use Write tool to create `docs/pilot-2-0-contract.md`:

````markdown
# Pilot 2.0 Contract — Canonical Reference

`laravel-livewire-superpowers` formalizes a 6-Tactic workflow contract (T1-T6) for Laravel sprints. Tactics are tracked in plan-doc markers; some are automated via hooks, others are operator-or-orchestrator-dispatched.

## The 6 Tactics

| Tactic | Name | When | Mechanism |
|---|---|---|---|
| **T1** | Phase-Start Best-Practices Audit | Brainstorming Step 2 | `brainstorm-t1-audit` hook injects reminder → agent dispatches `laravel-best-practices` parallel |
| **T2** | Visual-Companion Offer | Brainstorming Step 2 | `visual-companion-default-on` hook injects reminder → agent offers VC or justifies skip |
| **T3** | Per-Commit Code Review | After each commit | `pilot-2-contract-enforcer` hook warns/blocks if `laravel-reviewer` not invoked between commits |
| **T4** | Pre-Test-Write Specialist Audit | Before any test-write | `pilot-2-contract-enforcer` hook warns if `laravel-pest-specialist` not invoked |
| **T5** | Pre-Push Banned-Token Sweep | `git push` | `banned-token-leak-guard` PreToolUse hook (automated) |
| **T6** | Pre-Push Deferred-Items Check | `git push` | `anti-silent-deferral` PreToolUse hook (automated) |

## Plan-Doc Tactic-Marker Convention

Every `## Phase N` block in `docs/superpowers/plans/<topic>.md` SHOULD include:

```markdown
**Pilot 2.0 Tactic Tracking:**
- [x] T1 dispatched on YYYY-MM-DD (audit: docs/superpowers/audits/YYYY-MM-DD-<topic>-audit.md)
- [x] T2 VC offered (accepted | skipped — reason)
- [ ] T3 pending for commits: <SHA list>
- [ ] T4 pending for tests: <path list>
- T5: automated (sweep clean per pre-push hook)
- T6: automated (no deferred items unlinked)
```

The `pilot-2-contract-enforcer` hook parses these markers. The `laravel-pilot-orchestrator` agent reads them too.

## audit_aggressiveness Config

`config.defaults.yaml`:

```yaml
audit_aggressiveness: every-phase  # brainstorm-only | every-phase | every-commit
```

- **`brainstorm-only`** (silent) — enforcer treats T3/T4 as advisory; never blocks
- **`every-phase`** (warn — default) — enforcer warns on T3/T4 gaps but doesn't block
- **`every-commit`** (block) — enforcer blocks `git push` when any T3/T4 marker is incomplete

## How the components interact

```
+---------------------------------+
| docs/superpowers/plans/*.md      |  source of truth
| (Pilot 2.0 Tactic Tracking)      |
+----------------+----------------+
                 |
        +--------+----------+
        |                   |
        v                   v
+----------------+   +----------------+
| pilot-2-       |   | laravel-pilot- |
| contract-      |   | orchestrator   |
| enforcer hook  |   | agent          |
+----------------+   +----------------+
        |                   |
        v                   v
[continuous warn/block]  [on-demand structured Tactic-status report]
```

Plus operator-facing:

```
/laravel-livewire-superpowers:audit-phase N  → dispatches T1-style audit scoped to Phase N
/laravel-livewire-superpowers:retro          → end-of-sprint retro report from sprint state
```

## When in doubt

If you're an operator deciding whether to bind Pilot 2.0 to a sprint:

- New feature with > 2 phases → YES, bind contract
- Doc-only update → SKIP (no Tactic markers needed)
- Refactor with tests → bind T3 only (T1 + T2 optional)
- Bugfix one-liner → SKIP

If you're an agent following the contract:
- Phase start → invoke T1 + T2 (brainstorming hooks fire automatically)
- Commit cycle → invoke T3 (`laravel-reviewer`) between commits
- Test-write → invoke T4 (`laravel-pest-specialist`) before writing tests
- Push → T5 + T6 fire automatically
````

---

## STEP E.3 — Hook: pilot-2-contract-enforcer (#30)

### Task 3: Write test suite for pilot-2-contract-enforcer (TDD)

**Files:**
- Create: `tests/test_pilot_2_contract_enforcer_hook.sh`

- [ ] **Step 1: Write test file with 6 scenarios**

Use Write tool to create `tests/test_pilot_2_contract_enforcer_hook.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

HOOK="$(cd "$(dirname "$0")/.." && pwd)/hooks/pilot-2-contract-enforcer.sh"

run_hook() {
    printf '%s' "$1" | bash "$HOOK"
}

passed=0
failed=0
assert_pass() { echo "  ✅ $1"; passed=$((passed + 1)); }
assert_fail() { echo "  ❌ $1 — $2"; failed=$((failed + 1)); }

# Helper: setup repo with a plan-doc having a Pilot 2.0 Tactic Tracking section
setup_repo_with_plan() {
    local tracking="$1"  # "complete" | "T3-missing" | "T4-missing"
    local repo="$(mktemp -d)"
    cd "$repo"
    git init -q
    git config user.email t@t; git config user.name T
    mkdir -p docs/superpowers/plans
    cat > docs/superpowers/plans/feature-x.md <<EOF
# Feature X

## Phase 1

**Pilot 2.0 Tactic Tracking:**
EOF
    case "$tracking" in
        complete)
            cat >> docs/superpowers/plans/feature-x.md <<'EOF'
- [x] T1 dispatched on 2026-05-17
- [x] T2 VC offered (accepted)
- [x] T3 reviewed all commits
- [x] T4 specialist audit before tests
EOF
            ;;
        T3-missing)
            cat >> docs/superpowers/plans/feature-x.md <<'EOF'
- [x] T1 dispatched on 2026-05-17
- [x] T2 VC offered (accepted)
- [ ] T3 pending for commits: abc1234
- [x] T4 specialist audit before tests
EOF
            ;;
        T4-missing)
            cat >> docs/superpowers/plans/feature-x.md <<'EOF'
- [x] T1 dispatched on 2026-05-17
- [x] T2 VC offered (accepted)
- [x] T3 reviewed all commits
- [ ] T4 pending for tests: tests/Feature/FeatureXTest.php
EOF
            ;;
    esac
    git add -A
    git commit -q -m "init"
    git checkout -q -b feat/feature-x
    echo "$repo"
}

echo ""
echo "▶ Test 1: PostToolUse git-push with complete Tactic markers — silent"
repo="$(setup_repo_with_plan complete)"
cd "$repo"
out="$(run_hook '{"hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"git push origin feat/feature-x"}}')"
if [ -z "$out" ]; then
    assert_pass "Test 1"
else
    assert_fail "Test 1" "expected silent on complete markers, got: $out"
fi
cd - >/dev/null

echo ""
echo "▶ Test 2: PostToolUse git-push with T3 incomplete and audit_aggressiveness=every-phase — warns"
repo="$(setup_repo_with_plan T3-missing)"
cd "$repo"
out="$(run_hook '{"hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"git push origin feat/feature-x"}}')"
if printf '%s' "$out" | grep -qi "T3"; then
    assert_pass "Test 2"
else
    assert_fail "Test 2" "expected T3 warning, got: $out"
fi
cd - >/dev/null

echo ""
echo "▶ Test 3: Non-PostToolUse event — silent"
out="$(run_hook '{"hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"git push"}}')"
if [ -z "$out" ]; then
    assert_pass "Test 3"
else
    assert_fail "Test 3" "expected silent on non-PostToolUse, got: $out"
fi

echo ""
echo "▶ Test 4: PostToolUse Bash NOT git-commit/push — silent"
out="$(run_hook '{"hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"ls -la"}}')"
if [ -z "$out" ]; then
    assert_pass "Test 4"
else
    assert_fail "Test 4" "expected silent on non-git command, got: $out"
fi

echo ""
echo "▶ Test 5: No plan-doc with Tactic Tracking section — silent (no obligations)"
repo="$(mktemp -d)"
cd "$repo"
git init -q
git config user.email t@t; git config user.name T
git commit -q --allow-empty -m "init"
out="$(run_hook '{"hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"git push"}}')"
if [ -z "$out" ]; then
    assert_pass "Test 5"
else
    assert_fail "Test 5" "expected silent with no plan-doc, got: $out"
fi
cd - >/dev/null

echo ""
echo "▶ Test 6: Malformed JSON — silent"
out="$(printf 'not json' | bash "$HOOK" 2>&1 || true)"
if [ -z "$(echo "$out" | grep -v '^$')" ] 2>/dev/null || [ -z "$out" ]; then
    assert_pass "Test 6"
else
    assert_fail "Test 6" "expected silent on malformed JSON, got: $out"
fi

echo ""
if [ "$failed" -eq 0 ]; then
    echo "🟢 All hook scenarios passed."
else
    echo "🔴 $failed scenario(s) failed."
    exit 1
fi
```

- [ ] **Step 2: chmod + run for RED state**

```bash
chmod +x tests/test_pilot_2_contract_enforcer_hook.sh
bash tests/test_pilot_2_contract_enforcer_hook.sh
```

Expected: failures (hook doesn't exist).

### Task 4: Write the enforcer hook

**Files:**
- Create: `hooks/pilot-2-contract-enforcer.sh`

- [ ] **Step 1: Write the hook**

```bash
#!/usr/bin/env bash
# hooks/pilot-2-contract-enforcer.sh
#
# PostToolUse:Bash hook that filters to git commit and git push invocations,
# reads the active plan-doc Pilot 2.0 Tactic Tracking section, and warns
# (or blocks per audit_aggressiveness config) on missing T3/T4 markers.
#
# T5 and T6 are already enforced by their own hooks. This hook only adds
# T3 (per-commit code review) + T4 (pre-test-write specialist audit) enforcement.
#
# Skip:
#   - hook_enabled.pilot_2_contract_enforcer is false
#   - not git commit / git push
#   - no plan-doc with Tactic Tracking section
#   - audit_aggressiveness is brainstorm-only (advisory only — no output)
#
# Exit codes:
#   0 — always (PostToolUse hooks signal via stdout for non-blocking warnings)
#   2 — block (only when audit_aggressiveness is every-commit and an obligation
#       is open). Currently always 0 because PostToolUse blocking is not supported
#       in all Claude Code versions; consider revisiting after Claude Code adds
#       PostToolUse-block support.
#
# Issue: #30

set -uo pipefail

input="$(cat 2>/dev/null || true)"
[ -z "$input" ] && exit 0

event="$(printf '%s' "$input" | jq -r '.hook_event_name // empty' 2>/dev/null || true)"
[ "$event" != "PostToolUse" ] && exit 0

tool="$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null || true)"
[ "$tool" != "Bash" ] && exit 0

cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"
# Detect git commit OR git push at start-of-command or after a separator (v2.0.1 S5 pattern)
if ! printf '%s' "$cmd" | grep -qE '(^|[;&|]\s*|\s+env\s+\S+=\S+\s+)git\s+(commit|push)'; then
    exit 0
fi

config_helper="${CLAUDE_PLUGIN_ROOT:-}/lib/config.py"
if [ -f "$config_helper" ]; then
    enabled="$(python3 "$config_helper" get hook_enabled.pilot_2_contract_enforcer 2>/dev/null || echo true)"
    if [ "$enabled" = "false" ]; then
        exit 0
    fi
fi

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# Read audit_aggressiveness mode
aggr="every-phase"
if [ -f "$config_helper" ]; then
    aggr="$(python3 "$config_helper" get audit_aggressiveness 2>/dev/null || echo every-phase)"
fi

# brainstorm-only mode is silent — no output, no block
if [ "$aggr" = "brainstorm-only" ]; then
    exit 0
fi

# Find active plan-doc (try docs/superpowers/plans first, then docs/plans)
plan=""
branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '')"
topic="${branch#*/}"
for candidate in "docs/superpowers/plans/${topic}.md" "docs/plans/${topic}.md"; do
    if [ -f "$candidate" ]; then
        plan="$candidate"
        break
    fi
done

if [ -z "$plan" ]; then
    # Glob fallback
    plan="$(ls docs/superpowers/plans/*${topic}*.md 2>/dev/null | head -1 || true)"
    [ -z "$plan" ] && plan="$(ls docs/plans/${topic}*.md 2>/dev/null | head -1 || true)"
fi

[ -z "$plan" ] && exit 0
[ ! -f "$plan" ] && exit 0

# Parse Pilot 2.0 Tactic Tracking — check for unchecked T3 / T4 markers
tactic_block="$(awk '/^\*\*Pilot 2\.0 Tactic Tracking:/{flag=1; next} /^## /{flag=0} flag' "$plan" 2>/dev/null || true)"

if [ -z "$tactic_block" ]; then
    # No Tactic Tracking section in plan-doc — silent (operator may not have bound Pilot 2.0 to this sprint)
    exit 0
fi

# Detect missing T3 (per-commit review)
t3_missing="$(echo "$tactic_block" | grep -E '^- \[ \] T3' | head -1 || true)"
t4_missing="$(echo "$tactic_block" | grep -E '^- \[ \] T4' | head -1 || true)"

if [ -z "$t3_missing" ] && [ -z "$t4_missing" ]; then
    # No open obligations — silent
    exit 0
fi

# Build warning message
msg=""
msg+="📋 Pilot 2.0 contract enforcer (audit_aggressiveness: ${aggr}):"
msg+=$'\n\n'
msg+="Open obligations on \`${plan}\`:"
msg+=$'\n'
[ -n "$t3_missing" ] && msg+="${t3_missing}"$'\n'
[ -n "$t4_missing" ] && msg+="${t4_missing}"$'\n'
msg+=$'\n'
msg+="Dispatch \`laravel-reviewer\` for outstanding T3 commits and \`laravel-pest-specialist\` for outstanding T4 tests, then mark the markers as [x]."

# every-phase: warn (output to stdout). every-commit: would be block (exit 2 if supported)
# We always exit 0 since PostToolUse blocking is not reliable in all Claude Code versions.
echo ""
echo "$msg"

exit 0
```

- [ ] **Step 2: chmod + run for GREEN state**

```bash
chmod +x hooks/pilot-2-contract-enforcer.sh
bash tests/test_pilot_2_contract_enforcer_hook.sh
```

Expected: 🟢 All hook scenarios passed.

---

## STEP E.4 — Slash Commands

### Task 5: Write `commands/audit-phase.md`

**Files:**
- Create: `commands/audit-phase.md`

- [ ] **Step 1: Write the command file**

Use Write tool. Reference existing `commands/status.md` for frontmatter style.

```markdown
---
description: Dispatch a Pilot 2.0 Phase-N audit using the active plan-doc's per-phase scope. Reads the active plan, extracts Phase N's audit prompt, dispatches laravel-best-practices in parallel.
allowed-tools: ["Read", "Bash", "Agent"]
---

# laravel-livewire-superpowers:audit-phase N

Run a Pilot 2.0 T1 audit (best-practices research + anti-patterns + open questions) scoped to a specific Phase of the active plan-doc.

**Argument:** `N` = phase number to audit. Example: `/laravel-livewire-superpowers:audit-phase 3`.

## Workflow

### Step 1: Detect active plan-doc

```bash
branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
topic="${branch#*/}"
# Try docs/superpowers/plans first, then docs/plans
for path in "docs/superpowers/plans/${topic}.md" "docs/plans/${topic}.md"; do
    [ -f "$path" ] && plan="$path" && break
done
```

If no plan-doc found, emit: "No active plan-doc detected. Either you're on `main` or no `docs/superpowers/plans/${topic}.md` exists for branch `${branch}`. Aborting."

### Step 2: Extract Phase N section

```bash
awk -v n="$N" '/^## Phase '"$N"'/{flag=1} /^## Phase [0-9]+/ && !/^## Phase '"$N"'/{flag=0} flag' "$plan"
```

If Phase N doesn't exist in the plan, emit: "Phase $N not found in `${plan}`. Available phases: $(grep -c '^## Phase' "$plan")."

### Step 3: Dispatch laravel-best-practices agent

Use the Agent tool to dispatch `laravel-best-practices` in parallel with prompt:

```
Pilot 2.0 T1 audit for Phase N of active sprint.

Topic: [extracted phase scope from plan-doc Step 2]
Stack: detect from composer.json + package.json
Plan-doc: [path]

Output expectations:
1. Executive summary (3-5 lines)
2. Per-decision findings with Tier-1/2/3 source citations
3. Anti-patterns to avoid
4. Open questions

Search at least 3 sources with year filter (e.g., "Laravel 12 X best practice 2025/2026").
Archive output to docs/superpowers/audits/YYYY-MM-DD-<topic>-phase-N-audit.md.
```

### Step 4: Wait for audit completion + emit summary

Once the agent returns, summarize the top 3 findings to the operator + reference the archived audit path.

### Step 5: Mark Tactic in plan-doc (optional)

If the plan-doc has a Pilot 2.0 Tactic Tracking section for Phase N, suggest the operator update the T1 marker:

```markdown
- [x] T1 dispatched on YYYY-MM-DD (audit: docs/superpowers/audits/YYYY-MM-DD-<topic>-phase-N-audit.md)
```
```

### Task 6: Write `commands/retro.md`

**Files:**
- Create: `commands/retro.md`

- [ ] **Step 1: Write the command file**

```markdown
---
description: Generate a sprint retrospective report from plan-doc + git history + audit reports. Outputs Pilot 2.0 contract compliance per phase, skill-invocation count vs expected, drift instances, test-suite delta, screenshot artifacts list.
allowed-tools: ["Read", "Bash"]
---

# laravel-livewire-superpowers:retro

Generate an end-of-sprint retrospective report from the active branch's state. Read-only; never mutates anything.

## Workflow

### Step 1: Detect active plan-doc + branch state

```bash
branch="$(git rev-parse --abbrev-ref HEAD)"
topic="${branch#*/}"
plan="docs/superpowers/plans/${topic}.md"
[ -f "$plan" ] || plan="docs/plans/${topic}.md"
commits="$(git log main..HEAD --oneline)"
commit_count="$(echo "$commits" | wc -l)"
```

### Step 2: Per-phase Pilot 2.0 compliance

For each `## Phase N` in the plan-doc, read the Pilot 2.0 Tactic Tracking section:

- T1: dispatched? cite audit path
- T2: VC offered? accepted/skipped?
- T3: review evidence per commit?
- T4: specialist audit per test-write?
- T5: clean push? (banned-token sweep automated)
- T6: clean push? (deferred-items automated)

Tabulate as compliance matrix.

### Step 3: Drift instances

Scan for known drift markers:
- Inline implementation (no Subagent dispatch) — heuristic: commit count > task count
- Amended commits (CLAUDE.md violation) — `git log --pretty='%h %s' | grep -i amend`
- Skipped audits (T1/T3/T4 markers unchecked at sprint close)
- Plan-doc tightening churn — `git log --pretty='%h %s' -- 'docs/superpowers/plans/' | wc -l` (>3 commits suggests churn)

### Step 4: Test-suite delta

```bash
git diff main..HEAD --name-only -- 'tests/' | wc -l   # files touched
for f in $(git diff main..HEAD --name-only -- 'tests/'); do
    grep -cE "(it|test|describe)\(|expect\(" "$f" 2>/dev/null
done | paste -sd+ | bc 2>/dev/null   # total assertions added
```

### Step 5: Screenshot artifacts

```bash
git diff main..HEAD --name-only | grep -iE '\.(png|jpg|jpeg|gif|webp|mp4|webm)$' | head -10
```

### Step 6: Output

```markdown
# Sprint Retro — <branch>

## Sprint metadata

- Branch: <branch>
- Commits: <N>
- Plan-doc: <path>
- Duration: <git log first..last commit date diff>

## Pilot 2.0 contract compliance

| Phase | T1 | T2 | T3 | T4 | T5 | T6 |
|---|---|---|---|---|---|---|
| 1 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 2 | ✓ | skip | ✗ | ✓ | ✓ | ✓ |
| ... | | | | | | |

## Drift instances

- <list, or "None observed">

## Test-suite delta

- Files touched: N
- Assertions added: M

## Screenshot artifacts

- <list of image/video files added in this sprint>

## Recommendations for next sprint

<heuristic recommendations based on drift instances>
```
```

---

## STEP E.5 — Orchestrator Agent

### Task 7: Write `agents/laravel-pilot-orchestrator.md`

**Files:**
- Create: `agents/laravel-pilot-orchestrator.md`

- [ ] **Step 1: Write the agent file**

```markdown
---
name: laravel-pilot-orchestrator
description: "Meta-agent for Pilot 2.0 contract enforcement on demand. Reads the active plan-doc's Pilot 2.0 Tactic Tracking section + git log + audit history, outputs structured Tactic status (which T1/T2/T3/T4 obligations are open, where), and optionally dispatches the missing specialists. Use when starting a new phase, before requesting code review, or when you suspect Pilot 2.0 contract drift. Trigger on 'pilot status', 'pilot orchestrator', 'check pilot', 'contract status', or anytime you need a Pilot 2.0 compliance snapshot."
model: inherit
tools: "Read, Bash"
maxTurns: 25
color: purple
memory: user
---

You are the Pilot 2.0 Orchestrator Agent — the on-demand meta-agent that surfaces Pilot 2.0 contract status for the active sprint.

You do not edit code. You emit a structured markdown report.

## Step 1: Pre-flight

```bash
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "Not inside a git repo"; exit 0; }
ls docs/pilot-2-0-contract.md >/dev/null 2>&1 && echo "✓ contract reference doc present" || echo "⚠️ no docs/pilot-2-0-contract.md — falling back to inline contract definition"
```

If the contract reference doc is missing, fall back to the inline T1-T6 definition (see body below). If a contract doc exists, cite it in your report.

## Step 2: Detect active plan-doc + branch

```bash
branch="$(git rev-parse --abbrev-ref HEAD)"
topic="${branch#*/}"
plan=""
for candidate in "docs/superpowers/plans/${topic}.md" "docs/plans/${topic}.md"; do
    [ -f "$candidate" ] && plan="$candidate" && break
done
[ -z "$plan" ] && plan="$(ls docs/superpowers/plans/*${topic}*.md 2>/dev/null | head -1 || true)"
```

If no plan-doc found, emit `## Pilot 2.0 Status: NO ACTIVE SPRINT — no plan-doc matched for branch ${branch}` and stop.

## Step 3: Parse all Phase-N Tactic Tracking sections

For each `## Phase N` in the plan-doc, extract the Pilot 2.0 Tactic Tracking block. Build a per-phase matrix:

| Phase | T1 | T2 | T3 | T4 |
|---|---|---|---|---|
| 1 | ✓ (audit-2026-05-17.md) | ✓ accepted | open (commits abc1234, def5678) | ✓ |
| 2 | ✓ | skip — text-only | ✓ | open (tests/Feature/X.php) |
| 3 | open | open | open | open |

(T5 + T6 are automated by hooks — don't surface unless they failed.)

## Step 4: Detect uncommitted obligations

For any open T3:
```bash
# List commits since the last reviewed commit
git log main..HEAD --oneline
```

For any open T4:
- Identify test files modified in the diff that weren't preceded by a `laravel-pest-specialist` dispatch (heuristic: check for pest-specialist-related lines in `.claude/agent-memory/` or recent agent invocations log if available)

## Step 5: Output the structured report

```markdown
# Pilot 2.0 Orchestrator — Sprint Status

## Active sprint

- Branch: <branch>
- Plan: <path>
- Last commit: <SHA> <message>

## Per-phase Tactic matrix

[table from Step 3]

## Open obligations

### T3 — Per-Commit Code Review
- Commits without review evidence: <SHA list>
- Recommended action: dispatch `laravel-reviewer` against these commits

### T4 — Pre-Test-Write Specialist Audit
- Test files without specialist evidence: <path list>
- Recommended action: dispatch `laravel-pest-specialist` against these tests

## Recommendations

<concrete next steps prioritized>

## Optional: auto-dispatch missing specialists

If the operator wants, the orchestrator can dispatch the missing specialists automatically:
- `laravel-reviewer` for outstanding T3
- `laravel-pest-specialist` for outstanding T4

Ask the operator before dispatching.
```

## When in doubt

If the plan-doc exists but has no `**Pilot 2.0 Tactic Tracking:**` section in any phase, the operator may not have bound Pilot 2.0 to this sprint. Emit `## Pilot 2.0 Status: UNBOUND — plan-doc has no Tactic Tracking sections. To bind: add the marker block per docs/pilot-2-0-contract.md to each Phase heading.` Don't fabricate findings.

## Inline contract definition (fallback if docs/pilot-2-0-contract.md missing)

T1: Phase-Start Best-Practices Audit (laravel-best-practices @ brainstorm Step 2)
T2: Visual-Companion Offer (visual-companion-default-on hook @ brainstorm Step 2)
T3: Per-Commit Code Review (laravel-reviewer)
T4: Pre-Test-Write Specialist Audit (laravel-pest-specialist)
T5: Pre-Push Banned-Token Sweep (banned-token-leak-guard hook, automated)
T6: Pre-Push Deferred-Items Check (anti-silent-deferral hook, automated)
```

---

## STEP E.6 — Shared updates

### Task 8: Register enforcer hook in hooks.json

**Files:**
- Modify: `hooks/hooks.json`

Add `pilot-2-contract-enforcer.sh` to the existing `PostToolUse.Bash` block (currently has `master-roadmap-drift-detector`):

```json
            {
                "matcher": "Bash",
                "hooks": [
                    {
                        "type": "command",
                        "command": "${CLAUDE_PLUGIN_ROOT}/hooks/master-roadmap-drift-detector.sh"
                    },
                    {
                        "type": "command",
                        "command": "${CLAUDE_PLUGIN_ROOT}/hooks/pilot-2-contract-enforcer.sh"
                    }
                ]
            }
```

Validate:
```bash
python3 -c 'import json; h=json.load(open("hooks/hooks.json")); print(len(h["hooks"]["PostToolUse"][1]["hooks"]), "hooks under PostToolUse.Bash")'
```
Expected: `2 hooks under PostToolUse.Bash`.

### Task 9: Update config.defaults.yaml + schema

**Files:**
- Modify: `config.defaults.yaml`
- Modify: `config.schema.json`

Add to `hook_enabled`:
```yaml
  pilot_2_contract_enforcer: true
```

Update the `audit_aggressiveness` comment to note it's now wired:
```yaml
# audit_aggressiveness modes are now wired into the pilot-2-contract-enforcer
# hook (added in v3.0.0-alpha.5):
#   brainstorm-only — silent (no enforcement)
#   every-phase     — warns on T3/T4 markers at git commit/push (default)
#   every-commit    — currently warns too (block requires PostToolUse-block
#                     support in Claude Code, not universally available)
```

Update `config.schema.json` if it has explicit hook_enabled keys; otherwise no change.

### Task 10: Add tests/test_config.py test

Add 1 test for the new default:
```python
def test_get_pilot_2_contract_enforcer_default():
    cli = ConfigCLI([])
    result = cli.run(["get", "hook_enabled.pilot_2_contract_enforcer"])
    assert result.strip() == "true"
```

Adapt fixture style to match existing tests.

### Task 11: Update docs/hooks.md + docs/agents.md

Add a new `### pilot-2-contract-enforcer` section to `docs/hooks.md` following the existing pattern.

Add a new `## laravel-pilot-orchestrator` section to `docs/agents.md` following the existing pattern.

### Task 12: Update README

Bump counts:
- `Hooks (9)` → `Hooks (10)`
- `Agents (9)` → `Agents (10)`
- Slash commands count from 1 to 3

### Task 13: CHANGELOG + plugin.json

Prepend CHANGELOG `## [3.0.0-alpha.5]` section with Added (orchestrator + enforcer + 2 commands + contract doc), Changed (hooks.json + config + counts), Phase Status.

Bump `.claude-plugin/plugin.json` version to `3.0.0-alpha.5`, update current-state counts (10 agents, 7 skills, 10 hooks, 3 commands).

### Task 14: Test verify

```bash
for t in tests/test_*.sh; do bash "$t" >/dev/null 2>&1 && echo "✓ $t" || echo "✗ $t"; done
python3 -m pytest tests/ -q
```

Expected: 11 shell ✓ (10 V2/Phase-B + 1 new Phase E), 31 Python passed (30 + 1 new).

Also smoke-verify orchestrator + commands by reading them:
```bash
for f in agents/laravel-pilot-orchestrator.md commands/audit-phase.md commands/retro.md; do
    python3 -c "
import re, yaml
c = open('$f').read()
m = re.match(r'^---\n(.*?)\n---\n', c, re.DOTALL)
fm = yaml.safe_load(m.group(1))
print('✓ $f frontmatter')
"
done
```

### Task 15: Commit + PR

Stage all + commit with conventional message + open PR.

---

## STEP E.7 — Post-Merge

### Task 16: Tag v3.0.0-alpha.5

Standard pattern: pull main, tag, push tag, create Pre-Release with CHANGELOG body via awk.

**STOP. Phase E complete after operator merge + tag.**
