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
    refs+="📚 **Livewire source** for \`wire:*\` directive contracts: \`vendor/livewire/livewire/src/Component.php\` + \`vendor/livewire/livewire/src/Features/\`"$'\n'
    refs+="   Common: \`wire:click\`, \`wire:model\`, \`wire:loading\`, \`wire:navigate\`, \`wire:ignore\`, \`wire:target\`."$'\n'
fi

ctx="🔍 **vendor-source-preflight** (PreToolUse on \`${tool}\` of \`$(basename "$file_path")\`):"$'\n\n'"${refs}"
ctx+=$'\n'
ctx+="Reading the relevant vendor stub before composing your Blade saves a round-trip if the API doesn't match your assumption (canonical Block-1H bug class)."

jq -nc --arg ctx "$ctx" '{ hookSpecificOutput: { hookEventName: "PreToolUse", additionalContext: $ctx } }'
