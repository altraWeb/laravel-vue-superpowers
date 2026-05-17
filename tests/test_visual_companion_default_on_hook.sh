#!/usr/bin/env bash
# Shell test driver for hooks/visual-companion-default-on.sh
#
# PostToolUse hook — signals via stdout JSON (additionalContext) rather than
# exit code. We assert on stdout presence/absence rather than exit code.
#
# Run from repo root: bash tests/test_visual_companion_default_on_hook.sh

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="${REPO_ROOT}/hooks/visual-companion-default-on.sh"

[ -x "$HOOK" ] || { echo "FAIL: hook not executable at $HOOK"; exit 1; }

failures=0

run_with_payload() {
    # $1 = JSON payload as compact string
    # Returns: "EXIT:<code>\n<stdout>"
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
    # $1 = output from run_with_payload, $2 = test name
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
    # Strip exit line; check remainder is empty/whitespace only.
    local payload_only
    payload_only="$(printf '%s' "$output" | sed -e '/^EXIT:/d')"
    if [ -z "$(printf '%s' "$payload_only" | tr -d '[:space:]')" ]; then
        printf '  ✅ %s — no output (correctly skipped)\n' "$name"
    else
        printf '  ❌ %s — expected silence, got: %s\n' "$name" "$payload_only"
        failures=$((failures + 1))
    fi
}

# ─── Test 1: Brainstorming activation emits reminder ─────────────────────────
echo
echo "▶ Test 1: superpowers:brainstorming activation emits reminder"
payload='{"tool_input":{"skill":"superpowers:brainstorming"}}'
result=$(run_with_payload "$payload")
assert_emitted "$result" "Brainstorming activation should emit additionalContext"

# ─── Test 2: Different skill passthrough ─────────────────────────────────────
echo
echo "▶ Test 2: Different skill passthrough (no emit)"
payload='{"tool_input":{"skill":"superpowers:writing-plans"}}'
result=$(run_with_payload "$payload")
assert_silent "$result" "writing-plans skill should not emit"

# ─── Test 3: Text-only denylist skip ─────────────────────────────────────────
echo
echo "▶ Test 3: Text-only topic (naming vote) skips"
payload='{"tool_input":{"skill":"superpowers:brainstorming","args":"naming vote for the new flag"}}'
result=$(run_with_payload "$payload")
assert_silent "$result" "Naming-vote topic should skip auto-offer"

# ─── Test 4: Semver topic skip ───────────────────────────────────────────────
echo
echo "▶ Test 4: Semver bump topic skips"
payload='{"tool_input":{"skill":"superpowers:brainstorming","args":"semver bump strategy for next release"}}'
result=$(run_with_payload "$payload")
assert_silent "$result" "Semver topic should skip auto-offer"

# ─── Test 5: Config-flag topic skip ──────────────────────────────────────────
echo
echo "▶ Test 5: Config-flag topic skips"
payload='{"tool_input":{"skill":"superpowers:brainstorming","args":"config flag rollout for feature X"}}'
result=$(run_with_payload "$payload")
assert_silent "$result" "Config-flag topic should skip auto-offer"

# ─── Test 6: Visual topic emits ──────────────────────────────────────────────
echo
echo "▶ Test 6: UI-design topic emits reminder"
payload='{"tool_input":{"skill":"superpowers:brainstorming","args":"redesign the dashboard layout with side nav and widgets"}}'
result=$(run_with_payload "$payload")
assert_emitted "$result" "UI-design topic should emit reminder"

# ─── Test 7: Empty args emits (cannot detect text-only) ──────────────────────
echo
echo "▶ Test 7: Empty args emits (default-on)"
payload='{"tool_input":{"skill":"superpowers:brainstorming","args":""}}'
result=$(run_with_payload "$payload")
assert_emitted "$result" "Empty args should default to emit"

# ─── Test 8: Empty stdin → exit 0 silent ─────────────────────────────────────
echo
echo "▶ Test 8: Empty stdin → silent"
result=$(run_with_payload "")
assert_silent "$result" "Empty stdin should pass silently"

# ─── Test 9: Malformed JSON → silent ─────────────────────────────────────────
echo
echo "▶ Test 9: Malformed JSON → silent"
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
