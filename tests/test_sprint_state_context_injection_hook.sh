#!/usr/bin/env bash
# Tests for hooks/sprint-state-context-injection.sh
set -euo pipefail

HOOK="$(cd "$(dirname "$0")/.." && pwd)/hooks/sprint-state-context-injection.sh"

# Helper: run hook with given stdin JSON, return stdout
run_hook() {
    local json="$1"
    printf '%s' "$json" | bash "$HOOK"
}

# Helper: extract additionalContext field from hook JSON output
extract_context() {
    printf '%s' "$1" | jq -r '.hookSpecificOutput.additionalContext // empty'
}

passed=0
failed=0

assert_pass() {
    local name="$1"
    echo "  ✅ $name"
    passed=$((passed + 1))
}

assert_fail() {
    local name="$1"
    local reason="$2"
    echo "  ❌ $name — $reason"
    failed=$((failed + 1))
}

echo ""
echo "▶ Test 1: SessionStart on feature branch — injects sprint context"
cd "$(mktemp -d)"
git init -q
git config user.email t@t
git config user.name T
git commit -q --allow-empty -m "init"
git checkout -q -b feat/notification-sounds
out="$(run_hook '{"hook_event_name":"SessionStart"}')"
ctx="$(extract_context "$out")"
if printf '%s' "$ctx" | grep -q "feat/notification-sounds"; then
    assert_pass "Test 1"
else
    assert_fail "Test 1" "expected branch name in additionalContext, got: $ctx"
fi
cd - >/dev/null

echo ""
echo "▶ Test 2: SessionStart on main branch — no injection (silent)"
cd "$(mktemp -d)"
git init -q -b main
git config user.email t@t
git config user.name T
git commit -q --allow-empty -m "init"
out="$(run_hook '{"hook_event_name":"SessionStart"}')"
if [ -z "$out" ]; then
    assert_pass "Test 2"
else
    assert_fail "Test 2" "expected no output on main, got: $out"
fi
cd - >/dev/null

echo ""
echo "▶ Test 3: SessionStart with LARAVEL_SUPERPOWERS_SKIP_AUTO_RESUME=1 — silent"
cd "$(mktemp -d)"
git init -q
git config user.email t@t
git config user.name T
git commit -q --allow-empty -m "init"
git checkout -q -b feat/x
out="$(LARAVEL_SUPERPOWERS_SKIP_AUTO_RESUME=1 run_hook '{"hook_event_name":"SessionStart"}')"
if [ -z "$out" ]; then
    assert_pass "Test 3"
else
    assert_fail "Test 3" "expected silent on env-disable, got: $out"
fi
cd - >/dev/null

echo ""
echo "▶ Test 4: SessionStart with resume-anchor file — referenced in context"
cd "$(mktemp -d)"
git init -q
git config user.email t@t
git config user.name T
mkdir -p docs/superpowers
echo "# Resume Block 1H" > docs/superpowers/editor-toolbar-resume.md
git add -A
git commit -q -m "init"
git checkout -q -b feat/editor-toolbar
out="$(run_hook '{"hook_event_name":"SessionStart"}')"
ctx="$(extract_context "$out")"
if printf '%s' "$ctx" | grep -q "editor-toolbar-resume.md"; then
    assert_pass "Test 4"
else
    assert_fail "Test 4" "expected resume-anchor path in context, got: $ctx"
fi
cd - >/dev/null

echo ""
echo "▶ Test 5: SessionStart with plan-doc — referenced in context"
cd "$(mktemp -d)"
git init -q
git config user.email t@t
git config user.name T
mkdir -p docs/plans
echo "# Editor Toolbar Plan" > docs/plans/editor-toolbar.md
echo "## Phase 1" >> docs/plans/editor-toolbar.md
echo "Status: in-progress" >> docs/plans/editor-toolbar.md
git add -A
git commit -q -m "init"
git checkout -q -b feat/editor-toolbar
out="$(run_hook '{"hook_event_name":"SessionStart"}')"
ctx="$(extract_context "$out")"
if printf '%s' "$ctx" | grep -q "editor-toolbar.md"; then
    assert_pass "Test 5"
else
    assert_fail "Test 5" "expected plan-doc path in context, got: $ctx"
fi
cd - >/dev/null

echo ""
echo "▶ Test 6: Non-SessionStart event — silent passthrough"
out="$(run_hook '{"hook_event_name":"PreToolUse"}')"
if [ -z "$out" ]; then
    assert_pass "Test 6"
else
    assert_fail "Test 6" "expected silent on non-SessionStart, got: $out"
fi

echo ""
echo "▶ Test 7: Malformed JSON — silent passthrough"
out="$(printf 'not json' | bash "$HOOK" 2>&1 || true)"
# Acceptable: either empty output OR non-zero exit silently
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
