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
