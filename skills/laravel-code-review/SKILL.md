---
name: laravel-code-review
description: "Use in Laravel projects when completing a feature, reviewing code, or preparing for merge. Checks Laravel-specific concerns: N+1 queries, mass assignment protection, authorization coverage, validation completeness, security, performance. In Laravel codebases, invoke this alongside superpowers:requesting-code-review. Trigger on any 'review', 'check', 'PR', 'done with feature', 'ready to merge' in a Laravel project."
---

# Laravel Code Review

## Purpose

Catch Laravel-specific issues before they reach production. Run this **after** the generic `superpowers:requesting-code-review` flow, or as a standalone review for Laravel-specific concerns.

## Review Checklist

Work through each section. For every `[ ]` item, check the actual code — don't assume.

---

### 1. Database & Eloquent

**N+1 Queries**
```bash
# Check for relationship access inside loops
grep -rn "foreach\|->each(" app/Http/ app/Services/ app/Actions/
# Then verify: is `with()` used before the loop?
```

- [ ] All `hasMany`/`belongsToMany` relationships loaded inside loops use eager loading (`with()`)
- [ ] `$collection->count()` called on already-loaded collection (OK), not `->count()` (fires query) — distinguish `$user->posts->count()` from `$user->posts()->count()`
- [ ] `->exists()` or `->doesntExist()` used instead of counting for existence checks

**Mass Assignment**
- [ ] Every model that is mass-assigned has `$fillable` defined (prefer) or `$guarded = []` (intentional)
- [ ] `$request->all()` is NOT used for `create()`/`fill()` — use `$request->validated()` or `$request->only([...])`
- [ ] New columns in migrations are reflected in the model's `$fillable`

**Migrations**
- [ ] New migration does not break existing data (nullable or has default if column is added to existing table)
- [ ] Foreign keys have `constrained()` and appropriate `onDelete` behavior
- [ ] No `php artisan migrate:fresh` assumption in production migrations

**Queries**
- [ ] No `Model::all()` without pagination or explicit small-dataset justification
- [ ] `env()` is NOT called in application code — only `config()` (env() bypasses config cache)

---

### 2. Authorization

- [ ] Every controller method or route that accesses user-specific data calls `authorize()` or uses a Policy
- [ ] Policies cover both the "allowed" case and the "forbidden" case (tested in Pest)
- [ ] `authorize()` is called before querying the database (fail fast)
- [ ] Routes that should be guest-only are protected by `guest` middleware
- [ ] Routes that require auth have `auth` middleware (not just relying on `authorize()` inside)

```bash
# Check for missing authorization
grep -rn "public function " app/Http/Controllers/ | grep -v "__construct\|middleware"
# For each method, verify it calls $this->authorize() or has a policy
```

---

### 3. Validation

- [ ] All user input is validated before use
- [ ] Form Requests used for complex validation (not inline `$request->validate()` if reused)
- [ ] Validation covers ALL fields (check for `$request->input('field')` without prior validation)
- [ ] Nested/array validation uses dot notation: `'items.*.price' => 'required|numeric'`
- [ ] `$request->validated()` used (not `$request->all()` or `$request->input()`) after validation

---

### 4. Security

- [ ] No raw SQL with user input: `DB::select("... WHERE id = '$id'")` → use bindings
- [ ] `{!! $var !!}` (unescaped Blade) only used for explicitly trusted HTML
- [ ] File uploads: MIME type validated, stored outside public dir or via `Storage::disk()`
- [ ] Sensitive data (passwords, tokens) not logged
- [ ] API tokens / secrets come from `config()` not hardcoded
- [ ] CSRF protection: POST/PUT/DELETE forms have `@csrf` or API routes use Sanctum/Passport

---

### 5. Performance

- [ ] Pagination used for any list endpoint (`->paginate()`, `->simplePaginate()`, `->cursorPaginate()`)
- [ ] Heavy operations dispatched as Jobs, not run synchronously in the request
- [ ] Expensive computed values cached where appropriate (`cache()->remember(...)`)
- [ ] API Resources / Transformers used instead of `->toArray()` for response shaping

---

### 6. Error Handling

- [ ] External API calls wrapped in try/catch with meaningful error handling
- [ ] Queue Jobs implement `$tries`, `$backoff`, and `failed()` method where appropriate
- [ ] HTTP client failures (`Http::get(...)`) check `->failed()` or `->throw()`
- [ ] Custom exceptions are used for domain errors (not raw `Exception` or `RuntimeException`)

---

### 7. Test Coverage

- [ ] Happy path has a Pest Feature test
- [ ] Authorization: both allowed and forbidden cases tested
- [ ] Validation: at least one "missing required field" or "invalid format" case tested
- [ ] Facade fakes used for Mail, Queue, Event, Notification where relevant (`Mail::fake()` etc.)
- [ ] N+1 regression: if a relationship is eager-loaded, a test verifies query count

