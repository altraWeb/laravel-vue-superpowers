#!/usr/bin/env bash
# no-claude-attribution — PreToolUse hook that blocks git commits and MR
# creations whose message contains Claude / AI attribution.
#
# Reads tool input JSON from stdin, filters to git commit / gh pr create /
# glab mr create invocations, extracts the message content from inline flags
# (-m, --body, --description) or file flags (-F, --body-file, --description-
# file), scans for attribution patterns, blocks (exit 2) on match.
#
# Exit codes:
#   0 — pass through (not a target command, hook disabled, no match, or
#       anything that isn't a definitive block reason). Fail-open.
#   2 — block; attribution found.
#
# Registered in hooks/hooks.json as PreToolUse on Bash, alongside
# banned-token-leak-guard. Both fire; each filters internally.

set -uo pipefail

# ─── Step 1: Read tool input from stdin ───────────────────────────────────────
input="$(cat 2>/dev/null || true)"
[ -z "$input" ] && exit 0

command_str="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"
[ -z "$command_str" ] && exit 0

# ─── Step 2: Detect command family ────────────────────────────────────────────
# Returns one of: git-commit, gh-pr, glab-mr, or empty (passthrough).
#
# v2.0.1 (S5): match at command-position — start of string OR after a
# separator (`;`, `&&`, `||`, `|`), optionally preceded by env-var assignments.
# Previous substring matching caused false-positives when the bash command
# contained the target as literal text inside `echo`, `grep`, `cat <<EOF`, etc.
# See docs/audits/2026-05-15-v2-mvp-self-audit.md §"Should-fix S5".
detect_family() {
    # Reject `git commit-tree` (porcelain that looks similar).
    case "$command_str" in
        *"git commit-tree"*) printf ''; return ;;
    esac
    local prefix='(^|[;&|][[:space:]]*)([A-Z_][A-Za-z0-9_]*=[^[:space:]]+[[:space:]]+)*'
    if printf '%s' "$command_str" | grep -qE "${prefix}git commit([[:space:]]|$)"; then
        printf 'git-commit'
    elif printf '%s' "$command_str" | grep -qE "${prefix}gh pr (create|edit)([[:space:]]|$)"; then
        printf 'gh-pr'
    elif printf '%s' "$command_str" | grep -qE "${prefix}glab mr (create|update)([[:space:]]|$)"; then
        printf 'glab-mr'
    else
        printf ''
    fi
}

family="$(detect_family)"
[ -z "$family" ] && exit 0

# Skip if --help mode.
case "$command_str" in
    *"--help"*|*" -h "*|*" -h"|*"--interactive"*)
        exit 0 ;;
esac

# ─── Step 3: Config check (fail-open) ─────────────────────────────────────────
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

enabled="$(config_get hook_enabled.no_claude_attribution true)"
[ "$enabled" = "true" ] || exit 0

# ─── Step 4: Extract message content ──────────────────────────────────────────
# We scan the command string itself for inline flags and any file flag's
# target file. The message is the concatenation of every extracted piece.
#
# Helper: extract value of a flag like `-m "foo bar"` or `--body 'baz'` or
# `--body=baz`. We use python3 with shlex for safe parsing.
#
# IMPORTANT (v2.0.1 fix): the heredoc must be quoted (<<'PYEOF') so Bash does
# NOT expand $flag / $cmd into the Python source. Values pass via environment
# variables; Python reads them from os.environ. Previously the unquoted heredoc
# embedded $cmd directly into a Python triple-quoted string, which broke on any
# message containing a `"` character — silently fail-opening the entire hook.
# See docs/audits/2026-05-15-v2-mvp-self-audit.md §"Blocker B1".
extract_flag_value() {
    FLAG="$1" CMD="$2" python3 - <<'PYEOF' 2>/dev/null
import os, shlex, sys
flag = os.environ.get("FLAG", "")
cmd = os.environ.get("CMD", "")
if not flag or not cmd:
    sys.exit(0)
try:
    tokens = shlex.split(cmd)
except ValueError:
    sys.exit(0)
values = []
i = 0
while i < len(tokens):
    t = tokens[i]
    if t == flag and i + 1 < len(tokens):
        values.append(tokens[i + 1])
        i += 2
    elif t.startswith(flag + "="):
        values.append(t[len(flag) + 1:])
        i += 1
    else:
        i += 1
print("\n".join(values))
PYEOF
}

