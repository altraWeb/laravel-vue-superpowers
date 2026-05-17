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