```bash
php artisan test --coverage   # needs XDEBUG_MODE=coverage
```

---

### 8. Code Style & Conventions

- [ ] Follows the project's existing pattern (Actions vs Services vs fat controllers)
- [ ] `php artisan pint` (Laravel Pint) runs clean — no style violations
- [ ] Model relationships follow naming: `hasMany` → plural method name (`posts()`), `belongsTo` → singular (`user()`)
- [ ] Controller methods follow resource naming: `index`, `create`, `store`, `show`, `edit`, `update`, `destroy`
- [ ] New Artisan commands follow `module:action` naming (`orders:process-overdue`)

```bash
./vendor/bin/pint --test   # check style without fixing
./vendor/bin/pint          # fix style
```

---

## Summary Report Format

After reviewing, report findings grouped by severity:

**Blockers** (must fix before merge):
- [File:Line] — [issue] — [why it matters]

**Should fix** (important but not blocking):
- [File:Line] — [issue]

**Nice to have** (optional improvements):
- [File:Line] — [suggestion]

**Looks good** (explicit sign-off areas):
- Auth: covered
- Validation: complete
- Tests: green and meaningful

---

## Quick Commands

```bash
php artisan test              # run full test suite
./vendor/bin/pint --test      # style check
php artisan route:list        # verify routes
php artisan model:show Model  # check schema/relationships
php artisan queue:failed      # check for failed jobs
```

---

## §9 — Inertia + Vue 3 Component Review

When the diff touches Inertia controllers or Vue page components, audit these specifically:

### Controller side (Inertia::render returns)

- [ ] **No `Inertia::share()` overuse** — every shared prop fires on EVERY response. Use page-specific props instead unless data is truly global (auth user, flash messages, app config).
- [ ] **Lazy + deferred props for expensive computations** — use `Inertia::lazy(fn() => ExpensiveQuery::all())` for partial-reload-only data and `Inertia::defer(fn() => ...)` for above-the-fold deferral.
- [ ] **Form Request validation flows through** — Inertia auto-handles 422 redirects; verify the controller uses `FormRequest` not manual `validate()` for complex forms.
- [ ] **Redirect-after-POST pattern** — Inertia controllers return `redirect()` after mutations; flash data via `with()`.

### Vue page side

- [ ] **TypeScript on props** — `defineProps<{ user: User }>()`, not `defineProps({ user: Object })`. Without TS, IDE + runtime help is lost.
- [ ] **`useForm` for forms, not raw axios/fetch** — `useForm` integrates with Precognition, validation errors, processing state, and Inertia's redirect handling. Raw axios bypasses all of it.
- [ ] **`<Link>` for internal navigation, `<a>` for external URLs** — `<Link>` triggers Inertia visit; external URLs cause silent 409. (The `inertia-link-external-url` hook catches this at edit-time.)
- [ ] **`usePoll` for polling, not `setInterval`** — `usePoll` respects tab visibility, batches with other Inertia visits. (The `vue-setinterval-cleanup` hook catches missing cleanup.)
- [ ] **`router.visit` with Wayfinder-generated helpers, not hardcoded paths** — when Wayfinder is installed, hardcoded paths bypass type safety. (The `inertia-hardcoded-route` hook catches this.)
- [ ] **Listener cleanup in `onUnmounted`** — manual `addEventListener` outside Vue's reactivity must be paired with cleanup.

When in scope: invoke `laravel-inertia-specialist` agent for deep audit.

---

## §10 — Reka UI Component Review

When the diff touches Vue components using Reka UI primitives, audit these specifically:

- [ ] **Canonical Root/Trigger/Content composition** — Reka primitives expect their sub-components in canonical order (e.g., `DialogRoot > DialogTrigger + DialogPortal > DialogContent`). Skipping a layer breaks state propagation.
- [ ] **Controlled/uncontrolled state correctly chosen** — uncontrolled (Reka manages state internally) for simple cases; controlled (`v-model:open="state"`) for cross-component coordination.
- [ ] **NO manual `aria-*` on Reka primitives** — Reka ships ARIA-by-default. Manual `aria-*` conflicts with Reka's own management.
- [ ] **`data-[state=*]:` Tailwind modifiers for state-based styling** — instead of `v-if` toggling, use `data-[state=open]:animate-in` for smooth Reka-managed transitions.
- [ ] **`asChild` correctness** — when `asChild` used, the wrapped child must have exactly ONE root element.
- [ ] **`<DialogPortal>` for floating content** — without Portal, Dialog/Popover content can be clipped by parent overflow rules.
- [ ] **Slot prop destructuring** — `<DropdownMenuTrigger #default="{ open }">` to access state in trigger.

When in scope: invoke `laravel-reka-ui-specialist` agent for deep audit.

