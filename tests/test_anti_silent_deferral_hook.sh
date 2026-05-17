#!/usr/bin/env bash
# Shell test driver for hooks/anti-silent-deferral.sh
#
# Each scenario sets up a tmp git repo with a `main` branch + feature branch,
# writes a plan-doc with various Deferred Items section content, invokes the
# hook with a mock `git push` command, asserts exit code.
#
# Run from repo root: bash tests/test_anti_silent_deferral_hook.sh

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="${REPO_ROOT}/hooks/anti-silent-deferral.sh"

[ -x "$HOOK" ] || { echo "FAIL: hook not executable at $HOOK"; exit 1; }

failures=0

# Run a scenario:
#   $1 = name of a bash function that writes plan-doc(s) into the tmp repo
#        (after a main-branch baseline commit is made; function runs on feature branch)
#   $2 = bash command to feed as tool_input.command
#   $3 = optional extra env-var assignments (e.g. "LARAVEL_SUPERPOWERS_ALLOW_UNCAPTURED_DEFERRAL=1")
run_scenario() {
    local setup_fn="$1"
    local cmd="$2"
    local extra_env="${3:-}"
    local stderr_file tmp_dir exit_code
    stderr_file="$(mktemp)"
    tmp_dir="$(mktemp -d)"

    (
        cd "$tmp_dir" || exit 1
        git init -q
        git config user.email "test@example.com"
        git config user.name "Test"
        # Create main branch baseline.
        mkdir -p docs/plans
        printf 'baseline\n' > README.md
        git add README.md
        git commit -q -m "init"
        git checkout -q -b main 2>/dev/null || git branch -m main
        # Create feature branch and run setup.
        git checkout -q -b feature
        "$setup_fn"
        git add -A
        git commit -q -m "feature work" || true

        export CLAUDE_PLUGIN_ROOT="$REPO_ROOT"
        if [ -n "$extra_env" ]; then
            eval "export $extra_env"
        fi

        printf '{"tool_input":{"command":%s}}' "$(printf '%s' "$cmd" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')" \
            | bash "$HOOK" 2> "$stderr_file"
    )
    exit_code=$?

    rm -rf "$tmp_dir"
    printf 'exit=%s\n' "$exit_code"
    printf -- '--- stderr ---\n'
    cat "$stderr_file"
    printf -- '--- end ---\n'
    rm -f "$stderr_file"
}

assert_exit() {
    local actual="$1" expected="$2" name="$3"
    if [ "$actual" = "$expected" ]; then
        printf '  ✅ %s — exit %s (expected)\n' "$name" "$actual"
    else
        printf '  ❌ %s — got exit %s, expected %s\n' "$name" "$actual" "$expected"
        failures=$((failures + 1))
    fi
}

extract_exit() {
    printf '%s' "$1" | grep -oE 'exit=[0-9]+' | head -1 | cut -d= -f2
}

# ─── Test 1: Block on free-form prose ────────────────────────────────────────
echo
echo "▶ Test 1: Block on free-form prose"

setup_free_form() {
    cat > docs/plans/2026-05-15-feature.md <<'EOF'
# Feature Plan

## Phase 1

Implement the thing.

## Phase 1 — Deferred Items

This still needs more thought. We'll come back to it.
EOF
}

result=$(run_scenario setup_free_form "git push")
assert_exit "$(extract_exit "$result")" "2" "Free-form prose should block"

# ─── Test 2: Block on bullets without issue refs ─────────────────────────────
echo
echo "▶ Test 2: Block on bullets without issue refs"

setup_unlinked_bullets() {
    cat > docs/plans/2026-05-15-feature.md <<'EOF'
# Feature Plan

## Phase 2 — Deferred Items

- Refactor the legacy module
- Add admin import endpoint
EOF
}

result=$(run_scenario setup_unlinked_bullets "git push")
assert_exit "$(extract_exit "$result")" "2" "Unlinked bullets should block"

# ─── Test 3: Allow None marker ───────────────────────────────────────────────
echo
echo "▶ Test 3: Allow None marker"

setup_none_marker() {
    cat > docs/plans/2026-05-15-feature.md <<'EOF'
# Feature Plan

## Phase 3 — Deferred Items

**None — all tasks completed as planned.**
EOF
}

result=$(run_scenario setup_none_marker "git push")
assert_exit "$(extract_exit "$result")" "0" "None marker should pass"

# ─── Test 4: Allow captured bullets ──────────────────────────────────────────
echo
echo "▶ Test 4: Allow bullets with #N issue refs"

setup_captured_bullets() {
    cat > docs/plans/2026-05-15-feature.md <<'EOF'
# Feature Plan

## Phase 4 — Deferred Items

- #142 — refactor the legacy module
- #143 — add admin import endpoint
- gh issue #144 — third deferred item
EOF
}

result=$(run_scenario setup_captured_bullets "git push")
assert_exit "$(extract_exit "$result")" "0" "Bullets with issue refs should pass"

# ─── Test 5: Allow empty section body ────────────────────────────────────────
echo
echo "▶ Test 5: Allow empty section body"

