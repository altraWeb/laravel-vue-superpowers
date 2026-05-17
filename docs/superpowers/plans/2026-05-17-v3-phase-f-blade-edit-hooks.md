# V3 Phase F — Advanced Blade-Edit Hooks — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development. Checkbox tracking.

**Goal:** Land Phase F — two PreToolUse hooks that fire on Edit/Write of `*.blade.php` files to inject context. Ship as v3.0.0-alpha.6.

**Architecture:** Two bash hooks registered under `PreToolUse.Edit` AND `PreToolUse.Write` (new matchers in hooks.json). Both read `tool_input.file_path` and `tool_input.new_string` / `tool_input.content`, filter to blade files with specific patterns, and emit context as `hookSpecificOutput.additionalContext`. Non-blocking — they only inform.

**Tech Stack:** Bash + jq. No new dependencies.

**Spec:** `docs/superpowers/specs/2026-05-17-v3-livewire-megarelease-design.md` Section 5 — Phase F.

**Issues:** [#28](https://github.com/altraWeb/laravel-livewire-superpowers/issues/28), [#29](https://github.com/altraWeb/laravel-livewire-superpowers/issues/29)

---

## File Structure

### New files

| File | Purpose |
|---|---|
| `hooks/vendor-source-preflight.sh` | On blade-file Edit/Write with `<flux:*>` or `wire:*`, surfaces relevant vendor stub paths |
| `hooks/lang-key-existence-preflight.sh` | On blade-file Edit/Write with `__()` or `@lang()`, verifies each key exists in `lang/*` |
| `tests/test_vendor_source_preflight_hook.sh` | 5 scenarios |
| `tests/test_lang_key_existence_preflight_hook.sh` | 5 scenarios |

### Modified files

| File | Change |
|---|---|
| `hooks/hooks.json` | Add 2 new matcher blocks under PreToolUse: `Edit` and `Write`, each registering both hooks |
| `config.defaults.yaml` | 2 new `hook_enabled.*` flags (default true) |
| `tests/test_config.py` | 2 new tests |
| `docs/hooks.md` | 2 new sections |
| `README.md` | Hook count `10 → 12` |
| `CHANGELOG.md` | Prepend `## [3.0.0-alpha.6]` section |
| `.claude-plugin/plugin.json` | Version `3.0.0-alpha.5` → `3.0.0-alpha.6`; hook count `10 → 12` |

### Branch / release

- Branch: `feat/v3-phase-f-blade-edit-hooks`
- Post-merge: tag `v3.0.0-alpha.6` + Pre-Release

---

## STEP F.1 — Foundation

### Task 1: Pre-flight + branch

- [ ] **Step 1: Verify clean state**

```bash
cd ~/dev/laravel-livewire-superpowers
git status; git log --oneline -3; git tag --list | grep '^v3\.'
```
Expected: clean, tags alpha.1-5.

- [ ] **Step 2: Baseline tests**

```bash
for t in tests/test_*.sh; do bash "$t" >/dev/null 2>&1 && echo "✓" || echo "✗ $t"; done
python3 -m pytest tests/ -q
```
Expected: 11 ✓, 31 passed.

- [ ] **Step 3: Branch**

```bash
git switch -c feat/v3-phase-f-blade-edit-hooks
```

---

## STEP F.2 — Hook 1: vendor-source-preflight (#28)

### Task 2: Write test suite (TDD)

**File:** `tests/test_vendor_source_preflight_hook.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

HOOK="$(cd "$(dirname "$0")/.." && pwd)/hooks/vendor-source-preflight.sh"
run_hook() { printf '%s' "$1" | bash "$HOOK"; }
extract_context() { printf '%s' "$1" | jq -r '.hookSpecificOutput.additionalContext // empty'; }
passed=0; failed=0
assert_pass() { echo "  ✅ $1"; passed=$((passed+1)); }
assert_fail() { echo "  ❌ $1 — $2"; failed=$((failed+1)); }

echo ""
echo "▶ Test 1: Edit on .blade.php with flux:button — surfaces Flux stub paths"
out="$(run_hook '{"hook_event_name":"PreToolUse","tool_name":"Edit","tool_input":{"file_path":"/tmp/foo.blade.php","new_string":"<flux:button>Hello</flux:button>"}}')"
ctx="$(extract_context "$out")"
if printf '%s' "$ctx" | grep -qi "flux"; then
    assert_pass "Test 1"
else
    assert_fail "Test 1" "expected flux stub reference, got: $ctx"
fi

echo ""
echo "▶ Test 2: Write on .blade.php with wire:model — surfaces Livewire source paths"
out="$(run_hook '{"hook_event_name":"PreToolUse","tool_name":"Write","tool_input":{"file_path":"/tmp/foo.blade.php","content":"<input wire:model=\"name\">"}}')"
ctx="$(extract_context "$out")"
if printf '%s' "$ctx" | grep -qi "livewire"; then
    assert_pass "Test 2"
else
    assert_fail "Test 2" "expected livewire source reference, got: $ctx"
fi

echo ""
echo "▶ Test 3: Edit on .blade.php without flux/wire directives — silent"
out="$(run_hook '{"hook_event_name":"PreToolUse","tool_name":"Edit","tool_input":{"file_path":"/tmp/foo.blade.php","new_string":"<div class=\"text-red\">x</div>"}}')"
if [ -z "$out" ]; then
    assert_pass "Test 3"
else
    assert_fail "Test 3" "expected silent on no-flux-no-wire blade, got: $out"
fi

echo ""
echo "▶ Test 4: Edit on non-blade file with flux text — silent"
out="$(run_hook '{"hook_event_name":"PreToolUse","tool_name":"Edit","tool_input":{"file_path":"/tmp/foo.txt","new_string":"<flux:button>Hello</flux:button>"}}')"
if [ -z "$out" ]; then
    assert_pass "Test 4"
else
    assert_fail "Test 4" "expected silent on non-blade file, got: $out"
fi

echo ""
echo "▶ Test 5: Malformed JSON — silent"
out="$(printf 'not json' | bash "$HOOK" 2>&1 || true)"
if [ -z "$(echo "$out" | grep -v '^$')" ] 2>/dev/null || [ -z "$out" ]; then
    assert_pass "Test 5"
else
    assert_fail "Test 5" "expected silent on malformed JSON, got: $out"
fi

echo ""
if [ "$failed" -eq 0 ]; then
    echo "🟢 All hook scenarios passed."
else
    echo "🔴 $failed scenario(s) failed."
    exit 1
fi
```

```bash
chmod +x tests/test_vendor_source_preflight_hook.sh
bash tests/test_vendor_source_preflight_hook.sh   # RED state expected
```

### Task 3: Write the hook

**File:** `hooks/vendor-source-preflight.sh`

```bash
#!/usr/bin/env bash
# hooks/vendor-source-preflight.sh
#
# PreToolUse hook on Edit AND Write. When the file_path ends in .blade.php
# AND the new content contains <flux:*> or wire:* directives, surfaces
# relevant vendor stub paths (Flux Pro v2 stubs + Livewire source) as
# additional context so the agent can reference canonical patterns.
#
# Skip:
#   - hook_enabled.vendor_source_preflight is false
#   - file_path doesn't end in .blade.php
#   - content has no flux:* or wire:* directives
#
# Issue: #28

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
    enabled="$(python3 "$config_helper" get hook_enabled.vendor_source_preflight 2>/dev/null || echo true)"
    [ "$enabled" = "false" ] && exit 0
fi

file_path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)"
case "$file_path" in
    *.blade.php) ;;
    *) exit 0 ;;
esac

# Extract content (new_string for Edit, content for Write)
content="$(printf '%s' "$input" | jq -r '.tool_input.new_string // .tool_input.content // empty' 2>/dev/null || true)"
[ -z "$content" ] && exit 0

# Detect directives
has_flux="$(printf '%s' "$content" | grep -ciE '<flux:[a-z]+(\.|[ />])' || true)"
has_wire="$(printf '%s' "$content" | grep -ciE 'wire:[a-z]+' || true)"

if [ "$has_flux" = "0" ] && [ "$has_wire" = "0" ]; then
    exit 0
fi

# Build reference list
refs=""
if [ "$has_flux" != "0" ]; then
    refs+="📚 **Flux Pro v2 stubs** for reference patterns: \`vendor/livewire/flux-pro/stubs/resources/views/flux/\`"$'\n'
    refs+="   Common: \`button/index.blade.php\`, \`field/\`, \`modal/\`, \`tooltip/\`, \`editor/\`."$'\n\n'
fi
if [ "$has_wire" != "0" ]; then
    refs+="📚 **Livewire source** for `wire:*` directive contracts: \`vendor/livewire/livewire/src/Component.php\` + \`vendor/livewire/livewire/src/Features/\`"$'\n'
    refs+="   Common: `wire:click`, `wire:model`, `wire:loading`, `wire:navigate`, `wire:ignore`, `wire:target`."$'\n'
fi

ctx="🔍 **vendor-source-preflight** (PreToolUse on \`${tool}\` of \`$(basename "$file_path")\`):"$'\n\n'"${refs}"
ctx+=$'\n'
ctx+="Reading the relevant vendor stub before composing your Blade saves a round-trip if the API doesn't match your assumption (canonical Block-1H bug class)."

jq -nc --arg ctx "$ctx" '{ hookSpecificOutput: { hookEventName: "PreToolUse", additionalContext: $ctx } }'
```

```bash
chmod +x hooks/vendor-source-preflight.sh
bash tests/test_vendor_source_preflight_hook.sh   # GREEN expected
```

---

## STEP F.3 — Hook 2: lang-key-existence-preflight (#29)

### Task 4: Write test suite

**File:** `tests/test_lang_key_existence_preflight_hook.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

HOOK="$(cd "$(dirname "$0")/.." && pwd)/hooks/lang-key-existence-preflight.sh"
run_hook() { printf '%s' "$1" | bash "$HOOK"; }
extract_context() { printf '%s' "$1" | jq -r '.hookSpecificOutput.additionalContext // empty'; }
passed=0; failed=0
assert_pass() { echo "  ✅ $1"; passed=$((passed+1)); }
assert_fail() { echo "  ❌ $1 — $2"; failed=$((failed+1)); }

# Helper: setup a temp project with lang files
setup_with_lang() {
    local project="$(mktemp -d)"
    mkdir -p "$project/lang/en"
    cat > "$project/lang/en/messages.php" <<'EOF'
<?php return ['greeting' => 'Hello', 'farewell' => 'Goodbye'];
EOF
    echo "$project"
}

echo ""
echo "▶ Test 1: Edit blade with __('messages.greeting') existing key — silent"
project="$(setup_with_lang)"
cd "$project"
out="$(run_hook '{"hook_event_name":"PreToolUse","tool_name":"Edit","tool_input":{"file_path":"'$project'/foo.blade.php","new_string":"<p>{{ __(\"messages.greeting\") }}</p>"}}')"
if [ -z "$out" ]; then
    assert_pass "Test 1"
else
    assert_fail "Test 1" "expected silent on existing key, got: $out"
fi
cd - >/dev/null

echo ""
echo "▶ Test 2: Edit blade with __('messages.missing') unknown key — warns"
project="$(setup_with_lang)"
cd "$project"
out="$(run_hook '{"hook_event_name":"PreToolUse","tool_name":"Edit","tool_input":{"file_path":"'$project'/foo.blade.php","new_string":"<p>{{ __(\"messages.missing\") }}</p>"}}')"
ctx="$(extract_context "$out")"
if printf '%s' "$ctx" | grep -qi "messages.missing"; then
    assert_pass "Test 2"
else
    assert_fail "Test 2" "expected missing key warning, got: $ctx"
fi
cd - >/dev/null

echo ""
echo "▶ Test 3: Edit blade without __() / @lang() — silent"
out="$(run_hook '{"hook_event_name":"PreToolUse","tool_name":"Edit","tool_input":{"file_path":"/tmp/foo.blade.php","new_string":"<p>Static text</p>"}}')"
if [ -z "$out" ]; then
    assert_pass "Test 3"
else
    assert_fail "Test 3" "expected silent on no-lang-call blade, got: $out"
fi

echo ""
echo "▶ Test 4: Edit non-blade file with __() — silent"
out="$(run_hook '{"hook_event_name":"PreToolUse","tool_name":"Edit","tool_input":{"file_path":"/tmp/foo.txt","new_string":"<p>{{ __(\"messages.x\") }}</p>"}}')"
if [ -z "$out" ]; then
    assert_pass "Test 4"
else
    assert_fail "Test 4" "expected silent on non-blade, got: $out"
fi

echo ""
echo "▶ Test 5: Malformed JSON — silent"
out="$(printf 'not json' | bash "$HOOK" 2>&1 || true)"
if [ -z "$(echo "$out" | grep -v '^$')" ] 2>/dev/null || [ -z "$out" ]; then
    assert_pass "Test 5"
else
    assert_fail "Test 5" "expected silent on malformed JSON, got: $out"
fi

echo ""
if [ "$failed" -eq 0 ]; then
    echo "🟢 All hook scenarios passed."
else
    echo "🔴 $failed scenario(s) failed."
    exit 1
fi
```

```bash
chmod +x tests/test_lang_key_existence_preflight_hook.sh
bash tests/test_lang_key_existence_preflight_hook.sh   # RED
```

### Task 5: Write the hook

**File:** `hooks/lang-key-existence-preflight.sh`

```bash
#!/usr/bin/env bash
# hooks/lang-key-existence-preflight.sh
#
# PreToolUse hook on Edit/Write of .blade.php with __() or @lang() calls.
# For each lang-key referenced, verifies it exists in lang/<locale>/<file>.php
# (Laravel convention) and warns about missing ones. Non-blocking.
#
# Skip:
#   - hook_enabled.lang_key_existence_preflight is false
#   - file_path doesn't end in .blade.php
#   - no __() or @lang() in the content
#   - no lang/ directory in the project (not a Laravel project, or pre-Laravel-9)
#
# Issue: #29

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
    enabled="$(python3 "$config_helper" get hook_enabled.lang_key_existence_preflight 2>/dev/null || echo true)"
    [ "$enabled" = "false" ] && exit 0
fi

file_path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)"
case "$file_path" in
    *.blade.php) ;;
    *) exit 0 ;;
esac

content="$(printf '%s' "$input" | jq -r '.tool_input.new_string // .tool_input.content // empty' 2>/dev/null || true)"
[ -z "$content" ] && exit 0

# Extract lang keys from __('key.path') and @lang('key.path') patterns
# Handles both single and double quotes
keys="$(printf '%s' "$content" | grep -oE "__\(['\"]([a-zA-Z0-9_.-]+)['\"]\)|@lang\(['\"]([a-zA-Z0-9_.-]+)['\"]\)" 2>/dev/null | grep -oE "[a-zA-Z0-9_.-]+" | grep -E '\.' | sort -u || true)"

[ -z "$keys" ] && exit 0

# Find project root (look for lang/ dir relative to the blade file)
# Use the blade file's directory as starting point, walk up looking for `lang/`
project_root=""
search_dir="$(dirname "$file_path" 2>/dev/null || echo "")"
[ -z "$search_dir" ] && exit 0

while [ "$search_dir" != "/" ] && [ -n "$search_dir" ]; do
    if [ -d "$search_dir/lang" ]; then
        project_root="$search_dir"
        break
    fi
    search_dir="$(dirname "$search_dir")"
done

[ -z "$project_root" ] && exit 0

# Default locale: try en first, fall back to first available
locale_dir="$project_root/lang/en"
[ ! -d "$locale_dir" ] && locale_dir="$(ls -d "$project_root/lang/"*/ 2>/dev/null | head -1)"
[ -z "$locale_dir" ] && exit 0

# Check each key
missing=""
while IFS= read -r key; do
    [ -z "$key" ] && continue
    # Key format: filename.nested.path → look for filename.php with nested.path entries
    file_part="$(echo "$key" | cut -d. -f1)"
    rest="$(echo "$key" | cut -d. -f2-)"
    lang_file="$locale_dir/${file_part}.php"
    if [ ! -f "$lang_file" ]; then
        missing+="  - \`${key}\` — lang file \`lang/$(basename "$locale_dir")/${file_part}.php\` missing"$'\n'
        continue
    fi
    # Simple check: does the rest appear in the lang file? (heuristic — not nested-array-aware)
    if ! grep -qE "['\"]${rest}['\"]\\s*=>" "$lang_file" 2>/dev/null; then
        missing+="  - \`${key}\` — key \`${rest}\` not found in \`lang/$(basename "$locale_dir")/${file_part}.php\`"$'\n'
    fi
done <<< "$keys"

[ -z "$missing" ] && exit 0

ctx="🌐 **lang-key-existence-preflight** (PreToolUse on \`${tool}\` of \`$(basename "$file_path")\`):"$'\n\n'"Missing or unresolved lang keys:"$'\n'"${missing}"$'\n'"Add the missing keys to \`lang/<locale>/\` before this edit lands, or the rendered Blade will show the raw key string."

jq -nc --arg ctx "$ctx" '{ hookSpecificOutput: { hookEventName: "PreToolUse", additionalContext: $ctx } }'
```

```bash
chmod +x hooks/lang-key-existence-preflight.sh
bash tests/test_lang_key_existence_preflight_hook.sh   # GREEN
```

---

## STEP F.4 — Shared updates

### Task 6: Register hooks in hooks.json

**File:** `hooks/hooks.json`

Add new PreToolUse matcher blocks `Edit` and `Write`, each registering both new hooks:

```json
"PreToolUse": [
    {
        "matcher": "Bash",
        "hooks": [
            { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/banned-token-leak-guard.sh" },
            { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/no-claude-attribution.sh" },
            { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/teamcity-always.sh" },
            { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/anti-silent-deferral.sh" }
        ]
    },
    {
        "matcher": "Edit",
        "hooks": [
            { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/vendor-source-preflight.sh" },
            { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/lang-key-existence-preflight.sh" }
        ]
    },
    {
        "matcher": "Write",
        "hooks": [
            { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/vendor-source-preflight.sh" },
            { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/lang-key-existence-preflight.sh" }
        ]
    }
]
```

Validate:
```bash
python3 -c 'import json; h=json.load(open("hooks/hooks.json")); print(len(h["hooks"]["PreToolUse"]), "matcher blocks under PreToolUse")'
```
Expected: `3 matcher blocks under PreToolUse`.

### Task 7: config.defaults.yaml + schema + test_config.py

Add to `hook_enabled`:
```yaml
  vendor_source_preflight: true
  lang_key_existence_preflight: true
```

Add 2 tests to `tests/test_config.py`:
```python
def test_get_vendor_source_preflight_default():
    cli = ConfigCLI([])
    result = cli.run(["get", "hook_enabled.vendor_source_preflight"])
    assert result.strip() == "true"

def test_get_lang_key_existence_preflight_default():
    cli = ConfigCLI([])
    result = cli.run(["get", "hook_enabled.lang_key_existence_preflight"])
    assert result.strip() == "true"
```

### Task 8: docs/hooks.md sections

Add 2 new `### vendor-source-preflight` + `### lang-key-existence-preflight` sections following existing pattern (Event / What it does / Why / Skip cases / Run trailer).

### Task 9: README + CHANGELOG + plugin.json

- README: bump `Hooks (10) → Hooks (12)`. Update versions section with new entry placeholder for alpha.6.
- CHANGELOG: prepend `## [3.0.0-alpha.6]` with Added (2 hooks), Changed (hooks.json, config, plugin.json), Phase Status.
- plugin.json: version 3.0.0-alpha.6, current-state hook count 10 → 12.

### Task 10: Test verify

```bash
for t in tests/test_*.sh; do bash "$t" >/dev/null 2>&1 && echo "✓" || echo "✗ $t"; done
python3 -m pytest tests/ -q
ls hooks/*.sh | wc -l
```
Expected: 13 ✓ (11 + 2 new), 33 passed (31 + 2 new), `12` hooks.

### Task 11: Commit + PR

Standard pattern.

---

## STEP F.5 — Post-Merge

### Task 12: Tag v3.0.0-alpha.6

Standard pattern: pull main, tag, push tag, GitHub Pre-Release.

**STOP. Phase F complete.**
