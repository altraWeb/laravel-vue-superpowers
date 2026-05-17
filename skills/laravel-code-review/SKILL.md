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

## 9. Livewire 4 Sub-Checklist

When the change touches Livewire components (`app/Livewire/`, `resources/views/livewire/`, `wire:*` attributes, `#[Computed]`/`#[On]`/`#[Locked]` PHP attributes):

**API existence (catches fabricated methods)**

- [ ] Every `$this->methodName()` call in component code refers to a real method
  - Verify via `php -r 'echo (new ReflectionClass("Livewire\\Component"))->hasMethod("name");'`
  - Or invoke `laravel-livewire-specialist` agent — reflects on vendor source automatically
  - Common fabrication: `$this->hasLoading()` — does NOT exist; use `wire:loading.attr="aria-busy"` template-side

**Reactivity binding precision**

- [ ] `wire:model.live` chosen only when every-keystroke reactivity is intended (perf cost)
- [ ] `wire:model.blur` for forms (de-bounces to blur event)
- [ ] `wire:model.lazy` for less-critical input that can wait for blur or explicit submit
- [ ] `wire:model` (no modifier) → deferred until next network roundtrip; check this is intentional

**Computed property semantics**

- [ ] `#[Computed]` on derived getters that should re-run per render (uncached default)
- [ ] `#[Computed(cache: true)]` for expensive computations within a single request lifecycle
- [ ] `#[Computed(persist: true)]` for cross-request caching — verify cache key + invalidation
- [ ] Mutating a `#[Computed]` is meaningless (it's a getter); flag any setter-style usage

**Locked properties**

- [ ] `#[Locked]` on properties that should NOT be re-hydratable from the frontend (e.g., user IDs, role flags, internal-state markers)
- [ ] Without `#[Locked]`, a malicious frontend can manipulate the property — security review

**wire:ignore zones**

- [ ] Every `wire:ignore` block documented (comment explaining why Livewire shouldn't morph this subtree)
- [ ] Descendants of `wire:ignore` that need reactivity use Alpine `x-bind` / `x-on:click="$wire.foo()"` bridges — never `wire:click` directly

**Echo / broadcasting integration**

- [ ] `Echo.private(...).notification(...)` callbacks dispatch matching events the rest of the app expects (no orphan listeners)
- [ ] Callbacks that mutate DOM directly (e.g., `document.getElementById(...).innerHTML = ...`) are flagged — race condition with Livewire morph; use `$wire.handle(data)` instead
- [ ] `#[On('foo.bar')]` listeners declared for every broadcast event the component should react to

**Form Objects vs property + rules() bloat**

- [ ] Components with 5+ form properties + complex validation → extract to `Livewire\Form` class (separate state from component lifecycle)
- [ ] One-off simple forms → `protected $rules = [...]` + `$this->validate()` is fine
- [ ] Multi-step wizards → ALWAYS `Livewire\Form`

**Lifecycle hooks**

- [ ] `mount()` only does initial state binding (runs once); does not contain logic that should run on every request
- [ ] `hydrate()` handles cross-request state reconstruction (runs every request)
- [ ] `updating($property, $value)` / `updated($property, $value)` — use named variants (`updatingFoo`/`updatedFoo`) when only one property is tracked, for clarity
- [ ] `boot()` side-effects are intentional (runs on every request — including hydration)

**Specialist invocation:** for deep Livewire 4 audit including reflection-based API verification, dispatch `laravel-livewire-specialist` agent.

---

## 10. Flux Pro v2 Sub-Checklist

When the change touches Flux Pro v2 Blade components (`<flux:*>` tags in templates, `vendor/livewire/flux-pro/`):

**Tooltip double-wrap detection**

- [ ] No `<flux:tooltip>` wrapping components that already self-tooltip (`<flux:button>`, `<flux:icon-button>`, `<flux:editor.button>`, `<flux:nav.item>`)
- [ ] Verify via vendor: `grep -l 'flux:with-tooltip' vendor/livewire/flux-pro/stubs/resources/views/flux/<component>.blade.php`
- [ ] Outer tooltip wrapper breaks `<ui-toolbar>` roving-tabindex — silent a11y regression
- [ ] Fix: remove outer `<flux:tooltip>`, pass `tooltip="..."` as a prop on the inner component

**Position / Align convention**

- [ ] `<flux:dropdown>`, `<flux:tooltip>`, `<flux:menu>`, `<flux:popover>` use **separate** `position="..." align="..."` props (project canon, 9+ callsites verifiable via `grep -rn 'position=' resources/views/`)
- [ ] Avoid compound `position="bottom end"` — both work but consistency matters

**Editor.spacer placement**

- [ ] `<flux:editor.spacer/>` placed only inside `<flux:editor.toolbar>` (renders `flex-1`, only meaningful in flex containers)
- [ ] Spacer pushes following items to right edge — verify visual layout matches intent

**wire:ignore + Flux components**

- [ ] No `wire:click` / `wire:model` on `<flux:button>` / `<flux:input>` inside `<flux:editor wire:ignore>` zones
- [ ] Use Alpine `x-on:click="$wire.foo()"` bridge instead — silent failure otherwise

**Slot composition vs string-prop**

- [ ] `<flux:editor>` toolbar with 3+ items or dynamic content → slot form `<flux:editor.toolbar>...</flux:editor.toolbar>`
- [ ] String prop `<flux:editor toolbar="Bold|Italic">` only for static single-text toolbars
- [ ] Slot form required for buttons with `wire:click` / Alpine handlers / `<flux:editor.spacer/>`

**Floating UI auto-flip**

- [ ] `<flux:dropdown position="bottom">` near viewport-bottom auto-flips to top — verify this is intended (or pin with `flip-options`)
- [ ] Same for tooltip/menu/popover

**Specialist invocation:** for deep Flux Pro v2 audit including vendor file:line citations, dispatch `laravel-flux-pro-specialist` agent.

