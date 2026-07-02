# Plugin Agents — Reference

> **Stack:** Laravel + Vue 3 (Composition API) + Inertia v3 + Reka UI + Tailwind CSS 4 + Pest 4. For the Livewire 4 + Flux Pro v2 variant see the sibling plugin [`laravel-livewire-superpowers`](https://github.com/altraWeb/laravel-livewire-superpowers).

`laravel-vue-superpowers` ships specialized agents you invoke for Laravel-specific tasks. Each agent has a focused scope and runs in its own context.

## When to route to which specialist

Specialist use should be **structural, not memory-dependent**. An orchestrator should bake this mapping into its plan-execution protocol — when a task step touches a layer below, the matching specialist is dispatched as part of executing that step, not as an afterthought if someone happens to remember. Treat the "when to dispatch" column as a trigger baked into the plan, the same way a test step is.

| When the work touches… | Route to | Dispatch when the plan step… |
|---|---|---|
| Migrations, Eloquent models, queries, N+1, layering (Actions/Services) | `laravel-architect` | adds/edits `database/migrations/*` or `app/Models/*`, or decides code placement |
| Realtime, broadcasting, presence/private channels, notification fan-out | `laravel-echo-reverb-specialist` | touches `routes/channels.php`, a `ShouldBroadcast` event, or an Echo client subscription |
| Inertia pages, props, shared data, forms, partial reloads | `laravel-inertia-specialist` | edits an `Inertia::render` controller or a `useForm`/`usePage`/`<Link>` page |
| Vue 3 composition, composables, reactivity, lifecycle | `laravel-vue3-specialist` | writes/edits a `.vue` `<script setup>` or a `resources/js/composables/*` |
| Reka UI primitives (Dialog, DropdownMenu, Combobox, …) | `laravel-reka-ui-specialist` | composes/edits a component importing from `reka-ui` |
| Search, indexing, Searchable models, Meilisearch settings | `laravel-scout-meilisearch-specialist` | edits `shouldBeSearchable()`/`toSearchableArray()`, index-settings, or a `Model::search()` + its tests |
| Authorization coverage, roles, permissions, policies, gates | `spatie-permission-auditor` | changes a `*RolePermission*Seeder`, a Policy, or a route's auth gate |
| Writing or reviewing Pest tests | `laravel-pest-specialist` | is about to write/edit any test file |
| Build-vs-buy for a non-trivial feature | `laravel-package-evaluator` | asks "is there a package for X?" / "should we build or buy?" |
| "What's the current best practice for X?" | `laravel-best-practices` | needs the current, source-verified recommendation for a pattern/decision |

Every specialist verifies its findings against the installed `vendor/` or `node_modules/` source rather than docs or training data — see each agent's "Source-of-truth verification" section.

## Agents

### `laravel-best-practices`

**Use when:** asking how something should be done in current-Laravel terms — *"how should I implement X?"*, *"is approach Y still recommended in Laravel 12?"*, *"is there a Spatie package for Z?"*.

**Approach:** searches official Laravel docs + core-team blogs (Tim MacDonald, Taylor Otwell) + trusted community (Spatie, Laracasts, Laravel News), synthesizes a 2025/2026-current recommendation with code example, pitfalls, and version notes.

**Tools:** Read, Bash, WebSearch, WebFetch.

---

### `laravel-reka-ui-specialist`

**Use when:** about to write or edit a Vue component that uses Reka UI primitives (`reka-ui` package — the unstyled, accessible primitives that ship with `laravel/vue-starter-kit`). Particularly valuable when composing dialogs, dropdown menus, comboboxes, or any primitive that requires the canonical Root/Trigger/Portal/Content composition chain. Reads `node_modules/reka-ui/dist/<primitive>/` as ground truth (training data may be stale) and cites `file:line` references in every finding.

**The audit checks:**

1. **Component inventory** — finds all Vue files importing from `reka-ui`; classifies primitives in use
2. **Per-primitive composition audit** — verifies canonical Root/Trigger/Content chain; flags `asChild` on fragments; detects missing `Portal` wrapping for Dialog/Popover/DropdownMenu
3. **Tailwind 4 composition audit** — verifies `data-[state=open]:` modifiers used for state styling (not `v-if` toggling); checks animation utilities on closed state
4. **Controlled vs uncontrolled state audit** — classifies each primitive as controlled/uncontrolled; flags mixed-mode and one-way binding
5. **Accessibility-by-default verification** — flags manual `aria-*` attributes that conflict with Reka's own ARIA management; detects missing `DialogTitle`, disabled focus traps, removed keyboard handlers

**Output:** structured markdown audit report with severity classification (Blocker / Should-fix / Nice-to-have) and concrete Vue-code suggestions per finding. Every finding cites `node_modules/reka-ui/dist/<path>`.

**Tools:** Read (node_modules/reka-ui/dist/), Bash, WebFetch, WebSearch.

**Required:** `reka-ui` installed in `node_modules/`. Falls back to docs-only verification via `https://reka-ui.com/` if node_modules missing.

**Stack note:** Targets the `laravel/vue-starter-kit` default stack (Reka UI + Tailwind 4). Does not apply to projects using Headless UI, shadcn-vue without Reka, or plain Tailwind without primitives.

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

### `laravel-inertia-specialist`

**Use when:** about to write or review code that touches Inertia.js — controller `Inertia::render` calls, `useForm` / `usePage` composables, `<Link>` navigation, partial reloads, deferred props, or Inertia v3 features (`useHttp`, `usePoll`, `history.encrypt`). Particularly valuable before any form implementation (useForm vs axios anti-pattern), before adding shared data (Inertia::share overuse), and before implementing polling (setInterval vs usePoll).

**The audit checks:**

1. **Pre-flight** — detects Inertia version (v3 vs v2 compat mode) from `vendor/inertiajs/inertia-laravel/composer.json`; notes v3-only features
2. **Controller-side inventory** — classifies `Inertia::render` data-passing patterns (eager / lazy / defer / full-model leak)
3. **Form handling audit** — flags `axios.post()` / `fetch()` instead of `useForm` (HARD BAN); checks `useForm().withPrecognition()` for Precognition integration
4. **Shared data audit** — flags `Inertia::share` overuse (>4 keys, large payloads); verifies `usePage().props.x` access wrapped in `computed()`
5. **Partial reload + deferred props audit** — verifies `only:` keys match controller render; checks `<Deferred>` wrapper on Vue side
6. **Modal stack + history encryption audit** — Inertia v3 modal API; `history.encrypt` on sensitive routes
7. **Polling audit** — flags manual `setInterval(() => router.reload(), N)` instead of `usePoll(N)` (v3 canonical)

**Output:** structured markdown audit report (Blocker / Should-fix / Nice-to-have) with `file:line` citations.

**Tools:** Read, Bash, WebFetch, WebSearch.

**Required:** `vendor/inertiajs/inertia-laravel/` present. Falls back to WebFetch `https://inertiajs.com/` if vendor missing.

**Stack note:** Targets Inertia v3 by default. v2 compat-mode detected automatically from vendor version; v3-only API checks skipped in compat mode.

---

### `laravel-vue3-specialist`

**Use when:** about to write or edit a Vue 3 component using Composition API + `<script setup>` + TypeScript, or any composable in `resources/js/Composables/`. Particularly valuable before implementing reactive state (ref vs reactive choice), before adding lifecycle hooks (cleanup discipline), and before writing composables (single-responsibility, module-level state SSR-safety).

**The audit checks:**

1. **Component inventory** — classifies all Vue files by script style; flags Options API files as HARD BAN (Blocker)
2. **Reactivity audit** — detects `const { x } = reactive(...)` destructure (loses reactivity); `reactive(0)` on primitives (invalid); refs in arrays without `.value`; pre-Vue-3.5 props destructure
3. **Props + emits audit** — flags `defineProps({ x: Object })` without TS generic (HARD BAN); `defineEmits(['event'])` without TS generic (HARD BAN); `any` typed props
4. **Composable design** — `use` prefix convention; single-responsibility check; module-level `ref()` safety for SSR environments
5. **Lifecycle cleanup audit** — flags `setInterval`, `addEventListener`, WebSocket without paired `onUnmounted` cleanup (Blocker)
6. **Watch usage audit** — `watch` vs `watchEffect` choice; async `watchEffect` without `onCleanup` + AbortController

**Output:** structured markdown audit report (Blocker / Should-fix / Nice-to-have) with `file:line` citations.

**Tools:** Read, Bash, WebFetch, WebSearch.

**Required:** `node_modules/vue/` present. Falls back to heuristic checks if node_modules missing.

**Stack note:** Targets Vue 3 Composition API + `<script setup lang="ts">`. Options API is a hard ban in this plugin's canon.

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

### `laravel-echo-reverb-specialist`

Broadcasting / realtime decision support. Scans `routes/channels.php`, `app/Notifications/`, `app/Events/`, and existing Echo callbacks in `resources/js/` to identify reuse-vs-new-channel opportunities BEFORE the brainstorm proposes a redundant broadcast.

**Use when:**
- Designing any realtime feature, broadcast event, presence/private channel
- About to add a new Notification with broadcast routing
- Reviewing whether a new `Event::dispatch()` is needed or an existing channel covers it

**Stack:** Laravel + Echo + (Reverb / Pusher / Soketi). Read-only.

**Issue:** [#7](https://github.com/altraWeb/laravel-vue-superpowers/issues/7)

---

### `spatie-permission-auditor`

Gate-coverage and dead-permission audit. Cross-references seeded permissions in `RolePermissionSeeder.php` against actual `@can()` / `$user->can()` / `middleware('can:...')` / Policy usage. Catches dead permissions, gate gaps, typo'd Blade refs, per-role drift.

**Use when:**
- Reviewing a feature with role/permission gates before shipping
- Quarterly authorization-coverage sweep
- Adding new roles or permissions to validate the seeder against actual usage

**Stack:** Laravel + spatie/laravel-permission v6+ / v7+. Read-only. Runs `php artisan permission:show` if available.

**Issue:** [#9](https://github.com/altraWeb/laravel-vue-superpowers/issues/9)

---

### `laravel-package-evaluator`

Build-vs-buy decision support. Given a feature description, searches Packagist + GitHub for 2-5 candidate packages and builds a structured trade-off matrix (license, stars, last-commit, Laravel-version compat, maintenance status, docs, test coverage, vs build-yourself LOC estimate). Recommends best-fit OR justifies build.

**Use when:**
- About to add a non-trivial feature where a package might exist (file versioning, audit logging, multi-tenancy, search, billing, ...)
- "Should I use X package?" or "Is there a package for Y?"
- Want a sanity-check before committing to a long-lived dependency

**Stack:** Generic Laravel — applies to any version 10+. Heavy web research (WebFetch + WebSearch).

**Issue:** [#12](https://github.com/altraWeb/laravel-vue-superpowers/issues/12)

---

### `laravel-scout-meilisearch-specialist`

**Use when:** about to write or edit a Searchable model, its `shouldBeSearchable()` / `toSearchableArray()` / `searchableAs()`, Meilisearch index-settings, or a `Model::search(...)` query and its tests. Catches the quiet, high-cost Scout bugs that don't surface until data leaks or an index goes stale.

**The 5 audit checks:**

1. **`shouldBeSearchable()` guard-blindness** — flags a `runningUnitTests()`/env short-circuit that leaves the real index gate untested in-suite (a `--covered-only` mutation run silently skips everything past it).
2. **Gate-parity across Searchable models** — when a privacy/visibility opt-out exists, verifies EVERY Searchable model that exposes the same subject conjoins it (real catch: an opt-out kept a user's albums out of search but not their own handle document).
3. **Index-time vs query-time gate separation** — CollectionEngine-based tests exercise the query/controller layer but never route writes through `shouldBeSearchable()`; verifies both a query-layer test AND a dedicated index-gate test exist.
4. **Meilisearch index-settings correctness** — `where()`/`orderBy()` attributes must be in `filterableAttributes`/`sortableAttributes` or Meilisearch rejects the query at runtime.
5. **Post-deploy indexing hygiene** — a changed `toSearchableArray()`/index-settings/gate needs a `scout:import` (or `scout:flush`) note; newly-restricted documents linger in the index until re-indexed.

**Output:** structured markdown audit report (Blocker / Should-fix / Nice-to-have) with `file:line` citations, a gate-parity matrix, and the exact re-index commands.

**Tools:** Read, Bash, WebFetch, WebSearch.

**Required:** `laravel/scout` in composer.json + at least one Searchable model. Verifies via `vendor/laravel/scout/src/` + the project's `config/scout.php`. Meilisearch index-settings checks are N/A on other drivers.

---

_See [ROADMAP.md](ROADMAP.md) for the broader roadmap._
