#!/usr/bin/env bash
# anti-silent-deferral — PreToolUse hook that blocks `git push` when any
# plan-doc on the current branch has uncaptured "## Phase N — Deferred Items"
# sections.
#
# Captured = section body is one of:
#   1. Empty (just whitespace)
#   2. Contains a "None — all tasks completed" marker line
#   3. Every `-` / `*` bullet contains an issue ref: #N, gh issue #N,
#      glab issue #N, or a github.com/gitlab.com issue URL
#
# Anything else (free-form prose, bullets without refs) = uncaptured = block.
#
# Exit codes:
#   0 — pass through (not a push, hook disabled, override env set, no plan-docs
#       changed, all sections captured)
#   2 — block; uncaptured deferrals found
#
# Registered in hooks/hooks.json as PreToolUse on Bash.

set -uo pipefail

# ─── Step 1: Read stdin ──────────────────────────────────────────────────────
input="$(cat 2>/dev/null || true)"
[ -z "$input" ] && exit 0

command_str="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"
[ -z "$command_str" ] && exit 0

# ─── Step 2: Filter to `git push` at command-position ────────────────────────
# v2.0.1 (S5): anchor at command-position to avoid matching `echo "git push"`
# or comments in inline scripts. See docs/audits/2026-05-15-v2-mvp-self-audit.md
# §"Should-fix S5".
if ! printf '%s' "$command_str" | grep -qE '(^|[;&|][[:space:]]*)([A-Z_][A-Za-z0-9_]*=[^[:space:]]+[[:space:]]+)*git push([[:space:]]|$)'; then
    exit 0
fi

# Skip --help and other non-actionable invocations.
case "$command_str" in
    *"--help"*|*" -h "*|*" -h"|*"--dry-run"*)
        exit 0
        ;;
esac

# ─── Step 3: Emergency override ──────────────────────────────────────────────
if [ "${LARAVEL_SUPERPOWERS_ALLOW_UNCAPTURED_DEFERRAL:-0}" = "1" ]; then
    printf 'anti-silent-deferral: override active (LARAVEL_SUPERPOWERS_ALLOW_UNCAPTURED_DEFERRAL=1) — deferrals not checked\n' >&2
    exit 0
fi

# ─── Step 4: Config check ─────────────────────────────────────────────────────
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

enabled="$(config_get hook_enabled.anti_silent_deferral true)"
[ "$enabled" = "true" ] || exit 0

# ─── Step 5: Determine branch scope ──────────────────────────────────────────
# Find plan-docs that changed on this branch vs main (or upstream).
# Fall back gracefully if main doesn't exist.

if ! git rev-parse --verify main >/dev/null 2>&1; then
    # No main ref — try upstream
    if ! upstream="$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)"; then
        # No upstream either — can't determine scope, pass through
        exit 0
    fi
    base_ref="$upstream"
else
    base_ref="main"
fi

# Get plan-docs changed on this branch.
plan_docs="$(git diff "$base_ref"..HEAD --name-only -- 'docs/plans/*.md' 2>/dev/null || true)"
[ -z "$plan_docs" ] && exit 0

# ─── Step 6: Parse and validate each plan-doc ────────────────────────────────
# For each plan-doc, walk `## Phase N — Deferred Items` sections via awk,
# collect each section's body lines + line numbers, then validate.

uncaptured_findings=""
finding_count=0

