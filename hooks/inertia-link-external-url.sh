#!/usr/bin/env bash
# hooks/inertia-link-external-url.sh
#
# PreToolUse on Edit/Write of .vue files. Detects <Link> usage with external
# URLs (http:// or https:// pointing to another origin). Inertia's <Link>
# issues an XHR fetch to the target URL; external URLs return non-Inertia
# responses and produce a silent 409 Conflict. Use plain <a> for external links.
#
# Anti-pattern source: docs/superpowers/audits/2026-05-17-vue-fork-deep-research.md
# Topic 6 (#14 — <Link> with external URL).

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
    enabled="$(python3 "$config_helper" get hook_enabled.inertia_link_external_url 2>/dev/null || echo true)"
    [ "$enabled" = "false" ] && exit 0
fi

file_path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)"
case "$file_path" in
    *.vue) ;;
    *) exit 0 ;;
esac

content="$(printf '%s' "$input" | jq -r '.tool_input.new_string // .tool_input.content // empty' 2>/dev/null || true)"
[ -z "$content" ] && exit 0

# Detect <Link ...href="https://... or http://... pattern (Inertia Link component with external URL)
# Only flag <Link> (capital L) — that's the Inertia component. Lowercase <a> is fine.
has_link_external="$(printf '%s' "$content" | grep -cE '<Link\s[^>]*href=["\x27]https?://' || true)"

if [ "$has_link_external" = "0" ]; then
    exit 0
fi

ctx="🔗 **inertia-link-external-url** (PreToolUse on \`${tool}\` of \`$(basename "$file_path")\`):"$'\n\n'
ctx+="\`<Link>\` used with an external URL (\`http://\` or \`https://\`). Inertia's \`<Link>\` component issues an XHR fetch to the target URL expecting an Inertia JSON response. External URLs return plain HTML or API responses — Inertia receives a non-Inertia response and throws a silent \`409 Conflict\`."$'\n\n'
ctx+="Canonical fix — use plain \`<a>\` for external links:"$'\n\n'
ctx+="\`\`\`vue"$'\n'
ctx+="<!-- Inertia Link: internal routes only -->"$'\n'
ctx+="<Link href=\"/posts\">All posts</Link>"$'\n\n'
ctx+="<!-- External link: use native <a> -->"$'\n'
ctx+="<a href=\"https://external.com\" target=\"_blank\" rel=\"noopener noreferrer\">"$'\n'
ctx+="  External site"$'\n'
ctx+="</a>"$'\n'
ctx+="\`\`\`"$'\n\n'
ctx+="To disable: \`hook_enabled.inertia_link_external_url: false\` in \`.laravel-vue-superpowers.yaml\`."

jq -nc --arg ctx "$ctx" '{ hookSpecificOutput: { hookEventName: "PreToolUse", additionalContext: $ctx } }'
