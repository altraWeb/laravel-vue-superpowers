# V1 Phase D — Hook Repurpose — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development.

**Goal:** Rename + rewrite `vendor-source-preflight` for Reka UI + Inertia component detection; broaden `lang-key-existence-preflight` to `.vue` files. Ship as v1.0.0-alpha.4.

**Spec:** `docs/superpowers/specs/2026-05-17-vue-fork-adaptation-design.md` Section 5 Phase D.

---

## File Structure

| File | Change |
|---|---|
| `hooks/vendor-source-preflight.sh` | `git mv` to `hooks/inertia-vendor-preflight.sh` + rewrite body |
| `tests/test_vendor_source_preflight_hook.sh` | `git mv` to `tests/test_inertia_vendor_preflight_hook.sh` + rewrite |
| `hooks/lang-key-existence-preflight.sh` | Broaden file-type filter from `*.blade.php` only to `*.blade.php` OR `*.vue` |
| `tests/test_lang_key_existence_preflight_hook.sh` | Add 1 scenario for `.vue` file with `__()` |
| `hooks/hooks.json` | Update hook reference: `vendor-source-preflight.sh` → `inertia-vendor-preflight.sh` |
| `config.defaults.yaml` | Rename `vendor_source_preflight` flag → `inertia_vendor_preflight` |
| `tests/test_config.py` | Rename matching test |
| `docs/hooks.md` | Rewrite vendor-source-preflight section as inertia-vendor-preflight; extend lang-key section with Vue note |
| `CHANGELOG.md` | Prepend `[1.0.0-alpha.4]` section |
| `.claude-plugin/plugin.json` | Bump version `1.0.0-alpha.3` → `1.0.0-alpha.4` |
| `README.md` | Hook listing: `vendor-source-preflight` → `inertia-vendor-preflight`; Versions section add alpha.4 |

Branch: `feat/v1-phase-d-hook-repurpose`. Post-merge: tag v1.0.0-alpha.4 + marketplace bump.

---

## Tasks

### Task 1: Pre-flight + branch

- [ ] Verify clean main post-Phase-C (tag v1.0.0-alpha.3 present, 17 shell + 37 Python tests green)
- [ ] `git switch -c feat/v1-phase-d-hook-repurpose`

### Task 2: Rename hook file via git mv

```bash
git mv hooks/vendor-source-preflight.sh hooks/inertia-vendor-preflight.sh
git mv tests/test_vendor_source_preflight_hook.sh tests/test_inertia_vendor_preflight_hook.sh
```

### Task 3: Rewrite `hooks/inertia-vendor-preflight.sh` body

Goal: on Edit/Write of `.vue` files importing Reka UI primitives OR using Inertia helpers (`useForm`, `usePage`, `router`, `<Link>`), surface relevant vendor source paths.

Use Write tool with content:

