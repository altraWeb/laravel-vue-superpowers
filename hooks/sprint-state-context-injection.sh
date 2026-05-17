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
