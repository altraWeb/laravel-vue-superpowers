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
