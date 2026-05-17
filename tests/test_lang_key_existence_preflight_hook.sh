#!/usr/bin/env bash
set -euo pipefail

HOOK="$(cd "$(dirname "$0")/.." && pwd)/hooks/lang-key-existence-preflight.sh"
run_hook() { printf '%s' "$1" | bash "$HOOK"; }
extract_context() { printf '%s' "$1" | jq -r '.hookSpecificOutput.additionalContext // empty'; }
passed=0; failed=0
assert_pass() { echo "  ✅ $1"; passed=$((passed+1)); }
assert_fail() { echo "  ❌ $1 — $2"; failed=$((failed+1)); }

# Helper: setup a temp project with lang files
setup_with_lang() {
    local project="$(mktemp -d)"
    mkdir -p "$project/lang/en"
    cat > "$project/lang/en/messages.php" <<'EOF'
<?php return ['greeting' => 'Hello', 'farewell' => 'Goodbye'];
EOF
    echo "$project"
}

echo ""
echo "▶ Test 1: Edit blade with __('messages.greeting') existing key — silent"
project="$(setup_with_lang)"
cd "$project"
out="$(run_hook '{"hook_event_name":"PreToolUse","tool_name":"Edit","tool_input":{"file_path":"'$project'/foo.blade.php","new_string":"<p>{{ __(\"messages.greeting\") }}</p>"}}')"
if [ -z "$out" ]; then
    assert_pass "Test 1"
else
    assert_fail "Test 1" "expected silent on existing key, got: $out"
fi
cd - >/dev/null

echo ""
echo "▶ Test 2: Edit blade with __('messages.missing') unknown key — warns"
project="$(setup_with_lang)"
cd "$project"
out="$(run_hook '{"hook_event_name":"PreToolUse","tool_name":"Edit","tool_input":{"file_path":"'$project'/foo.blade.php","new_string":"<p>{{ __(\"messages.missing\") }}</p>"}}')"
ctx="$(extract_context "$out")"
if printf '%s' "$ctx" | grep -qi "messages.missing"; then
    assert_pass "Test 2"
else
    assert_fail "Test 2" "expected missing key warning, got: $ctx"
fi
cd - >/dev/null

echo ""
echo "▶ Test 3: Edit blade without __() / @lang() — silent"
out="$(run_hook '{"hook_event_name":"PreToolUse","tool_name":"Edit","tool_input":{"file_path":"/tmp/foo.blade.php","new_string":"<p>Static text</p>"}}')"
if [ -z "$out" ]; then
    assert_pass "Test 3"
else
    assert_fail "Test 3" "expected silent on no-lang-call blade, got: $out"
fi

echo ""
echo "▶ Test 4: Edit non-blade file with __() — silent"
out="$(run_hook '{"hook_event_name":"PreToolUse","tool_name":"Edit","tool_input":{"file_path":"/tmp/foo.txt","new_string":"<p>{{ __(\"messages.x\") }}</p>"}}')"
if [ -z "$out" ]; then
    assert_pass "Test 4"
else
    assert_fail "Test 4" "expected silent on non-blade, got: $out"
fi

echo ""
echo "▶ Test 5: Malformed JSON — silent"
out="$(printf 'not json' | bash "$HOOK" 2>&1 || true)"
if [ -z "$(echo "$out" | grep -v '^$')" ] 2>/dev/null || [ -z "$out" ]; then
    assert_pass "Test 5"
else
    assert_fail "Test 5" "expected silent on malformed JSON, got: $out"
fi

echo ""
if [ "$failed" -eq 0 ]; then
    echo "🟢 All hook scenarios passed."
else
    echo "🔴 $failed scenario(s) failed."
    exit 1
fi
