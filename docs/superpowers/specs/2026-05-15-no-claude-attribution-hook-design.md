# `no-claude-attribution` Hook — Design Spec

**Issue:** [#17](https://github.com/altraWeb/laravel-superpowers/issues/17)
**Milestone:** V2-MVP
**Status:** Design draft
**Date:** 2026-05-15

---

## 1. Context & Motivation

Operator's `feedback_no_claude_attribution` memory rule: ZERO Claude attribution in commit messages, MR titles, MR bodies, or PR descriptions. Project-canon strict. Currently relies on agent discipline — every subagent could potentially slip a `Co-Authored-By: Claude <noreply@anthropic.com>` trailer or `🤖 Generated with Claude Code` banner.

Real session evidence: 9 of 19 commits in the `spec/22-config-foundation` branch had Claude attribution before manual cleanup via `git filter-branch` (PR #32 history). Operator pushed back hard. Subagent-dispatched commits inherited the default git template behavior from the Bash tool.

A PreToolUse hook on `git commit`, `gh pr create`, and `glab mr create` would catch this discipline-free at commit/MR creation time.

This is the second hook in the plugin, following the pattern established by `banned-token-leak-guard` (#39, merged).

## 2. Goals & Non-Goals

**Goals**

- Block `git commit -m`, `git commit -F` invocations whose message contains Claude attribution
- Block `gh pr create --title|--body|--body-file` invocations
- Block `glab mr create --title|--description|--description-file` invocations
- Show the offending line and a sanitized rewrite suggestion
- Fail-open on plugin internals failing
- Honor `hook_enabled.no_claude_attribution: false` to disable (escape hatch)

**Non-Goals**

- Catching attribution already committed to history (use `git filter-branch` for that — see #32 cleanup)
- Catching attribution in commit-message editor mode (`git commit` with no `-m` opens $EDITOR; we can't intercept the post-edit content from a PreToolUse hook on Bash). Document as known limitation.
- Catching attribution in pasted-body files we don't open — `--body-file` / `--description-file` paths we DO read and scan.
- Replacing operator vigilance — when the editor-mode case slips, the next sub-agent's reviewer-agent pass catches it.

## 3. Architecture

### 3.1 Hook Registration

Same `hooks/hooks.json` file as #16. We add a second PreToolUse-Bash entry (Claude Code merges multiple PreToolUse entries per matcher).

```json
{
    "hooks": {
        "PreToolUse": [
            {
                "matcher": "Bash",
                "hooks": [
                    { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/banned-token-leak-guard.sh" },
                    { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/no-claude-attribution.sh" }
                ]
            }
        ]
    }
}
```

Both hooks fire on every Bash call; each filters internally to its target commands.

### 3.2 Script Workflow (`hooks/no-claude-attribution.sh`)

1. **Read tool input from stdin** as JSON, extract `tool_input.command`
2. **Detect command family** — is this a `git commit`, `gh pr create`, `glab mr create`? If none → `exit 0` passthrough
3. **Config check** — `hook_enabled.no_claude_attribution: false` → `exit 0`
4. **Extract message content** based on command family:
   - `git commit -m "msg"` → quoted/heredoc-aware extraction from `-m` arg
   - `git commit -F path` → `cat $path`
   - `gh pr create --title X --body Y` → both X and Y
   - `gh pr create --body-file path` → `cat $path`
   - `glab mr create --title X --description Y` → both X and Y
   - `glab mr create --description-file path` → `cat $path`
5. **Scan message** for attribution patterns (default + config extras)
6. **On match:** print diagnostic with offending line + sanitized rewrite suggestion → `exit 2`
7. **No match:** `exit 0`

### 3.3 Default Attribution Patterns

| Pattern | Example match |
|---|---|
| `Co-Authored-By:.*Claude` | `Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>` |
| `Co-Authored-By:.*[Aa]nthropic` | `Co-Authored-By: claude@anthropic.com` |
| `🤖.*Claude Code` | `🤖 Generated with [Claude Code]` |
| `Generated with.*Claude` | `Generated with Claude` |
| `\bAI-assisted\b` | `AI-assisted refactor` |
| `\bAI-generated\b` | `AI-generated commit` |
| `noreply@anthropic\.com` | the literal email — catches Co-Authored-By variants |

All patterns OR'd into a single extended regex.

### 3.4 Sanitized Rewrite Suggestion

When a match is found, the diagnostic shows:
- The offending line(s)
- A rewritten message: remove the matching line(s) (typically the Co-Authored-By trailer and any 🤖 banner), keep the rest verbatim

The hook does NOT attempt to rewrite the message automatically; it just **suggests** what to remove.

## 4. Diagnostic Output Format

```
🚫 no-claude-attribution: commit blocked

Found Claude attribution in commit message:

  ── offending lines ──────────────────────────────────────────────
  Line 4: Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
  Line 6: 🤖 Generated with [Claude Code]
  ─────────────────────────────────────────────────────────────────

Sanitized message (remove the matching lines):

  ── suggested rewrite ────────────────────────────────────────────
  feat(#42): add user profile page

  Adds a /profile route with the user's basic info.
  ─────────────────────────────────────────────────────────────────

Operator's project canon: ZERO Claude attribution in commit messages,
MR titles, or MR bodies. Recommit with the sanitized message.
To disable globally: set `hook_enabled.no_claude_attribution: false`
in your project's .laravel-superpowers.yaml.
```

Exit 2 → commit blocked.

## 5. Error Handling / Fail-Open Behavior

Same matrix as #16:

| Scenario | Behavior |
|---|---|
| stdin empty / not JSON | `exit 0` |
| Not a `git commit` / `gh pr create` / `glab mr create` | `exit 0` |
| Hook disabled in config | `exit 0` |
| Config helper crashes | use defaults via `\|\| echo "true"` fallback |
| `-F` / `--body-file` path unreadable | print warning to stderr, scan only the inline args |
| No message extracted (e.g., `git commit` with no flags = editor mode) | `exit 0` with stderr note "editor mode not scanned; rely on reviewer agent" |
| Attribution found | `exit 2` |

## 6. Testing

Shell-level tests in `tests/test_no_claude_attribution_hook.sh`. Scenarios:

1. **Block on Co-Authored-By trailer** — `git commit -m` containing the standard trailer → exit 2
2. **Block on 🤖 banner** — `git commit -m` with `🤖 Generated with [Claude Code]` → exit 2
3. **Block on AI-assisted phrase** — `git commit -m "AI-assisted refactor"` → exit 2
4. **Block on `-F file`** — commit message in a file → exit 2 (file content scanned)
5. **Block on `gh pr create --body`** — body argument containing attribution → exit 2
6. **Block on `glab mr create --description-file`** — file content scanned → exit 2
7. **Allow clean commit** — no attribution → exit 0
8. **Allow non-commit Bash** — `git status` / `ls` → exit 0 passthrough
9. **Allow when disabled in config** — `hook_enabled.no_claude_attribution: false` → exit 0
10. **Editor-mode commit** — `git commit` with no `-m` → exit 0 with warning to stderr (known limitation)

## 7. Documentation Deliverables

- `hooks/no-claude-attribution.sh` (new)
- `hooks/hooks.json` (modified — add second entry)
- `tests/test_no_claude_attribution_hook.sh` (new)
- `README.md` (modified — append to Hooks section)
- `docs/hooks.md` (modified — insert entry, update Forthcoming)

## 8. AC Mapping

| AC from #17 | Where |
|---|---|
| Hook registered for `git commit` + `gh pr create` + `glab mr create` | §3.1 + §3.2 step 2 |
| Blocks commits/MRs with any attribution variant | §3.2 step 6 + §3.3 |
| Shows offending line + sanitized rewrite | §4 diagnostic format |
| Tested with all known patterns (trailer, banner, AI-assisted) | §6 tests 1-3 |

## 9. Out of Scope

- Editor-mode commit interception (cannot from PreToolUse Bash hook) — documented limitation
- Auto-rewriting the message — suggests only
- Server-side enforcement — Claude Code hook only
- Attribution-in-comment scanning (code comments) — that's `banned-token-leak-guard`'s territory if needed; for now we scan messages only

## 10. Open Questions for Implementation

- Should the hook intercept `git commit --amend` separately? (Defer: `--amend` re-runs the message extraction, same path)
- Should `gh pr edit` and `glab mr update` also be intercepted? (Yes — adding them to the command-family detection is trivial; include in implementation)
- Should we strip ANSI escape codes before pattern-matching? (No — patterns are plain ASCII or UTF-8 emoji; ANSI wouldn't appear in commit messages)
