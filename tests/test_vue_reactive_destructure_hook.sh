#!/usr/bin/env bash
set -euo pipefail
HOOK="$(cd "$(dirname "$0")/.." && pwd)/hooks/vue-reactive-destructure.sh"
run_hook() { printf '%s' "$1" | bash "$HOOK"; }
extract_context() { printf '%s' "$1" | jq -r '.hookSpecificOutput.additionalContext // empty'; }
passed=0; failed=0
assert_pass() { echo "  ✅ $1"; passed=$((passed+1)); }
assert_fail() { echo "  ❌ $1 — $2"; failed=$((failed+1)); }

echo ""
echo "▶ Test 1: Edit .vue with reactive destructure — warns"
out="$(run_hook '{"hook_event_name":"PreToolUse","tool_name":"Edit","tool_input":{"file_path":"/tmp/foo.vue","new_string":"<script setup>\nimport { reactive } from \"vue\";\nconst state = reactive({ count: 0 });\nconst { count } = state;\n</script>"}}')"
ctx="$(extract_context "$out")"
if printf '%s' "$ctx" | grep -qi "reactive"; then assert_pass "Test 1"; else assert_fail "Test 1" "expected warning, got: $ctx"; fi

echo ""
echo "▶ Test 2: Edit .vue with toRefs — silent"
out="$(run_hook '{"hook_event_name":"PreToolUse","tool_name":"Edit","tool_input":{"file_path":"/tmp/foo.vue","new_string":"<script setup>\nimport { reactive, toRefs } from \"vue\";\nconst state = reactive({ count: 0 });\nconst { count } = toRefs(state);\n</script>"}}')"
if [ -z "$out" ]; then assert_pass "Test 2"; else assert_fail "Test 2" "expected silent, got: $out"; fi

echo ""
echo "▶ Test 3: Edit .vue without reactive destructure — silent"
out="$(run_hook '{"hook_event_name":"PreToolUse","tool_name":"Edit","tool_input":{"file_path":"/tmp/foo.vue","new_string":"<script setup>\nimport { ref } from \"vue\";\nconst count = ref(0);\n</script>"}}')"
if [ -z "$out" ]; then assert_pass "Test 3"; else assert_fail "Test 3" "expected silent, got: $out"; fi

echo ""
echo "▶ Test 4: Edit non-.vue file with reactive destructure — silent"
out="$(run_hook '{"hook_event_name":"PreToolUse","tool_name":"Edit","tool_input":{"file_path":"/tmp/foo.ts","new_string":"const { count } = reactive({ count: 0 });"}}')"
if [ -z "$out" ]; then assert_pass "Test 4"; else assert_fail "Test 4" "expected silent, got: $out"; fi

echo ""
echo "▶ Test 5: Malformed JSON — silent"
out="$(printf 'not json' | bash "$HOOK" 2>&1 || true)"
if [ -z "$(echo "$out" | grep -v '^$')" ] 2>/dev/null || [ -z "$out" ]; then assert_pass "Test 5"; else assert_fail "Test 5" "got: $out"; fi

echo ""
if [ "$failed" -eq 0 ]; then echo "🟢 All hook scenarios passed."; else echo "🔴 $failed scenario(s) failed."; exit 1; fi
