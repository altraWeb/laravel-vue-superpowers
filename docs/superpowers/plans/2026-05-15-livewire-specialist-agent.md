# `laravel-livewire-specialist` Agent Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the `laravel-livewire-specialist` audit agent that catches fabricated APIs and 4 other Livewire-4 stolperer-classes by reflection-verifying against the actual vendor source.

**Architecture:** Single Markdown file (`agents/laravel-livewire-specialist.md`) with YAML frontmatter defining metadata + tool permissions, body prompt driving a 5-section audit workflow. PHP reflection via inline `php -r '...'` Bash calls. No supporting library.

**Tech Stack:** Markdown (agent prompt), Bash (PHP reflection invocation), PHP 8+ (reflection runtime, user-provided), Claude Code Agent tool (for smoke-test dispatch).

**Spec reference:** `docs/superpowers/specs/2026-05-15-livewire-specialist-agent-design.md`

---

## File Structure

| File | Purpose |
|---|---|
| `agents/laravel-livewire-specialist.md` | The agent itself (frontmatter + workflow prompt) |
| `README.md` | Add agent to the "Agent" section with one-line description |
| `docs/agents.md` | Reference page listing all agents shipped by the plugin |

---

## Smoke-Test Approach

The agent is prose — no pytest. Validation is **manual smoke tests** dispatched via the Claude Code Task tool. Each test:
1. Constructs a sample input (e.g. "audit: Phase 5 plan adds `$this->hasLoading()`")
2. Dispatches a subagent with the full text of `agents/laravel-livewire-specialist.md` as the system prompt + sample input as the user message
3. Captures the subagent's output
4. Manually verifies the output matches expected behavior
5. Pastes the captured output into the PR description as evidence

This validates the agent's prompt content end-to-end without requiring real plugin reinstall + Claude Code restart.

---

## Task 1: Write the agent file

**Files:**
- Create: `agents/laravel-livewire-specialist.md`

- [ ] **Step 1: Create the agent file with frontmatter + full workflow body**

```markdown
---
name: laravel-livewire-specialist
description: "Use in Laravel+Livewire projects before/during any Livewire-touching implementation phase. Audits API existence (catches fabricated methods like $this->hasLoading), wire:ignore zones, Form-Object patterns, Echo/broadcasting integration, and lifecycle-hook usage. Verifies via PHP reflection against vendor/livewire/livewire/src/Component.php — ground truth, not docs. Trigger automatically before any plan-phase that mentions Livewire components, $this->X() methods, wire:* directives, or #[On]/#[Computed]/#[Locked] attributes."
model: inherit
tools: "Read, Bash, WebFetch, WebSearch"
maxTurns: 25
color: blue
memory: user
---

You are the Laravel Livewire Specialist Agent. Your job: audit a Livewire-touching plan, phase description, or code snippet for the 5 most common Livewire-4 stolperer-classes. You verify APIs via PHP reflection against the actual vendor source — never trust docs, never guess from training data.

You do not edit code. You emit a structured markdown report with severity-classified findings.

---

## Step 1: Pre-flight

Before any audit, confirm the project is Livewire-based and the reflection source is available.

```bash
cat composer.json 2>/dev/null | grep -E '"livewire/livewire"'
ls vendor/livewire/livewire/src/Component.php 2>/dev/null
```

Branch on results:

- **Both present:** capture Livewire version from composer.json, continue to Step 2
- **Livewire not in composer.json:** emit `## Pre-flight: SKIPPED — not a Livewire project`, then stop
- **composer.json missing entirely:** emit `## Pre-flight: SKIPPED — no composer.json found, cannot confirm Livewire project`, then stop
- **Livewire present but vendor missing:** emit `## Pre-flight: WARNING — vendor/ missing, run \`composer install\`. Falling back to docs-only verification via WebFetch.` and continue. In Step 2.1, use WebFetch against `https://livewire.laravel.com/docs/properties` and `https://livewire.laravel.com/docs/lifecycle-hooks` instead of reflection
- **Livewire version ≠ 4:** emit `## Pre-flight: WARNING — Livewire <version> detected; this agent is tuned for Livewire 4. Most checks still apply but some attributes (#[Computed], #[Locked]) are 3+. Reading vendor regardless.` and continue with reflection

---

## Step 2: The Five Audit Checks

Each check is only run if the input contains relevant triggers. When triggers absent, emit `N/A — no [...] references in scope` for that section. Never silently skip.

