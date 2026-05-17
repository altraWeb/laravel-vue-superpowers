# `anti-silent-deferral` Hook — Design Spec

**Issue:** [#19](https://github.com/altraWeb/laravel-superpowers/issues/19)
**Milestone:** V2-MVP
**Status:** Design draft
**Date:** 2026-05-15

---

## 1. Context & Motivation

Pilot 2.0 contract has anti-silent-deferral as a hard-gate Task at the END of every plan (Block 1H Task 6.4, Block 1E Task 4.4). Currently the gate is a markdown checklist step the implementer must remember to execute.

A PreToolUse hook on `git push` automates this check — blocks pushes that have uncaptured deferrals in any plan-doc's `## Phase N — Deferred Items` section. "Captured" = either explicitly empty ("None — all tasks completed as planned") OR every bullet contains a filed-issue link (`#N` format).

This is the fourth plugin hook. Differs from #16-#18 (PreToolUse on Bash → command parsing) by adding plan-doc markdown parsing.

## 2. Goals & Non-Goals

**Goals**

- Block `git push` when any plan-doc on the branch has uncaptured deferrals
- Parse `## Phase N — Deferred Items` sections (and dash-variants like `Phase N - Deferred Items`)
- Validate each section as one of:
  - **Empty marker:** a line containing `None — all tasks completed` (or close variants)
  - **Captured bullets:** each `-` bullet contains a `#N` issue link (or `gh issue #N` / `glab issue #N`)
- Block with diagnostic naming the plan-doc + phase + offending line(s)
- Suggest concrete fix command: `glab issue create --title "..." --label "deferred"`
- Honor `LARAVEL_SUPERPOWERS_ALLOW_UNCAPTURED_DEFERRAL=1` env var for emergency-push (logged)
- Honor `hook_enabled.anti_silent_deferral: false` config
- Fail-open on plugin internals failing

**Non-Goals**

- Catching deferrals already pushed to main (only blocks NEW pushes)
- Server-side pre-receive enforcement
- Auto-creating the deferred-issue (operator must run `glab issue create` themselves)
- Parsing other types of plan-doc sections (only `Deferred Items`)

## 3. Architecture

### 3.1 Hook Registration

Fourth entry under PreToolUse Bash matcher in `hooks/hooks.json`:

```json
{ "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/anti-silent-deferral.sh" }
```

### 3.2 Script Workflow (`hooks/anti-silent-deferral.sh`)

1. **Read stdin JSON**, extract `tool_input.command`
2. **Filter to `git push`** (skip `git push-origin`, `git push --help`, etc.)
3. **Skip if emergency override** — env `LARAVEL_SUPERPOWERS_ALLOW_UNCAPTURED_DEFERRAL=1` → exit 0 with stderr log
4. **Config check** — `hook_enabled.anti_silent_deferral: false` → exit 0
5. **Find branch plan-docs** — files matching `docs/plans/*.md` that changed on this branch:
   ```bash
   git diff main..HEAD --name-only -- 'docs/plans/*.md'
   ```
   If `main` doesn't exist as a ref, fall back to `git rev-parse --abbrev-ref --symbolic-full-name @{u}` for upstream. If neither exists, exit 0 (nothing to compare against).
6. **For each plan-doc**: parse `## Phase N — Deferred Items` sections via awk (see §3.3)
7. **For each section body**: validate (see §3.4). Collect any failing section.
8. **If failures**: print diagnostic + exit 2. Else exit 0.

### 3.3 Section Parsing

Plan-docs use ATX-style markdown headers. Section starts at `## Phase N — Deferred Items` (and variants), ends at the next `##` header or EOF.

Header pattern (case-sensitive, allow dash or em-dash):
```
^## Phase [0-9]+ (—|-) Deferred Items\s*$
```

Awk extracts each section's body (lines between the header and the next `##`). Empty lines stripped from start/end of body.

### 3.4 Section Validation

A section body is **captured** if AT LEAST ONE of these holds:

- **Empty-marker line present:**
  - `**None — all tasks completed as planned.**` (canonical form)
  - `None — all tasks completed`
  - `**None.**`
  - `_None._`
  - Any line containing `None` followed by `tasks completed` or `task completed` (case-insensitive)

- **All bullets carry issue refs:** every line starting with `-` (or `*`) contains one of:
  - `#[0-9]+` (GitHub/GitLab issue reference)
  - `gh issue #[0-9]+`
  - `glab issue #[0-9]+`
  - `https://github.com/.../issues/[0-9]+`
  - `https://gitlab.com/.../issues/[0-9]+`

- **Empty body** (after stripping whitespace): allowed (the section was created but truly contains nothing)

If a body has bullets WITHOUT issue refs OR free-form prose (lines not starting with `-`, `*`, `**None**`, or blank) → **uncaptured**.

### 3.5 Plan-Doc Path Override

A pull-doc can opt out of the check entirely with a marker:
```
<!-- anti-silent-deferral-skip: <reason> -->
```
anywhere in the doc. The hook skips validation for that file but logs the skip.

## 4. Diagnostic Output

```
🚫 anti-silent-deferral: push blocked

Found uncaptured deferrals in plan-docs on this branch:

  ── docs/plans/2026-05-15-block-2-cms-pages.md ────────────────
  ## Phase 4 — Deferred Items
    Line 142: - Refactor PageRevision model (too coupled to versioning)
    Line 143: - Add admin import endpoint
  ── reason ───────────────────────────────────────────────────
  Bullets do not contain filed-issue refs (#N format).

  ── docs/plans/2026-05-15-block-2-cms-pages.md ────────────────
  ## Phase 5 — Deferred Items
    Line 178: This needs to wait for the audit feedback.
  ── reason ───────────────────────────────────────────────────
  Free-form prose detected — captured deferrals must be filed issues OR explicit None.

To unblock:
  1. Either complete the deferred work and remove the section
  2. OR file each deferral as a GitLab/GitHub issue, then replace
     the prose with bulleted #N references:

     glab issue create --title "Refactor PageRevision" --label "deferred"
     # → returns issue #142

     Then replace the bullet with:
     - #142 — refactor PageRevision (deferred from Block 2 Phase 4)

  3. OR mark the section explicitly empty:

     ## Phase 4 — Deferred Items
     **None — all tasks completed as planned.**

Emergency override (logged):
  LARAVEL_SUPERPOWERS_ALLOW_UNCAPTURED_DEFERRAL=1 git push

To disable globally:
  hook_enabled:
    anti_silent_deferral: false
```

Exit 2 → push blocked.

## 5. Error Handling / Fail-Open Behavior

| Scenario | Behavior |
|---|---|
| stdin empty / not JSON | `exit 0` |
| Not `git push` | `exit 0` |
| Hook disabled | `exit 0` |
| Emergency override env var set | `exit 0` + stderr log "override active, deferrals not checked" |
| `main` ref doesn't exist | `exit 0` (can't determine branch scope) |
| `docs/plans/` directory doesn't exist | `exit 0` (no plans to check) |
| No plan-docs changed on branch | `exit 0` |
| File unreadable | `exit 0` for that file + stderr warning |
| Awk script fails | `exit 0` + stderr warning |
| Uncaptured deferrals found | `exit 2` |

