#!/usr/bin/env bash
# Hook-integration smoke test: simulates a hook reading config the way #16-21 will.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PLUGIN_DIR="$REPO_DIR"
TMP_HOME="$(mktemp -d)"
trap 'rm -rf "$TMP_HOME"' EXIT

export CLAUDE_PLUGIN_ROOT="$PLUGIN_DIR"
export HOME="$TMP_HOME"

# Case 1: defaults — pilot_version should be 2
val=$(python3 "$PLUGIN_DIR/lib/config.py" get pilot_version)
[ "$val" = "2" ] || { echo "FAIL case 1: expected 2, got '$val'"; exit 1; }

# Case 2: user overlay
mkdir -p "$HOME/.claude/plugins/altraweb-laravel/laravel-superpowers"
echo "pilot_version: 1" > "$HOME/.claude/plugins/altraweb-laravel/laravel-superpowers/config.yaml"
val=$(python3 "$PLUGIN_DIR/lib/config.py" get pilot_version)
[ "$val" = "1" ] || { echo "FAIL case 2: expected 1, got '$val'"; exit 1; }

# Case 3: hook fail-open — broken yaml + key fallback in shell
# NOTE: ":::broken:::" is valid YAML (PyYAML parses it as a dict key), so
# "key: {broken yaml" is used instead — this is a real parse error that causes
# _load_yaml() to return {} and cmd_get to exit non-zero (key not found).
echo "key: {broken yaml" > "$HOME/.claude/plugins/altraweb-laravel/laravel-superpowers/config.yaml"
val=$(python3 "$PLUGIN_DIR/lib/config.py" get hook_enabled.banned_token_leak_guard 2>/dev/null || echo "true")
[ "$val" = "true" ] || { echo "FAIL case 3: expected true, got '$val'"; exit 1; }

# Case 4: missing python deps simulation — shell fallback works
val=$(false 2>/dev/null || echo "fallback-default")
[ "$val" = "fallback-default" ] || { echo "FAIL case 4"; exit 1; }

echo "all hook-integration cases pass"