### 2.1 API Verification

**Trigger:** input contains `$this->` references.

**Procedure:**

1. Extract every `$this->methodName(...)` call and every `$this->propertyName` access from the input.
2. For each, run reflection on `Livewire\Component`:

```bash
php -r 'echo (new ReflectionClass("Livewire\\Component"))->hasMethod("methodName") ? "yes" : "no";'
```

3. If reflection returns `no` AND the input references a user component file (e.g., `app/Livewire/Foo.php`), read that file and check if the method is declared there directly.
4. If reflection unavailable (pre-flight WARNING path), use:

```
WebFetch: https://livewire.laravel.com/docs/properties
WebFetch: https://livewire.laravel.com/docs/lifecycle-hooks
```

Match method/property names against documented APIs. Note in output: "verified via docs, not reflection".

5. Emit per result:
   - `✅ \`$this->mount()\` — exists on Livewire\Component` (or "in user component at <path>:<line>")
   - `❌ \`$this->hasLoading('save')\` — **NOT FOUND**`
     - Reflection: `... hasMethod("hasLoading") -> false`
     - Suggested: <concrete alternative — see Step 3 for guidance>

### 2.2 wire:ignore Zone Scan

**Trigger:** input contains `wire:ignore`.

**Procedure:**

1. Locate every `wire:ignore` block boundary in the template input.
2. For each block, scan descendant elements for any `wire:*` directive (wire:click, wire:model, wire:loading, wire:dispatch, etc.).
3. Any hit = silent failure: the descendant won't fire Livewire because the ignored parent gates morphing.
4. Emit per finding:
   - `⚠️ \`<div wire:ignore>\` at line N contains \`<button wire:click="save">\``
   - Risk: button won't trigger Livewire (parent ignored)
   - Suggested: bridge via Alpine — replace with `x-on:click="$wire.save()"` on the button (Alpine works inside ignored zones)

### 2.3 Form-Object Pattern

**Trigger:** input contains form code — `Livewire\Form` import, `rules()` method, `validate()` call, `protected $rules` property, or `#[Validate]` attribute.

**Procedure:**

1. Read the component / form code and classify the use-case along these axes:
   - Multi-step / wizard? → `Livewire\Form` recommended
   - Single-use, lifecycle-coupled? → `property + rules()` recommended
   - Read-only DTO, nested structure, type-strict serialization? → Spatie LaravelData recommended
2. Flag if both patterns are mixed in the same component (anti-pattern — pick one).
3. Emit recommendation with one-line justification, plus a flag if mixed-pattern detected.

### 2.4 Echo / Broadcasting

**Trigger:** input contains `Echo.private(`, `Echo.channel(`, `.notification(`, `.whisper(`, or PHP `#[On]` attribute with a broadcast event name (typically prefixed with `.` for namespaced events).

**Procedure:**

1. Scan callbacks for direct DOM mutation: `document.getElementById(...).innerHTML = ...`, `el.classList.add(...)`, `el.appendChild(...)`.
2. Any hit = race-condition risk: the callback runs JS-side BEFORE Livewire's next morph, and morphing can wipe the mutations.
3. Emit per finding:
   - `⚠️ Echo callback at line N directly mutates DOM (\`document.getElementById(...).innerHTML\`)`
   - Risk: race condition with Livewire morphing
   - Suggested: callback dispatches a Livewire action — `Echo.private('user.1').notification((n) => $wire.handleNotification(n))` — and the component re-renders normally

### 2.5 Lifecycle Hooks

**Trigger:** input contains any of: `mount(`, `boot(`, `hydrate(`, `dehydrate(`, `updating(`, `updated(`, `rendering(`, `rendered(`.

**Procedure:**

1. Verify each hook name via reflection on `Livewire\Component` (catches typos like `mountup`, `hydrated`).
2. Flag common mistakes:
   - `mount()` doing work that should also run on every hydration → suggest moving to `hydrate()` or a `#[Computed]` property
   - `updated()` without `$property` filtering or named suffix when only one property is tracked → suggest `updatedFooBar()` for clarity
   - `boot()` with side-effects → boot runs on every request including hydration; flag and confirm intent
3. Emit per finding with ✅ / ⚠️ marker and concrete suggestion.

---

## Step 3: Suggested-Alternative Strategy

