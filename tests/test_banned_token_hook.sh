#!/usr/bin/env bash
# Shell test driver for hooks/banned-token-leak-guard.sh
#
# Sets up a temp git repo, stages files with various content, invokes the hook
# with a mocked tool-input JSON on stdin, captures exit code + stderr.
#
# Run from repo root:  bash tests/test_banned_token_hook.sh

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="${REPO_ROOT}/hooks/banned-token-leak-guard.sh"

[ -x "$HOOK" ] || { echo "FAIL: hook not executable at $HOOK"; exit 1; }

failures=0

# Run the hook with a fake `git commit` invocation as tool input + a tmp git
# repo as CWD. Echoes "exit=<code>" on stdout; stderr from hook goes to a
# captured file the caller reads.
run_hook() {
    local tmp_dir stderr_file exit_code
    tmp_dir="$(mktemp -d)"
    stderr_file="$(mktemp)"

    (
        cd "$tmp_dir" || exit 1
        git init -q
        git config user.email "test@example.com"
        git config user.name "Test"

        # Stage files passed via the $stage_files() function the caller defined.
        # The caller writes them via a function name passed as $1.
        "$1"

        export CLAUDE_PLUGIN_ROOT="$REPO_ROOT"

        # Mock tool input. $2 is the bash command being "intercepted".
        printf '{"tool_input":{"command":"%s"}}' "$2" | bash "$HOOK" 2> "$stderr_file"
    )
    exit_code=$?

    rm -rf "$tmp_dir"
    # Print exit + stderr for the caller (stderr last so it's readable).
    printf 'exit=%s\n' "$exit_code"
    printf -- '--- stderr ---\n'
    cat "$stderr_file"
    printf -- '--- end ---\n'
    rm -f "$stderr_file"
}

assert_exit_code() {
    local actual="$1" expected="$2" test_name="$3"
    if [ "$actual" = "$expected" ]; then
        printf '  ✅ %s — exit %s (expected)\n' "$test_name" "$actual"
    else
        printf '  ❌ %s — got exit %s, expected %s\n' "$test_name" "$actual" "$expected"
        failures=$((failures + 1))
    fi
}

# ─── Test 1: Block on Block 1H Phase 6 regression case ───────────────────────
echo
echo "▶ Test 1: Block on Phase 4 in docblock (Block 1H regression case)"

stage_phase_4() {
    mkdir -p app/Abilities
    cat > app/Abilities/AiAbilityMethods.php <<'EOF'
<?php
/**
 * AI ability methods.
 * Phase 4 architecture test refs the matrix.
 */
class AiAbilityMethods {}
EOF
    git add app/Abilities/AiAbilityMethods.php
}

result=$(run_hook stage_phase_4 "git commit -m 'add ai methods'")
exit_code=$(printf '%s' "$result" | grep -oE 'exit=[0-9]+' | head -1 | cut -d= -f2)
assert_exit_code "$exit_code" "2" "Phase 4 in docblock should block"

if [ "$exit_code" = "2" ]; then
    if printf '%s' "$result" | grep -q "Phase 4"; then
        echo "  ✅ diagnostic mentions Phase 4"
    else
        echo "  ❌ diagnostic missing Phase 4 reference"
        failures=$((failures + 1))
    fi
fi

# ─── Test 2: Allow clean commit ──────────────────────────────────────────────
echo
echo "▶ Test 2: Allow clean commit (no banned tokens)"

stage_clean() {
    mkdir -p app/Models
    cat > app/Models/Post.php <<'EOF'
<?php
class Post {
    // Returns the post title.
    public function title() { return $this->title; }
}
EOF
    git add app/Models/Post.php
}

result=$(run_hook stage_clean "git commit -m 'add Post model'")
exit_code=$(printf '%s' "$result" | grep -oE 'exit=[0-9]+' | head -1 | cut -d= -f2)
assert_exit_code "$exit_code" "0" "Clean commit should pass"

# ─── Test 3: Allow override marker ───────────────────────────────────────────
echo
echo "▶ Test 3: Allow override marker (banned-token-ok)"

stage_override() {
    mkdir -p app/Domain
    cat > app/Domain/Workflow.php <<'EOF'
<?php
class Workflow {
    // Valid domain states: Phase 1, Phase 2, Phase 3 — banned-token-ok: domain term, not sprint state
    const STATES = ['draft', 'review', 'published'];
}
EOF
    git add app/Domain/Workflow.php
}

