#!/usr/bin/env bash
# Tests for hooks/master-roadmap-drift-detector.sh
set -euo pipefail

HOOK="$(cd "$(dirname "$0")/.." && pwd)/hooks/master-roadmap-drift-detector.sh"

run_hook() {
    local json="$1"
    printf '%s' "$json" | bash "$HOOK"
}

passed=0
failed=0
assert_pass() { echo "  ✅ $1"; passed=$((passed + 1)); }
assert_fail() { echo "  ❌ $1 — $2"; failed=$((failed + 1)); }

# Helper: set up a repo with a plan-doc commit and a master-roadmap that
# either matches (no drift) or mismatches (drift)
setup_repo_with_drift() {
    local drift="$1"  # "yes" or "no"
    local repo
    repo="$(mktemp -d)"
    cd "$repo"
    git init -q
    git config user.email t@t
    git config user.name T
    mkdir -p docs/plans
    cat > docs/plans/feature-x.md <<'EOF'
# Feature X
**Status:** archived (shipped via MR !99)
EOF
    if [ "$drift" = "yes" ]; then
        cat > docs/plans/master-roadmap-2026-q2.md <<'EOF'
# Master Roadmap Q2 2026
- Feature X: ready for review on branch
EOF
    else
        cat > docs/plans/master-roadmap-2026-q2.md <<'EOF'
# Master Roadmap Q2 2026
- Feature X: shipped via MR !99
EOF
    fi
    git add -A
    git commit -q -m "docs(plans): update feature-x plan"
    echo "$repo"
}

echo ""
echo "▶ Test 1: PostToolUse git-commit on plan-doc with master-roadmap drift — warns"
repo="$(setup_repo_with_drift yes)"
cd "$repo"
out="$(run_hook '{"hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"git commit -m \"docs(plans): update feature-x plan\""}}')"
if printf '%s' "$out" | grep -qi "drift\|master-roadmap"; then
    assert_pass "Test 1"
else
    assert_fail "Test 1" "expected drift warning, got: $out"
fi
cd - >/dev/null

echo ""
echo "▶ Test 2: PostToolUse git-commit on plan-doc with no drift — silent"
repo="$(setup_repo_with_drift no)"
cd "$repo"
out="$(run_hook '{"hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"git commit -m \"docs(plans): update feature-x plan\""}}')"
if [ -z "$out" ]; then
    assert_pass "Test 2"
else
    assert_fail "Test 2" "expected silent on no-drift, got: $out"
fi
cd - >/dev/null

echo ""
echo "▶ Test 3: PostToolUse git-commit NOT touching plan-doc — silent"
repo="$(mktemp -d)"
cd "$repo"
git init -q
git config user.email t@t; git config user.name T
echo "x" > file.txt
git add -A
git commit -q -m "feat: random change"
out="$(run_hook '{"hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"git commit -m \"feat: random change\""}}')"
if [ -z "$out" ]; then
    assert_pass "Test 3"
else
    assert_fail "Test 3" "expected silent on non-plan-doc commit, got: $out"
fi
cd - >/dev/null

echo ""
echo "▶ Test 4: PostToolUse with non-Bash tool — silent"
out="$(run_hook '{"hook_event_name":"PostToolUse","tool_name":"Edit","tool_input":{}}')"
if [ -z "$out" ]; then
    assert_pass "Test 4"
else
    assert_fail "Test 4" "expected silent on non-Bash tool, got: $out"
fi

echo ""
echo "▶ Test 5: PostToolUse Bash but not git-commit — silent"
out="$(run_hook '{"hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"ls -la"}}')"
if [ -z "$out" ]; then
    assert_pass "Test 5"
else
    assert_fail "Test 5" "expected silent on non-commit Bash, got: $out"
fi

echo ""
echo "▶ Test 6: Date-prefixed plan-doc with matching roadmap entry — silent (no false positive)"
repo="$(mktemp -d)"
cd "$repo"
git init -q
git config user.email t@t; git config user.name T
mkdir -p docs/plans
cat > docs/plans/2026-05-17-v3-phase-b-quickwin-hooks.md <<'EOF'
# V3 Phase B Quickwin Hooks
**Status:** archived (shipped via MR !54)
EOF
cat > docs/plans/master-roadmap-2026-q2.md <<'EOF'
# Master Roadmap Q2 2026
- V3 Phase B Quickwin Hooks: shipped via MR !54
EOF
git add -A
git commit -q -m "docs(plans): archive phase-b plan"
out="$(run_hook '{"hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"git commit -m \"docs(plans): archive phase-b plan\""}}')"
# After strip-date-prefix fix: pattern is "v3[-_ ]phase[-_ ]b[-_ ]quickwin[-_ ]hooks" which matches
# the roadmap line. Both archived AND found in roadmap -> no drift warning expected.
if [ -z "$out" ]; then
    assert_pass "Test 6"
else
    assert_fail "Test 6" "date-prefixed plan with matching roadmap should be silent, got: $out"
fi
cd - >/dev/null

echo ""
echo "▶ Test 7: Malformed JSON — silent"
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
