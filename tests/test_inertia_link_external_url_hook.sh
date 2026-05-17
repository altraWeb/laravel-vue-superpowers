#!/usr/bin/env bash
set -euo pipefail
HOOK="$(cd "$(dirname "$0")/.." && pwd)/hooks/inertia-link-external-url.sh"
run_hook() { printf '%s' "$1" | bash "$HOOK"; }
extract_context() { printf '%s' "$1" | jq -r '.hookSpecificOutput.additionalContext // empty'; }
passed=0; failed=0
assert_pass() { echo "  ✅ $1"; passed=$((passed+1)); }
assert_fail() { echo "  ❌ $1 — $2"; failed=$((failed+1)); }

echo ""
echo "▶ Test 1: Edit .vue with Link and internal URL — silent"
out="$(run_hook '{"hook_event_name":"PreToolUse","tool_name":"Edit","tool_input":{"file_path":"/tmp/foo.vue","new_string":"<template>\n<Link href=\"/posts\">Posts</Link>\n</template>"}}')"
if [ -z "$out" ]; then assert_pass "Test 1"; else assert_fail "Test 1" "expected silent, got: $out"; fi

echo ""
echo "▶ Test 2: Edit .vue with Link and external URL — warns"
out="$(run_hook '{"hook_event_name":"PreToolUse","tool_name":"Edit","tool_input":{"file_path":"/tmp/foo.vue","new_string":"<template>\n<Link href=\"https://external.com/page\">External</Link>\n</template>"}}')"
ctx="$(extract_context "$out")"
if printf '%s' "$ctx" | grep -qi "external\|Link\|inertia"; then assert_pass "Test 2"; else assert_fail "Test 2" "expected warning, got: $ctx"; fi

echo ""
echo "▶ Test 3: Edit .vue without Link import at all — silent"
out="$(run_hook '{"hook_event_name":"PreToolUse","tool_name":"Edit","tool_input":{"file_path":"/tmp/foo.vue","new_string":"<template><a href=\"https://external.com\">Link</a></template>"}}')"
if [ -z "$out" ]; then assert_pass "Test 3"; else assert_fail "Test 3" "expected silent, got: $out"; fi

echo ""
echo "▶ Test 4: Edit non-.vue file — silent"
out="$(run_hook '{"hook_event_name":"PreToolUse","tool_name":"Edit","tool_input":{"file_path":"/tmp/foo.ts","new_string":"<Link href=\"https://external.com\">Text</Link>"}}')"
if [ -z "$out" ]; then assert_pass "Test 4"; else assert_fail "Test 4" "expected silent, got: $out"; fi

echo ""
echo "▶ Test 5: Malformed JSON — silent"
out="$(printf 'not json' | bash "$HOOK" 2>&1 || true)"
if [ -z "$(echo "$out" | grep -v '^$')" ] 2>/dev/null || [ -z "$out" ]; then assert_pass "Test 5"; else assert_fail "Test 5" "got: $out"; fi

echo ""
if [ "$failed" -eq 0 ]; then echo "🟢 All hook scenarios passed."; else echo "🔴 $failed scenario(s) failed."; exit 1; fi
