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
    # Strip leading YYYY-MM-DD- date prefix if present (plan files in docs/plans/ are date-prefixed)
    plan_basename_clean="$(echo "$plan_basename" | sed 's/^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-//')"

    # Parse plan-doc state (look for archive/shipped/merged markers in first 20 lines)
    plan_state="$(head -20 "$plan" 2>/dev/null | grep -iE 'status:|shipped|archived|merged' | head -1 || true)"

    # Detect "shipped" state in plan-doc
    if printf '%s' "$plan_state" | grep -qiE 'archived|shipped|merged'; then
        plan_shipped="yes"
    else
        plan_shipped="no"
    fi

    # Find matching entry in each master-roadmap
    # Build a flexible pattern: "feature-x" matches "feature-x", "feature x", "Feature X", etc.
    # Use plan_basename_clean (date-prefix stripped) so "2026-05-17-v3-phase-b" -> "v3-phase-b"
    plan_pattern="$(echo "$plan_basename_clean" | sed 's/-/[-_ ]/g')"

    found_in_roadmap=""
    roadmap_says_pending="no"
    while IFS= read -r roadmap; do
        [ -z "$roadmap" ] && continue
        if grep -qiE "(^|[[:blank:][:punct:]])${plan_pattern}([[:blank:][:punct:]]|$)" "$roadmap" 2>/dev/null; then
            found_in_roadmap="yes"
            # Read the matching line
            roadmap_line="$(grep -iE "(^|[[:blank:][:punct:]])${plan_pattern}([[:blank:][:punct:]]|$)" "$roadmap" | head -1)"
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
