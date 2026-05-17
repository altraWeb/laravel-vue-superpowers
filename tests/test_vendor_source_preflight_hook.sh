#!/usr/bin/env bash
set -euo pipefail

HOOK="$(cd "$(dirname "$0")/.." && pwd)/hooks/vendor-source-preflight.sh"
run_hook() { printf '%s' "$1" | bash "$HOOK"; }
extract_context() { printf '%s' "$1" | jq -r '.hookSpecificOutput.additionalContext // empty'; }
passed=0; failed=0
assert_pass() { echo "  ✅ $1"; passed=$((passed+1)); }
assert_fail() { echo "  ❌ $1 — $2"; failed=$((failed+1)); }

echo ""
echo "▶ Test 1: Edit on .blade.php with flux:button — surfaces Flux stub paths"
out="$(run_hook '{"hook_event_name":"PreToolUse","tool_name":"Edit","tool_input":{"file_path":"/tmp/foo.blade.php","new_string":"<flux:button>Hello</flux:button>"}}')"
ctx="$(extract_context "$out")"
if printf '%s' "$ctx" | grep -qi "flux"; then
    assert_pass "Test 1"
else
    assert_fail "Test 1" "expected flux stub reference, got: $ctx"
fi

echo ""
echo "▶ Test 2: Write on .blade.php with wire:model — surfaces Livewire source paths"
out="$(run_hook '{"hook_event_name":"PreToolUse","tool_name":"Write","tool_input":{"file_path":"/tmp/foo.blade.php","content":"<input wire:model=\"name\">"}}')"
ctx="$(extract_context "$out")"
if printf '%s' "$ctx" | grep -qi "livewire"; then
    assert_pass "Test 2"
else
    assert_fail "Test 2" "expected livewire source reference, got: $ctx"
fi

echo ""
echo "▶ Test 3: Edit on .blade.php without flux/wire directives — silent"
out="$(run_hook '{"hook_event_name":"PreToolUse","tool_name":"Edit","tool_input":{"file_path":"/tmp/foo.blade.php","new_string":"<div class=\"text-red\">x</div>"}}')"
if [ -z "$out" ]; then
    assert_pass "Test 3"
else
    assert_fail "Test 3" "expected silent on no-flux-no-wire blade, got: $out"
fi

echo ""
echo "▶ Test 4: Edit on non-blade file with flux text — silent"
out="$(run_hook '{"hook_event_name":"PreToolUse","tool_name":"Edit","tool_input":{"file_path":"/tmp/foo.txt","new_string":"<flux:button>Hello</flux:button>"}}')"
if [ -z "$out" ]; then
    assert_pass "Test 4"
else
    assert_fail "Test 4" "expected silent on non-blade file, got: $out"
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
