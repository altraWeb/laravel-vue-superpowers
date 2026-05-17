#!/usr/bin/env bash
# Shell test driver for hooks/no-claude-attribution.sh
#
# Each scenario invokes the hook with a mocked tool_input JSON on stdin,
# captures exit code + stderr, and asserts.
#
# Run from repo root: bash tests/test_no_claude_attribution_hook.sh

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="${REPO_ROOT}/hooks/no-claude-attribution.sh"

[ -x "$HOOK" ] || { echo "FAIL: hook not executable at $HOOK"; exit 1; }

failures=0

run_with_command() {
    # $1 = bash command string to feed as tool_input.command
    local cmd="$1"
    local stderr_file
    stderr_file="$(mktemp)"
    export CLAUDE_PLUGIN_ROOT="$REPO_ROOT"
    local exit_code
    set +e
    printf '{"tool_input":{"command":%s}}' "$(printf '%s' "$cmd" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')" \
        | bash "$HOOK" 2> "$stderr_file"
    exit_code=$?
    set -e
    printf 'exit=%s\n' "$exit_code"
    printf -- '--- stderr ---\n'
    cat "$stderr_file"
    printf -- '--- end ---\n'
    rm -f "$stderr_file"
}

assert_exit() {
    local actual="$1" expected="$2" test_name="$3"
    if [ "$actual" = "$expected" ]; then
        printf '  ✅ %s — exit %s (expected)\n' "$test_name" "$actual"
    else
        printf '  ❌ %s — got exit %s, expected %s\n' "$test_name" "$actual" "$expected"
        failures=$((failures + 1))
    fi
}

extract_exit() {
    printf '%s' "$1" | grep -oE 'exit=[0-9]+' | head -1 | cut -d= -f2
}

# ─── Test 1: Block on Co-Authored-By trailer ─────────────────────────────────
echo
echo "▶ Test 1: Block on Co-Authored-By: Claude trailer"
msg="feat: add user page

Adds the user profile route.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
result=$(run_with_command "git commit -m '$msg'")
assert_exit "$(extract_exit "$result")" "2" "Co-Authored-By trailer should block"

# ─── Test 2: Block on robot emoji banner ─────────────────────────────────────
echo
echo "▶ Test 2: Block on 🤖 Generated with Claude Code banner"
msg="fix: tweak ui

