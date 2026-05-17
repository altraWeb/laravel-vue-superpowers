#!/usr/bin/env bash
# Shell test driver for hooks/brainstorm-t1-audit.sh
#
# PostToolUse hook — signals via stdout JSON (additionalContext).
#
# Run from repo root: bash tests/test_brainstorm_t1_audit_hook.sh

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="${REPO_ROOT}/hooks/brainstorm-t1-audit.sh"

[ -x "$HOOK" ] || { echo "FAIL: hook not executable at $HOOK"; exit 1; }

failures=0

run_with_payload() {
    local payload="$1"
    local stdout_file
    stdout_file="$(mktemp)"
    export CLAUDE_PLUGIN_ROOT="$REPO_ROOT"
    local exit_code
    set +e
    printf '%s' "$payload" | bash "$HOOK" > "$stdout_file" 2>/dev/null
    exit_code=$?
    set -e
    printf 'EXIT:%s\n' "$exit_code"
    cat "$stdout_file"
    rm -f "$stdout_file"
}

assert_emitted() {
    local output="$1" name="$2"
    if printf '%s' "$output" | grep -q '"additionalContext"'; then
        printf '  ✅ %s — additionalContext emitted\n' "$name"
    else
        printf '  ❌ %s — expected additionalContext, got nothing\n' "$name"
        failures=$((failures + 1))
    fi
}

assert_silent() {
    local output="$1" name="$2"
    local payload_only
    payload_only="$(printf '%s' "$output" | sed -e '/^EXIT:/d')"
    if [ -z "$(printf '%s' "$payload_only" | tr -d '[:space:]')" ]; then
        printf '  ✅ %s — no output (correctly skipped)\n' "$name"
    else
        printf '  ❌ %s — expected silence, got: %s\n' "$name" "$payload_only"
        failures=$((failures + 1))
    fi
}

# ─── Test 1: Brainstorming activation emits with prompt template ─────────────
echo
echo "▶ Test 1: superpowers:brainstorming activation emits reminder with prompt template"
payload='{"tool_input":{"skill":"superpowers:brainstorming","args":"design the new notifications panel"}}'
result=$(run_with_payload "$payload")
assert_emitted "$result" "Brainstorming activation should emit additionalContext"
if printf '%s' "$result" | grep -q "Pilot 2.0 Tactic 1"; then
    echo "  ✅ reminder mentions Pilot 2.0 Tactic 1"
else
    echo "  ❌ reminder missing Pilot 2.0 Tactic 1 reference"
    failures=$((failures + 1))
fi
if printf '%s' "$result" | grep -q "laravel-best-practices"; then
    echo "  ✅ reminder names laravel-best-practices agent"
else
    echo "  ❌ reminder missing laravel-best-practices agent name"
    failures=$((failures + 1))
fi
if printf '%s' "$result" | grep -q "design the new notifications panel"; then
    echo "  ✅ topic from args interpolated into reminder"
else
    echo "  ❌ topic from args not interpolated"
    failures=$((failures + 1))
fi

# ─── Test 2: Different skill passthrough ─────────────────────────────────────
echo
echo "▶ Test 2: Different skill passthrough (writing-plans, no emit)"
payload='{"tool_input":{"skill":"superpowers:writing-plans"}}'
result=$(run_with_payload "$payload")
assert_silent "$result" "writing-plans should not emit"

# ─── Test 3: Empty args defaults to context-detect ───────────────────────────
echo
echo "▶ Test 3: Empty args emits with context-detect topic"
payload='{"tool_input":{"skill":"superpowers:brainstorming","args":""}}'
result=$(run_with_payload "$payload")
assert_emitted "$result" "Empty args should still emit"
if printf '%s' "$result" | grep -q "detect from conversation context"; then
    echo "  ✅ empty-args fallback text emitted"
else
    echo "  ❌ empty-args fallback missing"
    failures=$((failures + 1))
fi

# ─── Test 4: Empty stdin → silent ────────────────────────────────────────────
echo
echo "▶ Test 4: Empty stdin → silent"
result=$(run_with_payload "")
assert_silent "$result" "Empty stdin should pass silently"

# ─── Test 5: Malformed JSON → silent ─────────────────────────────────────────
echo
echo "▶ Test 5: Malformed JSON → silent"
payload='not even json'
result=$(run_with_payload "$payload")
assert_silent "$result" "Malformed JSON should pass silently"

# ─── Summary ─────────────────────────────────────────────────────────────────
echo
if [ "$failures" -eq 0 ]; then
    echo "🟢 All hook scenarios passed."
    exit 0
else
    echo "🔴 ${failures} scenario(s) failed."
    exit 1
fi
