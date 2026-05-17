---
name: laravel-mr-body-writer
description: "Use in Laravel projects when writing a merge-request / pull-request body at sprint close-out. Generates the canonical MR shape (Summary / Decisions / Pilot 2.0 contract / Spec + Plan link / Test plan with file paths + assertion counts / Scope changes / Deferred items / Follow-up issues / Screenshots) from the project's plan-doc, /laravel-livewire-superpowers:status output, and git history. Standardizes the 15-minute manual close-out task. Trigger on 'write MR body', 'PR description', 'sprint close-out', 'ready to merge', or before pushing a feature branch."
---

# Laravel MR Body Writer

You are generating the canonical merge-request body for a finished Laravel sprint. The output goes into the MR/PR description; reviewers depend on this structure to know what shipped.

## The canonical MR body shape

```markdown
## Summary

<1-2 paragraphs: what changed, why it matters. Lead with the user-visible outcome, not the implementation.>

## Decisions locked in brainstorm

<bullet list of the 3-5 major decisions made during brainstorming. e.g.:
- Use Spatie Permission's existing user-private channel for fan-out (no new channel)
- Component-based architecture vs trait-based (component won for testability)
- Pest 4 browser plugin instead of Dusk (already in stack)>

## Pilot 2.0 contract

- T1 Best-Practices Audit: ✓ dispatched <YYYY-MM-DD> (see `docs/superpowers/audits/<YYYY-MM-DD>-<topic>-audit.md`)
- T2 Visual Companion: ✓ offered, used for layout mockups
- T3 Per-Commit Review: ✓ all commits reviewed by `laravel-reviewer` agent
- T4 Pre-Test-Write Audit: ✓ `laravel-pest-specialist` invoked before each test file
- T5 Banned-Token Sweep: ✓ automated via pre-push hook
- T6 Deferred-Items Check: ✓ automated via pre-push hook

(Do NOT include memory-file paths — reviewers can't resolve them. Use repo paths only.)

## Spec + Plan

- Spec: [`docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`](docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md)
- Plan: [`docs/superpowers/plans/YYYY-MM-DD-<topic>.md`](docs/superpowers/plans/YYYY-MM-DD-<topic>.md)

## Test plan

- [x] `tests/Feature/<Topic>Test.php` — N assertions
- [x] `tests/Browser/<Topic>BrowserTest.php` — M scenarios
- [x] `tests/Unit/<Service>Test.php` — K cases
- [ ] Reviewer manually verifies <UX-thing>

## Scope changes from original plan

<This section is critical for review transparency. Explicit list of:
- Audit-driven simplifications (e.g., "Removed proposed `SoundShouldPlay` event after laravel-echo-reverb-specialist showed user-private channel already fans out the data")
- SUPERSEDED tasks (e.g., "Task 4.3 originally proposed Service+Repository pattern; switched to single Action class for sibling-canon consistency")
- Any deviation from the locked plan

If NO scope changes, write: `**None — implemented as planned.**`>

## Deferred items

<Either:
**None — all tasks completed.**

Or:
- Improve X — filed as #N
- Refactor Y — filed as #M

(Every deferred item MUST have an issue link. Bare bullets without `#N` will be flagged by the anti-silent-deferral hook and block the push.)>

## Follow-up issues filed during sprint

- Related to #N — <description>
- Related to #M — <description>

(GitLab keyword: `Related to #` does NOT auto-close the issue on merge. Use `Closes #` only if THIS MR resolves the linked issue completely.)

## Screenshots

<Always include for any UI change:
- Before / after pair if modifying existing UI
- Screen recording / GIF for animations or state transitions
- Mobile + desktop if responsive
- Light + dark mode if both apply>
```

## How to generate the body

### Step 1: Gather inputs

Run in parallel:

```bash
# Plan-doc
ls docs/superpowers/plans/*.md docs/plans/*.md 2>/dev/null | head -3

# Sprint state
/laravel-livewire-superpowers:status

# Commits on the branch
git log main..HEAD --format='%h %s'

# Test files touched on the branch
git diff main..HEAD --name-only -- 'tests/' | head -20

# Spec-doc
ls docs/superpowers/specs/*.md 2>/dev/null | tail -3
```

### Step 2: Extract from plan-doc

For each `## Phase N` section:
- Status (complete / in-progress / deferred)
- Tactic markers (T1/T2/T3/T4) — pull into Pilot 2.0 section
- Deferred items section (with issue links)

### Step 3: Count test assertions

For each test file in the diff:

```bash
grep -cE "(it|test|describe)\(|expect\(" tests/path/to/TestFile.php
```

For Pest browser tests, count `->visit()` calls as scenarios.

### Step 4: Identify scope changes

Compare the original plan-doc tasks vs what actually shipped (git diff). Flag:
- Tasks marked SUPERSEDED in the plan-doc
- Tasks in the plan but not in the diff (deferred without note)
- Tasks in the diff but not in the plan (scope creep)

### Step 5: Assemble + emit

Use the canonical shape above. Fill in concrete content from Steps 1-4. Output as final MR-body markdown.

## When in doubt

If the plan-doc is missing or the sprint didn't follow Pilot 2.0 explicitly, generate a SIMPLIFIED MR body:
- Summary
- What changed (bullet list from git log)
- Test plan
- Screenshots

Skip the Pilot 2.0 / Decisions / Spec sections rather than fabricating them. Note in the MR body: `(simplified shape — sprint did not follow Pilot 2.0 contract)`.

## Anti-patterns

- **Memory-file paths in MR body.** Reviewers can't resolve `~/.claude/agent-memory/...` paths. Use repo paths only.
- **Bare deferred-items without issue links.** The anti-silent-deferral hook will block the push.
- **`Closes #N` for partial fixes.** Only use `Closes` when the MR fully resolves the linked issue. Use `Related to #N` otherwise.
- **Forgetting screenshots for UI changes.** Reviewers need visual confirmation. A wall of code without an attached image is a slow review.