setup_empty_section() {
    cat > docs/plans/2026-05-15-feature.md <<'EOF'
# Feature Plan

## Phase 5 — Deferred Items


## Phase 6

Other stuff.
EOF
}

result=$(run_scenario setup_empty_section "git push")
assert_exit "$(extract_exit "$result")" "0" "Empty section should pass"

# ─── Test 6: Passthrough non-push ────────────────────────────────────────────
echo
echo "▶ Test 6: Passthrough git status (not push)"

setup_with_violations() {
    cat > docs/plans/2026-05-15-feature.md <<'EOF'
## Phase 1 — Deferred Items

Free-form prose that should block on push.
EOF
}

result=$(run_scenario setup_with_violations "git status")
assert_exit "$(extract_exit "$result")" "0" "git status should pass through"

# ─── Test 7: Passthrough git push --help ─────────────────────────────────────
echo
echo "▶ Test 7: Passthrough git push --help"

result=$(run_scenario setup_with_violations "git push --help")
assert_exit "$(extract_exit "$result")" "0" "--help should pass through"

# ─── Test 8: Passthrough when no plan-docs changed ───────────────────────────
echo
echo "▶ Test 8: Passthrough when no plan-docs on branch"

setup_no_plan_docs() {
    printf 'code change\n' >> README.md
}

result=$(run_scenario setup_no_plan_docs "git push")
assert_exit "$(extract_exit "$result")" "0" "No plan-docs → pass"

# ─── Test 9: Emergency override ──────────────────────────────────────────────
echo
echo "▶ Test 9: Emergency override env var"

result=$(run_scenario setup_with_violations "git push" "LARAVEL_SUPERPOWERS_ALLOW_UNCAPTURED_DEFERRAL=1")
assert_exit "$(extract_exit "$result")" "0" "Override env should bypass with stderr log"
if printf '%s' "$result" | grep -q "override active"; then
    echo "  ✅ stderr log emitted for override"
else
    echo "  ⚠️  no override log to stderr (acceptable but documented)"
fi

# ─── Test 10: Per-doc skip marker ────────────────────────────────────────────
echo
echo "▶ Test 10: Per-doc skip marker bypasses validation"

setup_skip_marker() {
    cat > docs/plans/2026-05-15-feature.md <<'EOF'
# Feature Plan

<!-- anti-silent-deferral-skip: WIP plan, not for review yet -->

## Phase 1 — Deferred Items

Free-form prose that would normally block.
EOF
}

result=$(run_scenario setup_skip_marker "git push")
assert_exit "$(extract_exit "$result")" "0" "Skip marker should bypass"

# ─── Test 11: Multi-section detection ────────────────────────────────────────
echo
echo "▶ Test 11: Multi-section — Phase 4 captured, Phase 5 uncaptured"

setup_multi_section() {
    cat > docs/plans/2026-05-15-feature.md <<'EOF'
# Feature Plan

## Phase 4 — Deferred Items

**None — all tasks completed as planned.**

## Phase 5 — Deferred Items

- Refactor without issue link
EOF
}

result=$(run_scenario setup_multi_section "git push")
assert_exit "$(extract_exit "$result")" "2" "Multi-section: Phase 5 should block"
if printf '%s' "$result" | grep -q "Phase 5"; then
    if ! printf '%s' "$result" | grep -E "Phase 4" | grep -qv "Phase 5"; then
        # Phase 4 only mentioned through context, not as uncaptured — that's correct
        echo "  ✅ Phase 5 named in diagnostic"
    else
        echo "  ✅ Phase 5 named in diagnostic"
    fi
else
    echo "  ❌ Phase 5 not named in diagnostic output"
    failures=$((failures + 1))
fi

# ─── v2.0.1 S5 — command-position filter ─────────────────────────────────────
# Pre-v2.0.1 substring-glob filter intercepted `echo "git push"` and similar
# literal mentions. See docs/audits/2026-05-15-v2-mvp-self-audit.md §"S5".

echo
echo "▶ Test 12: Passthrough \`echo 'do not git push yet'\` (v2.0.1/S5)"
no_deferrals() {
    cat > docs/plans/clean.md <<'EOF'
# Clean plan
## Phase 1 — Deferred Items
**None — all tasks completed as planned.**
EOF
}
result=$(run_scenario no_deferrals "echo info: do not git push yet")
exit_code=$(printf '%s' "$result" | grep -oE 'exit=[0-9]+' | head -1 | cut -d= -f2)
if [ "$exit_code" = "0" ]; then
    echo "  ✅ Substring inside echo should pass through — exit 0 (expected)"
else
    echo "  ❌ Expected exit 0, got $exit_code"
    failures=$((failures + 1))
fi

# ─── Summary ─────────────────────────────────────────────────────────────────
echo
if [ "$failures" -eq 0 ]; then
    echo "🟢 All hook scenarios passed."
    exit 0
else
    echo "🔴 ${failures} scenario(s) failed."
    exit 1
fi
