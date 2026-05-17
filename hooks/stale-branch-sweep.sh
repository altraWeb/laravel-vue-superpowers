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
# Time-bounded fetch — 10s connect timeout, no terminal prompts. Won't block session start
# if remote is slow/unreachable.
GIT_TERMINAL_PROMPT=0 git -c http.connectTimeout=5 -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=5 fetch --prune --quiet 2>/dev/null || true

# ─── Step 6: List local branches with upstream gone ──────────────────────────
stale_branches="$(git branch -vv 2>/dev/null | grep ': gone\]' | sed 's/^\* //' | awk '{print $1}' | sort -u || true)"

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