result=$(run_hook stage_override "git commit -m 'add workflow phases'")
exit_code=$(printf '%s' "$result" | grep -oE 'exit=[0-9]+' | head -1 | cut -d= -f2)
assert_exit_code "$exit_code" "0" "Line with banned-token-ok marker should pass"

# ─── Test 4: Passthrough on non-commit Bash call ─────────────────────────────
echo
echo "▶ Test 4: Passthrough on non-commit Bash call (git status)"

stage_phase_4_again() {
    mkdir -p app/Abilities
    cat > app/Abilities/X.php <<'EOF'
<?php
// Phase 5 — would block if it scanned, but the command is git status
class X {}
EOF
    git add app/Abilities/X.php
}

result=$(run_hook stage_phase_4_again "git status")
exit_code=$(printf '%s' "$result" | grep -oE 'exit=[0-9]+' | head -1 | cut -d= -f2)
assert_exit_code "$exit_code" "0" "Non-commit Bash call should pass through"

# ─── Test 5: Exception path passes (docs/plans/) ─────────────────────────────
echo
echo "▶ Test 5: Allow Phase ref in exception path (docs/plans/)"

stage_phase_in_docs() {
    mkdir -p docs/plans
    cat > docs/plans/sprint-roadmap.md <<'EOF'
# Sprint Roadmap

Phase 4 of the rollout starts next quarter. Sprint 12 onwards covers cleanup.
EOF
    git add docs/plans/sprint-roadmap.md
}

result=$(run_hook stage_phase_in_docs "git commit -m 'sprint plan'")
exit_code=$(printf '%s' "$result" | grep -oE 'exit=[0-9]+' | head -1 | cut -d= -f2)
assert_exit_code "$exit_code" "0" "Phase ref in docs/plans/ should pass"

# ─── Test 6: Context-anchored dated audit ref blocks (v2.0.1/S1) ─────────────
# Pre-v2.0.1: bare ISO date pattern matched "2026-05-14 audit fixes" — but
# also false-positived on Carbon::parse('2026-01-01') and other legitimate
# date literals. v2.0.1 narrows to require a sprint-state keyword prefix.
echo
echo "▶ Test 6: Block context-anchored dated audit ref in Blade (v2.0.1/S1)"

stage_dated_ref() {
    mkdir -p resources/views
    cat > resources/views/dropdown.blade.php <<'EOF'
{{-- Audit: 2026-05-14 — fixes for the editor toolbar --}}
<div class="dropdown">...</div>
EOF
    git add resources/views/dropdown.blade.php
}

result=$(run_hook stage_dated_ref "git commit -m 'add dropdown'")
exit_code=$(printf '%s' "$result" | grep -oE 'exit=[0-9]+' | head -1 | cut -d= -f2)
assert_exit_code "$exit_code" "2" "Context-anchored dated audit ref should block"

# ─── Test 7: Carbon date literal must NOT trigger (v2.0.1/S1) ────────────────
# Pre-v2.0.1 the bare date pattern false-positived on Carbon literals,
# fixture arrays, migration constants etc. v2.0.1 narrows to skip them.
echo
echo "▶ Test 7: Allow Carbon date literal (v2.0.1/S1)"

stage_carbon_literal() {
    mkdir -p app/Models
    cat > app/Models/Event.php <<'EOF'
<?php
namespace App\Models;

class Event {
    public function defaultStart(): \Carbon\Carbon {
        return \Carbon\Carbon::parse('2026-01-01');
    }

    public const HOLIDAYS = ['2026-04-03', '2026-12-25'];
}
EOF
    git add app/Models/Event.php
}

result=$(run_hook stage_carbon_literal "git commit -m 'add Event model'")
exit_code=$(printf '%s' "$result" | grep -oE 'exit=[0-9]+' | head -1 | cut -d= -f2)
assert_exit_code "$exit_code" "0" "Carbon date literal should pass through"

# ─── Test 8: Substring 'git commit' inside echo must passthrough (v2.0.1/S5) ──
echo
echo "▶ Test 8: Passthrough on echo containing 'git commit' substring (v2.0.1/S5)"
result=$(run_hook : "echo 'info: do not git commit yet'")
exit_code=$(printf '%s' "$result" | grep -oE 'exit=[0-9]+' | head -1 | cut -d= -f2)
assert_exit_code "$exit_code" "0" "Substring inside echo should pass through"

# ─── Summary ─────────────────────────────────────────────────────────────────
echo
if [ "$failures" -eq 0 ]; then
    echo "🟢 All hook scenarios passed."
    exit 0
else
    echo "🔴 ${failures} scenario(s) failed."
    exit 1
fi