```bash
#!/usr/bin/env bash
# hooks/inertia-vendor-preflight.sh
#
# PreToolUse on Edit/Write of .vue files. Detects Reka UI imports +
# Inertia helpers (useForm, usePage, router, <Link>) and surfaces
# relevant vendor source paths so the agent has canonical examples
# at hand before generating component code.
#
# Skip:
#   - hook_enabled.inertia_vendor_preflight is false
#   - file_path doesn't end in .vue
#   - content has no Reka UI import OR Inertia helper usage
#
# Repurposed from vendor-source-preflight (Livewire variant) in Phase D.

set -uo pipefail

input="$(cat 2>/dev/null || true)"
[ -z "$input" ] && exit 0

event="$(printf '%s' "$input" | jq -r '.hook_event_name // empty' 2>/dev/null || true)"
[ "$event" != "PreToolUse" ] && exit 0

tool="$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null || true)"
case "$tool" in
    Edit|Write) ;;
    *) exit 0 ;;
esac

config_helper="${CLAUDE_PLUGIN_ROOT:-}/lib/config.py"
if [ -f "$config_helper" ]; then
    enabled="$(python3 "$config_helper" get hook_enabled.inertia_vendor_preflight 2>/dev/null || echo true)"
    [ "$enabled" = "false" ] && exit 0
fi

file_path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)"
case "$file_path" in
    *.vue) ;;
    *) exit 0 ;;
esac

content="$(printf '%s' "$input" | jq -r '.tool_input.new_string // .tool_input.content // empty' 2>/dev/null || true)"
[ -z "$content" ] && exit 0

# Detect Reka UI imports
has_reka="$(printf '%s' "$content" | grep -ciE "from\s+['\"]reka-ui['\"]" || true)"

# Detect Inertia helpers
has_inertia_form="$(printf '%s' "$content" | grep -ciE "useForm\s*\(|usePage\s*\(|router\.(visit|get|post|put|patch|delete)" || true)"
has_inertia_link="$(printf '%s' "$content" | grep -ciE "from\s+['\"]@inertiajs/vue3['\"]" || true)"

if [ "$has_reka" = "0" ] && [ "$has_inertia_form" = "0" ] && [ "$has_inertia_link" = "0" ]; then
    exit 0
fi

refs=""

if [ "$has_reka" != "0" ]; then
    refs+="📚 **Reka UI source** for primitive patterns: \`node_modules/reka-ui/dist/\`"$'\n'
    refs+="   Common primitives: \`dialog/\`, \`dropdown-menu/\`, \`popover/\`, \`form/\`, \`select/\`, \`combobox/\`."$'\n\n'
fi

if [ "$has_inertia_link" != "0" ] || [ "$has_inertia_form" != "0" ]; then
    refs+="📚 **Inertia Vue 3 source** for helper contracts: \`node_modules/@inertiajs/vue3/dist/\`"$'\n'
    refs+="   Key helpers: \`useForm\`, \`usePage\`, \`router\`, \`<Link>\`, \`<Head>\`, \`usePoll\`, \`useHttp\` (v3+)."$'\n'
    refs+="   Laravel-side: \`vendor/inertiajs/inertia-laravel/src/\` for \`Inertia::render\`, \`Inertia::share\`, \`Inertia::defer\`, \`Inertia::lazy\`."$'\n'
fi

ctx="🔍 **inertia-vendor-preflight** (PreToolUse on \`${tool}\` of \`$(basename "$file_path")\`):"$'\n\n'"${refs}"
ctx+=$'\n'
ctx+="Reading the relevant vendor source before composing your Vue component saves a round-trip if the API doesn't match your assumption."

jq -nc --arg ctx "$ctx" '{ hookSpecificOutput: { hookEventName: "PreToolUse", additionalContext: $ctx } }'
```

Verify executable: `chmod +x hooks/inertia-vendor-preflight.sh`.

### Task 4: Rewrite test suite

Use Write tool to replace `tests/test_inertia_vendor_preflight_hook.sh`:

```bash
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
```

`chmod +x tests/test_inertia_vendor_preflight_hook.sh` + run for GREEN.

### Task 5: Broaden `hooks/lang-key-existence-preflight.sh` to `.vue` files

Read the current hook. Find the file-type filter:

```bash
case "$file_path" in
    *.blade.php) ;;
    *) exit 0 ;;
esac
```

Replace with:

```bash
case "$file_path" in
    *.blade.php|*.vue) ;;
    *) exit 0 ;;
esac
```

No other logic change needed — `__()` and `@lang()` regex detection works identically in `.vue` template strings.

### Task 6: Add 1 test scenario to `tests/test_lang_key_existence_preflight_hook.sh`

Append before the malformed JSON test:

```bash
echo ""
echo "▶ Test N: .vue file with __() — applies same key existence check"
project="$(setup_with_lang)"  # reuse existing helper
cd "$project"
out="$(run_hook '{"hook_event_name":"PreToolUse","tool_name":"Edit","tool_input":{"file_path":"'$project'/Page.vue","new_string":"<template><p>{{ __(\"messages.greeting\") }}</p></template>"}}')"
if [ -z "$out" ]; then assert_pass "Test N"; else assert_fail "Test N" "expected silent on existing key in .vue, got: $out"; fi
cd - >/dev/null
```

Renumber if needed.

### Task 7: Update `hooks/hooks.json`

Find the reference to `vendor-source-preflight.sh` (under PreToolUse.Edit AND PreToolUse.Write blocks) and replace with `inertia-vendor-preflight.sh`. 2 occurrences total.

