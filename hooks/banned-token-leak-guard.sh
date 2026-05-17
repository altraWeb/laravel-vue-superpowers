#!/usr/bin/env bash
# banned-token-leak-guard — PreToolUse hook that blocks `git commit` when staged
# files contain banned tokens (Phase/Sprint/MR/dated refs) in code comments.
#
# Reads tool input JSON from stdin, filters to git commit invocations, queries
# the plugin config (lib/config.py) for enable flag + project extras + exception
# paths, then scans staged files. Honors per-line override marker `banned-token-ok:`.
#
# Exit codes:
#   0 — pass through (not a commit, hook disabled, no matches, or anything that
#       isn't a definitive block reason). Fail-open.
#   2 — block the commit; matches found.
#
# This hook is registered in hooks/hooks.json as PreToolUse on Bash.

set -uo pipefail

# ─── Step 1: Read tool input from stdin ───────────────────────────────────────
input="$(cat 2>/dev/null || true)"
[ -z "$input" ] && exit 0

# Extract the bash command; if jq is missing or parse fails, pass through.
command_str="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"
[ -z "$command_str" ] && exit 0

# ─── Step 2: Filter to `git commit` at command-position ──────────────────────
# v2.0.1 (S5): match `git commit` ONLY when it appears at command-position —
# start of string OR after a separator (`;`, `&&`, `||`, `|`), optionally
# preceded by env-var assignments. This avoids false-positives when the bash
# command contains `git commit` as a literal substring inside an `echo`,
# `grep`, `man`, or heredoc body. Reject `git commit-tree` explicitly.
# See docs/audits/2026-05-15-v2-mvp-self-audit.md §"Should-fix S5".
if ! printf '%s' "$command_str" | grep -qE '(^|[;&|][[:space:]]*)([A-Z_][A-Za-z0-9_]*=[^[:space:]]+[[:space:]]+)*git commit([[:space:]]|$)'; then
    exit 0
fi
# Defensive: reject `git commit-tree` (porcelain that looks similar).
case "$command_str" in
    *"git commit-tree"*) exit 0 ;;
esac

# Some commit variants we still pass through (interactive --help / --interactive).
case "$command_str" in
    *"--help"*|*" -h "*|*" -h"|*"--interactive"*)
        exit 0
        ;;
esac

# ─── Step 3: Read config (fail-open on any error) ─────────────────────────────
config_helper="${CLAUDE_PLUGIN_ROOT:-}/lib/config.py"

config_get() {
    # $1 = dotted key, $2 = fallback value when helper fails or key missing
    local key="$1"
    local fallback="$2"
    if [ -x "$config_helper" ] || [ -f "$config_helper" ]; then
        python3 "$config_helper" get "$key" 2>/dev/null || printf '%s' "$fallback"
    else
        printf '%s' "$fallback"
    fi
}

# Hook can be disabled by setting hook_enabled.banned_token_leak_guard: false in
# either the user-global or per-project config. Default = true.
enabled="$(config_get hook_enabled.banned_token_leak_guard true)"
[ "$enabled" = "true" ] || exit 0

# Project-specific extras (JSON array of regex patterns). Default = [].
project_extras_json="$(config_get banned_tokens.project_extras "[]")"