## 6. Testing

Shell tests in `tests/test_anti_silent_deferral_hook.sh`. Scenarios:

1. **Block on free-form prose** — plan-doc with `## Phase 4 — Deferred Items\n\nThis needs more thought` → exit 2
2. **Block on bullets without issue refs** — `- refactor X\n- add feature Y` → exit 2
3. **Allow None marker** — `**None — all tasks completed as planned.**` → exit 0
4. **Allow captured bullets** — `- #142 — refactor X\n- gh issue #143` → exit 0
5. **Allow empty section body** — header followed by blank line then next `##` → exit 0
6. **Passthrough non-push** — `git status` → exit 0
7. **Passthrough git push --help** — exit 0
8. **Passthrough when no plan-docs changed** — branch only touches code → exit 0
9. **Emergency override** — `LARAVEL_SUPERPOWERS_ALLOW_UNCAPTURED_DEFERRAL=1` → exit 0 even with violations
10. **Plan-doc-level skip marker** — `<!-- anti-silent-deferral-skip: WIP -->` in doc → exit 0
11. **Multi-section detection** — same doc, Phase 4 captured, Phase 5 uncaptured → exit 2, only Phase 5 in output

## 7. Documentation Deliverables

- `hooks/anti-silent-deferral.sh` (new)
- `hooks/hooks.json` (modified — add fourth entry)
- `tests/test_anti_silent_deferral_hook.sh` (new)
- `README.md` (modified — append to Hooks section)
- `docs/hooks.md` (modified — insert entry, remove from Forthcoming)

## 8. AC Mapping

| AC from #19 | Where |
|---|---|
| Hook registered for `git push` | §3.1 + §3.2 step 2 |
| Scans touched `docs/plans/*.md` files | §3.2 step 5 |
| Blocks push on any uncaptured deferral | §3.4 + §3.2 step 8 |
| Output names plan-doc + phase + offending text | §4 diagnostic |
| Suggests `glab issue create` with deferred label | §4 diagnostic step 2 |
| Override flag for emergency-push (logged) | §5 + env var `LARAVEL_SUPERPOWERS_ALLOW_UNCAPTURED_DEFERRAL=1` |

## 9. Out of Scope

- Auto-creating deferred issues
- Catching deferrals already in main
- Server-side enforcement
- Other section types (only `Deferred Items`)

## 10. Open Questions for Implementation

- Should the hook block on `git push --force` separately or treat it like normal push? (Same — force-push doesn't change deferral semantics.)
- Should the emergency-override write to a log file in `~/.claude/plugins/.../overrides.log`? (Defer — stderr is sufficient for v1)
- Should `anti-silent-deferral-skip` marker require operator initials + date? (Defer — convention, hook just checks presence)