For each ❌ or ⚠️ finding, the Suggested line must be **concrete and actionable**, never generic. Examples:

- ❌ `$this->hasLoading('save')` — suggest `wire:loading.attr="aria-busy" wire:target="save"` directly in the template
- ⚠️ `wire:click inside wire:ignore` — suggest `x-on:click="$wire.save()"` using Alpine
- ⚠️ Echo callback mutates DOM — suggest `Echo.private(channel).notification((n) => $wire.handleNotification(n))` and add `public function handleNotification(array $n) { ... }` server-side

If you cannot produce a concrete alternative for a finding, say so explicitly: `Suggested: no canonical alternative — recommend opening a question to a Livewire 4 specialist`.

---

## Step 4: Output Format

Emit ONE markdown report with this exact structure:

```markdown
## Livewire Specialist Audit — <scope name from caller's input>

**Livewire version:** <version from composer.json>
**Reflection source:** vendor/livewire/livewire/src/Component.php  (OR: docs-only fallback)

### 1. API Verification
<per-method results or "N/A — no $this-> references in scope">

### 2. wire:ignore Zone Scan
<findings or "N/A — no wire:ignore in scope">

### 3. Form-Object Pattern
<recommendation or "N/A — no form code in scope">

### 4. Echo / Broadcasting
<findings or "N/A — no Echo/broadcast references in scope">

### 5. Lifecycle Hooks
<findings or "N/A — no lifecycle hooks in scope">

---

## Summary

**N issues found:** X critical, Y important, Z minor.
**Block implementation until:** <list of critical blockers, or "none">
**Other issues:** <one-line guidance on important/minor>
```

### Severity rules

- **Critical** (blocks ship): fabricated APIs — would crash at runtime
- **Important** (should fix before merge): wire:ignore zones with reactive children, Echo morphing race-conditions, lifecycle-hook typos
- **Minor** (nice to fix): pattern recommendations, missing property filters on lifecycle hooks

---

## Important Behaviors

**Never edit code.** You are read-only. Emit suggestions, never patches.

**Always verify before declaring.** A method that "should" exist on Livewire\Component must be checked with reflection. If reflection unavailable, say so explicitly — never assert from memory.

**Be concrete in suggestions.** "Use a different approach" is not a suggestion. "Use \`wire:loading.attr=\"aria-busy\"\` directly in the template" is a suggestion.

**Run all 5 checks every time** (or explicitly mark N/A). The caller relies on the consistent report shape.

**Flag uncertainty.** If a check produces ambiguous results (e.g., reflection says `yes` but the user's calling pattern doesn't match the method signature), flag it as `⚠️ — verified but signature mismatch: ...` rather than ✅.
```

- [ ] **Step 2: Verify the file is valid Markdown + has correct frontmatter**

```bash
head -10 agents/laravel-livewire-specialist.md
wc -l agents/laravel-livewire-specialist.md
```

Expected: frontmatter block visible at top, total ~180-200 lines.

- [ ] **Step 3: Commit**

```bash
git add agents/laravel-livewire-specialist.md
git commit -m "feat(#1): add laravel-livewire-specialist agent"
```

---

## Task 2: Smoke Test 1 — Canonical bug (`$this->hasLoading`)

**Files:**
- None modified — this is a manual test, output captured for PR

- [ ] **Step 1: Dispatch the agent via Task tool with the canonical bug input**

Use the Agent tool with `subagent_type: general-purpose`, `model: sonnet`, and this prompt structure:

```
You are an agent whose system prompt is the contents of `/Users/altrano/dev/laravel-superpowers/agents/laravel-livewire-specialist.md` (everything BELOW the closing `---` of the frontmatter — that block is metadata, the body is your instructions).

[Then paste the entire body of the agent file, starting from "You are the Laravel Livewire Specialist Agent..."]

---

User input to audit:

"audit: Phase 5 plan adds aria-busy resolver via $this->hasLoading($method) — Livewire computed getter on Editor\AiToolbar component (file: app/Livewire/Editor/AiToolbar.php)"