# Project-specific exception paths (JSON array of glob strings).
exception_paths_json="$(config_get banned_tokens.exception_paths '["docs/plans/**","docs/superpowers/**","CHANGELOG.md"]')"

# ─── Step 4: Get staged files ────────────────────────────────────────────────
staged_files="$(git diff --cached --name-only 2>/dev/null || true)"
[ -z "$staged_files" ] && exit 0

# ─── Step 5+6: Filter by extension AND exception paths ────────────────────────
# Allowed extensions: php, blade.php, js, ts, css, md
# Drop any path matching exception paths.

# Build exception-path bash glob list from JSON array.
# (mapfile is bash 4+, not available on macOS's default bash 3.2 — use while-read.)
exception_paths=()
while IFS= read -r glob_line; do
    [ -n "$glob_line" ] && exception_paths+=("$glob_line")
done < <(printf '%s' "$exception_paths_json" | jq -r '.[]' 2>/dev/null)

is_excepted() {
    local file="$1"
    local glob
    # Guard against empty array under `set -u`.
    if [ "${#exception_paths[@]}" -eq 0 ]; then
        return 1
    fi
    shopt -s globstar 2>/dev/null
    for glob in "${exception_paths[@]}"; do
        # shellcheck disable=SC2053
        if [[ "$file" == $glob ]]; then
            return 0
        fi
    done
    return 1
}

# Filter staged files.
filtered_files=()
while IFS= read -r file; do
    [ -z "$file" ] && continue
    case "$file" in
        *.php|*.blade.php|*.js|*.ts|*.css|*.md) ;;
        *) continue ;;
    esac
    if is_excepted "$file"; then
        continue
    fi
    # Skip files that don't exist (deletions still show in --name-only).
    [ -f "$file" ] || continue
    filtered_files+=("$file")
done <<< "$staged_files"

[ ${#filtered_files[@]} -eq 0 ] && exit 0

# ─── Step 7: Build banned-token pattern ───────────────────────────────────────
# Defaults
#
# Date pattern (v2.0.1): context-anchored so legitimate ISO date literals
# (Carbon::parse('2026-01-01'), test fixtures, migration constants) do NOT
# trigger. Matches dates preceded by sprint-state keywords:
#   On 2026-05-15, Sprint: 2026-05-15, Released 2026-05-15, Phase: 2026-05-15,
#   Audit 2026-05-15, Review 2026-05-15, Deferred 2026-05-15
# See docs/audits/2026-05-15-v2-mvp-self-audit.md §"Should-fix S1".
default_patterns='Phase [0-9]+|Slice [0-9]+|Track [0-9]+|Sprint [0-9]+|MR !?[0-9]+|Pilot 2\.0|(On|Date|Sprint|Phase|Released|Shipped|Audit|Review|Deferred)[[:space:]:]+20[0-9]{2}-[0-9]{2}-[0-9]{2}'

# Project extras (each pattern OR'd into the main pattern).
extras="$(printf '%s' "$project_extras_json" | jq -r '. | join("|")' 2>/dev/null)"
if [ -n "$extras" ]; then
    pattern="${default_patterns}|${extras}"
else
    pattern="$default_patterns"
fi

# ─── Step 8: Scan filtered files, skip override-marker lines ──────────────────
findings=""
finding_count=0

for file in "${filtered_files[@]}"; do
    # grep -nE prints "line_no:line_content"; we then drop lines with
    # `banned-token-ok:` marker.
    while IFS= read -r match; do
        line_no="${match%%:*}"
        line_content="${match#*:}"
        # Skip if override marker present on the line.
        if printf '%s' "$line_content" | grep -q "banned-token-ok:"; then
            continue
        fi
        # Identify which pattern matched (best-effort — pick first match).
        token="$(printf '%s' "$line_content" | grep -oE "$pattern" | head -1)"
        findings="${findings}  ${file}:${line_no}  → \"${token}\"
    ${line_content}
"
        finding_count=$((finding_count + 1))
    done < <(grep -nE "$pattern" "$file" 2>/dev/null || true)
done

# ─── Step 9: Block or pass ────────────────────────────────────────────────────
if [ "$finding_count" -gt 0 ]; then
    cat >&2 <<EOF
🚫 banned-token-leak-guard: commit blocked

${finding_count} banned-token reference(s) found in staged files:

${findings}
These references rot fast and look unprofessional in shipped code.

To override per-line, add: \`banned-token-ok: <reason>\` to the line.
To disable globally, set in .laravel-superpowers.yaml (filename preserved from V2 for config compatibility):
    hook_enabled:
      banned_token_leak_guard: false
EOF
    exit 2
fi

exit 0
