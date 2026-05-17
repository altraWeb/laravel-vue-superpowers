# Plugin Agents — Reference

> **Stack:** Laravel + Livewire 4 + Flux Pro v2 + Pest 4. For the Vue 3 + Inertia v2 variant see the planned sibling plugin [`laravel-vue-superpowers`](https://github.com/altraWeb/laravel-vue-superpowers).

`laravel-livewire-superpowers` ships specialized agents you invoke for Laravel-specific tasks. Each agent has a focused scope and runs in its own context.

## Agents

### `laravel-best-practices`

**Use when:** asking how something should be done in current-Laravel terms — *"how should I implement X?"*, *"is approach Y still recommended in Laravel 12?"*, *"is there a Spatie package for Z?"*.

**Approach:** searches official Laravel docs + core-team blogs (Tim MacDonald, Taylor Otwell) + trusted community (Spatie, Laracasts, Laravel News), synthesizes a 2025/2026-current recommendation with code example, pitfalls, and version notes.

**Tools:** Read, Bash, WebSearch, WebFetch.

---

### `laravel-livewire-specialist`

**Use when:** auditing a plan-phase or code snippet that touches Livewire 4 components, blade templates with `wire:*` directives, or Echo/broadcasting integration. Particularly valuable before implementation when a plan mentions a `$this->...()` method — the agent verifies API existence via reflection against the vendor source, catching fabricated methods (like the `$this->hasLoading()` case from Block 1H Phase 5) before they ship.

**The 5 audit checks:**

1. **API verification** — PHP reflection on `Livewire\Component` (catches fabricated methods like `$this->hasLoading()`)
2. **`wire:ignore` zone scan** — finds descendants with `wire:*` directives inside ignored subtrees (silent reactivity failure)
3. **Form-Object pattern recommendation** — picks between `Livewire\Form` / property+`rules()` / Spatie LaravelData based on use-case shape
4. **Echo / broadcasting morphing-race detection** — flags callbacks that mutate DOM directly before Livewire's next morph
5. **Lifecycle hook usage** — verifies hook names and flags common mistakes (`updated()` without filtering, `mount()` doing work that belongs in `hydrate()`, etc.)

**Output:** structured markdown audit report with severity classification (critical / important / minor) and concrete suggestions per finding.

**Tools:** Read, Bash, WebFetch, WebSearch.

**Required:** PHP 8+ in PATH (for reflection invocation). Falls back to docs-only verification via WebFetch if `vendor/livewire/` is missing.

**Smoke-test evidence:** See [`superpowers/test-evidence/2026-05-15-livewire-specialist-smoke-*.md`](superpowers/test-evidence/) for captured outputs covering the canonical bug, a clean phase, and a non-Livewire fail-clean case.

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

**Smoke-test evidence:** See [`superpowers/test-evidence/2026-05-15-pest-specialist-smoke-*.md`](superpowers/test-evidence/) for captured outputs covering the variadic-misuse catch, a clean expectation chain, and a non-Pest fail-clean case.

---

### `laravel-flux-pro-specialist`

**Use when:** about to write or edit a Blade template that uses Flux Pro v2 components (`<flux:*>`). Particularly valuable when wrapping Flux components in tooltips, building toolbars, or composing dropdowns/menus/popovers. Reads `vendor/livewire/flux-pro/stubs/resources/views/flux/` as ground truth (docs sometimes lag) and cites vendor `file:line` references in every finding.

**The 5 audit checks:**

1. **`<flux:with-tooltip>` Self-Wrap Detection** — flags double-wrap when an outer `<flux:tooltip>` wraps a component that already self-tooltips (`<flux:button>`, `<flux:icon-button>`, `<flux:editor.button>`, etc.). Double-wrap breaks `<ui-toolbar>` roving-tabindex — silent a11y regression.
2. **Position/Align Convention Scan** — flags compound `position="bottom end"` syntax in favor of project-canon separate props `position="bottom" align="end"`.
3. **`<flux:editor.spacer/>` Semantics** — verifies spacer placement inside toolbar containers (renders `flex-1`, only meaningful in flex contexts).
4. **`wire:ignore` Zone Reactive-Descendant Detection** — catches Livewire-reactive attrs (`wire:click`, `wire:model`, etc.) on Flux components inside `wire:ignore` zones. Suggests Alpine `x-on:click="$wire.foo()"` bridge.
5. **Slot Composition vs String-Prop Trade-off** — flags string `toolbar="..."` prop usage when slot form is needed (3+ items, dynamic content, event handlers, `<flux:editor.spacer/>`).

**Output:** structured markdown audit report with severity classification + concrete Blade-code suggestions per finding. Every finding cites `vendor/livewire/flux-pro/stubs/resources/views/flux/<path>:<line>`.

**Tools:** Read (vendor Blade files), Bash, WebFetch, WebSearch.

**Required:** Flux Pro installed in vendor/. Falls back to docs-only verification via `https://fluxui.dev/docs/` if vendor missing.

**Smoke-test evidence:** See [`superpowers/test-evidence/2026-05-15-flux-pro-specialist-smoke-*.md`](superpowers/test-evidence/) for captured outputs covering the double-wrap catch (Block 1H Phase 1 canonical bug), a clean dropdown with separate position+align, and a non-Flux fail-clean case.

---

### `laravel-architect`

**Use when:** about to write code that touches Eloquent models, migrations, queries, or architectural placement (Actions vs Services vs Form Objects vs Controllers). Structurally different from the specialist agents above — instead of reflecting on third-party vendor source, this agent reads the **user's own codebase** (`app/Actions/`, `app/Services/`, `app/Http/Requests/`, `app/Data/`) and recommends consistency with what's already in the project (sibling-canon) over generic best practices.

**The 5 audit checks:**

1. **Eloquent N+1 Detection** — extracts `foreach`/`->each()` blocks, identifies relationship-access without eager-loading, recommends exact `with()`/`withCount()`/`loadMissing()` rewrite + Pest QueryCount test stub. Surfaces `preventLazyLoading` status from `AppServiceProvider`.
2. **Architecture Pattern Sibling-Canon Check** — recommends Actions vs Services vs FormRequests based on existing dominant pattern in the project, citing 2-3 specific files. Explicitly flags **Repository pattern as anti-pattern** in Laravel apps + flags fat controllers.
3. **Migration Discipline** — `nullable() + default()` on new columns to existing tables, `constrained() + onDelete()` on FKs, no `migrate:fresh` assumptions in production.
4. **Performance** — uncached expensive computed values, `count()` vs `exists()`, memory-bound iteration (`chunk`/`lazy`), `Cache::flexible()` SWR pattern (Laravel 11+).
5. **API Design** — `JsonResource` recommendation, pagination strategy (`paginate`/`simplePaginate`/`cursorPaginate`) based on scale, API versioning sibling-canon match.

**Output:** structured markdown audit report with severity classification + concrete code (action class skeletons, query rewrites, Pest test stubs). Project profile in header lists detected architectural patterns + `preventLazyLoading` status.

**Tools:** Read (scans `app/` directories), Bash (read-only `php artisan` commands like `model:show`, `route:list`), WebFetch, WebSearch.

**Required:** Laravel 11+ project with `app/` directory. Falls back to generic recommendations if `app/` missing.

**Smoke-test evidence:** See [`superpowers/test-evidence/2026-05-15-architect-smoke-*.md`](superpowers/test-evidence/) for captured outputs covering the N+1 catch (controller foreach), Repository anti-pattern flag with concrete alternatives, and non-Laravel (Spring Boot) fail-clean case.

---

### `laravel-reviewer`

**Use when:** completing a feature, reviewing code, or preparing for merge in a Laravel project. Wraps the existing `laravel-code-review` skill (reads it at runtime as checklist scaffold) and adds tool-based evidence verification (grep, find, Read, `php artisan` read-only commands). Every finding cites `file:line`. **Composes specialist agents** — when Livewire/Flux/Pest/architectural code is in scope, recommends calling the corresponding specialist agent rather than re-implementing their checks.

**The 6-step workflow:**

1. **Pre-flight** — confirms Laravel project, reads the `laravel-code-review` skill content (or falls back to embedded checklist if missing).
2. **Stack Detection** — scans input for `<flux:*>` / `wire:*` / Pest / Eloquent triggers and records specialist recommendations.
3. **Core Review with Evidence** — walks the skill's checklist, runs grep/find/`php artisan route:list`/Read for each check; every finding is grounded in actual repo state.
4. **Banned-Token Sweep** (default) — greps touched files for `Phase N`, `Sprint N`, `MR !N`, dated refs, etc. Exception paths: `docs/plans/**`, `docs/superpowers/**`, `CHANGELOG.md`.
5. **Sibling-Canon Verification** — before flagging a pattern as wrong, checks if the project consistently uses it (defers to project convention over generic best-practice).
6. **Output** — grouped by **Blocker / Should-fix / Nice-to-have** (matches skill convention, distinct from critical/important/minor of #1-#4), with Specialist Recommendations + Verdict.

**Output:** structured markdown audit report. Every finding includes Where (`file:line`), Evidence (grep output or file excerpt), Project canon reference, and concrete suggested fix.

**Tools:** Read, Bash (grep/find/`php artisan`), WebFetch, WebSearch.

**Required:** Laravel project. Falls back to embedded checklist if `skills/laravel-code-review/SKILL.md` is missing.

**Composability:** when stack-specific code is detected, the reviewer recommends running the corresponding specialist agent — never re-implements their checks. This keeps the reviewer thin and lets specialists own their depth.

**Smoke-test evidence:** See [`superpowers/test-evidence/2026-05-15-reviewer-smoke-*.md`](superpowers/test-evidence/) for captured outputs covering a multi-issue PR (3 blockers + 4 should-fix + 4 specialist recommendations), a clean PR (0 issues, ready to merge), and a non-Laravel (Node.js Express) fail-clean case.

---

### `laravel-echo-reverb-specialist`

Broadcasting / realtime decision support. Scans `routes/channels.php`, `app/Notifications/`, `app/Events/`, and existing Echo callbacks in `resources/js/` to identify reuse-vs-new-channel opportunities BEFORE the brainstorm proposes a redundant broadcast.

**Use when:**
- Designing any realtime feature, broadcast event, presence/private channel
- About to add a new Notification with broadcast routing
- Reviewing whether a new `Event::dispatch()` is needed or an existing channel covers it

**Stack:** Laravel + Echo + (Reverb / Pusher / Soketi). Read-only.

**Issue:** [#7](https://github.com/altraWeb/laravel-livewire-superpowers/issues/7)

---

### `spatie-permission-auditor`

Gate-coverage and dead-permission audit. Cross-references seeded permissions in `RolePermissionSeeder.php` against actual `@can()` / `$user->can()` / `middleware('can:...')` / Policy usage. Catches dead permissions, gate gaps, typo'd Blade refs, per-role drift.

**Use when:**
- Reviewing a feature with role/permission gates before shipping
- Quarterly authorization-coverage sweep
- Adding new roles or permissions to validate the seeder against actual usage

**Stack:** Laravel + spatie/laravel-permission v6+ / v7+. Read-only. Runs `php artisan permission:show` if available.

**Issue:** [#9](https://github.com/altraWeb/laravel-livewire-superpowers/issues/9)

---

### `laravel-package-evaluator`

Build-vs-buy decision support. Given a feature description, searches Packagist + GitHub for 2-5 candidate packages and builds a structured trade-off matrix (license, stars, last-commit, Laravel-version compat, maintenance status, docs, test coverage, vs build-yourself LOC estimate). Recommends best-fit OR justifies build.

**Use when:**
- About to add a non-trivial feature where a package might exist (file versioning, audit logging, multi-tenancy, search, billing, ...)
- "Should I use X package?" or "Is there a package for Y?"
- Want a sanity-check before committing to a long-lived dependency

**Stack:** Generic Laravel — applies to any version 10+. Heavy web research (WebFetch + WebSearch).

**Issue:** [#12](https://github.com/altraWeb/laravel-livewire-superpowers/issues/12)

---

---

## `laravel-pilot-orchestrator`

**Use when:** starting a new phase, before requesting code review, or when you suspect Pilot 2.0 contract drift. Produces a structured per-phase Tactic status report (T1-T4) and recommends next steps.

**Trigger on:** `pilot status`, `pilot orchestrator`, `check pilot`, `contract status`, or anytime you need a Pilot 2.0 compliance snapshot.

**Contract reference:** `docs/pilot-2-0-contract.md` — reads this file first for the canonical T1-T6 definition.

**Workflow:**
1. Pre-flight — confirms git repo + contract doc presence
2. Detects active plan-doc from branch name (`docs/superpowers/plans/<topic>.md`)
3. Parses all `## Phase N` Tactic Tracking sections → per-phase T1/T2/T3/T4 matrix
4. Detects uncommitted obligations (open commits without T3 evidence, test files without T4 evidence)
5. Emits structured markdown report with open obligations + concrete next steps
6. Optionally dispatches `laravel-reviewer` (T3) or `laravel-pest-specialist` (T4) — always asks before dispatching

**T5 + T6 (automated hooks):** not surfaced unless they failed — enforced continuously by `banned-token-leak-guard` and `anti-silent-deferral`.

**Tools:** Read, Bash.

**UNBOUND behavior:** if the plan-doc has no Tactic Tracking sections, emits `## Pilot 2.0 Status: UNBOUND` with instructions to bind via `docs/pilot-2-0-contract.md`.

---

_**V3 Phase E agents shipped.** See [ROADMAP.md](ROADMAP.md) for the broader V3 roadmap._
