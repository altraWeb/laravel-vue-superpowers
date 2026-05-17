# `laravel-pest-specialist` Agent Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the `laravel-pest-specialist` audit agent that catches Pest-4-specific stolperer (variadic gotchas, browser-plugin smells, view anti-patterns, location mismatches, block-pattern mistakes) by reflecting against the actual Pest vendor source.

**Architecture:** Single Markdown file (`agents/laravel-pest-specialist.md`) with YAML frontmatter + 5-section audit workflow body. Multi-namespace PHP reflection inline via `php -r '...'` Bash calls. Mirrors the `laravel-livewire-specialist` pattern.

**Tech Stack:** Markdown (agent prompt), Bash (PHP reflection invocation), PHP 8+ (reflection runtime), Claude Code Task tool (for smoke-test dispatch).

**Spec reference:** `docs/superpowers/specs/2026-05-15-pest-specialist-agent-design.md`

---

## File Structure

| File | Purpose |
|---|---|
| `agents/laravel-pest-specialist.md` | The agent (frontmatter + 5-section workflow prompt) |
| `README.md` | Append to existing Agents list |
| `docs/agents.md` | Insert entry; update Forthcoming list (remove #2) |

---

## Task 1: Write the agent file

**Files:**
- Create: `agents/laravel-pest-specialist.md`

- [ ] **Step 1: Write the file with frontmatter + body**

```markdown
---
name: laravel-pest-specialist
description: "Use in Laravel+Pest projects before/during any test-write step. Audits Pest 4 API usage (catches variadic-gotchas like toContain($needle, $message)), browser-plugin smells (wait(N) abuse), view-context anti-patterns ($this in views), test-file location conventions, and it() vs arch() block correctness. Verifies via PHP reflection against vendor/pestphp/pest/ — ground truth, not docs. Trigger before any test file write/edit."
model: inherit
tools: "Read, Bash, WebFetch, WebSearch"
maxTurns: 25
color: yellow
memory: user
---

You are the Laravel Pest Specialist Agent. Your job: audit a planned test snippet, file write, or audit-input for the 5 most common Pest-4 stolperer-classes. You verify APIs via PHP reflection against the actual vendor source — never trust docs, never guess from training data.

You do not edit code. You emit a structured markdown report with severity-classified findings.

---

## Step 1: Pre-flight

```bash
cat composer.json 2>/dev/null | grep -E '"pestphp/pest"'
ls vendor/pestphp/pest/src/ 2>/dev/null | head -5
```

Branch on results:

- **Both present:** capture Pest version, continue to Step 2
- **Pest not in composer.json:** emit `## Pre-flight: SKIPPED — not a Pest project`, then stop
- **composer.json missing entirely:** emit `## Pre-flight: SKIPPED — no composer.json found, cannot confirm Pest project`, then stop
- **Pest present but vendor missing:** emit `## Pre-flight: WARNING — vendor/ missing, run \`composer install\`. Falling back to docs-only verification via WebFetch.`, continue with WebFetch fallback for API checks (use `https://pestphp.com/docs/...`)
- **Pest version ≠ 4:** emit `## Pre-flight: WARNING — Pest <version> detected; this agent is tuned for Pest 4. Most checks still apply but browser-plugin and some expectations are 4+. Reading vendor regardless.`, continue

### Multi-namespace mapping

Pest spreads APIs across several classes. During pre-flight, confirm these exist in `vendor/pestphp/pest/src/`:

| API surface | Canonical class |
|---|---|
| `expect()->to...` / `->because()` / `->and()` | `Pest\Expectation` |
| `it()` / `test()` / `describe()` / `beforeEach()` | function-level (walk via `Pest\PendingCall` or equivalent) |
| `arch()` blocks | `Pest\Arch\PendingArchExpectation` |
| Browser: `visit()` / `assertVisible/Present/See` / `wait()` | `Pest\Browser\PendingBrowser` (verify exact namespace on pre-flight) |
| `dataset()` | `Pest\Dataset` |

If a class path differs in the installed Pest version, note it in the pre-flight section and use the actual path for reflection.

---

## Step 2: The Five Audit Checks

Each check runs only if the input contains triggers. When absent, emit `N/A — no [...] references in scope`.

### 2.1 Variadic-API Verification

**Trigger:** input contains `toContain(`, `toHaveKeys(`, `toMatchArray(`, `toHaveProperty(`, or other multi-arg expectations.

**Procedure:**

1. Extract each `to<Method>(...)` call and its argument list from input
2. Run reflection to get parameter info:

```bash
php -r '
$m = new ReflectionMethod("Pest\\Expectation", "toContain");
echo "params=" . $m->getNumberOfParameters() . " ";
echo "variadic=" . ($m->getParameters()[0]->isVariadic() ? "yes" : "no");
'
```

3. If the method is variadic AND the user passed 2+ args, flag: "Pest treats arg #2 as a second needle, not a failure message — use `->because('msg')` modifier instead"
4. If reflection unavailable: WebFetch `https://pestphp.com/docs/expectations` and match the documented signature
5. Emit per call:
   - `✅ \`->toContain('foo')\` — correct usage`
   - `❌ \`->toContain('foo', 'should include foo')\` — **VARIADIC MISUSE**`
     - Reflection: `Pest\Expectation::toContain` is variadic, both args treated as needles
     - Suggested: `->toContain('foo')->because('should include foo')`

### 2.2 Browser-Plugin Smell Scan

**Trigger:** input contains `visit(`, `assertVisible(`, `assertPresent(`, `assertSee(`, `assertText(`, `assertAttribute(`, `wait(`, `pause(`.

**Procedure:**

1. Locate every `->wait(N)` or `->pause(N)` call
2. Check 5-line window before/after for `assertVisible/Present/See/Text/Attribute`
3. If found within window → flag: "Pest 4 has a 5s implicit timeout on assertions — manual wait adds flake risk"
4. Suggested: remove `->wait(N)`, rely on implicit timeout
5. Selector strategy: scan for raw text selectors (`assertSee('Login')`) and class selectors (`->click('.btn-primary')`). Prefer `data-testid`:
   - `❌ \`->assertSee('Login')\`` — suggest test-id approach with i18n bridge
   - `✅ \`->assertVisible('@login-btn')\`` (Pest 4 `@` prefix = data-testid)

### 2.3 View-Context Anti-Patterns

**Trigger:** input contains `view(` followed by `->with([` containing array.

**Procedure:**

1. Scan all `view()->with([...])` and `view([...])` call array keys
2. Reserved Blade/PHP names that won't work:
   - `'this'`, `'loop'`, `'errors'`, `'__env'`, `'app'`, `'attributes'`, `'component'`, `'slot'`
3. Each hit: explain why (Blade compiles these to internal references, not your value) + suggest renaming
   - `❌ \`view()->with(['this' => $obj])\`` — \`$this\` in compiled view = render context, not your value
   - Suggested: rename key (e.g., `'subject' => $obj`) and access as `$subject` in the view

### 2.4 Test-Location Convention

**Trigger:** input mentions paths like `tests/Unit/`, `tests/Feature/`, `tests/Browser/`, `tests/Architecture/`, or `uses(...)` / `pest()->use(...)` declarations.

**Procedure:**

1. For each referenced path, classify expected content:
   - `tests/Unit/` — no DB, no HTTP, isolated logic
   - `tests/Feature/` — full app boot, HTTP + DB allowed
   - `tests/Architecture/` — Pest `arch()` blocks only
   - `tests/Browser/` — Pest 4 browser plugin
2. Flag mismatches by content type:
   - HTTP call in `tests/Unit/` → suggest `tests/Feature/`
   - DB query without `uses(LazilyRefreshDatabase::class)` in DB-touching test → suggest adding it
   - Browser test outside `tests/Browser/` → suggest moving

### 2.5 it()/arch()/dataset Block Patterns

**Trigger:** input contains `it(`, `test(`, `describe(`, `arch(`, or `dataset(`.

**Procedure:**

1. For `arch()` blocks: scan body for method invocations on the asserted classes (`$class->method()` patterns) — arch() is structural-only
   - `⚠️ \`arch()\` block at line N calls method \`$class->method()\` — arch is structural only, use `it()` for runtime assertions`
2. For `dataset()` vs `foreach` inside one `it()`: when checking many rows, `dataset()` gives one report entry per row (better for drift-guards); `foreach` obscures which row failed
   - Suggest dataset for drift-guard patterns
3. For `it()` / `test()` descriptions: prefer action-oriented (`it('returns 404 when missing')`) over implementation-tied (`it('tests UserController::show')`)
4. For `describe()` blocks: >2 levels of nesting = consider splitting file

---

## Step 3: Suggested-Alternative Strategy

For each ❌ or ⚠️ finding, the Suggested line must be **concrete code**, never generic advice.

Examples:
- ❌ `toContain('a', 'b')` variadic misuse → suggest `->toContain('a')->because('b')`
- ⚠️ `->wait(1)` before `assertVisible` → suggest dropping `wait()`
- ❌ `view()->with(['this' => $obj])` → suggest `view()->with(['subject' => $obj])` with view access via `$subject`
- ⚠️ HTTP call in `tests/Unit/` → suggest moving to `tests/Feature/`
- ⚠️ `arch()` block with `->method()` call → suggest splitting: keep structural assertions in arch(), move runtime to `it()`

If no canonical alternative exists, state: `Suggested: no canonical alternative — recommend opening a question to the Pest 4 docs or community`.

---

## Step 4: Output Format

Emit ONE markdown report:

```markdown
## Pest Specialist Audit — <scope name from caller>

**Pest version:** <from composer.json>
**Reflection source:** vendor/pestphp/pest/src/  (OR: docs-only fallback)

### 1. Variadic-API Verification
<results or N/A>

### 2. Browser-Plugin Smell Scan
<findings or N/A>

### 3. View-Context Anti-Patterns
<findings or N/A>

### 4. Test-Location Convention
<recommendations or N/A>

### 5. it()/arch()/dataset Block Patterns
<findings or N/A>

---

## Summary

**N issues found:** X critical, Y important, Z minor.
**Block test-write until:** <list of critical blockers, or "none">
**Other issues:** <one-line guidance>
```

### Severity rules

- **Critical** (RED on first run): variadic misuse, view reserved-name collision, fabricated browser API
- **Important** (silent flake / wrong-positive): `wait(N)` smell, missing `LazilyRefreshDatabase`, `arch()` with runtime calls
- **Minor** (style + maintainability): selector strategy, description quality, describe-nesting

---

## Important Behaviors

**Never edit code.** Read-only audit. Emit suggestions, never patches.

**Always verify before declaring.** Pest method existence + signature must come from reflection. If reflection unavailable, label findings "verified via docs, not reflection".

**Be concrete in suggestions.** Show the rewritten code, not "use the right approach".

**Run all 5 checks every time** (or explicit N/A). Consistent report shape.

**Flag uncertainty.** If a check produces ambiguous results, mark `⚠️` not `✅`.
```

- [ ] **Step 2: Verify file structure**

```bash
head -10 agents/laravel-pest-specialist.md
wc -l agents/laravel-pest-specialist.md
```

Expected: valid YAML frontmatter, ~200 lines total.

- [ ] **Step 3: Commit**

```bash
git add agents/laravel-pest-specialist.md
git commit -m "feat(#2): add laravel-pest-specialist agent"
```

---

## Task 2: Smoke Test 1 — Canonical bug (`toContain` variadic)

**Files:**
- Create: `docs/superpowers/test-evidence/2026-05-15-pest-specialist-smoke-1.md`

- [ ] **Step 1: Dispatch the agent via Task tool**

Use Agent tool, `general-purpose` subagent, `sonnet` model:

```
You are the Laravel Pest Specialist Agent — your instructions are the body of `/Users/altrano/dev/laravel-superpowers/agents/laravel-pest-specialist.md` (everything BELOW the closing `---` of the frontmatter).

Read that file and act as that agent.

DO NOT add any Co-Authored-By line or AI attribution if you happen to commit anything.

---

Audit input:
"audit: planning expect($response->json('items'))->toContain('foo', 'response should include foo')"

Working directory: /Users/altrano/dev/laravel-superpowers (no composer.json — pre-flight will SKIP, but surface the variadic misuse as informational critical from plan text).

Return ONLY the markdown report.
```

- [ ] **Step 2: Capture output and verify**

Expected: Pre-flight SKIPPED + informational critical finding for the variadic misuse + concrete `->because()` rewrite.

- [ ] **Step 3: Save evidence**

```bash
cat > docs/superpowers/test-evidence/2026-05-15-pest-specialist-smoke-1.md <<'EOF'
# Smoke Test 1 — Canonical bug (toContain variadic)

**Date:** 2026-05-15
**Dispatcher:** Claude Code Task tool, general-purpose, sonnet

## Input
audit: planning expect($response->json('items'))->toContain('foo', 'response should include foo')

## Environment
Working directory: /Users/altrano/dev/laravel-superpowers (not a Pest project, no composer.json).

## Captured output

<paste full subagent output here>

## Verdict
PASS / FAIL with notes
EOF
```

- [ ] **Step 4: Commit**

```bash
git add docs/superpowers/test-evidence/2026-05-15-pest-specialist-smoke-1.md
git commit -m "test(#2): smoke test 1 — toContain variadic misuse"
```

---

## Task 3: Smoke Test 2 — Clean test (`expect()->toBe + ->and + ->toHaveKey`)

**Files:**
- Create: `docs/superpowers/test-evidence/2026-05-15-pest-specialist-smoke-2.md`

- [ ] **Step 1: Dispatch with clean test input**

```
[Same agent-as-system-prompt setup as Task 2 Step 1]

Audit input:
"audit: planning expect($response->status())->toBe(200)->and($response->json())->toHaveKey('user')"

Working directory: /Users/altrano/dev/laravel-superpowers (no composer.json — pre-flight will SKIP).

Return ONLY the markdown report.
```

- [ ] **Step 2: Capture output and verify**

Expected: Pre-flight SKIPPED + informational note that the planned expectations use single-arg variadic methods + chained `->and()` correctly. 0 issues.

- [ ] **Step 3: Save evidence**

```bash
cat > docs/superpowers/test-evidence/2026-05-15-pest-specialist-smoke-2.md <<'EOF'
# Smoke Test 2 — Clean test chain (toBe + and + toHaveKey)

[full evidence as in Task 2 Step 3, with captured output]
EOF
```

- [ ] **Step 4: Commit**

```bash
git add docs/superpowers/test-evidence/2026-05-15-pest-specialist-smoke-2.md
git commit -m "test(#2): smoke test 2 — clean expectation chain"
```

---

## Task 4: Smoke Test 3 — Non-Pest project (Python/pytest context)

**Files:**
- Create: `docs/superpowers/test-evidence/2026-05-15-pest-specialist-smoke-3.md`

- [ ] **Step 1: Dispatch with non-Pest input**

```
[Same agent-as-system-prompt setup]

Audit input:
"audit: I'm writing a pytest test for my Django app. Check for issues."

Working directory: /tmp (no composer.json, not a Pest project at all).

Return ONLY the markdown report.
```

- [ ] **Step 2: Capture output and verify**

Expected: clean SKIP, all 5 sections N/A, no false positives, summary explicitly states no jurisdiction.

- [ ] **Step 3: Save evidence**

```bash
cat > docs/superpowers/test-evidence/2026-05-15-pest-specialist-smoke-3.md <<'EOF'
# Smoke Test 3 — Non-Pest project (Python/pytest)

[full evidence]
EOF
```

- [ ] **Step 4: Commit**

```bash
git add docs/superpowers/test-evidence/2026-05-15-pest-specialist-smoke-3.md
git commit -m "test(#2): smoke test 3 — non-Pest project (clean SKIP)"
```

---

## Task 5: Update README Agents section

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Read current Agents section**

```bash
grep -n -A 5 "^## Agents" README.md
```

- [ ] **Step 2: Append new entry**

Add this line after the `laravel-livewire-specialist` entry, before the link to docs/agents.md:

```markdown
- **laravel-pest-specialist** — Audits Pest 4 tests for variadic-API misuse (`toContain($needle, $message)` gotcha), browser-plugin smells (`wait(N)` abuse), view-context anti-patterns, test-location mismatches, and `it()`/`arch()`/dataset block correctness. Verifies via PHP reflection against the actual Pest vendor source. Use before any test write/edit.
```

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs(#2): README lists laravel-pest-specialist agent"
```

---

## Task 6: Update docs/agents.md

**Files:**
- Modify: `docs/agents.md`

- [ ] **Step 1: Insert new agent entry between `laravel-livewire-specialist` and "Forthcoming"**

Use Edit tool to insert this block (find the line `## Forthcoming (V2-MVP)` and add before it):

```markdown
---

### `laravel-pest-specialist`

**Use when:** about to write or edit a Pest 4 test, especially when the test will use multi-arg expectations like `toContain`, browser plugin APIs, view rendering, or `arch()` structural assertions. Catches Pest 4 stolperer that would either RED on first run (variadic misuse) or silently produce wrong-positives (`->wait(1)` before assertions that already have implicit timeout, reserved-name view keys, runtime calls inside `arch()` blocks).

**The 5 audit checks:**

1. **Variadic-API Verification** — reflects on `Pest\Expectation` to flag misuse like `toContain($needle, $message)` where Pest treats both args as needles. Suggests `->because('msg')` modifier.
2. **Browser-Plugin Smell Scan** — flags `->wait(N)` before assertions (5s implicit timeout already), recommends `data-testid` selectors over text/class.
3. **View-Context Anti-Patterns** — catches reserved-name keys in `view()->with([...])` (`'this'`, `'loop'`, `'errors'`, etc.).
4. **Test-Location Convention** — flags content/location mismatches (HTTP in Unit, DB without `LazilyRefreshDatabase`, browser tests outside `tests/Browser/`).
5. **it()/arch()/dataset Block Patterns** — flags runtime calls inside `arch()` blocks (structural-only), suggests `dataset()` for drift-guards.

**Output:** structured markdown audit report with severity classification (critical / important / minor) and concrete suggestions per finding.

**Tools:** Read, Bash, WebFetch, WebSearch.

**Required:** PHP 8+ in PATH. Falls back to docs-only verification if `vendor/pestphp/` is missing.
```

- [ ] **Step 2: Update Forthcoming list (remove #2 line)**

In the same file, find the Forthcoming list and remove the `laravel-pest-specialist` line. Result:

```markdown
## Forthcoming (V2-MVP)

- `laravel-flux-pro-specialist` ([#3](https://github.com/altraWeb/laravel-superpowers/issues/3)) — Flux Pro v2 vendor source + slot composition
- `laravel-architect` ([#4](https://github.com/altraWeb/laravel-superpowers/issues/4)) — Eloquent + architecture decisions (N+1, eager-loading, Actions vs Services)
- `laravel-reviewer` ([#5](https://github.com/altraWeb/laravel-superpowers/issues/5)) — wraps `laravel-code-review` skill with grep/find/MCP integration
```

- [ ] **Step 3: Commit**

```bash
git add docs/agents.md
git commit -m "docs(#2): docs/agents.md entry for laravel-pest-specialist + update Forthcoming"
```

---

## Task 7: Final review + flip PR to ready

- [ ] **Step 1: Verification suite**

```bash
git status
git log --oneline main..HEAD
wc -l agents/laravel-pest-specialist.md
grep -c "laravel-pest-specialist" README.md docs/agents.md
ls docs/superpowers/test-evidence/ | grep pest-specialist
```

Expected: clean tree, 7+ commits (spec + plan + agent + 3 smoke tests + README + docs/agents.md), agent ~180-200 lines, both docs reference pest-specialist, 3 smoke evidence files.

- [ ] **Step 2: Push**

```bash
git push
```

- [ ] **Step 3: Flip PR to ready + update body**

```bash
gh pr ready <PR-number>
gh pr edit <PR-number> --title "feat(#2): laravel-pest-specialist agent" --body "[updated body with smoke test summary table]"
```

The PR body template mirrors PR #34 — summary table of 3 smoke tests with PASS/FAIL + links to evidence files.

---

## Self-Review Notes

**Spec coverage:**
- §3.2 Frontmatter → Task 1
- §3.4-3.5 Pre-flight + multi-namespace → Task 1 (agent body)
- §4.1-4.5 Five checks → Task 1 (agent body)
- §5 Output Format → Task 1 (agent body)
- §6 Error Handling → Task 1 + Tasks 2-4 smoke tests verify
- §7 Three smoke tests → Tasks 2, 3, 4
- §8 Documentation → Tasks 5, 6
- §9 AC mapping → all covered
- §11 Open questions → deferred with reasoning

**Placeholder scan:** none — every step has concrete content. The agent body in Task 1 is the full prompt, ready to paste.

**Type consistency:**
- Agent path consistent: `agents/laravel-pest-specialist.md`
- Smoke evidence dir: `docs/superpowers/test-evidence/`
- Test names: pest-specialist-smoke-1/2/3

**Known limitation:** smoke tests run in the laravel-superpowers repo (no Pest vendor), so reflection isn't exercised end-to-end. Same constraint as #1 — validates prompt structure + judgment.

---

## Execution Handoff

Inline execution recommended (same as #1) — prose-heavy content, smoke tests are Task-tool dispatches regardless of top-level executor.
