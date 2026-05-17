# `laravel-reviewer` Agent — Design Spec

**Issue:** [#5](https://github.com/altraWeb/laravel-superpowers/issues/5)
**Milestone:** V2-MVP
**Status:** Design draft
**Date:** 2026-05-15

---

## 1. Context & Motivation

The existing `laravel-code-review` skill is a checklist — useful but limited. A skill alone cannot:

- Execute `grep` / `find` to verify a claim
- Read sibling files for canon-check
- Run `php artisan route:list` to verify references
- Cite `file:line` from actual repo state

The reviewer agent wraps the existing skill (uses it as checklist scaffold) and **adds tool access** — same checks, but evidence-based not assumption-based.

This is the fifth and final V2-MVP specialist agent — after this, the agent quintet (livewire / pest / flux / architect / reviewer) is complete and V2-MVP pivots to hooks (#16-21) and skill enhancements (#13-15).

## 2. Goals & Non-Goals

**Goals**

- Wrap `laravel-code-review` skill (read its content at runtime, never duplicate)
- Add evidence-based verification — every finding cites `file:line` + sibling-canon reference where applicable
- Banned-token sweep default (per `feedback_no_sprint_labels_in_code_term_hopping`)
- Output grouped by **Blocker / Should-fix / Nice-to-have** (matching skill's grouping convention)
- **Compose, don't duplicate** — when Livewire/Flux/Pest code is in scope, agent recommends calling the existing specialist agents rather than re-implementing their checks
- Skip cleanly when project isn't Laravel

**Non-Goals**

- Auto-dispatch on commit boundaries → #20 territory
- Replacing the `laravel-code-review` skill (skill stays as-is for non-agent invocations)
- Re-implementing Livewire/Pest/Flux-specific checks already done by #1-#3 specialists
- Editing code — read-only review

## 3. Architecture

### 3.1 Single-file Agent

`agents/laravel-reviewer.md` — frontmatter + body. No supporting library.

### 3.2 Frontmatter

```yaml
---
name: laravel-reviewer
description: "Use in Laravel projects after every implementation commit, before pushing, or as a standalone evidence-based review. Wraps the laravel-code-review skill with tool access (grep/find/php artisan), reads sibling files for canon-check, runs banned-token sweep on touched paths, and recommends calling specialist agents (laravel-livewire-specialist / laravel-pest-specialist / laravel-flux-pro-specialist) when stack-specific code is in scope. Output grouped by Blocker / Should-fix / Nice-to-have with file:line citations. Trigger on any 'review', 'check', 'PR', 'done with feature', 'ready to merge' in Laravel projects."
model: inherit
tools: "Read, Bash, WebFetch, WebSearch"
maxTurns: 30
color: red
memory: user
---
```

`maxTurns: 30` (higher than #1-#4's 25) because the agent does more grep/find/Read passes — sibling-canon discovery is expensive in token-turns.

### 3.3 Input Contract

Caller pastes inline:
- A list of changed files (`git diff --name-only` output)
- A specific code snippet to audit
- A free-text request ("review my new Pages feature in PR #N")
- Optionally: explicit module composition request ("review with Livewire + Flux modules")

### 3.4 Pre-flight

```bash
cat composer.json 2>/dev/null | grep -E '"laravel/framework"' | head -1
ls skills/laravel-code-review/SKILL.md 2>/dev/null
```

Branches:
- **Both present:** capture Laravel version, read skill content via `Read`, continue
- **Laravel not in composer.json:** `Pre-flight: SKIPPED — not a Laravel project`, stop
- **composer.json missing:** `Pre-flight: SKIPPED — no composer.json found`, stop
- **Laravel present, skill file missing:** `Pre-flight: WARNING — laravel-code-review skill not found at expected path. Falling back to embedded core checklist (reduced scope).`, continue

### 3.5 Stack Detection (Step 2 of agent workflow)

After pre-flight, scan input for stack triggers:

| Trigger | Suggestion in output |
|---|---|
| `<flux:*>` or `flux:editor` in changed Blade files | "Detected Flux Pro v2 code — recommend running `laravel-flux-pro-specialist` after this review for component-level audit." |
| `wire:*`, `$this->...()`, `#[Computed]`/`#[On]`/`#[Locked]` in PHP | "Detected Livewire 4 code — recommend running `laravel-livewire-specialist` for API-existence verification." |
| `pest()`, `it(`, `test(`, `expect(`, `toContain(`, `assertSee(` in test files | "Detected Pest 4 tests — recommend running `laravel-pest-specialist` for variadic-API + browser-plugin audit." |
| Model/migration/query code | "Detected Eloquent + architecture concerns — recommend running `laravel-architect` for N+1 + sibling-canon audit." |

Critical: the reviewer does NOT re-implement those specialists' checks. It signals when they should run. The user (or future auto-dispatch hook #20) decides whether to invoke them.

## 4. Review Procedure

### 4.1 Read the laravel-code-review Skill

First action: `Read skills/laravel-code-review/SKILL.md` (or use embedded fallback if missing). Use its checklist as scaffold for every check.

### 4.2 Run each checklist section with Evidence

For every item in the skill checklist, gather evidence — never assume:

- **N+1 detection:** `grep -rn "foreach\|->each(" app/Http/ app/Services/ app/Actions/` + verify `with()` precedes
- **Mass assignment:** `grep -rn '\$fillable\|\$guarded' app/Models/` + verify each model
- **Authorization:** `grep -rn 'authorize\|->canForget' app/Http/Controllers/` + verify policy coverage
- **Route registration:** `php artisan route:list` to verify references actually exist
- **Migrations:** `Read` each migration file referenced, verify `nullable()+default()` on existing-table changes

Each finding includes:
```
**[Blocker | Should-fix | Nice-to-have]** <one-line summary>
- Where: <file>:<line>
- Evidence: <grep output OR file content excerpt>
- Project canon: <sibling reference, e.g., "5 of your existing actions use this pattern at app/Actions/Posts/PublishPost.php:1-12">
- Suggested: <concrete code fix>
```

### 4.3 Banned-Token Sweep (Default)

After core review, run on every touched file:

```bash
# Adjust touched_paths to actual scope from input
grep -nE "Phase [0-9]|Sprint [0-9]|MR !?[0-9]+|Slice [0-9]|Track [0-9]|\\b20[0-9]{2}-[0-9]{2}-[0-9]{2}\\b" $touched_paths
```

Exception paths (do NOT flag): `docs/plans/**`, `docs/superpowers/**`, `CHANGELOG.md`.

Each hit → `Should-fix` severity (code rots fast with sprint labels in comments).

### 4.4 Sibling-Canon Verification

Before flagging a pattern as wrong, agent checks sibling code:

```bash
# Example: if input proposes a Service class
ls app/Services/ 2>/dev/null
# Read 2-3 existing service classes to confirm shape
```

If project consistently uses pattern X, do NOT flag the new code's use of X as wrong even if generic best-practice would prefer Y. Cite the sibling references in the output.

### 4.5 Stack-Module Composition Suggestions

In the output's `Recommendations` section, list specialist-agent suggestions detected in Step 3.5 — never re-implement their checks.

## 5. Output Format

```markdown
## Laravel Code Review — <scope name>

**Laravel version:** <from composer.json>
**Skill source:** skills/laravel-code-review/SKILL.md (or "embedded fallback")
**Files reviewed:** <count + list>

---

## Blockers (must fix before merge)

<findings or "None">

## Should-fix (anti-patterns, fix before merge if possible)

<findings or "None">

## Nice-to-have (consistency + polish)

<findings or "None">

---

## Banned-Token Sweep

<results — N hits or "Clean">

## Specialist Recommendations

<list of specialist agents to run separately, or "None applicable">

---

## Summary

**N issues:** X blockers, Y should-fix, Z nice-to-have.
**Specialist follow-ups recommended:** <list>
**Verdict:** <ready to merge | hold for fixes | needs deeper specialist review>
```

### Severity rules (matches skill convention)

- **Blocker** (must fix): N+1 with `preventLazyLoading` enabled, missing authorization on user-data endpoint, mass assignment of `$request->all()`, broken FK, banned token in code (not docs)
- **Should-fix** (anti-pattern or production smell): missing `$fillable`, env() in app code, fat controller, banned token in comments
- **Nice-to-have** (consistency): pattern drift from sibling-canon, formatting, naming

## 6. Error Handling

| Situation | Behavior |
|---|---|
| Not a Laravel project | SKIPPED, exit |
| composer.json missing | SKIPPED, exit |
| Skill file missing | WARNING + embedded fallback |
| grep/find unavailable | Per check `⚠️ Evidence unavailable: <error>`, mark uncertain |
| Referenced file unreadable | `⚠️ Could not read <path>`, skip checks needing it |

## 7. Testing

Three smoke tests captured in `docs/superpowers/test-evidence/`:

1. **Canonical scenario:** changed files include a controller with `foreach ($posts as $post) { $post->user->name }` AND a `<flux:tooltip>` wrapper AND banned `Phase 3` comment → expect Blocker (N+1) + Should-fix (banned token) + Specialist recommendation (laravel-flux-pro-specialist + laravel-livewire-specialist for related concerns)
2. **Clean PR:** changed file uses proper eager-loading + authorize() + no banned tokens → expect 0 issues + ready-to-merge verdict
3. **Non-Laravel project:** node.js review request → expect Pre-flight SKIPPED, no false positives

## 8. Documentation Deliverables

- `agents/laravel-reviewer.md`
- `README.md` — append to Agents list
- `docs/agents.md` — insert entry; remove #5 from Forthcoming (= empty Forthcoming list, end of V2-MVP agent quintet)

## 9. AC Mapping

| AC from #5 | Where |
|---|---|
| Agent dispatched after implementation commit (auto-dispatch is #20) | §2 Non-goals: agent dispatchable; WHEN is separate |
| Output groups: Blocker / Should-fix / Nice-to-have | §5 output format |
| Every finding cites file:line + sibling-canon ref | §4.2 finding template |
| Banned-token sweep default on touched paths | §4.3 |
| Sub-checklists composable | §4.5 — composes via specialist-agent recommendations, not re-implementation |

## 10. Out of Scope

- Auto-dispatch → #20
- Specialist-agent auto-invocation (reviewer suggests; caller invokes) → would require nested-agent dispatch which has limits
- Embedded duplicate of Livewire/Pest/Flux/architect checks → compose via specialist recommendations instead
- Editing code → read-only by design

## 11. Open Questions for Implementation

- Should the agent auto-invoke specialist agents when their triggers are detected? (Defer: nested-agent dispatch has known issues per `project_agentic_workflows_research`. Caller invokes specialists themselves based on the reviewer's recommendation.)
- Should banned-token sweep be configurable via #22 config foundation? (Yes — `banned_tokens.project_extras` from config.yaml gets appended to the default list. Already covered by config schema.)
- Should the reviewer cache the skill content across invocations? (Defer: stateless reads are cheap; recheck per invocation.)
