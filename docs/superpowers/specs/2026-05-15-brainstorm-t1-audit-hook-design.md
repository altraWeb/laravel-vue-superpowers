# `brainstorm-t1-audit` Hook — Design Spec

**Issue:** [#20](https://github.com/altraWeb/laravel-superpowers/issues/20)
**Milestone:** V2-MVP
**Status:** Design draft
**Date:** 2026-05-15

---

## 1. Context & Motivation

Pilot 2.0 Tactic 1 (Phase-Start Agent-Audit) is canonical at brainstorm-time. Block 1H + 1E both ran a parallel `laravel-best-practices` Agent alongside `superpowers:brainstorming`, surfacing 11+ sources of best-practice research and 10+ findings per brainstorm.

Currently orchestrator dispatches manually. If forgotten → brainstorm proceeds without audit (Block 1A retro: "super aber nicht ULTRA").

This is the second PostToolUse hook on `superpowers:brainstorming` activation (sibling of #21). The two hooks complement each other:
- `#21 visual-companion-default-on` — nudges agent to offer Visual Companion at Step 2
- `#20 brainstorm-t1-audit` (this) — nudges agent to dispatch parallel `laravel-best-practices` Agent for best-practice research

This is the **sixth and final V2-MVP hook**, completing the V2-MVP scope (#22 config + #1-5 agents + #13-15 skill enhancements + #23 slash command + 6 hooks).

## 2. Goals & Non-Goals

**Goals**

- Fire on every `superpowers:brainstorming` skill invocation
- Inject reminder via `additionalContext` that Pilot 2.0 T1 audit should be dispatched as a parallel background task
- Provide a canonical prompt template the agent uses when dispatching `laravel-best-practices`
- Honor `hook_enabled.brainstorm_t1_audit: false` config flag
- Honor `audit_aggressiveness` config (e.g., `brainstorm-only` vs `every-phase` vs `every-commit`)
- Fail-open on plugin internals failing

**Non-Goals (important deviation from issue AC)**

- **Auto-dispatch the Agent directly from the hook.** Hooks in Claude Code are shell scripts; they cannot invoke an Agent (agents live in the harness, not in shell). Implementation injects a **REMINDER + prompt template** via `additionalContext`. The agent in the user's session does the actual dispatch via the Task tool when it sees the reminder.
- Auto-archiving the agent's output to `docs/superpowers/audits/`. The dispatched agent's output is captured by the harness, not by our hook. The reminder instructs the parent agent to manually archive after the audit completes.
- Detecting stack versions from composer.json + package.json automatically (out of scope for hook — the dispatched `laravel-best-practices` agent does this on its own when invoked).

## 3. Architecture

### 3.1 Hook Registration

Second entry under the existing PostToolUse Skill matcher in `hooks/hooks.json` (alongside `visual-companion-default-on`):

```json
{
    "hooks": {
        "PostToolUse": [
            {
                "matcher": "Skill",
                "hooks": [
                    { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/visual-companion-default-on.sh" },
                    { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/brainstorm-t1-audit.sh" }
                ]
            }
        ]
    }
}
```

### 3.2 Script Workflow (`hooks/brainstorm-t1-audit.sh`)

1. **Read stdin JSON**, extract `tool_input.skill` and `tool_input.args`
2. **Filter to `superpowers:brainstorming`** — anything else → exit 0
3. **Config check** — `hook_enabled.brainstorm_t1_audit: false` → exit 0
4. **`audit_aggressiveness` config check** — if `brainstorm-only` (default) or `every-phase` or `every-commit`, we always fire on brainstorm. If set to a value that excludes brainstorm-time, skip. (For V2-MVP all valid values include brainstorm-time, so this is forward-compat.)
5. **Build the reminder** containing:
   - The intent (auto-dispatch Pilot 2.0 T1 audit)
   - The canonical Task-dispatch prompt template
   - The expected output shape (executive summary + per-decision findings + anti-patterns + open questions)
   - Where to archive when complete (`docs/superpowers/audits/{date}-{topic}-audit.md`)
6. **Emit** as `additionalContext` via PostToolUse JSON output

## 4. Output Format (additionalContext)

```
📋 Pilot 2.0 Tactic 1 (Phase-Start Agent-Audit): when you enter Step 2 of `superpowers:brainstorming`, dispatch `laravel-best-practices` as a **parallel background task** via the Task tool. The audit runs alongside your interactive brainstorming and surfaces best-practice research + anti-patterns + open questions.

Canonical dispatch prompt for the audit:

> Brainstorm-time Pilot 2.0 T1 audit. Topic: <topic from brainstorming args>. Stack: detect via `composer.json` + `package.json` (Laravel + Livewire + Flux Pro v2 + Pest 4 + PHP version). Output expectations:
>
> 1. **Executive summary** — 3-5 lines, the most important findings
> 2. **Per-decision findings** — for each design decision in the brainstorm topic, what's the current-Laravel best practice? Cite sources (Tier 1: official docs, Tier 2: core-team blogs, Tier 3: Spatie/Laracasts/Laravel News)
> 3. **Anti-patterns** — what to AVOID, with one-line rationale each
> 4. **Open questions** — what's actively debated in the community, what couldn't be resolved from available sources
>
> Search at least 3 sources. Always include the year filter (e.g., "Laravel 12 X best practice 2025/2026") to avoid stale content.

When the audit completes, archive its output to `docs/superpowers/audits/$(date +%Y-%m-%d)-<short-topic>-audit.md` so it's discoverable later.

This dispatch is **default-on** unless the operator explicitly says they don't want it. If `audit_aggressiveness` in config is set to `every-commit` or `brainstorm-only`, this brainstorm-time dispatch is required per project canon.

If you decide to skip the audit (operator opt-out for this brainstorm), say so explicitly and document why in your response — don't silently skip.
```

## 5. Error Handling / Fail-Open

| Scenario | Behavior |
|---|---|
| stdin empty / not JSON | exit 0 |
| Not brainstorming skill | exit 0 |
| Hook disabled | exit 0 |
| `audit_aggressiveness` excludes brainstorm | exit 0 (forward-compat — currently all values include it) |
| Config helper crashes | use defaults, continue |
| Otherwise | emit additionalContext, exit 0 |

## 6. Testing

Shell tests in `tests/test_brainstorm_t1_audit_hook.sh`. Scenarios:

1. **Brainstorming activation emits reminder with prompt template** — verify stdout JSON contains "Pilot 2.0 Tactic 1" + "laravel-best-practices" + the dispatch-template heading
2. **Different skill passthrough** — `writing-plans` skill → no emit
3. **Hook disabled in config** — no emit
4. **Empty stdin** → silent
5. **Malformed JSON** → silent

## 7. Documentation Deliverables

- `hooks/brainstorm-t1-audit.sh` (new)
- `hooks/hooks.json` (modified — add second PostToolUse Skill entry)
- `tests/test_brainstorm_t1_audit_hook.sh` (new)
- `README.md` (modified — append to Hooks section)
- `docs/hooks.md` (modified — insert entry, **remove all from Forthcoming** since this is the last V2-MVP hook)

## 8. AC Mapping

| AC from #20 | Where |
|---|---|
| Hook fires on every brainstorming activation | §3.2 step 2 |
| Auto-dispatches Agent in background | **Deviation:** hook injects a REMINDER + prompt template instead. The agent in the user's session does the actual Task-tool dispatch. (Hooks-cannot-invoke-agents constraint; see spec §2 Non-Goals.) |
| Detects stack versions from composer.json + package.json | **Deferred to dispatched agent.** `laravel-best-practices` already does this on its own when invoked. |
| Auto-archives agent output to docs/superpowers/audits/ on completion | **Deferred to agent's discipline.** Reminder text instructs the parent agent to archive the output. Hook itself cannot intercept Agent output. |
| Diagnostic emit visible: "Pilot 2.0 T1 audit dispatched as background task" | §4 — operator sees the reminder; the agent then dispatches and reports the dispatch ID in its response |

## 9. Out of Scope

- True async/background dispatch from hook layer (architecture constraint)
- Audit-completion notification mechanism (Claude Code doesn't expose hooks for parallel-Task completion)
- Auto-archival logic in the hook itself

## 10. Open Questions for Implementation

- Should the hook emit the dispatch prompt template inline, or reference a file (e.g., `hooks/templates/brainstorm-t1-audit-prompt.md`)? **Decision: inline** for v1 — keeps the hook self-contained, no file dependency.
- Should the hook check if an audit was ALREADY dispatched in this session (deduplication)? **Decision: no** for v1 — the parent agent can decide. Hook is stateless.
