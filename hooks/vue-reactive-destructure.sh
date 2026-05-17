#!/usr/bin/env bash
# hooks/vue-reactive-destructure.sh
#
# PreToolUse on Edit/Write of .vue files. Detects destructuring of reactive()
# objects without toRefs() — a pattern that silently loses reactivity.
# Warns via hookSpecificOutput; non-blocking.
#
# Anti-pattern source: docs/superpowers/audits/2026-05-17-vue-fork-deep-research.md
# Topic 6 (#1 — reactive destructure pitfall).

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
    enabled="$(python3 "$config_helper" get hook_enabled.vue_reactive_destructure 2>/dev/null || echo true)"
    [ "$enabled" = "false" ] && exit 0
fi

file_path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)"
case "$file_path" in
    *.vue) ;;
    *) exit 0 ;;
esac

content="$(printf '%s' "$input" | jq -r '.tool_input.new_string // .tool_input.content // empty' 2>/dev/null || true)"
[ -z "$content" ] && exit 0

# Detect pattern A: const { ... } = reactive( — direct destructure
has_destructure_direct="$(printf '%s' "$content" | grep -cE 'const\s*\{[^}]+\}\s*=\s*reactive\s*\(' || true)"

# Detect pattern B: reactive() assigned to variable, then destructured
# e.g.: const state = reactive({...}); const { x } = state;
# We look for: (1) reactive() assigned to a variable, AND (2) destructure of that variable
has_reactive_var=""
if printf '%s' "$content" | grep -qE 'const\s+\w+\s*=\s*reactive\s*\('; then
    # Extract the variable name(s) assigned from reactive()
    reactive_vars="$(printf '%s' "$content" | grep -oE 'const\s+\w+\s*=\s*reactive\s*\(' | grep -oE 'const\s+\w+' | awk '{print $2}')"
    for rvar in $reactive_vars; do
        if printf '%s' "$content" | grep -qE "const\s*\{[^}]+\}\s*=\s*${rvar}[^(]"; then
            has_reactive_var="yes"
            break
        fi
    done
fi

has_torefs="$(printf '%s' "$content" | grep -cE 'const\s*\{[^}]+\}\s*=\s*toRefs\s*\(' || true)"

# If neither direct nor indirect reactive destructure pattern found, skip
if [ "$has_destructure_direct" = "0" ] && [ -z "$has_reactive_var" ]; then
    exit 0
fi

# If toRefs is used for the same destructure pattern, it's canonical — silent
if [ "$has_torefs" != "0" ]; then
    exit 0
fi

ctx="⚛️ **vue-reactive-destructure** (PreToolUse on \`${tool}\` of \`$(basename "$file_path")\`):"$'\n\n'
ctx+="\`const { ... } = reactive(...)\` detected without \`toRefs()\`. Destructuring a \`reactive()\` object produces plain values — reactivity is lost silently. The component will not update when the reactive object changes."$'\n\n'
ctx+="Canonical fixes:"$'\n\n'
ctx+="\`\`\`vue"$'\n'
ctx+="// Fix A: keep wrapped — access via state.count"$'\n'
ctx+="const state = reactive({ count: 0, name: '' })"$'\n'
ctx+="// Use state.count in template and functions"$'\n\n'
ctx+="// Fix B: toRefs — destructured refs stay reactive"$'\n'
ctx+="const state = reactive({ count: 0, name: '' })"$'\n'
ctx+="const { count, name } = toRefs(state)"$'\n'
ctx+="// count.value and name.value are now Ref<number> / Ref<string>"$'\n'
ctx+="\`\`\`"$'\n\n'
ctx+="To disable: \`hook_enabled.vue_reactive_destructure: false\` in \`.laravel-vue-superpowers.yaml\`."

jq -nc --arg ctx "$ctx" '{ hookSpecificOutput: { hookEventName: "PreToolUse", additionalContext: $ctx } }'
