# `visual-companion-default-on` Hook — Design Spec

**Issue:** [#21](https://github.com/altraWeb/laravel-superpowers/issues/21)
**Milestone:** V2-MVP
**Status:** Design draft
**Date:** 2026-05-15

---

## 1. Context & Motivation

Operator memory rule `feedback_visual_companion_default_on` (saved 2026-05-14 after Block 1E): the `superpowers:brainstorming` Visual Companion is DEFAULT-ON for every brainstorm unless provably text-only (naming votes / semver-bump / config-flip).

Block 1E missed it ("sounds are auditory" rationalization) — operator-corrected. Block 1H leveraged it for 4 visual screens (operator: "diese visual irgendwas fand ich mega ober geil bitte wann immer möglich einbinden als standard").

A PostToolUse hook on `superpowers:brainstorming` skill activation reminds the agent that Visual Companion is default-on, so it doesn't forget at Step 2.

This is the fifth plugin hook and the first PostToolUse hook (previous four are PreToolUse).

## 2. Goals & Non-Goals

**Goals**

- Fire on every `superpowers:brainstorming` skill invocation
- Inject reminder via `additionalContext` (PostToolUse output) that Visual Companion is default-on
- Skip when topic args match text-only denylist (naming votes, semver, config-flips)
- Honor allowlist override (operator can force offer even on text-only topics)
- Honor `hook_enabled.visual_companion_default_on: false` config flag
- Honor top-level `visual_companion_default: off` (operator-wide opt-out)
- Fail-open on plugin internals failing

**Non-Goals**

- Emitting the Companion offer itself — the skill spec requires the offer to be "its own message", which a PostToolUse `additionalContext` cannot guarantee. Instead we **remind** the agent to offer at Step 2.
- Detecting Step 2 timing precisely — PostToolUse fires once when the skill is invoked, not per-step. The reminder lives in context for the duration.
- Replacing operator vigilance — when args don't reveal the topic, the agent's own judgment per skill spec still applies.

## 3. Architecture

### 3.1 Hook Registration

Fifth entry in `hooks/hooks.json`, but under a NEW matcher (PostToolUse on Skill tool, not PreToolUse on Bash):

```json
{
    "hooks": {
        "PreToolUse": [
            { "matcher": "Bash", "hooks": [ /* #16-19 hooks */ ] }
        ],
        "PostToolUse": [
            {
                "matcher": "Skill",
                "hooks": [
                    { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/visual-companion-default-on.sh" }
                ]
            }
        ]
    }
}
```

### 3.2 Script Workflow (`hooks/visual-companion-default-on.sh`)

1. **Read stdin JSON**, extract `tool_input.skill` (and `tool_input.args` if present)
2. **Filter to `superpowers:brainstorming`** — anything else → exit 0
3. **Config check** — `hook_enabled.visual_companion_default_on: false` → exit 0
4. **Top-level config** — `visual_companion_default: off` → exit 0 (operator never wants this enforced)
5. **Args denylist check** — if `tool_input.args` matches text-only patterns (configurable, defaults below) → exit 0
6. **Allowlist override** — if args also match an `always_offer` pattern → proceed to emit (overrides denylist)
7. **Emit additionalContext** via PostToolUse JSON output reminding the agent

### 3.3 Default Text-Only Denylist

Configurable via `visual_companion_default.text_only_patterns` in config (appended to defaults):

| Pattern (regex, case-insensitive) | Example match |
|---|---|
| `\bname[d]? vote\b` | "name vote for the new flag" |
| `\bnaming\b` | "naming convention for endpoints" |
| `\brename\b` | "rename UserService to AuthService" |
| `\bsemver\b` | "semver bump strategy" |
| `\bversion bump\b` | "version bump for next release" |
| `\bconfig flag\b` | "config flag for feature X" |
| `\bconfig flip\b` | "config flip rollout" |
| `\bwhich constant\b` | "which constant should we use" |
| `\bnumeric default\b` | "numeric default for timeout" |
| `\benum value\b` | "enum value for status" |

### 3.4 Output Format (PostToolUse `additionalContext`)

```json
{
    "hookSpecificOutput": {
        "hookEventName": "PostToolUse",
        "additionalContext": "📋 Per operator memory rule `feedback_visual_companion_default_on`: Visual Companion is DEFAULT-ON for every brainstorm unless the topic is provably text-only. When you reach Step 2 of `superpowers:brainstorming`, you MUST offer the Visual Companion as its own message (per the skill's spec). Do not skip it — operator explicitly wants it for any topic that could benefit from mockups/diagrams/wireframes. If you genuinely believe this topic is text-only (naming vote, semver, config-flip), say so explicitly and explain why."
    }
}
```

Exit 0 → success, context injected.

## 4. Error Handling / Fail-Open

| Scenario | Behavior |
|---|---|
| stdin empty / not JSON | exit 0 |
| Not brainstorming skill | exit 0 |
| Hook disabled | exit 0 |
| Top-level `visual_companion_default: off` | exit 0 |
| Args match denylist (and not allowlist) | exit 0 |
| Config helper crashes | use defaults, continue with emit |
| Otherwise | exit 0 + emit additionalContext JSON to stdout |

## 5. Testing

Shell tests in `tests/test_visual_companion_default_on_hook.sh`. Scenarios:

1. **Brainstorming activation emits reminder** — `tool_input.skill = superpowers:brainstorming` → exit 0, stdout contains additionalContext JSON
2. **Different skill passthrough** — `tool_input.skill = superpowers:writing-plans` → exit 0, NO stdout output
3. **Text-only denylist skip** — args contain "naming vote for new flag" → exit 0, NO output
4. **Allowlist override** — args contain "naming vote" + custom allowlist pattern → emit anyway
5. **Hook disabled in config** — exit 0, no output (test driver simulates disabled config)
6. **Top-level visual_companion_default: off** — exit 0, no output

## 6. Documentation Deliverables

- `hooks/visual-companion-default-on.sh` (new)
- `hooks/hooks.json` (modified — add PostToolUse Skill matcher block)
- `tests/test_visual_companion_default_on_hook.sh` (new)
- `README.md` (modified — append to Hooks section)
- `docs/hooks.md` (modified — insert entry, remove from Forthcoming)

## 7. AC Mapping

| AC from #21 | Where |
|---|---|
| Hook fires on every brainstorming Step 2 | §3.2 — fires on every skill invocation (closest practical approximation; Step 2 detection from outside not portable) |
| Auto-emits Visual Companion offer in own message | **Deviation**: emits a REMINDER to the agent (additionalContext) rather than the offer itself. Agent still issues the actual offer as its own message at Step 2 per skill spec. |
| Skips topic-text-only patterns | §3.3 + §3.2 step 5 |
| Allowlist + denylist patterns configurable | §3.3 + config `visual_companion_default.text_only_patterns` + `visual_companion_default.always_offer_patterns` |
| Operator can decline via standard skill response — no force | The agent offers, operator declines normally per skill spec. Hook just nudges, doesn't force. |

## 8. Out of Scope

- Skill internal-state inspection (not exposed to hooks)
- Forcing the Companion to launch automatically (operator must consent per skill spec)
- Browser-side companion management (separate skill territory)