### Task 8: Update `config.defaults.yaml` flag rename

Find `vendor_source_preflight:` and rename to `inertia_vendor_preflight:`. Keep `true` default.

### Task 9: Rename test_config.py test

Find `test_get_vendor_source_preflight_default` and rename to `test_get_inertia_vendor_preflight_default`. Update the body to query the new key.

### Task 10: Update `docs/hooks.md`

- Replace the `### vendor-source-preflight` section heading with `### inertia-vendor-preflight`
- Rewrite the body for Reka UI + Inertia detection (analogous structure: Event / What it does / Why / Skip cases / Run trailer)
- In the `### lang-key-existence-preflight` section, add a line under "Trigger" or "Skip cases" noting that the hook also fires on `.vue` files (Vue templates can use `__()` via Inertia shared translations).

### Task 11: Update `README.md`

- Hook listing: rename `vendor-source-preflight` → `inertia-vendor-preflight`; update description
- Versions section: add `v1.0.0-alpha.4` entry, move `(current)`

### Task 12: Prepend CHANGELOG `## [1.0.0-alpha.4]` section

```markdown
## [1.0.0-alpha.4] — 2026-05-17 — Phase D: Hook Repurpose

Phase D repurposes the inherited `vendor-source-preflight` hook for Reka UI + Inertia detection (was: Flux Pro v2 + Livewire) and broadens `lang-key-existence-preflight` to also fire on `.vue` files.

### Changed

- `hooks/vendor-source-preflight.sh` → `hooks/inertia-vendor-preflight.sh` (`git mv` + full rewrite). Now detects Reka UI imports + Inertia helpers (useForm, usePage, router, <Link>) in `.vue` file Edit/Write, surfaces `node_modules/reka-ui/dist/`, `node_modules/@inertiajs/vue3/dist/`, and `vendor/inertiajs/inertia-laravel/src/` as canonical source references.
- `hooks/lang-key-existence-preflight.sh` — file-type filter broadened from `*.blade.php` only to `*.blade.php` OR `*.vue`. Vue templates can call `__()` via Inertia shared translation props.
- `tests/test_vendor_source_preflight_hook.sh` → `tests/test_inertia_vendor_preflight_hook.sh` (renamed + 5 scenarios rewritten for Reka/Inertia detection).
- `tests/test_lang_key_existence_preflight_hook.sh` — 1 new scenario for `.vue` file.
- `hooks/hooks.json` — hook reference renamed (2 occurrences: PreToolUse.Edit + PreToolUse.Write).
- `config.defaults.yaml` — `hook_enabled.vendor_source_preflight` → `hook_enabled.inertia_vendor_preflight` (default true).
- `tests/test_config.py` — test renamed to match.
- `docs/hooks.md` — section heading + body rewritten; lang-key section extended with `.vue` note.
- `README.md` — hook listing updated.
- `.claude-plugin/plugin.json` — version 1.0.0-alpha.3 → 1.0.0-alpha.4.

### Phase Status

Phase D (this alpha) — ✅ shipped 2026-05-17 as v1.0.0-alpha.4.

Phase E remains (release polish + v1.0.0 stable cut).

---
```

### Task 13: Bump plugin.json version

`1.0.0-alpha.3` → `1.0.0-alpha.4`.

### Task 14: Test verify

```bash
for t in tests/test_*.sh; do bash "$t" >/dev/null 2>&1 && echo "✓" || echo "✗ $t"; done
python3 -m pytest tests/ -q
ls hooks/*.sh | wc -l   # still 16 (rename, not add/remove)
```

Expected: 17 shell ✓ (still 17, just renamed file), 37 Python passed.

### Task 15: Commit + push + PR

Standard pattern.

**STOP. Wait for operator merge.**

### Task 16: Post-Merge — tag v1.0.0-alpha.4 + Pre-Release + marketplace bump

Standard pattern: pull main, tag, push tag, GitHub Pre-Release, bump Vue plugin in marketplace.json from `1.0.0-alpha.3` to `1.0.0-alpha.4`.

**STOP. Phase D complete.**
