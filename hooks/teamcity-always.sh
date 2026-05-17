#!/usr/bin/env bash
# teamcity-always — PreToolUse hook that blocks `php artisan test` invocations
# missing the `--teamcity` flag (per project canon, CLAUDE.md PersonalGuidelines:
# always use --teamcity for IDE-friendly per-test event output).
#
# Reads tool input JSON from stdin, filters to php artisan test family, blocks
# (exit 2) with retry suggestion when --teamcity missing.
#
# Note: issue #18 spec says "auto-append --teamcity". This implementation
# BLOCKS with retry instead — auto-modifying tool_input is not a portable
# Claude Code hook output feature. 90% of value at 10% complexity. See spec
# docs/superpowers/specs/2026-05-15-teamcity-always-hook-design.md §2 + §9.
#
# Exit codes:
#   0 — pass through (not a target, --teamcity present, alt reporter, or
#       disabled). Fail-open.
#   2 — block; --teamcity missing on php artisan test command.
#
# Registered in hooks/hooks.json under PreToolUse Bash matcher.

set -uo pipefail

# ─── Step 1: Read tool input ──────────────────────────────────────────────────
input="$(cat 2>/dev/null || true)"
[ -z "$input" ] && exit 0

command_str="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"
[ -z "$command_str" ] && exit 0

# ─── Step 2: Filter to `php artisan test` and `composer test` families ────────
# Match: `php artisan test`, `php artisan test:parallel`, `php artisan test:compact`,
# `composer test`, `composer run test`, `composer run-script test`
# (with anything after — flags, file paths, etc.)
#
# v2.0.1 (S3): extended to cover composer wrappers (`composer test`) since
# many Laravel projects expose the Pest/PHPUnit runner via composer.json
# scripts. See docs/audits/2026-05-15-v2-mvp-self-audit.md §"Should-fix S3".
#
# v2.0.1 (S5): anchor at command-position to avoid matching `echo "php artisan
# test ..."` or `grep "composer test" docs/`. Also require whitespace or EOL
# after `test` to avoid matching `composer test-coverage` etc.
# See §"Should-fix S5".
prefix='(^|[;&|][[:space:]]*)([A-Z_][A-Za-z0-9_]*=[^[:space:]]+[[:space:]]+)*'
if printf '%s' "$command_str" | grep -qE "${prefix}(php artisan test(:parallel|:compact)?([[:space:]]|$)|composer (run-script |run )?test([[:space:]]|$))"; then
    : # proceed
else
    exit 0
fi

# ─── Step 3: Skip if --teamcity already present ──────────────────────────────
case "$command_str" in
    *"--teamcity"*) exit 0 ;;
esac

# ─── Step 4: Skip if alternative reporter explicit ───────────────────────────
case "$command_str" in
    *"--testdox"*|*"--printer-class"*|*"--printer="*)
        exit 0
        ;;
esac

# ─── Step 5: Config check ─────────────────────────────────────────────────────
config_helper="${CLAUDE_PLUGIN_ROOT:-}/lib/config.py"

config_get() {
    local key="$1"
    local fallback="$2"
    if [ -f "$config_helper" ]; then
        python3 "$config_helper" get "$key" 2>/dev/null || printf '%s' "$fallback"
    else
        printf '%s' "$fallback"
    fi
}

# Per-hook flag — if explicitly disabled, exit.
enabled="$(config_get hook_enabled.teamcity_always true)"
[ "$enabled" = "true" ] || exit 0

# Top-level project-canon flag — operator-wide opt-out.
teamcity_always="$(config_get teamcity_always true)"
[ "$teamcity_always" = "true" ] || exit 0

# ─── Step 6: Build retry suggestion ──────────────────────────────────────────
# Insert --teamcity right after the test subcommand. composer wrappers use
# `-- --teamcity` to pass the flag through. Direct artisan calls take the
# flag inline.
#
# v2.0.1: handles `composer test` / `composer run test` wrappers by inserting
# `-- --teamcity` (composer passes args after `--` to the wrapped command).
suggested="$(CMD="$command_str" python3 - <<'PYEOF' 2>/dev/null
import os, re
cmd = os.environ.get("CMD", "").rstrip("\n")
# composer wrappers: insert ` -- --teamcity` after the test token (unless `--`
# already present).
if re.search(r"\bcomposer (run-script |run )?test\b", cmd):
    if "--" in cmd.split("test", 1)[1]:
        # `--` already present — append --teamcity after it
        result = re.sub(r"--\s*", "-- --teamcity ", cmd, count=1)
    else:
        result = re.sub(
            r"\b(composer (?:run-script |run )?test)\b",
            r"\1 -- --teamcity",
            cmd,
            count=1,
        )
    print(result)
else:
    # Direct artisan: inline insertion
    pattern = re.compile(r"\bphp artisan (test(?::parallel|:compact)?)\b")
    result = pattern.sub(lambda m: f"php artisan {m.group(1)} --teamcity", cmd, count=1)
    print(result)
PYEOF
)"

[ -z "$suggested" ] && suggested="(rebuild failed — append --teamcity manually after \`test\`)"

# ─── Step 7: Block with diagnostic ────────────────────────────────────────────
cat >&2 <<EOF
🚫 teamcity-always: test command blocked

Detected \`php artisan test\` invocation without \`--teamcity\`:

  ── command ─────────────────────────────────────────────────────
  ${command_str}
  ─────────────────────────────────────────────────────────────────

Project canon (CLAUDE.md PersonalGuidelines): always use \`--teamcity\`
for parsable test output. IDE integration (PhpStorm/VSCode) requires
the TeamCity reporter for per-test events.

Retry with --teamcity:

  ── suggested rewrite ───────────────────────────────────────────
  ${suggested}
  ─────────────────────────────────────────────────────────────────

To disable globally, set in .laravel-superpowers.yaml (filename preserved from V2 for config compatibility):
    hook_enabled:
      teamcity_always: false
    # OR
    teamcity_always: false   # top-level kill switch

To explicitly use an alternate reporter, add --testdox or --printer-class.
EOF

exit 2
