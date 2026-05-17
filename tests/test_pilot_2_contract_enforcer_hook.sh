#!/usr/bin/env bash
set -euo pipefail

HOOK="$(cd "$(dirname "$0")/.." && pwd)/hooks/pilot-2-contract-enforcer.sh"

run_hook() {
    printf '%s' "$1" | bash "$HOOK"
}

passed=0
failed=0
assert_pass() { echo "  ✅ $1"; passed=$((passed + 1)); }
assert_fail() { echo "  ❌ $1 — $2"; failed=$((failed + 1)); }

# Helper: setup repo with a plan-doc having a Pilot 2.0 Tactic Tracking section
setup_repo_with_plan() {
    local tracking="$1"  # "complete" | "T3-missing" | "T4-missing"
    local repo="$(mktemp -d)"
    cd "$repo"
    git init -q
    git config user.email t@t; git config user.name T
    mkdir -p docs/superpowers/plans
    cat > docs/superpowers/plans/feature-x.md <<EOF
# Feature X

## Phase 1

**Pilot 2.0 Tactic Tracking:**
EOF
    case "$tracking" in
        complete)
            cat >> docs/superpowers/plans/feature-x.md <<'EOF'
- [x] T1 dispatched on 2026-05-17
- [x] T2 VC offered (accepted)
- [x] T3 reviewed all commits
- [x] T4 specialist audit before tests
EOF
            ;;
        T3-missing)
            cat >> docs/superpowers/plans/feature-x.md <<'EOF'
- [x] T1 dispatched on 2026-05-17
- [x] T2 VC offered (accepted)
- [ ] T3 pending for commits: abc1234
- [x] T4 specialist audit before tests
EOF
            ;;
        T4-missing)
            cat >> docs/superpowers/plans/feature-x.md <<'EOF'
- [x] T1 dispatched on 2026-05-17
- [x] T2 VC offered (accepted)
- [x] T3 reviewed all commits
- [ ] T4 pending for tests: tests/Feature/FeatureXTest.php
EOF
            ;;
    esac
    git add -A
    git commit -q -m "init"
    git checkout -q -b feat/feature-x
    echo "$repo"
}

echo ""
echo "▶ Test 1: PostToolUse git-push with complete Tactic markers — silent"
repo="$(setup_repo_with_plan complete)"
cd "$repo"
out="$(run_hook '{"hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"git push origin feat/feature-x"}}')"
if [ -z "$out" ]; then
    assert_pass "Test 1"
else
    assert_fail "Test 1" "expected silent on complete markers, got: $out"
fi
cd - >/dev/null

echo ""
echo "▶ Test 2: PostToolUse git-push with T3 incomplete and audit_aggressiveness=every-phase — warns"
repo="$(setup_repo_with_plan T3-missing)"
cd "$repo"
out="$(run_hook '{"hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"git push origin feat/feature-x"}}')"
if printf '%s' "$out" | grep -qi "T3"; then
    assert_pass "Test 2"
else
    assert_fail "Test 2" "expected T3 warning, got: $out"
fi
cd - >/dev/null

echo ""
echo "▶ Test 3: Non-PostToolUse event — silent"
out="$(run_hook '{"hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"git push"}}')"
if [ -z "$out" ]; then
    assert_pass "Test 3"
else
    assert_fail "Test 3" "expected silent on non-PostToolUse, got: $out"
fi

echo ""
echo "▶ Test 4: PostToolUse Bash NOT git-commit/push — silent"
out="$(run_hook '{"hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"ls -la"}}')"
if [ -z "$out" ]; then
    assert_pass "Test 4"
else
    assert_fail "Test 4" "expected silent on non-git command, got: $out"
fi

echo ""
echo "▶ Test 5: No plan-doc with Tactic Tracking section — silent (no obligations)"
repo="$(mktemp -d)"
cd "$repo"
git init -q
git config user.email t@t; git config user.name T
git commit -q --allow-empty -m "init"
out="$(run_hook '{"hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"git push"}}')"
if [ -z "$out" ]; then
    assert_pass "Test 5"
else
    assert_fail "Test 5" "expected silent with no plan-doc, got: $out"
fi
cd - >/dev/null

echo ""
echo "▶ Test 6: Malformed JSON — silent"
out="$(printf 'not json' | bash "$HOOK" 2>&1 || true)"
if [ -z "$(echo "$out" | grep -v '^$')" ] 2>/dev/null || [ -z "$out" ]; then
    assert_pass "Test 6"
else
    assert_fail "Test 6" "expected silent on malformed JSON, got: $out"
fi

echo ""
if [ "$failed" -eq 0 ]; then
    echo "🟢 All hook scenarios passed."
else
    echo "🔴 $failed scenario(s) failed."
    exit 1
fi
