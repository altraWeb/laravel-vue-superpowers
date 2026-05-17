# V3 Phase B — Quickwin Hooks — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Land Phase B of the V3 Megarelease — three SessionStart / PostToolUse hooks that surface the most-asked-for daily context (active sprint state, stale branches, master-roadmap drift). Ship as v3.0.0-alpha.2.

**Architecture:** Three independent shell-script hooks following the established V2.0.1 hook pattern (read stdin JSON, check config for `hook_enabled.<name>` flag, match-then-act, emit `hookSpecificOutput.additionalContext` or stdout). All three are non-blocking — they inform but never prevent operator action. Plus the shared updates (config defaults, schema, docs, CHANGELOG, version bump).

**Tech Stack:** Bash + jq + python3 (for the config helper). No new dependencies.

**Spec:** `docs/superpowers/specs/2026-05-17-v3-livewire-megarelease-design.md` Section 5 — Phase B.

**Issues:** [#24](https://github.com/altraWeb/laravel-livewire-superpowers/issues/24), [#26](https://github.com/altraWeb/laravel-livewire-superpowers/issues/26), [#25](https://github.com/altraWeb/laravel-livewire-superpowers/issues/25)

---

## File Structure

### New files

| File | Purpose |
|---|---|
| `hooks/sprint-state-context-injection.sh` | SessionStart hook — detects active sprint, injects resume state into system prompt context |
| `hooks/stale-branch-sweep.sh` | SessionStart hook — runs `git fetch --prune`, lists `[gone]`-upstream branches with cleanup suggestion |
| `hooks/master-roadmap-drift-detector.sh` | PostToolUse on Bash (filter to `git commit`) — warns when plan-doc commits diverge from master-roadmap state |
| `tests/test_sprint_state_context_injection_hook.sh` | Shell test suite for hook 1 |
| `tests/test_stale_branch_sweep_hook.sh` | Shell test suite for hook 2 |
| `tests/test_master_roadmap_drift_detector_hook.sh` | Shell test suite for hook 3 |

### Modified files

| File | Change |
|---|---|
| `hooks/hooks.json` | Register new hooks under `SessionStart` (new event type) and `PostToolUse.Bash` |
| `config.defaults.yaml` | Add 3 new `hook_enabled.*` flags (default true) + 1 `stale_branch_sweep.auto_prune` opt-in flag (default false) |
| `config.schema.json` | Extend schema to allow new flags |
| `tests/test_config.py` | Add 2-3 tests for new schema entries |
| `docs/hooks.md` | Add 3 new hook reference sections |
| `README.md` | Bump hook count 6→9 in feature counts (V2.0.1 actually shipped 6, not 7 — see Task 15 note) |
| `CHANGELOG.md` | Prepend `## [3.0.0-alpha.2]` section |
| `.claude-plugin/plugin.json` | Bump version `3.0.0-alpha.1` → `3.0.0-alpha.2`; description active hook count `7` → `9` for the alpha-current-state phrasing (correcting prior off-by-one) |

### Branch / release sequencing

- All Phase B work lands on feature branch `feat/v3-phase-b-quickwin-hooks` as a single PR.
- After merge → tag `v3.0.0-alpha.2` + GitHub Pre-Release.
- Marketplace.json on `altraWeb/laravel-marketplace` does NOT need updating (it points at `github:altraWeb/laravel-livewire-superpowers` without pinning a version; the install-source pulls the latest matching tag).

---

## STEP B.1 — Foundation: Pre-flight + branch

### Task 1: Pre-flight checks and feature branch creation

**Files:** None (verification + git branch creation).

- [ ] **Step 1: Verify clean main state**

```bash
cd ~/dev/laravel-livewire-superpowers
git status
git log --oneline -3
git rev-list --left-right --count origin/main..HEAD
```

Expected: working tree clean, HEAD at the merge of PR #52 (`1749292` or later as Phase A.3 progresses). `git rev-list` returns `0 0`.

- [ ] **Step 2: Verify v3.0.0-alpha.1 tag exists**

```bash
git tag --list | grep '^v3\.'
```

Expected: `v3.0.0-alpha.1` present.

- [ ] **Step 3: Run full test baseline**

```bash
for t in tests/test_*.sh; do bash "$t" >/dev/null 2>&1 && echo "✓ $t" || echo "✗ $t"; done
python3 -m pytest tests/ -q
```

Expected: 7 shell tests `✓`, pytest `28 passed`.

If anything fails, STOP and report BLOCKED.

- [ ] **Step 4: Create feature branch**

```bash
git switch -c feat/v3-phase-b-quickwin-hooks
git branch
```

Expected: `* feat/v3-phase-b-quickwin-hooks` is current.

---

## STEP B.2 — Hook 1: sprint-state-context-injection (#24)

A SessionStart hook that detects an active sprint (current branch + optional resume-anchor file + plan-doc) and injects a compact sprint-state summary into the session's system prompt context.

### Task 2: Write shell test suite for sprint-state-context-injection hook (TDD)

**Files:**
- Create: `tests/test_sprint_state_context_injection_hook.sh`

- [ ] **Step 1: Write the test file with 7 scenarios**

Use the Write tool to create `tests/test_sprint_state_context_injection_hook.sh` with:

```bash
#!/usr/bin/env bash
# Tests for hooks/sprint-state-context-injection.sh
set -euo pipefail

HOOK="$(cd "$(dirname "$0")/.." && pwd)/hooks/sprint-state-context-injection.sh"

# Helper: run hook with given stdin JSON, return stdout
run_hook() {
    local json="$1"
    printf '%s' "$json" | bash "$HOOK"
}

# Helper: extract additionalContext field from hook JSON output
extract_context() {
    printf '%s' "$1" | jq -r '.hookSpecificOutput.additionalContext // empty'
}

passed=0
failed=0

assert_pass() {
    local name="$1"
    echo "  ✅ $name"
    passed=$((passed + 1))
}

assert_fail() {
    local name="$1"
    local reason="$2"
    echo "  ❌ $name — $reason"
    failed=$((failed + 1))
}

echo ""
echo "▶ Test 1: SessionStart on feature branch — injects sprint context"
cd "$(mktemp -d)"
git init -q
git config user.email t@t
git config user.name T
git commit -q --allow-empty -m "init"
git checkout -q -b feat/notification-sounds
out="$(run_hook '{"hook_event_name":"SessionStart"}')"
ctx="$(extract_context "$out")"
if printf '%s' "$ctx" | grep -q "feat/notification-sounds"; then
    assert_pass "Test 1"
else
    assert_fail "Test 1" "expected branch name in additionalContext, got: $ctx"
fi
cd - >/dev/null

echo ""
echo "▶ Test 2: SessionStart on main branch — no injection (silent)"
cd "$(mktemp -d)"
git init -q -b main
git config user.email t@t
git config user.name T
git commit -q --allow-empty -m "init"
out="$(run_hook '{"hook_event_name":"SessionStart"}')"
if [ -z "$out" ]; then
    assert_pass "Test 2"
else
    assert_fail "Test 2" "expected no output on main, got: $out"
fi
cd - >/dev/null

echo ""
echo "▶ Test 3: SessionStart with LARAVEL_SUPERPOWERS_SKIP_AUTO_RESUME=1 — silent"
cd "$(mktemp -d)"
git init -q
git config user.email t@t
git config user.name T
git commit -q --allow-empty -m "init"
git checkout -q -b feat/x
out="$(LARAVEL_SUPERPOWERS_SKIP_AUTO_RESUME=1 run_hook '{"hook_event_name":"SessionStart"}')"
if [ -z "$out" ]; then
    assert_pass "Test 3"
else
    assert_fail "Test 3" "expected silent on env-disable, got: $out"
fi
cd - >/dev/null

echo ""
echo "▶ Test 4: SessionStart with resume-anchor file — referenced in context"
cd "$(mktemp -d)"
git init -q
git config user.email t@t
git config user.name T
mkdir -p docs/superpowers
echo "# Resume Block 1H" > docs/superpowers/editor-toolbar-resume.md
git add -A
git commit -q -m "init"
git checkout -q -b feat/editor-toolbar
out="$(run_hook '{"hook_event_name":"SessionStart"}')"
ctx="$(extract_context "$out")"
if printf '%s' "$ctx" | grep -q "editor-toolbar-resume.md"; then
    assert_pass "Test 4"
else
    assert_fail "Test 4" "expected resume-anchor path in context, got: $ctx"
fi
cd - >/dev/null

echo ""
echo "▶ Test 5: SessionStart with plan-doc — referenced in context"
cd "$(mktemp -d)"
git init -q
git config user.email t@t
git config user.name T
mkdir -p docs/plans
echo "# Editor Toolbar Plan" > docs/plans/editor-toolbar.md
echo "## Phase 1" >> docs/plans/editor-toolbar.md
echo "Status: in-progress" >> docs/plans/editor-toolbar.md
git add -A
git commit -q -m "init"
git checkout -q -b feat/editor-toolbar
out="$(run_hook '{"hook_event_name":"SessionStart"}')"
ctx="$(extract_context "$out")"
if printf '%s' "$ctx" | grep -q "editor-toolbar.md"; then
    assert_pass "Test 5"
else
    assert_fail "Test 5" "expected plan-doc path in context, got: $ctx"
fi
cd - >/dev/null

echo ""
echo "▶ Test 6: Non-SessionStart event — silent passthrough"
out="$(run_hook '{"hook_event_name":"PreToolUse"}')"
if [ -z "$out" ]; then
    assert_pass "Test 6"
else
    assert_fail "Test 6" "expected silent on non-SessionStart, got: $out"
fi

echo ""
echo "▶ Test 7: Malformed JSON — silent passthrough"
out="$(printf 'not json' | bash "$HOOK" 2>&1 || true)"
# Acceptable: either empty output OR non-zero exit silently
if [ -z "$(echo "$out" | grep -v '^$')" ] 2>/dev/null || [ -z "$out" ]; then
    assert_pass "Test 7"
else
    assert_fail "Test 7" "expected silent on malformed JSON, got: $out"
fi

echo ""
if [ "$failed" -eq 0 ]; then
    echo "🟢 All hook scenarios passed."
else
    echo "🔴 $failed scenario(s) failed."
    exit 1
fi
```

- [ ] **Step 2: Make the test executable**

```bash
chmod +x tests/test_sprint_state_context_injection_hook.sh
```

- [ ] **Step 3: Run the test — confirm it fails (hook doesn't exist yet)**

```bash
bash tests/test_sprint_state_context_injection_hook.sh
```

Expected: ERROR — hook file not found. Or scenario failures because the hook script doesn't exist. This is the TDD "RED" state.

### Task 3: Implement sprint-state-context-injection hook

**Files:**
- Create: `hooks/sprint-state-context-injection.sh`

- [ ] **Step 1: Write the hook script**

Use the Write tool to create `hooks/sprint-state-context-injection.sh` with:

```bash
#!/usr/bin/env bash
# hooks/sprint-state-context-injection.sh
#
# SessionStart hook that detects an active sprint and injects a compact
# sprint-state summary into the session's system prompt context, so the
# operator (and Claude) don't need to manually re-establish context at
# the start of every session.
#
# Detection: active sprint = current branch is feat/* or chore/* AND
# (optionally) a matching docs/superpowers/<topic>-resume.md or
# docs/plans/<topic>.md file exists.
#
# Skip cases:
#   - branch is main / master / default
#   - LARAVEL_SUPERPOWERS_SKIP_AUTO_RESUME env var is set to non-empty
#   - hook_enabled.sprint_state_context_injection is false in config
#
# Emits: hookSpecificOutput.additionalContext (JSON) — string ≤2KB
#
# Issue: #24

set -uo pipefail

# ─── Step 1: Read stdin ──────────────────────────────────────────────────────
input="$(cat 2>/dev/null || true)"
[ -z "$input" ] && exit 0

# ─── Step 2: Filter to SessionStart event ────────────────────────────────────
event="$(printf '%s' "$input" | jq -r '.hook_event_name // empty' 2>/dev/null || true)"
[ "$event" != "SessionStart" ] && exit 0

# ─── Step 3: Env-var disable ─────────────────────────────────────────────────
if [ -n "${LARAVEL_SUPERPOWERS_SKIP_AUTO_RESUME:-}" ]; then
    exit 0
fi

# ─── Step 4: Config check ────────────────────────────────────────────────────
config_helper="${CLAUDE_PLUGIN_ROOT:-}/lib/config.py"
if [ -f "$config_helper" ]; then
    enabled="$(python3 "$config_helper" get hook_enabled.sprint_state_context_injection 2>/dev/null || echo true)"
    if [ "$enabled" = "false" ]; then
        exit 0
    fi
fi

# ─── Step 5: Detect active branch ────────────────────────────────────────────
# Only run if we're inside a git working tree
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '')"
# Skip on main / master / detached HEAD
case "$branch" in
    main|master|HEAD|'')
        exit 0
        ;;
esac

# Only inject for sprint-style branches (feat/* or chore/* or spec/*)
case "$branch" in
    feat/*|chore/*|spec/*|fix/*|docs/*)
        ;; # proceed
    *)
        exit 0
        ;;
esac

# ─── Step 6: Gather sprint context ───────────────────────────────────────────
# Derive a "topic slug" from the branch name (suffix after the type/ prefix)
topic="${branch#*/}"

# Find resume-anchor file (convention: docs/superpowers/<topic>-resume.md)
resume_anchor=""
if [ -f "docs/superpowers/${topic}-resume.md" ]; then
    resume_anchor="docs/superpowers/${topic}-resume.md"
fi

# Find plan-doc (convention: docs/plans/<topic>.md or docs/superpowers/plans/*-<topic>*.md)
plan_doc=""
if [ -f "docs/plans/${topic}.md" ]; then
    plan_doc="docs/plans/${topic}.md"
elif compgen -G "docs/superpowers/plans/*${topic}*.md" >/dev/null 2>&1; then
    plan_doc="$(compgen -G "docs/superpowers/plans/*${topic}*.md" | head -1)"
fi

# Last commit info
last_commit_sha="$(git log -1 --format=%h 2>/dev/null || echo '')"
last_commit_msg="$(git log -1 --format=%s 2>/dev/null || echo '')"

# Detect current phase from plan-doc (find first ## Phase N where Status != complete)
current_phase=""
if [ -n "$plan_doc" ] && [ -f "$plan_doc" ]; then
    current_phase="$(awk '
        /^## Phase [0-9]+/ { phase=$0; next }
        /^Status:/ && phase != "" {
            if (tolower($0) !~ /complete/) {
                print phase
                exit
            }
            phase = ""
        }
    ' "$plan_doc" 2>/dev/null || echo '')"
fi

# ─── Step 7: Build context block (≤2KB) ──────────────────────────────────────
ctx=""
ctx+="📍 **Active sprint detected:** \`${branch}\`"
ctx+=$'\n\n'

if [ -n "$resume_anchor" ]; then
    ctx+="**Resume anchor:** [\`${resume_anchor}\`](${resume_anchor}) — read for cross-session continuity."
    ctx+=$'\n'
fi

if [ -n "$plan_doc" ]; then
    ctx+="**Plan doc:** [\`${plan_doc}\`](${plan_doc})"
    if [ -n "$current_phase" ]; then
        ctx+=" — currently at: ${current_phase}"
    fi
    ctx+=$'\n'
fi

if [ -n "$last_commit_sha" ]; then
    ctx+="**Last commit:** ${last_commit_sha} ${last_commit_msg}"
    ctx+=$'\n'
fi

ctx+=$'\n'
ctx+="If you (the assistant) need full Pilot 2.0 obligation status, run \`/laravel-livewire-superpowers:status\`."
ctx+=$'\n'
ctx+="To disable this auto-injection: set \`LARAVEL_SUPERPOWERS_SKIP_AUTO_RESUME=1\` in env, OR set \`hook_enabled.sprint_state_context_injection: false\` in .laravel-superpowers.yaml (filename preserved from V2 for config compatibility)."

# Truncate to 2KB safety limit
ctx_truncated="$(printf '%s' "$ctx" | head -c 2048)"

# ─── Step 8: Emit additionalContext ──────────────────────────────────────────
jq -nc \
    --arg ctx "$ctx_truncated" \
    '{ hookSpecificOutput: { hookEventName: "SessionStart", additionalContext: $ctx } }'
```

- [ ] **Step 2: Make the hook executable**

```bash
chmod +x hooks/sprint-state-context-injection.sh
```

- [ ] **Step 3: Run the test suite — expect all 7 to pass**

```bash
bash tests/test_sprint_state_context_injection_hook.sh
```

Expected: `🟢 All hook scenarios passed.` and all 7 tests show `✅`. This is the TDD "GREEN" state.

If any fail, investigate the specific failure and fix the hook (or test if the test itself is wrong). Do not proceed to Task 4 until all 7 pass.

### Task 4: Register sprint-state-context-injection in hooks.json

**Files:**
- Modify: `hooks/hooks.json`

- [ ] **Step 1: Add the SessionStart event with this hook**

Use the Edit tool. Read `hooks/hooks.json` first (already cached: it has `PreToolUse` and `PostToolUse` blocks).

Insert a new `SessionStart` key under `hooks` — the JSON structure becomes:

```json
{
    "hooks": {
        "PreToolUse": [
            {
                "matcher": "Bash",
                "hooks": [
                    {
                        "type": "command",
                        "command": "${CLAUDE_PLUGIN_ROOT}/hooks/banned-token-leak-guard.sh"
                    },
                    {
                        "type": "command",
                        "command": "${CLAUDE_PLUGIN_ROOT}/hooks/no-claude-attribution.sh"
                    },
                    {
                        "type": "command",
                        "command": "${CLAUDE_PLUGIN_ROOT}/hooks/teamcity-always.sh"
                    },
                    {
                        "type": "command",
                        "command": "${CLAUDE_PLUGIN_ROOT}/hooks/anti-silent-deferral.sh"
                    }
                ]
            }
        ],
        "PostToolUse": [
            {
                "matcher": "Skill",
                "hooks": [
                    {
                        "type": "command",
                        "command": "${CLAUDE_PLUGIN_ROOT}/hooks/visual-companion-default-on.sh"
                    },
                    {
                        "type": "command",
                        "command": "${CLAUDE_PLUGIN_ROOT}/hooks/brainstorm-t1-audit.sh"
                    }
                ]
            }
        ],
        "SessionStart": [
            {
                "hooks": [
                    {
                        "type": "command",
                        "command": "${CLAUDE_PLUGIN_ROOT}/hooks/sprint-state-context-injection.sh"
                    }
                ]
            }
        ]
    }
}
```

Use the Edit tool with `old_string` set to the current closing `}}` of PostToolUse + the closing `}` of hooks + the closing `}` of the root, and `new_string` set to the same plus the inserted SessionStart block.

If the Edit tool can't find a unique string, rewrite the file with the Write tool — it's small (~50 lines).

- [ ] **Step 2: Validate the JSON**

```bash
python3 -c 'import json; h = json.load(open("hooks/hooks.json")); print("events:", list(h["hooks"].keys()))'
```

Expected output: `events: ['PreToolUse', 'PostToolUse', 'SessionStart']`

- [ ] **Step 3: Re-run the hook test suite to confirm registration didn't break anything**

```bash
bash tests/test_sprint_state_context_injection_hook.sh
```

Expected: still 🟢 all passed.

---

## STEP B.3 — Hook 2: stale-branch-sweep (#26)

A SessionStart hook that surfaces local branches whose upstream is `[gone]` (typically post-merge) and suggests cleanup. Does NOT auto-delete by default.

### Task 5: Write shell test suite for stale-branch-sweep hook (TDD)

**Files:**
- Create: `tests/test_stale_branch_sweep_hook.sh`

- [ ] **Step 1: Write the test file with 6 scenarios**

Use the Write tool to create `tests/test_stale_branch_sweep_hook.sh` with:

```bash
#!/usr/bin/env bash
# Tests for hooks/stale-branch-sweep.sh
set -euo pipefail

HOOK="$(cd "$(dirname "$0")/.." && pwd)/hooks/stale-branch-sweep.sh"

run_hook() {
    local json="$1"
    printf '%s' "$json" | bash "$HOOK"
}

extract_context() {
    printf '%s' "$1" | jq -r '.hookSpecificOutput.additionalContext // empty'
}

passed=0
failed=0

assert_pass() {
    echo "  ✅ $1"
    passed=$((passed + 1))
}

assert_fail() {
    echo "  ❌ $1 — $2"
    failed=$((failed + 1))
}

# Helper: set up a git repo with a stale branch (upstream gone)
setup_repo_with_stale() {
    local repo_dir
    repo_dir="$(mktemp -d)"
    # Create a bare "remote"
    local bare_dir="$repo_dir/remote.git"
    git init -q --bare "$bare_dir"
    # Create the working clone
    cd "$repo_dir"
    git clone -q "$bare_dir" work
    cd work
    git config user.email t@t
    git config user.name T
    git commit -q --allow-empty -m "init"
    git push -q origin main 2>/dev/null || git push -q -u origin main 2>/dev/null || git push -q -u origin master 2>/dev/null
    # Create a feature branch with upstream
    git checkout -q -b feat/old-feature
    git commit -q --allow-empty -m "feature work"
    git push -q -u origin feat/old-feature
    # Now delete the remote branch to make local upstream "gone"
    git push -q origin --delete feat/old-feature
    # Local feat/old-feature now has upstream gone
    git checkout -q main 2>/dev/null || git checkout -q master 2>/dev/null
    echo "$repo_dir/work"
}

echo ""
echo "▶ Test 1: SessionStart with stale branches — lists them in additionalContext"
work="$(setup_repo_with_stale)"
cd "$work"
out="$(run_hook '{"hook_event_name":"SessionStart"}')"
ctx="$(extract_context "$out")"
if printf '%s' "$ctx" | grep -q "feat/old-feature"; then
    assert_pass "Test 1"
else
    assert_fail "Test 1" "expected feat/old-feature in additionalContext, got: $ctx"
fi
cd - >/dev/null

echo ""
echo "▶ Test 2: SessionStart with no stale branches — silent"
clean_repo="$(mktemp -d)"
cd "$clean_repo"
git init -q
git config user.email t@t
git config user.name T
git commit -q --allow-empty -m "init"
out="$(run_hook '{"hook_event_name":"SessionStart"}')"
if [ -z "$out" ]; then
    assert_pass "Test 2"
else
    assert_fail "Test 2" "expected silent on no-stale, got: $out"
fi
cd - >/dev/null

echo ""
echo "▶ Test 3: Non-SessionStart event — silent passthrough"
out="$(run_hook '{"hook_event_name":"PreToolUse"}')"
if [ -z "$out" ]; then
    assert_pass "Test 3"
else
    assert_fail "Test 3" "expected silent on non-SessionStart, got: $out"
fi

echo ""
echo "▶ Test 4: Outside a git repo — silent passthrough"
nogit="$(mktemp -d)"
cd "$nogit"
out="$(run_hook '{"hook_event_name":"SessionStart"}')"
if [ -z "$out" ]; then
    assert_pass "Test 4"
else
    assert_fail "Test 4" "expected silent outside git, got: $out"
fi
cd - >/dev/null

echo ""
echo "▶ Test 5: Cleanup command suggestion included"
work="$(setup_repo_with_stale)"
cd "$work"
out="$(run_hook '{"hook_event_name":"SessionStart"}')"
ctx="$(extract_context "$out")"
if printf '%s' "$ctx" | grep -q "git branch -D"; then
    assert_pass "Test 5"
else
    assert_fail "Test 5" "expected 'git branch -D' suggestion in context, got: $ctx"
fi
cd - >/dev/null

echo ""
echo "▶ Test 6: Malformed JSON — silent passthrough"
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

- [ ] **Step 2: Make executable**

```bash
chmod +x tests/test_stale_branch_sweep_hook.sh
```

- [ ] **Step 3: Run the test — confirm RED state**

```bash
bash tests/test_stale_branch_sweep_hook.sh
```

Expected: failures (hook doesn't exist).

### Task 6: Implement stale-branch-sweep hook

**Files:**
- Create: `hooks/stale-branch-sweep.sh`

- [ ] **Step 1: Write the hook script**

Use Write tool to create `hooks/stale-branch-sweep.sh` with:

```bash
#!/usr/bin/env bash
# hooks/stale-branch-sweep.sh
#
# SessionStart hook that surfaces local branches whose upstream is [gone]
# (typically post-merge) and emits a cleanup suggestion. Does NOT
# auto-delete by default.
#
# Skip cases:
#   - hook_enabled.stale_branch_sweep is false in config
#   - Not inside a git working tree
#
# Auto-delete opt-in: set LARAVEL_SUPERPOWERS_AUTO_PRUNE=1 env var OR
# stale_branch_sweep.auto_prune: true in config.
#
# Issue: #26

set -uo pipefail

# ─── Step 1: Read stdin ──────────────────────────────────────────────────────
input="$(cat 2>/dev/null || true)"
[ -z "$input" ] && exit 0

# ─── Step 2: Filter to SessionStart event ────────────────────────────────────
event="$(printf '%s' "$input" | jq -r '.hook_event_name // empty' 2>/dev/null || true)"
[ "$event" != "SessionStart" ] && exit 0

# ─── Step 3: Config check ────────────────────────────────────────────────────
config_helper="${CLAUDE_PLUGIN_ROOT:-}/lib/config.py"
if [ -f "$config_helper" ]; then
    enabled="$(python3 "$config_helper" get hook_enabled.stale_branch_sweep 2>/dev/null || echo true)"
    if [ "$enabled" = "false" ]; then
        exit 0
    fi
fi

# ─── Step 4: Verify inside git working tree ──────────────────────────────────
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# ─── Step 5: Fetch with prune (silent) ───────────────────────────────────────
git fetch --prune --quiet 2>/dev/null || true

# ─── Step 6: List local branches with upstream gone ──────────────────────────
stale_branches="$(git branch -vv 2>/dev/null | grep ': gone\]' | awk '{print $1}' | sed 's/^\*//' | xargs -n1 echo | sort -u || true)"

if [ -z "$stale_branches" ]; then
    exit 0
fi

# ─── Step 7: Determine auto-prune mode ───────────────────────────────────────
auto_prune="false"
if [ -n "${LARAVEL_SUPERPOWERS_AUTO_PRUNE:-}" ]; then
    auto_prune="true"
elif [ -f "$config_helper" ]; then
    cfg_prune="$(python3 "$config_helper" get stale_branch_sweep.auto_prune 2>/dev/null || echo false)"
    if [ "$cfg_prune" = "true" ]; then
        auto_prune="true"
    fi
fi

# ─── Step 8: If auto-prune, delete + emit summary; else emit suggestion ──────
if [ "$auto_prune" = "true" ]; then
    deleted=""
    while IFS= read -r br; do
        [ -z "$br" ] && continue
        if git branch -D "$br" >/dev/null 2>&1; then
            deleted+=" $br"
        fi
    done <<< "$stale_branches"
    ctx="🧹 **Stale branches auto-pruned** (LARAVEL_SUPERPOWERS_AUTO_PRUNE active):"$'\n\n'"\`\`\`"$'\n'"${deleted# }"$'\n'"\`\`\`"
else
    # Build the list with last-commit info
    listing=""
    while IFS= read -r br; do
        [ -z "$br" ] && continue
        last_info="$(git log -1 --format='%h %ad' --date=short "$br" 2>/dev/null || echo 'unknown')"
        listing+="  - \`${br}\` (last commit: ${last_info})"$'\n'
    done <<< "$stale_branches"

    cleanup_cmd="git branch -D $(echo "$stale_branches" | tr '\n' ' ')"

    ctx="🌿 **Stale branches detected** (upstream gone after merge):"$'\n\n'"${listing}"$'\n'"Cleanup with:"$'\n'"\`\`\`"$'\n'"${cleanup_cmd}"$'\n'"\`\`\`"$'\n\n'"To auto-prune at session start: set \`LARAVEL_SUPERPOWERS_AUTO_PRUNE=1\` in env, OR set \`stale_branch_sweep.auto_prune: true\` in .laravel-superpowers.yaml (filename preserved from V2 for config compatibility)."
fi

# ─── Step 9: Emit additionalContext ──────────────────────────────────────────
jq -nc \
    --arg ctx "$ctx" \
    '{ hookSpecificOutput: { hookEventName: "SessionStart", additionalContext: $ctx } }'
```

- [ ] **Step 2: Make executable**

```bash
chmod +x hooks/stale-branch-sweep.sh
```

- [ ] **Step 3: Run the test — confirm GREEN state**

```bash
bash tests/test_stale_branch_sweep_hook.sh
```

Expected: `🟢 All hook scenarios passed.`

### Task 7: Register stale-branch-sweep in hooks.json

**Files:**
- Modify: `hooks/hooks.json`

- [ ] **Step 1: Add the second hook under the existing SessionStart block**

Use the Edit tool to extend the SessionStart `hooks` array (created in Task 4) to include both hooks:

```json
        "SessionStart": [
            {
                "hooks": [
                    {
                        "type": "command",
                        "command": "${CLAUDE_PLUGIN_ROOT}/hooks/sprint-state-context-injection.sh"
                    },
                    {
                        "type": "command",
                        "command": "${CLAUDE_PLUGIN_ROOT}/hooks/stale-branch-sweep.sh"
                    }
                ]
            }
        ]
```

- [ ] **Step 2: Validate JSON**

```bash
python3 -c 'import json; h = json.load(open("hooks/hooks.json")); ss = h["hooks"]["SessionStart"][0]["hooks"]; print("SessionStart hooks:", len(ss))'
```

Expected: `SessionStart hooks: 2`

- [ ] **Step 3: Re-run both SessionStart hook tests**

```bash
bash tests/test_sprint_state_context_injection_hook.sh
bash tests/test_stale_branch_sweep_hook.sh
```

Expected: both 🟢.

---

## STEP B.4 — Hook 3: master-roadmap-drift-detector (#25)

A PostToolUse hook on `Bash` that detects `git commit` invocations touching `docs/plans/*.md` and warns if the master-roadmap state has drifted from the plan-doc state.

### Task 8: Write shell test suite for master-roadmap-drift-detector (TDD)

**Files:**
- Create: `tests/test_master_roadmap_drift_detector_hook.sh`

- [ ] **Step 1: Write the test file with 6 scenarios**

Use the Write tool to create `tests/test_master_roadmap_drift_detector_hook.sh` with:

```bash
#!/usr/bin/env bash
# Tests for hooks/master-roadmap-drift-detector.sh
set -euo pipefail

HOOK="$(cd "$(dirname "$0")/.." && pwd)/hooks/master-roadmap-drift-detector.sh"

run_hook() {
    local json="$1"
    printf '%s' "$json" | bash "$HOOK"
}

passed=0
failed=0
assert_pass() { echo "  ✅ $1"; passed=$((passed + 1)); }
assert_fail() { echo "  ❌ $1 — $2"; failed=$((failed + 1)); }

# Helper: set up a repo with a plan-doc commit and a master-roadmap that
# either matches (no drift) or mismatches (drift)
setup_repo_with_drift() {
    local drift="$1"  # "yes" or "no"
    local repo
    repo="$(mktemp -d)"
    cd "$repo"
    git init -q
    git config user.email t@t
    git config user.name T
    mkdir -p docs/plans
    cat > docs/plans/feature-x.md <<'EOF'
# Feature X
**Status:** archived (shipped via MR !99)
EOF
    if [ "$drift" = "yes" ]; then
        cat > docs/plans/master-roadmap-2026-q2.md <<'EOF'
# Master Roadmap Q2 2026
- Feature X: ready for review on branch
EOF
    else
        cat > docs/plans/master-roadmap-2026-q2.md <<'EOF'
# Master Roadmap Q2 2026
- Feature X: shipped via MR !99
EOF
    fi
    git add -A
    git commit -q -m "docs(plans): update feature-x plan"
    echo "$repo"
}

echo ""
echo "▶ Test 1: PostToolUse git-commit on plan-doc with master-roadmap drift — warns"
repo="$(setup_repo_with_drift yes)"
cd "$repo"
out="$(run_hook '{"hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"git commit -m \"docs(plans): update feature-x plan\""}}')"
if printf '%s' "$out" | grep -qi "drift\|master-roadmap"; then
    assert_pass "Test 1"
else
    assert_fail "Test 1" "expected drift warning, got: $out"
fi
cd - >/dev/null

echo ""
echo "▶ Test 2: PostToolUse git-commit on plan-doc with no drift — silent"
repo="$(setup_repo_with_drift no)"
cd "$repo"
out="$(run_hook '{"hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"git commit -m \"docs(plans): update feature-x plan\""}}')"
if [ -z "$out" ]; then
    assert_pass "Test 2"
else
    assert_fail "Test 2" "expected silent on no-drift, got: $out"
fi
cd - >/dev/null

echo ""
echo "▶ Test 3: PostToolUse git-commit NOT touching plan-doc — silent"
repo="$(mktemp -d)"
cd "$repo"
git init -q
git config user.email t@t; git config user.name T
echo "x" > file.txt
git add -A
git commit -q -m "feat: random change"
out="$(run_hook '{"hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"git commit -m \"feat: random change\""}}')"
if [ -z "$out" ]; then
    assert_pass "Test 3"
else
    assert_fail "Test 3" "expected silent on non-plan-doc commit, got: $out"
fi
cd - >/dev/null

echo ""
echo "▶ Test 4: PostToolUse with non-Bash tool — silent"
out="$(run_hook '{"hook_event_name":"PostToolUse","tool_name":"Edit","tool_input":{}}')"
if [ -z "$out" ]; then
    assert_pass "Test 4"
else
    assert_fail "Test 4" "expected silent on non-Bash tool, got: $out"
fi

echo ""
echo "▶ Test 5: PostToolUse Bash but not git-commit — silent"
out="$(run_hook '{"hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"ls -la"}}')"
if [ -z "$out" ]; then
    assert_pass "Test 5"
else
    assert_fail "Test 5" "expected silent on non-commit Bash, got: $out"
fi

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

- [ ] **Step 2: Make executable + run for RED state**

```bash
chmod +x tests/test_master_roadmap_drift_detector_hook.sh
bash tests/test_master_roadmap_drift_detector_hook.sh
```

Expected: failures (hook doesn't exist).

### Task 9: Implement master-roadmap-drift-detector hook

**Files:**
- Create: `hooks/master-roadmap-drift-detector.sh`

- [ ] **Step 1: Write the hook script**

Use Write tool to create `hooks/master-roadmap-drift-detector.sh` with:

```bash
#!/usr/bin/env bash
# hooks/master-roadmap-drift-detector.sh
#
# PostToolUse hook on Bash that fires when `git commit` touches any
# docs/plans/*.md file. It detects drift between the plan-doc state
# (archived / shipped via MR / etc.) and the master-roadmap entry
# (still says "ready for review", etc.) and emits a warning to stdout.
# Does NOT block the commit.
#
# Plan-doc state markers (parsed from plan-doc title + frontmatter):
#   - "archived" / "shipped via MR" / "merged"
#   - phase headings indicating progress
#
# Master-roadmap location convention:
#   docs/plans/master-roadmap-<year>-q<quarter>.md
#
# Drift cases flagged:
#   - plan-doc archived but master-roadmap entry still pending/ready-for-review
#   - plan-doc exists but no master-roadmap entry
#
# Skip cases:
#   - hook_enabled.master_roadmap_drift_detector is false in config
#
# Issue: #25

set -uo pipefail

# ─── Step 1: Read stdin ──────────────────────────────────────────────────────
input="$(cat 2>/dev/null || true)"
[ -z "$input" ] && exit 0

# ─── Step 2: Filter to PostToolUse / Bash / git commit ───────────────────────
event="$(printf '%s' "$input" | jq -r '.hook_event_name // empty' 2>/dev/null || true)"
[ "$event" != "PostToolUse" ] && exit 0

tool="$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null || true)"
[ "$tool" != "Bash" ] && exit 0

cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"
# Detect git commit at start-of-command or after a separator (per v2.0.1 S5 pattern)
if ! printf '%s' "$cmd" | grep -qE '(^|[;&|]\s*|\s+env\s+\S+=\S+\s+)git\s+commit'; then
    exit 0
fi

# ─── Step 3: Config check ────────────────────────────────────────────────────
config_helper="${CLAUDE_PLUGIN_ROOT:-}/lib/config.py"
if [ -f "$config_helper" ]; then
    enabled="$(python3 "$config_helper" get hook_enabled.master_roadmap_drift_detector 2>/dev/null || echo true)"
    if [ "$enabled" = "false" ]; then
        exit 0
    fi
fi

# ─── Step 4: Verify inside git working tree ──────────────────────────────────
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# ─── Step 5: Detect plan-doc files touched in last commit ────────────────────
touched_plans="$(git show --name-only --format= HEAD 2>/dev/null | grep -E '^docs/plans/[^/]+\.md$' | grep -vE '^docs/plans/master-roadmap-' || true)"
[ -z "$touched_plans" ] && exit 0

# ─── Step 6: Find master-roadmap file(s) ─────────────────────────────────────
master_roadmaps="$(find docs/plans -maxdepth 1 -name 'master-roadmap-*.md' 2>/dev/null || true)"

# If no master-roadmap exists, warn for each touched plan
if [ -z "$master_roadmaps" ]; then
    echo ""
    echo "⚠️  Master-roadmap drift detector: no master-roadmap-*.md file found in docs/plans/. Plan-doc(s) updated:"
    echo "$touched_plans" | sed 's/^/  - /'
    echo "Consider creating docs/plans/master-roadmap-<year>-q<quarter>.md to track plan-doc rollups."
    exit 0
fi

# ─── Step 7: Cross-reference each touched plan vs each master-roadmap ────────
drift_found=""

while IFS= read -r plan; do
    [ -z "$plan" ] && continue
    [ ! -f "$plan" ] && continue

    plan_basename="$(basename "$plan" .md)"

    # Parse plan-doc state (look for archive/shipped/merged markers in first 20 lines)
    plan_state="$(head -20 "$plan" 2>/dev/null | grep -iE 'status:|shipped|archived|merged' | head -1 || true)"

    # Detect "shipped" state in plan-doc
    if printf '%s' "$plan_state" | grep -qiE 'archived|shipped|merged'; then
        plan_shipped="yes"
    else
        plan_shipped="no"
    fi

    # Find matching entry in each master-roadmap
    found_in_roadmap=""
    roadmap_says_pending="no"
    while IFS= read -r roadmap; do
        [ -z "$roadmap" ] && continue
        if grep -qE "$plan_basename" "$roadmap" 2>/dev/null; then
            found_in_roadmap="yes"
            # Read the matching line
            roadmap_line="$(grep -E "$plan_basename" "$roadmap" | head -1)"
            if printf '%s' "$roadmap_line" | grep -qiE 'ready for review|pending|in.progress|on branch|todo'; then
                roadmap_says_pending="yes"
            fi
        fi
    done <<< "$master_roadmaps"

    # Drift detection
    if [ "$plan_shipped" = "yes" ] && [ "$roadmap_says_pending" = "yes" ]; then
        drift_found+="  - \`$plan\` is shipped/archived BUT master-roadmap still says pending"$'\n'
    fi

    if [ "$found_in_roadmap" != "yes" ]; then
        drift_found+="  - \`$plan\` has no entry in any master-roadmap-*.md"$'\n'
    fi

done <<< "$touched_plans"

# ─── Step 8: Emit drift warning if any ───────────────────────────────────────
if [ -n "$drift_found" ]; then
    echo ""
    echo "⚠️  Master-roadmap drift detected (commit succeeded; this is a warning):"
    echo ""
    echo "$drift_found"
    echo "Update the corresponding master-roadmap entry to reflect the plan-doc state."
fi

exit 0
```

- [ ] **Step 2: Make executable + run for GREEN state**

```bash
chmod +x hooks/master-roadmap-drift-detector.sh
bash tests/test_master_roadmap_drift_detector_hook.sh
```

Expected: `🟢 All hook scenarios passed.`

### Task 10: Register master-roadmap-drift-detector in hooks.json

**Files:**
- Modify: `hooks/hooks.json`

- [ ] **Step 1: Add the hook to the existing PostToolUse.Bash entry (if there's no Bash matcher yet under PostToolUse) OR create a new PostToolUse.Bash block**

Current PostToolUse has only a `Skill` matcher. Add a new entry under `PostToolUse` with `matcher: "Bash"`:

```json
        "PostToolUse": [
            {
                "matcher": "Skill",
                "hooks": [
                    {
                        "type": "command",
                        "command": "${CLAUDE_PLUGIN_ROOT}/hooks/visual-companion-default-on.sh"
                    },
                    {
                        "type": "command",
                        "command": "${CLAUDE_PLUGIN_ROOT}/hooks/brainstorm-t1-audit.sh"
                    }
                ]
            },
            {
                "matcher": "Bash",
                "hooks": [
                    {
                        "type": "command",
                        "command": "${CLAUDE_PLUGIN_ROOT}/hooks/master-roadmap-drift-detector.sh"
                    }
                ]
            }
        ]
```

- [ ] **Step 2: Validate JSON**

```bash
python3 -c '
import json
h = json.load(open("hooks/hooks.json"))
post = h["hooks"]["PostToolUse"]
print("PostToolUse blocks:", len(post))
for b in post:
    print(" ", b["matcher"], "→", len(b["hooks"]), "hook(s)")
'
```

Expected output:
```
PostToolUse blocks: 2
  Skill → 2 hook(s)
  Bash → 1 hook(s)
```

- [ ] **Step 3: Re-run the hook test**

```bash
bash tests/test_master_roadmap_drift_detector_hook.sh
```

Expected: still 🟢.

---

## STEP B.5 — Shared updates: config, schema, docs, version, CHANGELOG

### Task 11: Update config.defaults.yaml

**Files:**
- Modify: `config.defaults.yaml`

- [ ] **Step 1: Add 3 new hook_enabled entries + 1 stale_branch_sweep block**

Use Edit tool. Find the existing `hook_enabled:` block (lines ~16-22 of config.defaults.yaml — verify by reading first 30 lines).

Add 3 new lines under `hook_enabled:`:

```yaml
hook_enabled:
  banned_token_leak_guard: true
  no_claude_attribution: true
  teamcity_always: true
  anti_silent_deferral: true
  brainstorm_t1_audit: true
  visual_companion_default_on: true
  sprint_state_context_injection: true
  stale_branch_sweep: true
  master_roadmap_drift_detector: true
```

Then add a NEW top-level block at the end of the file:

```yaml

# Stale-branch-sweep configuration.
stale_branch_sweep:
  # If true, automatically delete local branches whose upstream is gone
  # at session start. Default false — sweep emits cleanup suggestions only.
  # Env-var equivalent: LARAVEL_SUPERPOWERS_AUTO_PRUNE=1 (env wins if set).
  auto_prune: false
```

- [ ] **Step 2: Verify YAML still parses**

```bash
python3 -c 'import yaml; c = yaml.safe_load(open("config.defaults.yaml")); print("hook_enabled keys:", len(c["hook_enabled"]), "stale_branch_sweep.auto_prune:", c["stale_branch_sweep"]["auto_prune"])'
```

Expected output: `hook_enabled keys: 9 stale_branch_sweep.auto_prune: False`

### Task 12: Update config.schema.json

**Files:**
- Modify: `config.schema.json`

- [ ] **Step 1: Read the current schema**

```bash
cat config.schema.json
```

Identify the section that defines allowed keys (likely under `properties.hook_enabled` or similar).

- [ ] **Step 2: Extend the schema to allow the new top-level `stale_branch_sweep` block**

If the schema has explicit per-hook entries, add:
- `sprint_state_context_injection`, `stale_branch_sweep`, `master_roadmap_drift_detector` under `properties.hook_enabled.properties` as `{ "type": "boolean" }`
- New top-level `stale_branch_sweep` block with `auto_prune: boolean`

If the schema relies on `additionalProperties: true` for hook_enabled, only add the new top-level `stale_branch_sweep` block.

The exact edit depends on schema shape — read it first, then apply the minimal change to allow the new keys without breaking existing validation.

- [ ] **Step 3: Validate the schema against config.defaults.yaml**

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

Expected: `✓ schema validates config.defaults.yaml` (no exception).

### Task 13: Update tests/test_config.py for new schema entries

**Files:**
- Modify: `tests/test_config.py`

- [ ] **Step 1: Add 2 tests for the new flags**

Read the existing test_config.py and find the `test_get_returns_default_value` and `test_validate_defaults_passes` tests to see the pattern.

Add two new tests:

```python
def test_get_sprint_state_context_injection_default():
    """New B-phase hook flag defaults to true."""
    cli = ConfigCLI([])  # use whatever your fixture pattern is — adapt to existing style
    result = cli.run(["get", "hook_enabled.sprint_state_context_injection"])
    assert result.strip() == "true"


def test_get_stale_branch_sweep_auto_prune_default():
    """Auto-prune opt-in defaults to false."""
    cli = ConfigCLI([])
    result = cli.run(["get", "stale_branch_sweep.auto_prune"])
    assert result.strip() == "false"
```

Adapt the test style to match the existing tests in the file. Read the file first to match fixture conventions.

- [ ] **Step 2: Run all Python tests**

```bash
python3 -m pytest tests/ -v
```

Expected: 30 passed (28 existing + 2 new). All green.

### Task 14: Add hook documentation to docs/hooks.md

**Files:**
- Modify: `docs/hooks.md`

- [ ] **Step 1: Read the existing pattern**

```bash
head -80 docs/hooks.md
```

Each hook section has: `### <hook-name>`, `**Event:**`, `**What it does:**`, `**Why:**`, examples, configuration notes.

- [ ] **Step 2: Append 3 new sections at the end of the Hooks section**

Use Edit tool to insert (before any "## Configuration" or trailing footer section) three new hook documentation blocks:

````markdown
### `sprint-state-context-injection`

**Event:** `SessionStart`.

**What it does:** detects active sprint via current branch name + optional resume-anchor file + plan-doc, injects a compact sprint-state summary (branch, plan-doc path, current phase, last commit) into the session's system prompt context.

**Why:** zero-touch sprint resume. Eliminates the 15-second manual paste of resume context at the start of every session.

**Detection logic:**

- Active sprint = current branch matches `feat/*`, `chore/*`, `spec/*`, `fix/*`, or `docs/*`
- Resume anchor (optional): `docs/superpowers/<branch-suffix>-resume.md`
- Plan doc (optional): `docs/plans/<branch-suffix>.md` or `docs/superpowers/plans/*<branch-suffix>*.md`

**Skip cases:**

- Branch is `main` / `master` / detached HEAD
- `LARAVEL_SUPERPOWERS_SKIP_AUTO_RESUME` env var is set
- `hook_enabled.sprint_state_context_injection: false` in config

### `stale-branch-sweep`

**Event:** `SessionStart`.

**What it does:** runs `git fetch --prune` silently, then lists local branches whose upstream is `[gone]` (typically post-merge) with a cleanup suggestion. Does NOT auto-delete by default.

**Why:** post-merge cleanup hygiene. Surfaces stale branches at the moment you're most likely to act on them (session start), without nagging or auto-deleting.

**Auto-delete opt-in:**

- Env var: `LARAVEL_SUPERPOWERS_AUTO_PRUNE=1`
- Or config: `stale_branch_sweep.auto_prune: true` in `.laravel-superpowers.yaml` (filename preserved from V2 for config compatibility)

**Skip cases:**

- `hook_enabled.stale_branch_sweep: false` in config
- Not inside a git working tree

### `master-roadmap-drift-detector`

**Event:** `PostToolUse` on `Bash` (filters internally to `git commit` invocations touching `docs/plans/*.md`).

**What it does:** after a commit touches a plan-doc file, cross-references the plan-doc state (archived / shipped / merged) against the matching entry in `docs/plans/master-roadmap-<year>-q<quarter>.md`. Emits a warning to stdout when the master-roadmap entry is out of sync. Does NOT block the commit.

**Why:** Block 1A canon-drift evidence — Bot Directory shipped via MR !123 but master-roadmap entry stayed in "ready for review on branch" state for weeks. This hook catches that exact pattern at commit time.

**Drift cases flagged:**

- Plan-doc is archived/shipped but master-roadmap entry still says pending / ready-for-review / on-branch
- Plan-doc exists but has no entry in any master-roadmap file

**Skip cases:**

- `hook_enabled.master_roadmap_drift_detector: false` in config
- No master-roadmap files exist (suggests creating one)
- Commit doesn't touch any `docs/plans/*.md` outside the master-roadmap itself
````

- [ ] **Step 3: Verify the additions render correctly**

```bash
grep -nE '^### `(sprint-state|stale-branch|master-roadmap)' docs/hooks.md
```

Expected: 3 matches, one per new hook.

### Task 15: Update README.md hook count

**Files:**
- Modify: `README.md`

**Note on counts:** V2.0.1 ships 6 hooks (`ls hooks/*.sh | wc -l` = 6 — the spec section "7 hooks" was off-by-one). Phase B adds 3 hooks → Phase B ships 9 hooks total.

- [ ] **Step 1: Find the hook count references**

```bash
grep -nE '[67] (hooks|enforcement)' README.md
```

- [ ] **Step 2: Update each occurrence**

For each line found in Step 1, update with Edit tool to reflect the new count:
- `6 hooks` or `7 hooks` → `9 hooks` (or `6 enforcement + 3 context-injection` if more descriptive)

Read the file's "Features" or "Plugin contents" section to understand the exact phrasing and adapt.

- [ ] **Step 3: Sanity check**

```bash
head -60 README.md
grep -nE '[0-9]+ hooks' README.md
```

Confirm only `9 hooks` (or equivalent descriptive phrasing summing to 9) appears.

### Task 16: Prepend v3.0.0-alpha.2 entry to CHANGELOG.md

**Files:**
- Modify: `CHANGELOG.md`

- [ ] **Step 1: Insert new section above `## [3.0.0-alpha.1]`**

Use Edit tool to insert immediately before `## [3.0.0-alpha.1]`:

```markdown
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

Phase B (this alpha) — ✅ shipped 2026-05-17 as v3.0.0-alpha.2.

Phases C-G remain.

---

```

(Match the existing `---` separator convention.)

### Task 17: Bump plugin.json version

**Files:**
- Modify: `.claude-plugin/plugin.json`

- [ ] **Step 1: Bump version + update description**

Read the current `plugin.json` to confirm structure. Then use Edit:

`old_string`:
```
    "version": "3.0.0-alpha.1",
```
`new_string`:
```
    "version": "3.0.0-alpha.2",
```

If the description mentions current hook count, update it too. The Phase A description currently says:
> "Current v3.0.0-alpha.1 ships 6 agents + 4 skills + 7 hooks + 1 slash command (renamed paths from v2)."

The "7 hooks" was off-by-one — actual count is 6 hooks in V2.0.1 + 3 new in Phase B = **9 hooks**.

Update the current-state clause to:
> "Current v3.0.0-alpha.2 ships 6 agents + 4 skills + 9 hooks + 1 slash command."

(Don't bother correcting the historical "Phase A shipped 7 hooks" wording — that's a Phase A description artifact. Just make the v3.0.0-alpha.2 current-state line correct.)

- [ ] **Step 2: Validate JSON**

```bash
python3 -c 'import json; p = json.load(open(".claude-plugin/plugin.json")); print(p["name"], p["version"])'
```

Expected output: `laravel-livewire-superpowers 3.0.0-alpha.2`

### Task 18: Full test suite verification

**Files:** None (verification).

- [ ] **Step 1: Run all shell hook tests**

```bash
for t in tests/test_*.sh; do bash "$t" >/dev/null 2>&1 && echo "✓ $t" || echo "✗ $t"; done
```

Expected: 10 shell tests `✓` (7 V2 + 3 new Phase B).

- [ ] **Step 2: Run all Python tests**

```bash
python3 -m pytest tests/ -v
```

Expected: 30 passed (28 existing + 2 new from Task 13).

- [ ] **Step 3: Sanity check hooks.json**

```bash
python3 -c '
import json
h = json.load(open("hooks/hooks.json"))
print("Event types:", list(h["hooks"].keys()))
print("Total hooks:")
total = 0
for ev, blocks in h["hooks"].items():
    for b in blocks:
        n = len(b.get("hooks", []))
        total += n
        print(f"  {ev} matcher={b.get(\"matcher\", \"any\")}: {n}")
print("Total:", total)
'
```

Expected output:
```
Event types: ['PreToolUse', 'PostToolUse', 'SessionStart']
Total hooks:
  PreToolUse matcher=Bash: 4
  PostToolUse matcher=Skill: 2
  PostToolUse matcher=Bash: 1
  SessionStart matcher=any: 2
Total: 9
```

(9 because the registration list is by event+matcher: PreToolUse.Bash=4 + PostToolUse.Skill=2 + PostToolUse.Bash=1 + SessionStart=2 = 9 registered entries. Physical file count: V2.0.1 had 6 .sh files; Phase B adds 3 = 9 .sh files total.)

```bash
ls hooks/*.sh | wc -l
```

Expected: `9` (V2.0.1 ships 6 hooks + 3 new from Phase B = 9 total).

### Task 19: Commit Phase B changes on the feature branch

**Files:** All Phase B additions/modifications staged.

- [ ] **Step 1: Review what will be committed**

```bash
git status
git diff --stat
```

Expected files in `git status` (12-15 files):
- New: `hooks/sprint-state-context-injection.sh`
- New: `hooks/stale-branch-sweep.sh`
- New: `hooks/master-roadmap-drift-detector.sh`
- New: `tests/test_sprint_state_context_injection_hook.sh`
- New: `tests/test_stale_branch_sweep_hook.sh`
- New: `tests/test_master_roadmap_drift_detector_hook.sh`
- Modified: `hooks/hooks.json`
- Modified: `config.defaults.yaml`
- Modified: `config.schema.json`
- Modified: `tests/test_config.py`
- Modified: `docs/hooks.md`
- Modified: `README.md`
- Modified: `CHANGELOG.md`
- Modified: `.claude-plugin/plugin.json`

- [ ] **Step 2: Stage all**

```bash
git add hooks/sprint-state-context-injection.sh hooks/stale-branch-sweep.sh \
        hooks/master-roadmap-drift-detector.sh \
        tests/test_sprint_state_context_injection_hook.sh \
        tests/test_stale_branch_sweep_hook.sh \
        tests/test_master_roadmap_drift_detector_hook.sh \
        hooks/hooks.json config.defaults.yaml config.schema.json \
        tests/test_config.py docs/hooks.md README.md CHANGELOG.md \
        .claude-plugin/plugin.json
git status
```

- [ ] **Step 3: Commit**

```bash
git commit -m "$(cat <<'EOF'
feat(v3): phase b — quickwin hooks (sprint-state, stale-branch, drift-detector)

Phase B of the V3 Megarelease ships three context-aware hooks that
surface daily sprint state without operator action. None block; all
are config-controlled with sensible defaults.

Hooks:
- sprint-state-context-injection (SessionStart, #24): detects active
  sprint via branch + optional resume-anchor + plan-doc, injects
  compact summary into session context. Skip on main; env-var or
  config disable.
- stale-branch-sweep (SessionStart, #26): runs git fetch --prune,
  lists [gone]-upstream branches with cleanup suggestion. Does NOT
  auto-delete. Auto-delete opt-in via env-var or config.
- master-roadmap-drift-detector (PostToolUse:Bash, #25): cross-refs
  plan-doc state vs master-roadmap entry on git commits touching
  docs/plans/. Non-blocking warning.

Shared updates:
- hooks/hooks.json: new SessionStart event registration + new
  PostToolUse.Bash matcher block.
- config.defaults.yaml: 3 new hook_enabled flags + 1 stale_branch_sweep
  block with auto_prune opt-in.
- config.schema.json: extended for new keys.
- tests: 3 new shell hook test suites (~18 scenarios total) + 2 new
  pytest tests. All 10 shell + 30 Python tests green.
- docs/hooks.md: 3 new reference sections.
- README.md: hook count bumped 6→9 (V2.0.1 had 6 hooks; Phase B adds 3).
- plugin.json: version 3.0.0-alpha.2.

All hooks follow established V2.0.1 patterns: stdin JSON read,
config check, match-then-act, emit hookSpecificOutput.additionalContext
or stdout for warnings. Env-var names preserve LARAVEL_SUPERPOWERS_
prefix for V2-operator habit continuity.
EOF
)"
```

Expected: commit succeeds, no hook blocks.

If `banned-token-leak-guard` blocks because the commit body mentions Phase B etc — read the block reason carefully (per v2.0.1 S1 narrowing, the date pattern only triggers on prefix-keywords directly preceding an ISO date; this commit body should be clean). If it does block, report.

### Task 20: Push feature branch and open PR

**Files:** None.

- [ ] **Step 1: Push the branch**

```bash
git push -u origin feat/v3-phase-b-quickwin-hooks
```

- [ ] **Step 2: Open the PR**

```bash
gh pr create \
  --base main \
  --head feat/v3-phase-b-quickwin-hooks \
  --title "feat(v3): phase b — quickwin hooks (sprint-state, stale-branch, drift-detector)" \
  --body "$(cat <<'EOF'
## Summary

Phase B of the V3 Megarelease — see [the design spec](docs/superpowers/specs/2026-05-17-v3-livewire-megarelease-design.md) Section 5 and [the Phase B implementation plan](docs/superpowers/plans/2026-05-17-v3-phase-b-quickwin-hooks.md).

Three context-aware hooks that surface daily sprint state without operator action. None block.

### Hooks added

- **`sprint-state-context-injection`** (SessionStart) — closes [#24](https://github.com/altraWeb/laravel-livewire-superpowers/issues/24)
- **`stale-branch-sweep`** (SessionStart) — closes [#26](https://github.com/altraWeb/laravel-livewire-superpowers/issues/26)
- **`master-roadmap-drift-detector`** (PostToolUse:Bash) — closes [#25](https://github.com/altraWeb/laravel-livewire-superpowers/issues/25)

### Shared updates

- `hooks/hooks.json`: new `SessionStart` event + new `PostToolUse.Bash` matcher
- `config.defaults.yaml` + `config.schema.json`: 3 new `hook_enabled.*` flags + new `stale_branch_sweep.auto_prune` block
- `docs/hooks.md`: 3 new reference sections
- `README.md`: hook count 6 → 9 (Phase B adds 3 context-injection hooks; corrects prior off-by-one phrasing)
- `.claude-plugin/plugin.json`: version 3.0.0-alpha.2

### Test plan

- [x] All 10 shell hook tests green (7 V2 + 3 new)
- [x] All 30 Python tests green (28 V2 + 2 new)
- [ ] Reviewer pulls the branch and runs `bash tests/test_*.sh` + `python3 -m pytest tests/`
- [ ] Reviewer manually triggers a SessionStart in a fresh Claude Code session in a feat/* branch to see sprint-state-context-injection in action

### After merge

- Cut `v3.0.0-alpha.2` tag + GitHub Pre-Release with the CHANGELOG section as release notes
- Move on to Phase C (3 new specialist agents: laravel-echo-reverb / spatie-permission-auditor / laravel-package-evaluator) with its own implementation plan
EOF
)"
```

Expected: PR URL returned.

- [ ] **Step 3: Report PR URL + pause for operator merge**

State to the operator: "Phase B PR open at <URL>. Tests green (10 shell + 30 Python). Ready for review + merge. After merge I'll cut v3.0.0-alpha.2 tag + GitHub Pre-Release, then start Phase C planning."

**STOP. Phase B implementation complete. Wait for operator to merge the PR before proceeding.**

---

## STEP B.6 — Post-Merge: Tag + Pre-Release

### Task 21: Tag v3.0.0-alpha.2 + GitHub Pre-Release

**Files:** None (git + gh CLI).

- [ ] **Step 1: Pull merged main**

```bash
cd ~/dev/laravel-livewire-superpowers
git switch main
git pull --ff-only origin main
git log --oneline -3
```

Expected: HEAD is the squash-merge commit of the Phase B PR.

- [ ] **Step 2: Tag v3.0.0-alpha.2**

```bash
git tag -a v3.0.0-alpha.2 -m "v3.0.0-alpha.2 — V3 Megarelease Phase B: Quickwin Hooks (sprint-state, stale-branch, drift-detector)"
git push origin v3.0.0-alpha.2
git tag --list | grep '^v3\.'
```

Expected: `v3.0.0-alpha.1`, `v3.0.0-alpha.2` both listed.

- [ ] **Step 3: Create GitHub Pre-Release**

Extract the CHANGELOG body for v3.0.0-alpha.2:

```bash
gh release create v3.0.0-alpha.2 \
  --title "v3.0.0-alpha.2 — V3 Megarelease Phase B: Quickwin Hooks" \
  --prerelease \
  --notes "$(awk '/^## \[3\.0\.0-alpha\.2\]/{flag=1; next} /^---$/{if(flag){flag=0}} flag' CHANGELOG.md)"
```

(Note: this awk pattern is portable to macOS — uses pure awk, no `head -n -1` which is GNU-only.)

- [ ] **Step 4: Verify release**

```bash
gh release view v3.0.0-alpha.2 --json name,tagName,isDraft,isPrerelease,url
```

Expected: name matches, isDraft `false`, isPrerelease `true`, URL accessible.

- [ ] **Step 5: Report Phase B completion**

State to the operator: "Phase B complete. v3.0.0-alpha.2 tagged + pre-released at <URL>. Ready for Phase C (Specialist Agents) planning when you give the go."

**STOP. Phase B complete.**
