# `banned-token-leak-guard` Hook Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Ship the first plugin hook — a PreToolUse Bash hook that blocks `git commit` when staged files contain banned tokens (Phase/Sprint/MR/dated refs) in code comments. First real consumer of #22 config foundation.

**Architecture:** Two new files — `hooks/hooks.json` (registration) + `hooks/banned-token-leak-guard.sh` (workflow). Reads stdin tool input, filters to `git commit`, queries config via `lib/config.py`, scans staged files, exits 2 on match. Shell-only.

**Spec:** `docs/superpowers/specs/2026-05-15-banned-token-leak-guard-hook-design.md`

---

## File Structure

| File | Purpose |
|---|---|
| `hooks/hooks.json` | Hook registration (PreToolUse Bash → script path) |
| `hooks/banned-token-leak-guard.sh` | Main hook implementation |
| `tests/test_banned_token_hook.sh` | Shell test driver — 4 scenarios |
| `README.md` | New `## Hooks` section after Agents |
| `docs/hooks.md` | New hook-reference page (analog to docs/agents.md) |

---

## Task 1: Write hook registration

- [ ] **Create `hooks/hooks.json`** with PreToolUse + Bash matcher + command handler pointing to `${CLAUDE_PLUGIN_ROOT}/hooks/banned-token-leak-guard.sh`
- [ ] **Commit:** `git commit -m "feat(#16): register banned-token-leak-guard PreToolUse hook"`

## Task 2: Write hook script

- [ ] **Create `hooks/banned-token-leak-guard.sh`** with the full workflow (read stdin, filter to git commit, query config, scan staged files, skip override markers, exit 2 on match)
- [ ] **Make executable:** `chmod +x hooks/banned-token-leak-guard.sh`
- [ ] **Verify shellcheck clean:** `shellcheck hooks/banned-token-leak-guard.sh` (if shellcheck installed; otherwise skip)
- [ ] **Commit:** `git commit -m "feat(#16): banned-token-leak-guard hook script"`

## Task 3: Write shell test driver

- [ ] **Create `tests/test_banned_token_hook.sh`** with 4 scenarios:
   - Block on Block 1H regression case (Phase 4 in docblock)
   - Allow clean commit
   - Allow override marker
   - Passthrough on non-commit Bash calls (e.g., `git status`)
- [ ] **Make executable** and run; verify all 4 pass
- [ ] **Commit:** `git commit -m "test(#16): shell test driver for banned-token-leak-guard hook"`

## Task 4: README + docs/hooks.md

- [ ] **Add `## Hooks` section to README** after Agents (announces the new hook category)
- [ ] **Create `docs/hooks.md`** with the same shape as docs/agents.md — currently lists 1 hook (`banned-token-leak-guard`), Forthcoming has the other 5 (#17-21) + auto-dispatch (#20) noted as meta
- [ ] **Commit:** `git commit -m "docs(#16): README Hooks section + docs/hooks.md reference"`

## Task 5: Push + flip PR ready

- [ ] `git push -u origin feat/16-banned-token-leak-guard-hook`
- [ ] Update PR body with test results
- [ ] `gh pr ready <PR-number>`

---

## Self-Review

Spec coverage:
- §3.1 registration → Task 1
- §3.2 script workflow → Task 2
- §3.3 default patterns → Task 2 (embedded in script as fallback when config unavailable)
- §3.4 exception paths → Task 2 (defaults + config extend)
- §3.5 override marker → Task 2 (skip lines containing `banned-token-ok:`)
- §4 diagnostic output → Task 2 (exact format from spec)
- §5 fail-open behavior → Task 2 (every `||` fallback)
- §6 testing → Task 3 (4 scenarios)
- §7 docs → Task 4
- §8 AC mapping → all covered

No placeholders. File paths consistent. Limitation: the test driver runs against a tmp git repo with mock stdin — not a real Claude Code hook invocation. End-to-end validation happens when the user commits with the plugin installed (user already does real-world tests in their actual Laravel project).
