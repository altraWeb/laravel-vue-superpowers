#!/usr/bin/env bash
# Tests for hooks/stale-branch-sweep.sh
set -euo pipefail

HOOK="$(cd "$(dirname "$0")/.." && pwd)/hooks/stale-branch-sweep.sh"

run_hook() {
    local json="$1"
    printf '%s' "$json" | bash "$HOOK"
}

extract_context() {
    printf '%s' "$1" | jq -r '.hookSpecificOutput.additionalContext // empty'
}

passed=0
failed=0

assert_pass() {
    echo "  ✅ $1"
    passed=$((passed + 1))
}

assert_fail() {
    echo "  ❌ $1 — $2"
    failed=$((failed + 1))
}

# Helper: set up a git repo with a stale branch (upstream gone)
setup_repo_with_stale() {
    local repo_dir
    repo_dir="$(mktemp -d)"
    # Create a bare "remote"
    local bare_dir="$repo_dir/remote.git"
    git init -q --bare "$bare_dir"
    # Create the working clone
    cd "$repo_dir"
    git clone -q "$bare_dir" work
    cd work
    git config user.email t@t
    git config user.name T
    git commit -q --allow-empty -m "init"
    git push -q origin main 2>/dev/null || git push -q -u origin main 2>/dev/null || git push -q -u origin master 2>/dev/null
    # Create a feature branch with upstream
    git checkout -q -b feat/old-feature
    git commit -q --allow-empty -m "feature work"
    git push -q -u origin feat/old-feature
    # Now delete the remote branch to make local upstream "gone"
    git push -q origin --delete feat/old-feature
    # Local feat/old-feature now has upstream gone
    git checkout -q main 2>/dev/null || git checkout -q master 2>/dev/null
    echo "$repo_dir/work"
}

echo ""
echo "▶ Test 1: SessionStart with stale branches — lists them in additionalContext"
work="$(setup_repo_with_stale)"
cd "$work"
out="$(run_hook '{"hook_event_name":"SessionStart"}')"
ctx="$(extract_context "$out")"
if printf '%s' "$ctx" | grep -q "feat/old-feature"; then
    assert_pass "Test 1"
else
    assert_fail "Test 1" "expected feat/old-feature in additionalContext, got: $ctx"
fi
cd - >/dev/null

echo ""
echo "▶ Test 2: SessionStart with no stale branches — silent"
clean_repo="$(mktemp -d)"
cd "$clean_repo"
git init -q
git config user.email t@t
git config user.name T
git commit -q --allow-empty -m "init"
out="$(run_hook '{"hook_event_name":"SessionStart"}')"
if [ -z "$out" ]; then
    assert_pass "Test 2"
else
    assert_fail "Test 2" "expected silent on no-stale, got: $out"
fi
cd - >/dev/null

echo ""
echo "▶ Test 3: Non-SessionStart event — silent passthrough"
out="$(run_hook '{"hook_event_name":"PreToolUse"}')"
if [ -z "$out" ]; then
    assert_pass "Test 3"
else
    assert_fail "Test 3" "expected silent on non-SessionStart, got: $out"
fi

echo ""
echo "▶ Test 4: Outside a git repo — silent passthrough"
nogit="$(mktemp -d)"
cd "$nogit"
out="$(run_hook '{"hook_event_name":"SessionStart"}')"
if [ -z "$out" ]; then
    assert_pass "Test 4"
else
    assert_fail "Test 4" "expected silent outside git, got: $out"
fi
cd - >/dev/null

echo ""
echo "▶ Test 5: Cleanup command suggestion included"
work="$(setup_repo_with_stale)"
cd "$work"
out="$(run_hook '{"hook_event_name":"SessionStart"}')"
ctx="$(extract_context "$out")"
if printf '%s' "$ctx" | grep -q "git branch -D"; then
    assert_pass "Test 5"
else
    assert_fail "Test 5" "expected 'git branch -D' suggestion in context, got: $ctx"
fi
cd - >/dev/null

echo ""
echo "▶ Test 6: Currently-checked-out branch with gone upstream — detected as stale"
repo_dir="$(mktemp -d)"
bare_dir="$repo_dir/remote.git"
git init -q --bare "$bare_dir"
cd "$repo_dir"
git clone -q "$bare_dir" work
cd work
git config user.email t@t
git config user.name T
git commit -q --allow-empty -m "init"
git push -q -u origin main 2>/dev/null || git push -q -u origin master 2>/dev/null
git checkout -q -b feat/current-branch-test
git commit -q --allow-empty -m "feature work"
git push -q -u origin feat/current-branch-test
git push -q origin --delete feat/current-branch-test
# Now feat/current-branch-test is the current branch AND has gone upstream
out="$(run_hook '{"hook_event_name":"SessionStart"}')"
ctx="$(extract_context "$out")"
if printf '%s' "$ctx" | grep -q "feat/current-branch-test"; then
    assert_pass "Test 6"
else
    assert_fail "Test 6" "current branch with gone upstream should be detected, got: $ctx"
fi
cd - >/dev/null

echo ""
echo "▶ Test 7: Malformed JSON — silent passthrough"
out="$(printf 'not json' | bash "$HOOK" 2>&1 || true)"
if [ -z "$(echo "$out" | grep -v '^$')" ] 2>/dev/null || [ -z "$out" ]; then
    assert_pass "Test 7"
else
    assert_fail "Test 7" "expected silent on malformed JSON, got: $out"
fi

echo ""
if [ "$failed" -eq 0 ]; then
    echo "🟢 All hook scenarios passed."
else
    echo "🔴 $failed scenario(s) failed."
    exit 1
fi
