#!/usr/bin/env bash
set -euo pipefail
HOOK="$(cd "$(dirname "$0")/.." && pwd)/hooks/inertia-hardcoded-route.sh"
run_hook() { printf '%s' "$1" | bash "$HOOK"; }
extract_context() { printf '%s' "$1" | jq -r '.hookSpecificOutput.additionalContext // empty'; }
passed=0; failed=0
assert_pass() { echo "  ✅ $1"; passed=$((passed+1)); }
assert_fail() { echo "  ❌ $1 — $2"; failed=$((failed+1)); }

# Create a fake wayfinder vendor dir for tests that need it
FAKE_WAYFINDER_DIR="$(mktemp -d)"
mkdir -p "$FAKE_WAYFINDER_DIR/vendor/laravel/wayfinder"
trap 'rm -rf "$FAKE_WAYFINDER_DIR"' EXIT

echo ""
echo "▶ Test 1: Edit .vue with Wayfinder action (no hardcoded route) — silent"
out="$(cd "$FAKE_WAYFINDER_DIR" && run_hook '{"hook_event_name":"PreToolUse","tool_name":"Edit","tool_input":{"file_path":"/tmp/foo.vue","new_string":"<script setup>\nimport { index as listPosts } from \"@/wayfinder/actions/PostController\";\nrouter.visit(listPosts());\n</script>"}}')"
if [ -z "$out" ]; then assert_pass "Test 1"; else assert_fail "Test 1" "expected silent, got: $out"; fi

echo ""
echo "▶ Test 2: Edit .vue with hardcoded route when Wayfinder installed — warns"
out="$(cd "$FAKE_WAYFINDER_DIR" && run_hook '{"hook_event_name":"PreToolUse","tool_name":"Edit","tool_input":{"file_path":"/tmp/foo.vue","new_string":"<script setup>\nrouter.visit(\"/posts/create\");\n</script>"}}')"
ctx="$(extract_context "$out")"
if printf '%s' "$ctx" | grep -qi "wayfinder\|hardcoded\|route"; then assert_pass "Test 2"; else assert_fail "Test 2" "expected warning, got: $ctx"; fi

echo ""
echo "▶ Test 3: Edit .vue with hardcoded route but Wayfinder NOT installed — silent"
TMPDIR_NOWAYFINDER="$(mktemp -d)"
out="$(cd "$TMPDIR_NOWAYFINDER" && run_hook '{"hook_event_name":"PreToolUse","tool_name":"Edit","tool_input":{"file_path":"/tmp/foo.vue","new_string":"<script setup>\nrouter.visit(\"/posts/create\");\n</script>"}}')"
rm -rf "$TMPDIR_NOWAYFINDER"
if [ -z "$out" ]; then assert_pass "Test 3"; else assert_fail "Test 3" "expected silent (Wayfinder not installed), got: $out"; fi

echo ""
echo "▶ Test 4: Edit non-.vue/.ts file — silent"
out="$(cd "$FAKE_WAYFINDER_DIR" && run_hook '{"hook_event_name":"PreToolUse","tool_name":"Edit","tool_input":{"file_path":"/tmp/foo.php","new_string":"router.visit(\"/posts/create\");"}}')"
if [ -z "$out" ]; then assert_pass "Test 4"; else assert_fail "Test 4" "expected silent, got: $out"; fi

echo ""
echo "▶ Test 5: Malformed JSON — silent"
out="$(printf 'not json' | bash "$HOOK" 2>&1 || true)"
if [ -z "$(echo "$out" | grep -v '^$')" ] 2>/dev/null || [ -z "$out" ]; then assert_pass "Test 5"; else assert_fail "Test 5" "got: $out"; fi

echo ""
if [ "$failed" -eq 0 ]; then echo "🟢 All hook scenarios passed."; else echo "🔴 $failed scenario(s) failed."; exit 1; fi