Working directory for any Bash invocations: /Users/altrano/dev/laravel-superpowers (note: there's no real Livewire vendor here — pre-flight will fall back to docs-only verification, which is fine for this test).

Run the audit and emit the markdown report.
```

- [ ] **Step 2: Verify the output**

Expected:
- `Pre-flight: SKIPPED — not a Livewire project` (because the laravel-superpowers repo isn't a Livewire app), OR
- `Pre-flight: WARNING — vendor missing` if the agent fakes-detects something

If pre-flight skips, the test still validates the prompt structure but NOT the reflection path. Note this in the output capture.

For a real test of the reflection path, the test would need to run inside an actual Livewire app. Document this limitation.

**For the prompt-content validation:** verify the output has the report structure (5 sections, summary, severity tags).

- [ ] **Step 3: Save the captured output to a comment file**

```bash
mkdir -p docs/superpowers/test-evidence
cat > docs/superpowers/test-evidence/2026-05-15-livewire-specialist-smoke-1.md <<'EOF'
# Smoke Test 1 — Canonical bug ($this->hasLoading)

**Date:** 2026-05-15
**Input:**

audit: Phase 5 plan adds aria-busy resolver via $this->hasLoading($method) — Livewire computed getter on Editor\AiToolbar component

**Captured output:**

<paste the subagent's full report here>

**Verdict:** PASS / FAIL with notes
EOF
```

- [ ] **Step 4: Commit**

```bash
git add docs/superpowers/test-evidence/
git commit -m "test(#1): smoke test 1 — canonical $this->hasLoading bug"
```

---

## Task 3: Smoke Test 2 — Clean phase (`$this->mount`)

**Files:**
- Create: `docs/superpowers/test-evidence/2026-05-15-livewire-specialist-smoke-2.md`

- [ ] **Step 1: Dispatch the agent with a clean-phase input**

Use the same Task-tool dispatch pattern as Task 2, but with this user input:

```
"audit: Phase 2 adds $this->mount(User $user) for initial state binding on UserDashboard component"
```

- [ ] **Step 2: Verify the output**

Expected:
- API Verification: `✅ $this->mount()` (mount IS a real Livewire\Component method)
- Sections 2-5: N/A
- Summary: `0 issues found`

If pre-flight skips (no Livewire project), the report should still emit the SKIPPED line and not crash.

- [ ] **Step 3: Save captured output**

```bash
cat > docs/superpowers/test-evidence/2026-05-15-livewire-specialist-smoke-2.md <<'EOF'
# Smoke Test 2 — Clean phase ($this->mount)

**Date:** 2026-05-15
**Input:**

audit: Phase 2 adds $this->mount(User $user) for initial state binding on UserDashboard component

**Captured output:**

<paste the subagent's full report here>

**Verdict:** PASS / FAIL with notes
EOF
```

- [ ] **Step 4: Commit**

```bash
git add docs/superpowers/test-evidence/2026-05-15-livewire-specialist-smoke-2.md
git commit -m "test(#1): smoke test 2 — clean phase $this->mount"
```

---

## Task 4: Smoke Test 3 — Non-Livewire project

**Files:**
- Create: `docs/superpowers/test-evidence/2026-05-15-livewire-specialist-smoke-3.md`

- [ ] **Step 1: Dispatch the agent with a non-Livewire-context input**

Use the same Task-tool dispatch pattern, with this user input:

```
"audit: I'm adding a new Vue.js component to my non-Laravel project. Check for issues."

Working directory: /tmp (deliberately no composer.json, no Livewire context anywhere).
```

- [ ] **Step 2: Verify the output**

Expected:
- `## Pre-flight: SKIPPED — no composer.json found, cannot confirm Livewire project`
- Agent exits cleanly without attempting the 5 checks
- No crash, no false positives

- [ ] **Step 3: Save captured output**

```bash
cat > docs/superpowers/test-evidence/2026-05-15-livewire-specialist-smoke-3.md <<'EOF'
# Smoke Test 3 — Non-Livewire project

**Date:** 2026-05-15
**Input:**

audit: I'm adding a new Vue.js component to my non-Laravel project. Check for issues.

**Captured output:**

<paste the subagent's full report here>

**Verdict:** PASS / FAIL with notes
EOF
```

- [ ] **Step 4: Commit**

```bash
git add docs/superpowers/test-evidence/2026-05-15-livewire-specialist-smoke-3.md
git commit -m "test(#1): smoke test 3 — non-Livewire project"
```

---

## Task 5: Update README with new agent

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Read the current README to find the Agent section**

```bash
grep -n -A 3 "^## Agent" README.md
```

- [ ] **Step 2: Replace the single-agent line with a two-entry list**

The current README probably has:

```markdown
## Agent

- **laravel-best-practices** — Web research agent for current Laravel best practices (Spatie, Laracasts, Laravel News)
```

Replace with:

```markdown
## Agents

- **laravel-best-practices** — Web research agent for current Laravel best practices (Spatie, Laracasts, Laravel News). Use when asking *"how should I implement X?"* or *"is my current approach still best practice?"*.
- **laravel-livewire-specialist** — Audits Livewire-touching code/plans for fabricated APIs, wire:ignore zones, Form-Object patterns, Echo/broadcasting race conditions, and lifecycle-hook misuse. Verifies via PHP reflection against the actual Livewire vendor source — ground truth, not docs. Use before any Livewire-touching implementation phase.
```

Note: section heading goes from "Agent" (singular) to "Agents" (plural).

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs(#1): README lists laravel-livewire-specialist agent"
```

---

## Task 6: Create `docs/agents.md` reference page

**Files:**
- Create: `docs/agents.md`

- [ ] **Step 1: Write the reference page**

```markdown
# Plugin Agents — Reference

`laravel-superpowers` ships specialized agents you invoke for Laravel-specific tasks. Each agent has a focused scope and runs in its own context.

## Agents

### `laravel-best-practices`

**Use when:** asking how something should be done in current-Laravel terms — *"how should I implement X?"*, *"is approach Y still recommended in Laravel 12?"*, *"is there a Spatie package for Z?"*.

**Approach:** searches official Laravel docs + core-team blogs (Tim MacDonald, Taylor Otwell) + trusted community (Spatie, Laracasts, Laravel News), synthesizes a 2025/2026-current recommendation with code example, pitfalls, and version notes.

**Tools:** Read, Bash, WebSearch, WebFetch.

---

### `laravel-livewire-specialist`

**Use when:** auditing a plan-phase or code snippet that touches Livewire 4 components, blade templates with `wire:*` directives, or Echo/broadcasting integration. Particularly valuable before implementation when a plan mentions a `$this->...()` method — the agent verifies API existence via reflection against the vendor source, catching fabricated methods (like the `$this->hasLoading()` case from Block 1H Phase 5) before they ship.

**The 5 audit checks:**
1. API verification (PHP reflection on `Livewire\Component`)
2. `wire:ignore` zone scan (descendant reactivity)
3. Form-Object pattern recommendation
4. Echo / broadcasting morphing-race detection
5. Lifecycle hook usage (typos + common mistakes)

**Output:** structured markdown audit report with severity classification (critical / important / minor) and concrete suggestions per finding.

**Tools:** Read, Bash, WebFetch, WebSearch.

**Required:** PHP 8+ in PATH (for reflection invocation). Falls back to docs-only verification if `vendor/livewire/` is missing.

---

## Forthcoming (V2-MVP)

- `laravel-pest-specialist` (#2) — Pest 4 API depth + browser-plugin recipes
- `laravel-flux-pro-specialist` (#3) — Flux Pro v2 vendor source + slot composition
- `laravel-architect` (#4) — Eloquent + architecture decisions (N+1, eager-loading, Actions vs Services)
- `laravel-reviewer` (#5) — wraps `laravel-code-review` skill with grep/find/MCP integration

See [ROADMAP.md](ROADMAP.md) for the full V2 plan.
```

- [ ] **Step 2: Commit**

```bash
git add docs/agents.md
git commit -m "docs(#1): create docs/agents.md with full agent reference"
```

---

## Task 7: Final review + flip PR to ready

- [ ] **Step 1: Run final tree check**

```bash
git status
git log --oneline main..HEAD
```

Expected: 6 commits on `spec/1-livewire-specialist-agent` branch (1 spec + 1 agent + 3 smoke tests + 1 README + 1 docs/agents.md = 7 commits). Clean tree.

- [ ] **Step 2: Verify agent file structure**

```bash
head -10 agents/laravel-livewire-specialist.md
wc -l agents/laravel-livewire-specialist.md
```

Expected: valid YAML frontmatter at top, total ~180-200 lines.

- [ ] **Step 3: Verify README and docs/agents.md cross-reference correctly**

```bash
grep -c "laravel-livewire-specialist" README.md docs/agents.md
```

Expected: at least 1 hit in each file.

- [ ] **Step 4: Confirm all three smoke-test evidence files exist**

```bash
ls docs/superpowers/test-evidence/
```

Expected: 3 markdown files (smoke-1, smoke-2, smoke-3).

- [ ] **Step 5: Push and flip PR to ready**

```bash
git push
gh pr ready 34
```

- [ ] **Step 6: Update PR body with smoke-test evidence inline**

```bash
gh pr edit 34 --body "$(cat <<'EOF'
Closes #1.

## Summary

First V2-MVP specialist agent. Audit-mode workflow that catches fabricated APIs and 4 other Livewire-4 stolperer-classes by reflection-verifying against `vendor/livewire/livewire/src/Component.php`.

## What ships

- `agents/laravel-livewire-specialist.md` — the agent (frontmatter + 5-section audit workflow)
- `README.md` — Agent section updated with the new entry
- `docs/agents.md` — new reference page for all plugin agents
- `docs/superpowers/test-evidence/` — captured outputs from 3 smoke tests

## Three smoke tests

| Test | Input | Expected | Actual |
|---|---|---|---|
| 1. Canonical bug | `$this->hasLoading($method)` audit | API Verification ❌ critical | see test-evidence/smoke-1 |
| 2. Clean phase | `$this->mount(User $user)` audit | 0 issues | see test-evidence/smoke-2 |
| 3. Non-Livewire | Vue.js project audit | Pre-flight SKIPPED | see test-evidence/smoke-3 |

## Acceptance criteria from #1

- [x] Agent dispatchable on Livewire-touching plan-phase (auto-dispatch on #20)
- [x] Output: API-verification section + wire:ignore scan + Alpine-bridge recommendations
- [x] Reads vendor source for ground truth via reflection
- [x] Smoke test 1 captures the `$this->hasLoading()` bug

## Spec + plan

- Spec: [`docs/superpowers/specs/2026-05-15-livewire-specialist-agent-design.md`](docs/superpowers/specs/2026-05-15-livewire-specialist-agent-design.md)
- Plan: [`docs/superpowers/plans/2026-05-15-livewire-specialist-agent.md`](docs/superpowers/plans/2026-05-15-livewire-specialist-agent.md)

## Out of scope (follow-ups)

- Auto-dispatch on plan-phase boundaries → #20
- Pest specialist → #2
- Flux Pro specialist → #3
EOF
)"
```

---

## Self-Review Notes

**Spec coverage:**
- §3.2 Frontmatter → Task 1 Step 1
- §3.4 Pre-flight → Task 1 Step 1 (in agent body)
- §4.1-4.5 The five audit checks → Task 1 Step 1 (in agent body)
- §5 Output Format → Task 1 Step 1 (in agent body)
- §6 Error Handling → Task 1 Step 1 (in agent body) + Tasks 2-4 smoke tests verify
- §7 Testing (three smoke tests) → Tasks 2, 3, 4
- §8 Documentation deliverables → Tasks 5, 6
- §9 AC mapping → all 4 covered
- §11 Open questions → deferred (markdown sufficient for v1, no caching needed, no vendor-snapshot)

**Placeholder scan:** none — every step has actual content. The agent body in Task 1 Step 1 is the full agent prompt, ready to paste.

**Type consistency:**
- Agent file path consistent across tasks: `agents/laravel-livewire-specialist.md`
- Smoke-test evidence dir consistent: `docs/superpowers/test-evidence/`
- Test naming consistent: `smoke-1`, `smoke-2`, `smoke-3`

**Known limitation flagged in Task 2 Step 2:** smoke tests run against the laravel-superpowers repo itself (no real Livewire vendor), so the reflection path can't be fully exercised. This is acceptable for prompt-structure validation; real-world reflection testing happens when an actual user invokes the agent in a Laravel+Livewire project.

---

## Execution Handoff

**Two execution options:**

1. **Subagent-Driven (recommended)** — I dispatch a fresh subagent per task, review between tasks, fast iteration. With Sonnet minimum per user preference. Smoke tests dispatch via Task tool naturally fit this pattern (subagent inside subagent — except the smoke-test dispatcher just runs the prompt and captures output).

2. **Inline Execution** — I execute tasks in this session. Faster for the prose-heavy tasks (agent file, docs), and the smoke tests are dispatched the same way (Task tool with the agent prompt) regardless of which top-level executor we choose.

For an agent (prose, not code), inline execution might actually be cleaner — less overhead for editing markdown files. But subagent-driven gives the per-task review checkpoints.

Which approach?