🤖 Generated with [Claude Code](https://claude.com/code)"
result=$(run_with_command "git commit -m '$msg'")
assert_exit "$(extract_exit "$result")" "2" "🤖 banner should block"

# ─── Test 3: Block on AI-assisted phrase ─────────────────────────────────────
echo
echo "▶ Test 3: Block on AI-assisted phrase"
result=$(run_with_command "git commit -m 'AI-assisted refactor of the auth module'")
assert_exit "$(extract_exit "$result")" "2" "AI-assisted phrase should block"

# ─── Test 4: Block on -F file with attribution ───────────────────────────────
echo
echo "▶ Test 4: Block on git commit -F file containing attribution"
tmp_msg_file="$(mktemp)"
cat > "$tmp_msg_file" <<'EOF'
chore: bump deps

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
result=$(run_with_command "git commit -F $tmp_msg_file")
assert_exit "$(extract_exit "$result")" "2" "-F file with attribution should block"
rm -f "$tmp_msg_file"

# ─── Test 5: Block on gh pr create --body ────────────────────────────────────
echo
echo "▶ Test 5: Block on gh pr create --body with attribution"
result=$(run_with_command "gh pr create --title 'Feat: profile' --body 'Adds profile.

🤖 Generated with Claude Code'")
assert_exit "$(extract_exit "$result")" "2" "gh pr create --body should block"

# ─── Test 6: Block on glab mr create --description-file ──────────────────────
echo
echo "▶ Test 6: Block on glab mr create --description-file"
tmp_desc_file="$(mktemp)"
cat > "$tmp_desc_file" <<'EOF'
## Summary

Adds profile page.

Co-Authored-By: Claude Sonnet <noreply@anthropic.com>
EOF
result=$(run_with_command "glab mr create --title 'Feat: profile' --description-file $tmp_desc_file")
assert_exit "$(extract_exit "$result")" "2" "glab mr create --description-file should block"
rm -f "$tmp_desc_file"

# ─── Test 7: Allow clean commit ──────────────────────────────────────────────
echo
echo "▶ Test 7: Allow clean commit (no attribution)"
result=$(run_with_command "git commit -m 'feat: add user profile route + tests'")
assert_exit "$(extract_exit "$result")" "0" "Clean commit should pass"

# ─── Test 8: Allow non-commit Bash ───────────────────────────────────────────
echo
echo "▶ Test 8: Passthrough on git status"
result=$(run_with_command "git status")
assert_exit "$(extract_exit "$result")" "0" "git status should pass through"

# ─── Test 9: Editor mode (no -m) — passthrough with warning ──────────────────
echo
echo "▶ Test 9: Editor-mode git commit (no -m, no -F)"
result=$(run_with_command "git commit")
assert_exit "$(extract_exit "$result")" "0" "Editor-mode commit should pass through"
if printf '%s' "$result" | grep -q "editor-mode"; then
    echo "  ✅ stderr warning emitted about editor mode"
else
    echo "  ⚠️  no editor-mode warning emitted to stderr (acceptable but documented in spec)"
fi

# ─── Test 10: Allow clean gh pr create ───────────────────────────────────────
echo
echo "▶ Test 10: Allow clean gh pr create"
result=$(run_with_command "gh pr create --title 'Feat: foo' --body 'Adds foo widget.'")
assert_exit "$(extract_exit "$result")" "0" "Clean gh pr create should pass"

# ─── v2.0.1 regression tests (B1 — quote-handling in extract_flag_value) ─────
# Previously the unquoted Python heredoc in extract_flag_value silently failed
# on any commit message containing a `"`, fail-opening the hook for the most
# common invocation pattern. These tests must turn red on the pre-fix code
# and green after the fix. See docs/audits/2026-05-15-v2-mvp-self-audit.md
# §"Blocker B1".

# ─── Test 11: BLOCK git commit -m with double-quoted attribution ─────────────
echo
echo "▶ Test 11: BLOCK git commit -m with DOUBLE-quoted attribution (v2.0.1/B1)"
result=$(run_with_command 'git commit -m "feat: add things" -m "Co-Authored-By: Claude <noreply@anthropic.com>"')
assert_exit "$(extract_exit "$result")" "2" "Double-quoted -m with Co-Authored-By should BLOCK"

# ─── Test 12: BLOCK gh pr create --body with double-quoted 🤖 banner ────────
echo
echo "▶ Test 12: BLOCK gh pr create --body with double-quoted 🤖 (v2.0.1/B1)"
result=$(run_with_command 'gh pr create --title foo --body "Summary line.

🤖 Generated with Claude Code"')
assert_exit "$(extract_exit "$result")" "2" "Double-quoted gh pr --body with 🤖 should BLOCK"

# ─── Test 13: BLOCK glab mr create --description with double-quoted AI ──────
echo
echo "▶ Test 13: BLOCK glab mr create --description with double-quoted AI-assisted (v2.0.1/B1)"
result=$(run_with_command 'glab mr create --title foo --description "This is AI-assisted refactor work."')
assert_exit "$(extract_exit "$result")" "2" "Double-quoted glab mr --description with AI-assisted should BLOCK"

# ─── v2.0.1 S5 regression tests — substring-not-command-position passthroughs ─
# The PreToolUse-Bash hooks must not intercept when the target command appears
# as a literal substring inside `echo`, `grep`, `cat <<EOF`, etc. See
# §"Should-fix S5".

# ─── Test 14: PASS echo containing 'git commit' as quoted argument ──────────
echo
echo "▶ Test 14: PASS echo with literal 'git commit' substring (v2.0.1/S5)"
result=$(run_with_command "echo 'info: do not git commit yet'")
assert_exit "$(extract_exit "$result")" "0" "Substring inside echo should pass through"

# ─── Test 15: PASS grep searching for 'gh pr create' ────────────────────────
echo
echo "▶ Test 15: PASS grep with literal 'gh pr create' substring (v2.0.1/S5)"
result=$(run_with_command "grep 'gh pr create' docs/workflow.md")
assert_exit "$(extract_exit "$result")" "0" "Substring inside grep should pass through"

# ─── Summary ─────────────────────────────────────────────────────────────────
echo
if [ "$failures" -eq 0 ]; then
    echo "🟢 All hook scenarios passed."
    exit 0
else
    echo "🔴 ${failures} scenario(s) failed."
    exit 1
fi
