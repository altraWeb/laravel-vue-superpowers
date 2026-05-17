#!/usr/bin/env bash
# hooks/vue-setinterval-cleanup.sh
#
# PreToolUse on Edit/Write of .vue files. Detects setInterval usage that
# lacks a paired onUnmounted (or watch-based cleanup). Warns via
# hookSpecificOutput; non-blocking.
#
# Anti-pattern source: docs/superpowers/audits/2026-05-17-vue-fork-deep-research.md
# Topic 6 (Vue 3 reactivity + lifecycle anti-patterns).

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
    enabled="$(python3 "$config_helper" get hook_enabled.vue_setinterval_cleanup 2>/dev/null || echo true)"
    [ "$enabled" = "false" ] && exit 0
fi

file_path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)"
case "$file_path" in
    *.vue) ;;
    *) exit 0 ;;
esac

content="$(printf '%s' "$input" | jq -r '.tool_input.new_string // .tool_input.content // empty' 2>/dev/null || true)"
[ -z "$content" ] && exit 0

has_setinterval="$(printf '%s' "$content" | grep -ciE 'setInterval\s*\(' || true)"
has_onUnmounted="$(printf '%s' "$content" | grep -ciE 'onUnmounted\s*\(|onBeforeUnmount\s*\(' || true)"

if [ "$has_setinterval" = "0" ]; then
    exit 0
fi

if [ "$has_onUnmounted" != "0" ]; then
    # Has both — assume cleanup is wired (heuristic; not AST-perfect, accept false negative)
    exit 0
fi

ctx="⏱️ **vue-setinterval-cleanup** (PreToolUse on \`${tool}\` of \`$(basename "$file_path")\`):"$'\n\n'
ctx+="\`setInterval\` detected without paired \`onUnmounted\` / \`onBeforeUnmount\` cleanup. In Vue 3 Composition API, timers must be cleared when the component unmounts or they leak across navigations (Inertia visits, route changes, KeepAlive cycles)."$'\n\n'
ctx+="Canonical pattern:"$'\n\n'
ctx+="\`\`\`vue"$'\n'
ctx+="<script setup>"$'\n'
ctx+="import { onMounted, onUnmounted } from 'vue'"$'\n'
ctx+="let intervalId"$'\n'
ctx+="onMounted(() => { intervalId = setInterval(() => {}, 1000) })"$'\n'
ctx+="onUnmounted(() => { clearInterval(intervalId) })"$'\n'
ctx+="</script>"$'\n'
ctx+="\`\`\`"$'\n\n'
ctx+="To disable: \`hook_enabled.vue_setinterval_cleanup: false\` in \`.laravel-vue-superpowers.yaml\`."

jq -nc --arg ctx "$ctx" '{ hookSpecificOutput: { hookEventName: "PreToolUse", additionalContext: $ctx } }'
