#!/usr/bin/env bash
# visual-companion-default-on — PostToolUse hook that fires on Skill tool
# invocations, filters to superpowers:brainstorming, and emits an
# additionalContext reminder that Visual Companion is default-on per the
# operator's memory rule.
#
# The reminder lives in the agent's context for the duration of the
# brainstorming flow, nudging it to offer the Companion at Step 2 unless the
# topic is provably text-only.
#
# Exit codes:
#   0 — always (PostToolUse hooks signal via JSON output, not exit code)
#       When emitting, stdout contains the additionalContext JSON.
#       When skipping (not brainstorming / disabled / text-only topic),
#       stdout is empty.
#
# Registered in hooks/hooks.json under PostToolUse Skill matcher.

set -uo pipefail

# ─── Step 1: Read stdin ──────────────────────────────────────────────────────
input="$(cat 2>/dev/null || true)"
[ -z "$input" ] && exit 0

# Extract skill name and args (if any).
skill_name="$(printf '%s' "$input" | jq -r '.tool_input.skill // empty' 2>/dev/null || true)"
[ -z "$skill_name" ] && exit 0

skill_args="$(printf '%s' "$input" | jq -r '.tool_input.args // empty' 2>/dev/null || true)"

# ─── Step 2: Filter to superpowers:brainstorming ─────────────────────────────
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

enabled="$(config_get hook_enabled.visual_companion_default_on true)"
[ "$enabled" = "true" ] || exit 0

# Top-level operator-wide opt-out.
visual_default="$(config_get visual_companion_default on)"
[ "$visual_default" = "off" ] && exit 0

# ─── Step 4: Text-only denylist check ─────────────────────────────────────────
# Defaults; project may extend via visual_companion_default.text_only_patterns
default_denylist='\bname[d]? vote\b|\bnaming\b|\brename\b|\bsemver\b|\bversion bump\b|\bconfig flag\b|\bconfig flip\b|\bwhich constant\b|\bnumeric default\b|\benum value\b'

# Extras (config returns JSON array; we join with |).
extras_json="$(config_get visual_companion_default.text_only_patterns '[]')"
extras="$(printf '%s' "$extras_json" | jq -r '. | join("|")' 2>/dev/null || true)"

if [ -n "$extras" ]; then
    denylist="${default_denylist}|${extras}"
else
    denylist="$default_denylist"
fi

# Allowlist (force-emit even on denylist match).
allowlist_json="$(config_get visual_companion_default.always_offer_patterns '[]')"
allowlist="$(printf '%s' "$allowlist_json" | jq -r '. | join("|")' 2>/dev/null || true)"

# Check args against denylist.
if [ -n "$skill_args" ] && printf '%s' "$skill_args" | grep -qiE "$denylist"; then
    # Args match denylist. Check allowlist override.
    if [ -n "$allowlist" ] && printf '%s' "$skill_args" | grep -qiE "$allowlist"; then
        : # allowlist overrides denylist, proceed to emit
    else
        # text-only topic, skip
        exit 0
    fi
fi

# ─── Step 5: Emit additionalContext reminder ─────────────────────────────────
reminder='📋 Per operator memory rule `feedback_visual_companion_default_on`: Visual Companion is DEFAULT-ON for every brainstorm unless the topic is provably text-only. When you reach Step 2 of `superpowers:brainstorming`, you MUST offer the Visual Companion as its own message (per the skill spec). Do not skip it — operator explicitly wants it for any topic that could benefit from mockups, diagrams, or wireframes. If you genuinely believe this topic is text-only (naming vote, semver, config-flip), say so explicitly and explain why before skipping.'

# Output PostToolUse hookSpecificOutput JSON.
jq -nc \
    --arg ctx "$reminder" \
    '{ hookSpecificOutput: { hookEventName: "PostToolUse", additionalContext: $ctx } }'

exit 0