validate_section() {
    # $1 = file path
    # $2 = phase number
    # $3 = first body line number
    # $4 = body (multi-line)
    local file="$1"
    local phase="$2"
    local first_line="$3"
    local body="$4"

    # Strip leading/trailing blank lines.
    local stripped
    stripped="$(printf '%s' "$body" | awk '
        BEGIN { in_content = 0 }
        /^[[:space:]]*$/ {
            if (in_content) { blank_buffer = blank_buffer "\n" }
            next
        }
        {
            if (!in_content) { in_content = 1 }
            else if (blank_buffer != "") { printf "%s", blank_buffer; blank_buffer = "" }
            print
        }
    ')"

    # Case 1: empty body → captured
    if [ -z "$stripped" ]; then
        return 0
    fi

    # Case 2: "None — all tasks completed" marker present → captured
    if printf '%s' "$stripped" | grep -qiE 'None.*task[s]? completed'; then
        return 0
    fi
    if printf '%s' "$stripped" | grep -qiE '^\s*\*\*?None\.?\*?\*?\s*$'; then
        return 0
    fi
    if printf '%s' "$stripped" | grep -qiE '^\s*_None\._\s*$'; then
        return 0
    fi

    # Case 3: every bullet line has an issue ref
    # Collect non-bullet, non-blank lines (free-form prose = uncaptured).
    local has_prose=0
    local has_unlinked_bullet=0
    local offending_lines=""

    local line_no=$((first_line - 1))
    while IFS= read -r line; do
        line_no=$((line_no + 1))
        # Skip blank lines.
        [[ "$line" =~ ^[[:space:]]*$ ]] && continue

        # Is it a bullet?
        if [[ "$line" =~ ^[[:space:]]*[-*][[:space:]] ]]; then
            # Bullet — check for issue ref.
            if printf '%s' "$line" | grep -qE '#[0-9]+|(gh|glab) issue #?[0-9]+|github\.com/.*/issues/[0-9]+|gitlab\.com/.*/issues/[0-9]+'; then
                continue  # captured bullet
            else
                has_unlinked_bullet=1
                offending_lines="${offending_lines}    Line ${line_no}: ${line}
"
            fi
        else
            # Free-form prose.
            has_prose=1
            offending_lines="${offending_lines}    Line ${line_no}: ${line}
"
        fi
    done <<< "$body"

    if [ "$has_prose" = "1" ] || [ "$has_unlinked_bullet" = "1" ]; then
        local reason
        if [ "$has_prose" = "1" ]; then
            reason="Free-form prose detected — captured deferrals must be filed issues OR explicit None."
        else
            reason="Bullets do not contain filed-issue refs (#N format)."
        fi
        uncaptured_findings="${uncaptured_findings}
  ── ${file} ────────────────────────────────
  ## Phase ${phase} — Deferred Items
${offending_lines}  ── reason ───────────────────────────────────
  ${reason}
"
        finding_count=$((finding_count + 1))
        return 1
    fi

    return 0
}

# Walk each plan-doc.
while IFS= read -r file; do
    [ -z "$file" ] && continue
    [ -f "$file" ] || continue

    # Per-doc skip marker.
    if grep -q '<!-- anti-silent-deferral-skip:' "$file"; then
        continue
    fi

    # Use awk to extract each `## Phase N — Deferred Items` section's body
    # and its starting line number. Output format per section:
    #   ===PHASE=== <phase> <first_body_line>
    #   <body lines>
    #   ===END===
    awk_output="$(awk '
        BEGIN { in_section = 0; phase = ""; first_line = 0; body = "" }
        /^## Phase [0-9]+ (—|-) Deferred Items[[:space:]]*$/ {
            if (in_section) {
                printf "===PHASE=== %s %s\n%s===END===\n", phase, first_line, body
            }
            in_section = 1
            # Extract phase number
            match($0, /Phase [0-9]+/)
            phase_str = substr($0, RSTART+6, RLENGTH-6)
            phase = phase_str
            first_line = NR + 1
            body = ""
            next
        }
        /^## / && in_section {
            printf "===PHASE=== %s %s\n%s===END===\n", phase, first_line, body
            in_section = 0
            body = ""
            next
        }
        in_section { body = body $0 "\n" }
        END {
            if (in_section) {
                printf "===PHASE=== %s %s\n%s===END===\n", phase, first_line, body
            }
        }
    ' "$file")"

    # Parse the awk output and validate each section.
    if [ -z "$awk_output" ]; then
        continue
    fi

    current_phase=""
    current_first_line=""
    current_body=""
    in_section_block=0

    while IFS= read -r line; do
        if [[ "$line" =~ ^===PHASE===\ ([0-9]+)\ ([0-9]+)$ ]]; then
            current_phase="${BASH_REMATCH[1]}"
            current_first_line="${BASH_REMATCH[2]}"
            current_body=""
            in_section_block=1
        elif [ "$line" = "===END===" ]; then
            validate_section "$file" "$current_phase" "$current_first_line" "$current_body"
            in_section_block=0
        elif [ "$in_section_block" = "1" ]; then
            current_body="${current_body}${line}
"
        fi
    done <<< "$awk_output"
done <<< "$plan_docs"

# ─── Step 7: Block or pass ───────────────────────────────────────────────────
if [ "$finding_count" -gt 0 ]; then
    cat >&2 <<EOF
🚫 anti-silent-deferral: push blocked

Found uncaptured deferrals in plan-docs on this branch:
${uncaptured_findings}

To unblock:
  1. Either complete the deferred work and remove the section
  2. OR file each deferral as a GitLab/GitHub issue, then replace
     the prose with bulleted #N references:

       glab issue create --title "..." --label "deferred"
       # → returns issue #N

       Then replace the bullet with:
       - #N — short description (deferred from <plan> Phase X)

  3. OR mark the section explicitly empty:

       ## Phase N — Deferred Items
       **None — all tasks completed as planned.**

Emergency override (logged):
  LARAVEL_SUPERPOWERS_ALLOW_UNCAPTURED_DEFERRAL=1 git push

To disable globally, set in .laravel-superpowers.yaml (filename preserved from V2 for config compatibility):
    hook_enabled:
      anti_silent_deferral: false
EOF
    exit 2
fi

exit 0
