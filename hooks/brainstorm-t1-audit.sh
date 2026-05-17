#!/usr/bin/env bash
# brainstorm-t1-audit — PostToolUse hook that fires on Skill tool invocations,
# filters to superpowers:brainstorming, and emits an additionalContext
# reminder that the parent agent should dispatch laravel-best-practices as a
# parallel background task per Pilot 2.0 Tactic 1 (Phase-Start Agent-Audit).
#
# Spec deviation from issue #20: issue asks for "auto-dispatch Agent in
# background". Hooks cannot invoke agents (architecture constraint — hooks
# are shell scripts; agent dispatch is a harness primitive). Hook injects a
# REMINDER + canonical dispatch prompt template instead. Parent agent does
# the actual Task-tool dispatch when it sees the reminder.
#
# Exit codes:
#   0 — always (PostToolUse hooks signal via stdout JSON)
#
# Registered in hooks/hooks.json under PostToolUse Skill matcher.

set -uo pipefail

# ─── Step 1: Read stdin ──────────────────────────────────────────────────────
input="$(cat 2>/dev/null || true)"
[ -z "$input" ] && exit 0

skill_name="$(printf '%s' "$input" | jq -r '.tool_input.skill // empty' 2>/dev/null || true)"
[ -z "$skill_name" ] && exit 0

skill_args="$(printf '%s' "$input" | jq -r '.tool_input.args // empty' 2>/dev/null || true)"

# ─── Step 2: Filter to brainstorming ──────────────────────────────────────────
if [ "$skill_name" != "superpowers:brainstorming" ]; then
    exit 0
fi

# ─── Step 3: Config check ─────────────────────────────────────────────────────
config_helper="${CLAUDE_PLUGIN_ROOT:-}/lib/config.py"

config_get() {
    local key="$1"
    local fallback="$2"
    if [ -f "$config_helper" ]; then
        python3 "$config_helper" get "$key" 2>/dev/null || printf '%s' "$fallback"
    else
        printf '%s' "$fallback"
    fi
}

enabled="$(config_get hook_enabled.brainstorm_t1_audit true)"
[ "$enabled" = "true" ] || exit 0

aggressiveness="$(config_get audit_aggressiveness every-phase)"
case "$aggressiveness" in
    every-phase|every-commit|brainstorm-only|"") : ;;
    *) exit 0 ;;
esac

# ─── Step 4: Build reminder ───────────────────────────────────────────────────
# Topic from brainstorming args; empty → agent infers from conversation.
if [ -n "$skill_args" ]; then
    topic_text="Topic: ${skill_args}"
else
    topic_text="Topic: detect from conversation context (operator brainstorm question or stated goal)"
fi

# Build reminder using printf — avoids heredoc/quote issues with bash 3.2.
# Backticks are escaped because they would otherwise expand under printf.
reminder=""
reminder+='📋 Pilot 2.0 Tactic 1 (Phase-Start Agent-Audit): when you enter Step 2 of \`superpowers:brainstorming\`, dispatch \`laravel-best-practices\` as a **parallel background task** via the Task tool. The audit runs alongside your interactive brainstorming and surfaces best-practice research + anti-patterns + open questions.'
reminder+=$'\n\n'
reminder+='Canonical dispatch prompt for the audit:'
reminder+=$'\n\n'
reminder+="> Brainstorm-time Pilot 2.0 T1 audit. ${topic_text}."
reminder+=$'\n'
reminder+='> Stack: detect via composer.json + package.json (Laravel + Livewire + Flux Pro v2 + Pest 4 + PHP version).'
reminder+=$'\n>\n'
reminder+='> Output expectations:'
reminder+=$'\n'
reminder+='> 1. **Executive summary** — 3-5 lines, most important findings'
reminder+=$'\n'
reminder+='> 2. **Per-decision findings** — for each design decision in the brainstorm topic, what is the current-Laravel best practice? Cite sources (Tier 1: official docs, Tier 2: core-team blogs, Tier 3: Spatie/Laracasts/Laravel News)'
reminder+=$'\n'
reminder+='> 3. **Anti-patterns** — what to AVOID, with one-line rationale each'
reminder+=$'\n'
reminder+='> 4. **Open questions** — what is actively debated, what could not be resolved'
reminder+=$'\n>\n'
reminder+='> Search at least 3 sources. Always include year filter (e.g., "Laravel 12 X best practice 2025/2026") to avoid stale content.'
reminder+=$'\n\n'
reminder+='When the audit completes, archive its output to \`docs/superpowers/audits/YYYY-MM-DD-<short-topic>-audit.md\` (use the current date) so it is discoverable later.'
reminder+=$'\n\n'
reminder+='This dispatch is **default-on** unless the operator explicitly opts out. If skipping, say so explicitly in your response and document why — do not silently skip.'

# ─── Step 5: Emit additionalContext ──────────────────────────────────────────
jq -nc \
    --arg ctx "$reminder" \
    '{ hookSpecificOutput: { hookEventName: "PostToolUse", additionalContext: $ctx } }'

exit 0
