# `laravel-pest-specialist` Agent — Design Spec

**Issue:** [#2](https://github.com/altraWeb/laravel-superpowers/issues/2)
**Milestone:** V2-MVP
**Status:** Design draft — pending review
**Author:** altraWeb + collaborator
**Date:** 2026-05-15

---

## 1. Context & Motivation

In the Block 1H + 1E sprints, four distinct Pest-4-specific stolperer surfaced that the generic `laravel-best-practices` agent missed:

1. **`toContain($needle, $message)` is variadic** — a Phase 4 implementer passed a descriptive message as the 2nd argument; Pest treated it as a second needle to find in the array. Resulted in `[]` does not contain '...' RED. Fix: use `->because('message')` modifier or drop the second arg.
2. **`->wait(N)` is a smell** — Pest 4 has a 5s implicit timeout on `assertVisible` / `assertPresent` / `assertSee`. Manual `wait(1)` adds flake risk on busy CI runners.
3. **`view()->with(['this' => new class{}])` won't work** — `$this` is reserved by PHP/Blade; the compiled template references render-context, not the test's anonymous class.
4. **`$page->script()` API availability unclear** — varies between Pest 4 versions; sibling-canon check needed before relying on it.

A generic agent catches none of these proactively. A Pest 4 specialist would catch them by construction on every test-write step.

This spec defines that agent. It is the second V2-MVP specialist agent and follows the exact pattern established by `laravel-livewire-specialist` (PR #34).

## 2. Goals & Non-Goals

**Goals**

- Audit test-write steps for the 5 most common Pest-4 stolperer-classes
- Verify Pest APIs via PHP reflection against the actual vendor source (`vendor/pestphp/pest/src/`) — not docs, not training data
- Suggest `->because('message')` modifier wherever failure messages would help
- Emit a structured markdown report (same shape as `laravel-livewire-specialist`)
- Be invokable manually or by future dispatch hooks (#20)
- Skip cleanly when the project isn't Pest-based

**Non-Goals**

- Auto-dispatch at test-write boundaries — that's #20 territory
- Refactoring existing tests — agent is read-only
- Replacing `laravel-tdd` skill — that skill teaches Pest patterns; this agent verifies API correctness on specific code
- Pest 3 / PHPUnit support — opinionated about Pest 4

## 3. Architecture

### 3.1 Single-file Agent

Same pattern as `laravel-livewire-specialist`: one Markdown file at `agents/laravel-pest-specialist.md` with YAML frontmatter + body prompt. PHP reflection inline via `php -r '...'` bash. No supporting library.

### 3.2 Frontmatter

```yaml
---
name: laravel-pest-specialist
description: "Use in Laravel+Pest projects before/during any test-write step. Audits Pest 4 API usage (catches variadic-gotchas like toContain($needle, $message)), browser-plugin smells (wait(N) abuse), view-context anti-patterns ($this in views), test-file location conventions, and it() vs arch() block correctness. Verifies via PHP reflection against vendor/pestphp/pest/ — ground truth, not docs. Trigger before any test file write/edit."
model: inherit
tools: "Read, Bash, WebFetch, WebSearch"
maxTurns: 25
color: yellow
memory: user
---
```

### 3.3 Input Contract

The caller pastes inline one of:
- A planned test snippet (PHP code)
- A path to a test file the implementer is about to write
- A free-text question like *"verify my browser test in tests/Browser/CheckoutTest.php"*

If a file path is mentioned, the agent reads it itself.

### 3.4 Pre-flight

```bash
cat composer.json 2>/dev/null | grep -E '"pestphp/pest"'
ls vendor/pestphp/pest/src/ 2>/dev/null | head -5
```

Branches:
- **Both present:** capture Pest version, continue
- **Pest not in composer.json:** `## Pre-flight: SKIPPED — not a Pest project`, stop
- **composer.json missing:** `## Pre-flight: SKIPPED — no composer.json found`, stop
- **Pest present, vendor missing:** `## Pre-flight: WARNING — vendor missing, run composer install. Falling back to docs-only verification via WebFetch.`, continue with WebFetch fallback
- **Pest version ≠ 4:** `## Pre-flight: WARNING — Pest <version> detected; this agent is tuned for Pest 4. Most checks still apply but browser-plugin and some expectations are 4+.`, continue

### 3.5 Multi-Namespace Reflection Strategy

Pest doesn't have a single `Component`-like umbrella class. The agent maps API names to their canonical Pest namespaces before reflecting:

| API surface | Canonical class to reflect |
|---|---|
| `expect()->toContain/toHaveKeys/toMatchArray/etc.` | `Pest\Expectation` |
| `->because()`, `->and()`, `->each()` modifiers | `Pest\Expectation` |
| `it()`, `test()`, `describe()`, `beforeEach()` | `Pest\PendingCall` (function-level, walk via reflection) |
| `arch()` blocks | `Pest\Arch\PendingArchExpectation` |
| Browser plugin: `visit()`, `assertVisible/Present/See`, `wait()` | `Pest\Browser\PendingBrowser` (or equivalent — verify on pre-flight) |
| `dataset()` | `Pest\Dataset` |

The agent walks `vendor/pestphp/pest/src/` to confirm class paths during pre-flight, then dispatches reflection per API call.

## 4. The Five Audit Checks

### 4.1 Variadic-API Verification

**Trigger:** input contains `toContain(`, `toHaveKeys(`, `toMatchArray(`, or any other multi-arg expectation.

**Procedure:**

1. Extract each `to<Method>(...)` call with its argument list
2. For each, run reflection to get the expected signature:

```bash
php -r 'echo (new ReflectionMethod("Pest\\Expectation", "toContain"))->getNumberOfParameters() . "\n";'
```

3. Check if it's variadic via `getParameters()[0]->isVariadic()`
4. If variadic and the user passed 2+ args, flag: "Pest treats arg #2 as a second needle, not a message — use `->because('msg')` modifier instead"
5. Emit per call: ✅ correct usage / ❌ misuse + concrete suggestion

### 4.2 Browser-Plugin Smell Scan

**Trigger:** input contains `visit(`, `assertVisible(`, `assertPresent(`, `assertSee(`, `assertText(`, `assertAttribute(`, `wait(`, or `pause(`.

**Procedure:**

1. Locate every `->wait(N)` or `->pause(N)` call
2. If preceded or followed within 5 lines by `assertVisible/Present/See/Text/Attribute` → flag as redundant (Pest 4 has 5s implicit timeout)
3. Suggested pattern: drop the `wait()`, rely on implicit timeout
4. Also check selector strategy: prefer `data-testid` over text-based or class-based selectors

### 4.3 View-Context Anti-Patterns

**Trigger:** input contains `view(` followed by `->with([` containing reserved keys.

**Procedure:**

1. Scan `view()->with([...])` and `view([...])` array keys
2. Flag reserved PHP/Blade names: `'this'`, `'loop'`, `'errors'`, `'__env'`, `'app'`, `'attributes'`, `'component'`, `'slot'`
3. Each hit: explain why it won't work (Blade compiles those to internal references) + suggest renaming

### 4.4 Test-Location Convention

**Trigger:** input mentions test file paths or `pest()->use()` / `uses()` declarations.

**Procedure:**

1. For each test file referenced, classify:
   - `tests/Unit/` — no DB, isolated logic
   - `tests/Feature/` — full app boot, HTTP layer, DB allowed
   - `tests/Architecture/` — Pest `arch()` blocks, structural assertions
   - `tests/Browser/` — Pest 4 browser plugin, real browser interaction
2. Flag mismatches: e.g., HTTP-touching test in `tests/Unit/`, DB-touching test without `uses(LazilyRefreshDatabase::class)`
3. Suggest correct directory + missing `uses()` declarations

### 4.5 it()/arch()/dataset Block Patterns

**Trigger:** input contains `it(`, `test(`, `describe(`, `arch(`, or `dataset(`.

**Procedure:**

1. For `arch()` blocks: scan body for method invocations on the asserted classes — `arch()` is structural-only, no runtime calls allowed
2. For `dataset()` usage: check if it's being used where a `foreach` inside one `it()` would obscure failures. Each dataset row = one test report entry (good for drift-guards)
3. For `it()` / `test()`: verify the description is action-oriented (`it('returns 404 when missing', ...)`) not implementation-tied
4. For `describe()` blocks: flag excessive nesting (>2 levels = consider splitting file)

## 5. Output Format

Identical structure to `laravel-livewire-specialist`:

```markdown
## Pest Specialist Audit — <scope name>

**Pest version:** <version from composer.json>
**Reflection source:** vendor/pestphp/pest/src/  (OR: docs-only fallback)

### 1. Variadic-API Verification
[per-call results or N/A]

### 2. Browser-Plugin Smell Scan
[findings or N/A]

### 3. View-Context Anti-Patterns
[findings or N/A]

### 4. Test-Location Convention
[recommendations or N/A]

### 5. it()/arch()/dataset Block Patterns
[findings or N/A]

---

## Summary

**N issues found:** X critical, Y important, Z minor.
**Block test-write until:** [list of critical blockers, or "none"]
**Other issues:** [one-line guidance]
```

### Severity

- **Critical** (RED on first run): variadic misuse, view reserved-name collision, fabricated browser-plugin API
- **Important** (silent test flake or wrong-positive): `wait(N)` smell, missing `LazilyRefreshDatabase`, `arch()` with runtime calls
- **Minor** (style + maintainability): selector strategy, description quality, describe-nesting

## 6. Error Handling

Same matrix as `laravel-livewire-specialist`:

| Situation | Behavior |
|---|---|
| No `pestphp/pest` in composer.json | `Pre-flight: SKIPPED — not a Pest project`, exit clean |
| `vendor/pestphp/` missing | `Pre-flight: WARNING — vendor missing, fallback to docs`, continue |
| Input has no Pest references | All sections N/A, summary clean |
| PHP reflection script fails | Per check, `⚠️ Verification unavailable: <error>`, don't crash audit |
| Referenced test file unreadable | `⚠️ Could not read <path>`, skip checks needing it |
| Pest version ≠ 4 | WARNING with version note, continue best-effort |

Principle: never crash, never silent-skip. Every situation gets an explicit report line.

## 7. Testing & Validation

Three smoke tests dispatched via Claude Code Task tool, outputs captured to `docs/superpowers/test-evidence/`:

1. **Canonical bug:** `audit: planning toContain($actual, 'should include foo') in test` → expect ❌ critical variadic misuse + ✅ suggested `->because('should include foo')` rewrite
2. **Clean phase:** `audit: planning expect($response->status())->toBe(200)->and($response->json())->toHaveKey('user')` → expect 0 issues, clean test
3. **Non-Pest project:** invoke from a Node.js / Rust project → expect Pre-flight: SKIPPED, no false positives

These are manual (agent is prose) but their outputs become PR evidence.

## 8. Documentation Deliverables

- `agents/laravel-pest-specialist.md` — the agent (frontmatter + body)
- `README.md` — append to existing Agents list
- `docs/agents.md` — append entry between `laravel-livewire-specialist` and "Forthcoming"; update Forthcoming list (remove #2, keep #3/#4/#5)

## 9. Acceptance Criteria Mapping

| AC from #2 | Where |
|---|---|
| Agent dispatched at every test-write step | §2 Non-goals (auto-dispatch is #20). Agent dispatchable; WHEN is separate. |
| Caches Pest 4 API surface from `vendor/pestphp/pest/` | §3.5 multi-namespace reflection |
| Documented examples: catches the 4 stolperer | §4.1-4.3 + §7 smoke tests |
| Suggests `because()` modifier where helpful | §4.1 Procedure step 4 |

## 10. Out of Scope

- Auto-dispatch → #20
- Phpunit support → never
- Auto-rewriting violating tests → never (read-only by design)
- Pest plugin authorship guidance → no issue, defer

## 11. Open Questions for Implementation Plan

- Should the agent verify dataset row counts against the function-under-test's branch coverage? (Defer: nice-to-have, not in scope)
- Should it lint `because()` message quality (not just presence)? (Defer: subjective, agent stays mechanical)
- Should it run a real `pest --filter` to confirm a test passes? (Defer: agent is read-only, doesn't execute tests)

---

*Spec ready. Next step: implementation plan via `superpowers:writing-plans`.*