# Read file content for -F / --body-file / --description-file paths.
read_file_safely() {
    local path="$1"
    [ -z "$path" ] && return 0
    [ -f "$path" ] && cat "$path" 2>/dev/null
}

message=""

case "$family" in
    git-commit)
        # -m one or more times (commit supports repeated -m for paragraph breaks)
        msg="$(extract_flag_value '-m' "$command_str")"
        message="${message}${msg:+$msg
}"
        # -F path
        file_path="$(extract_flag_value '-F' "$command_str")"
        if [ -n "$file_path" ]; then
            message="${message}$(read_file_safely "$file_path")
"
        fi
        # Editor mode (no -m, no -F) → cannot scan, warn + passthrough
        if [ -z "$message" ]; then
            case "$command_str" in
                *"-m "*|*"-m="*|*"-F "*|*"-F="*) ;;
                *)
                    printf 'no-claude-attribution: editor-mode commit detected; cannot scan message from PreToolUse hook. Rely on reviewer agent post-commit.\n' >&2
                    exit 0
                    ;;
            esac
        fi
        ;;
    gh-pr)
        for flag in --title --body; do
            v="$(extract_flag_value "$flag" "$command_str")"
            message="${message}${v:+$v
}"
        done
        file_path="$(extract_flag_value '--body-file' "$command_str")"
        if [ -n "$file_path" ]; then
            message="${message}$(read_file_safely "$file_path")
"
        fi
        ;;
    glab-mr)
        for flag in --title --description; do
            v="$(extract_flag_value "$flag" "$command_str")"
            message="${message}${v:+$v
}"
        done
        file_path="$(extract_flag_value '--description-file' "$command_str")"
        if [ -n "$file_path" ]; then
            message="${message}$(read_file_safely "$file_path")
"
        fi
        ;;
esac

# Nothing to scan? passthrough.
[ -z "$message" ] && exit 0

# ─── Step 5: Scan for attribution patterns ────────────────────────────────────
pattern='Co-Authored-By:.*Claude|Co-Authored-By:.*[Aa]nthropic|🤖.*Claude Code|Generated with.*Claude|\bAI-assisted\b|\bAI-generated\b|noreply@anthropic\.com'

# Collect offending lines with line numbers.
offending="$(printf '%s' "$message" | grep -nE "$pattern" 2>/dev/null || true)"

[ -z "$offending" ] && exit 0

# ─── Step 6: Build sanitized rewrite suggestion ───────────────────────────────
sanitized="$(printf '%s' "$message" | grep -vE "$pattern" 2>/dev/null | sed -e '/^$/N;/^\n$/D')"

# ─── Step 7: Diagnostic + block ───────────────────────────────────────────────
cat >&2 <<EOF
🚫 no-claude-attribution: commit blocked

Found Claude / AI attribution in ${family} message:

  ── offending lines ──────────────────────────────────────────────
$(printf '%s' "$offending" | sed 's/^/  Line /')
  ─────────────────────────────────────────────────────────────────

Sanitized message (remove the matching lines):

  ── suggested rewrite ────────────────────────────────────────────
$(printf '%s' "$sanitized" | sed 's/^/  /')
  ─────────────────────────────────────────────────────────────────

Operator's project canon: ZERO Claude attribution in commit messages,
MR titles, or MR bodies. Recommit with the sanitized message.

To disable globally, set in .laravel-superpowers.yaml (filename preserved from V2 for config compatibility):
    hook_enabled:
      no_claude_attribution: false
EOF

exit 2
