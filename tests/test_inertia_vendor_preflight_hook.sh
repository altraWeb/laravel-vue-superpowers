#!/usr/bin/env bash
set -euo pipefail
HOOK="$(cd "$(dirname "$0")/.." && pwd)/hooks/inertia-vendor-preflight.sh"
run_hook() { printf '%s' "$1" | bash "$HOOK"; }
extract_context() { printf '%s' "$1" | jq -r '.hookSpecificOutput.additionalContext // empty'; }
passed=0; failed=0
assert_pass() { echo "  ✅ $1"; passed=$((passed+1)); }
assert_fail() { echo "  ❌ $1 — $2"; failed=$((failed+1)); }

echo ""
echo "▶ Test 1: Edit .vue with Reka import — surfaces Reka source"
out="$(run_hook '{"hook_event_name":"PreToolUse","tool_name":"Edit","tool_input":{"file_path":"/tmp/foo.vue","new_string":"<script setup>\nimport { DialogRoot, DialogTrigger } from \"reka-ui\";\n</script>"}}')"
ctx="$(extract_context "$out")"
if printf '%s' "$ctx" | grep -qi "reka-ui"; then assert_pass "Test 1"; else assert_fail "Test 1" "expected reka reference, got: $ctx"; fi

echo ""
echo "▶ Test 2: Edit .vue with useForm — surfaces Inertia source"
out="$(run_hook '{"hook_event_name":"PreToolUse","tool_name":"Edit","tool_input":{"file_path":"/tmp/foo.vue","new_string":"<script setup>\nimport { useForm } from \"@inertiajs/vue3\";\nconst form = useForm({ email: \"\" });\n</script>"}}')"
ctx="$(extract_context "$out")"
if printf '%s' "$ctx" | grep -qi "inertia"; then assert_pass "Test 2"; else assert_fail "Test 2" "expected inertia reference, got: $ctx"; fi

echo ""
echo "▶ Test 3: Edit .vue without Reka or Inertia helpers — silent"
out="$(run_hook '{"hook_event_name":"PreToolUse","tool_name":"Edit","tool_input":{"file_path":"/tmp/foo.vue","new_string":"<template><div>x</div></template>"}}')"
if [ -z "$out" ]; then assert_pass "Test 3"; else assert_fail "Test 3" "expected silent, got: $out"; fi

echo ""
echo "▶ Test 4: Edit non-.vue file with Reka import — silent"
out="$(run_hook '{"hook_event_name":"PreToolUse","tool_name":"Edit","tool_input":{"file_path":"/tmp/foo.ts","new_string":"import { DialogRoot } from \"reka-ui\";"}}')"
if [ -z "$out" ]; then assert_pass "Test 4"; else assert_fail "Test 4" "expected silent on non-.vue, got: $out"; fi

echo ""
echo "▶ Test 5: Malformed JSON — silent"
out="$(printf 'not json' | bash "$HOOK" 2>&1 || true)"
if [ -z "$(echo "$out" | grep -v '^$')" ] 2>/dev/null || [ -z "$out" ]; then assert_pass "Test 5"; else assert_fail "Test 5" "got: $out"; fi

echo ""
if [ "$failed" -eq 0 ]; then echo "🟢 All hook scenarios passed."; else echo "🔴 $failed scenario(s) failed."; exit 1; fi
