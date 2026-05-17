#!/usr/bin/env bash
# hooks/inertia-hardcoded-route.sh
#
# PreToolUse on Edit/Write of .vue and .ts files. When vendor/laravel/wayfinder/
# is installed (detected via filesystem check from cwd), warns on hardcoded
# route string literals in router.visit/get/post/put/patch/delete calls.
# When Wayfinder is NOT installed, exits silently — no false positives.
#
# Anti-pattern source: docs/superpowers/audits/2026-05-17-vue-fork-deep-research.md
# Topic 3 (Wayfinder) + Topic 6 (#13 — hardcoded route strings).

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
    enabled="$(python3 "$config_helper" get hook_enabled.inertia_hardcoded_route 2>/dev/null || echo true)"
    [ "$enabled" = "false" ] && exit 0
fi

file_path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)"
case "$file_path" in
    *.vue|*.ts) ;;
    *) exit 0 ;;
esac

# Only warn if Wayfinder is installed (vendor/laravel/wayfinder/ exists relative to cwd)
if [ ! -d "vendor/laravel/wayfinder" ]; then
    exit 0
fi

content="$(printf '%s' "$input" | jq -r '.tool_input.new_string // .tool_input.content // empty' 2>/dev/null || true)"
[ -z "$content" ] && exit 0

# Detect: router.visit/get/post/put/patch/delete with a hardcoded string starting with /
# Matches: router.visit("/posts"), router.post('/api/orders')
# Note: backtick template literals not covered here to avoid shell quoting issues;
# the single/double-quote patterns cover the vast majority of hardcoded routes.
has_hardcoded="$(printf '%s' "$content" | grep -cE "router\.(visit|get|post|put|patch|delete)\s*\(\s*[\"'][/]" || true)"

if [ "$has_hardcoded" = "0" ]; then
    exit 0
fi

ctx="🗺️ **inertia-hardcoded-route** (PreToolUse on \`${tool}\` of \`$(basename "$file_path")\`):"$'\n\n'
ctx+="Hardcoded route string detected in \`router.*\` call while Wayfinder is installed (\`vendor/laravel/wayfinder/\` present). Hardcoded strings drift silently when routes are renamed — Wayfinder-generated action helpers provide compile-time type safety."$'\n\n'
ctx+="Canonical Wayfinder pattern:"$'\n\n'
ctx+="\`\`\`vue"$'\n'
ctx+="<script setup lang=\"ts\">"$'\n'
ctx+="import { store as storePost } from '@/wayfinder/actions/PostController'"$'\n'
ctx+="import { index as listPosts } from '@/wayfinder/actions/PostController'"$'\n\n'
ctx+="// Type-safe: action() returns { url, method } — Inertia routes automatically"$'\n'
ctx+="const submit = () => form.submit(storePost())"$'\n'
ctx+="const goToList = () => router.visit(listPosts())"$'\n'
ctx+="</script>"$'\n'
ctx+="\`\`\`"$'\n\n'
ctx+="Run \`php artisan wayfinder:generate\` (or \`npm run dev\`) to regenerate action helpers after route changes."$'\n\n'
ctx+="To disable: \`hook_enabled.inertia_hardcoded_route: false\` in \`.laravel-vue-superpowers.yaml\`."

jq -nc --arg ctx "$ctx" '{ hookSpecificOutput: { hookEventName: "PreToolUse", additionalContext: $ctx } }'
