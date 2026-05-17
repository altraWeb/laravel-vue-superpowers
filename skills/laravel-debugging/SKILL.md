---
name: laravel-debugging
description: "Use in Laravel projects when encountering any bug, test failure, unexpected behavior, N+1 queries, queue issues, or cache problems. Provides Laravel-specific debugging tools and workflows. In Laravel codebases, invoke this instead of superpowers:systematic-debugging. Trigger on any error, 500, unexpected output, slow query, or 'why is X not working' in a Laravel project."
---

# Laravel Systematic Debugging

## Core Principle

Find root cause before touching production code.
**In Laravel: read the logs and run tinker before guessing.**

## Iron Law

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

Random `dd()` placement is not debugging. It's thrashing.

## Phase 1: Gather Evidence

**Start here. Always. Before proposing any fix.**

### 1a. Read the error completely

```bash
# Laravel log (the first place to check)
tail -n 100 storage/logs/laravel.log
tail -f storage/logs/laravel.log   # live tail

# If using daily logs
tail -n 100 storage/logs/laravel-$(date +%Y-%m-%d).log
```

Read the **full stack trace** — not just the first line. The actual cause is often several frames deep.

### 1b. Check the HTTP response

For web/API issues:
- What HTTP status is returned?
- What does the JSON response body say?
- Is there a `message` or `errors` key?

```bash
# Quick API test
curl -s -w "\n%{http_code}" http://localhost/api/endpoint | tail -2
```

### 1c. Reproduce in tinker

```bash
php artisan tinker
```

Tinker has full app context — models, facades, services, config, DB. Use it to:

```php
# Test a model query
$user = App\Models\User::find(1);
$user->posts()->count();

# Check what a factory generates
App\Models\Post::factory()->make()->toArray();

# Test a service
$svc = app(App\Services\PaymentService::class);
$svc->charge(100, 'EUR');

# Check a config value
config('services.stripe.key');

# Test an event dispatch
event(new App\Events\UserRegistered(User::find(1)));

# Check a route resolution
app('router')->getRoutes()->getByName('dashboard');
```

### 1d. Check recent changes

```bash
git diff HEAD~3..HEAD --stat    # what changed recently
git log --oneline -10           # recent commits
git diff HEAD~1                 # last commit diff
```

### 1e. Clear caches (rule out stale state)

```bash
php artisan config:clear
php artisan cache:clear
php artisan view:clear
php artisan route:clear
php artisan event:clear
# All at once:
php artisan optimize:clear
```

If the bug disappears after clearing caches → the bug was a stale cache. Now understand why it got stale.

## Phase 2: Laravel-Specific Investigation

### Route/Controller issues

```bash
php artisan route:list                       # see all routes
php artisan route:list --name=user           # filter by name
php artisan route:list --path=api/users      # filter by path
```

Check middleware stack on the route — authorization failures often come from middleware, not the controller.

### Eloquent / Database issues

**N+1 queries** — the most common Laravel performance bug:

```php
// Add to AppServiceProvider::boot() temporarily:
\DB::listen(function ($query) {
    if ($query->time > 100) {  // queries slower than 100ms
        \Log::info('Slow query', ['sql' => $query->sql, 'bindings' => $query->bindings, 'time' => $query->time]);
    }
});

// In tinker — count queries for a request:
\DB::enableQueryLog();
// ... run the code that seems slow ...
\DB::getQueryLog();   // shows all executed queries with times
```

**Unexpected model values:**

```bash
php artisan tinker
# Check actual DB vs model cast vs what you expect
$post = App\Models\Post::find(1);
$post->toArray();             # all attributes + casts applied
$post->getRawOriginal();      # raw DB values before casting
$post->getDirty();            # unsaved changes
```

**Migration / schema issues:**

```bash
php artisan model:show User          # schema, relationships, attributes
php artisan migrate:status           # which migrations ran
php artisan schema:dump              # current schema
```

### Queue / Job issues

```bash
# Run one job manually (don't rely on the worker being up)
php artisan queue:work --once

# Watch queue in real time
php artisan queue:work --verbose

# See failed jobs
php artisan queue:failed

# Retry a specific failed job
php artisan queue:retry <id>

# Retry all failed jobs
php artisan queue:retry all
```

Check `failed_jobs` table:
```bash
php artisan tinker
# See the exception that caused the failure:
DB::table('failed_jobs')->latest()->first();
```

### Auth / Policy issues

```bash
php artisan tinker
# Test a policy
$user = App\Models\User::find(1);
$post = App\Models\Post::find(1);
$user->can('update', $post);   // true/false
Gate::forUser($user)->inspect('update', $post);  // detailed result
```

### Config / Environment issues

```bash
php artisan config:show database    # check DB config
php artisan config:show mail        # check mail config
php artisan env                     # check APP_ENV

# Verify .env is being loaded
php artisan tinker
env('APP_KEY');
config('app.key');  # these should match
```

### Mail / Notification issues

```bash
# Test sending mail without a real SMTP server
# Set MAIL_MAILER=log in .env — mail goes to laravel.log

php artisan tinker
Mail::to('test@test.com')->send(new App\Mail\WelcomeMail());
# Then check storage/logs/laravel.log
```

## Phase 3: Targeted Instrumentation

If Phase 1-2 didn't reveal the cause, add targeted logging:

```php
// In the code under investigation:
\Log::info('Checkpoint', [
    'user_id' => $user->id,
    'payload' => $data,
    'result'  => $result,
]);
```

**Trace boundary by boundary:**
1. Log at the controller entry — does the request arrive correctly?
2. Log before/after the service call — does the data transform correctly?
3. Log inside the service — where does it diverge from expectations?

Telescope (if installed at `/telescope`):
- **Requests** tab: exact request payload, response, session
- **Queries** tab: every SQL query with bindings and timing
- **Logs** tab: all log::info/error calls
- **Jobs** tab: dispatched jobs and their payloads
- **Exceptions** tab: full exceptions with stack traces

## Phase 4: Fix (Root Cause Only)

1. State the root cause clearly: "The bug is X because Y."
2. Write a **failing Pest test** that reproduces the bug (see `laravel-tdd` skill).
3. Make the **smallest possible code change** that fixes the root cause.
4. Run `php artisan test` — the new test must pass, no existing tests must break.

## Common Laravel Bug Patterns

| Symptom | Likely Root Cause |
|---------|-------------------|
| `500` with no message | Check `storage/logs/laravel.log` |
| `419 Page Expired` | CSRF token missing — check form has `@csrf` |
| `401 Unauthenticated` | Token missing/expired or wrong guard in route |
| `403 Forbidden` | Policy `authorize()` returns false |
| `422 Unprocessable` | Validation failed — check `errors` in response body |
| N+1 queries | Missing `with()` on relationship — check query log |
| Stale data | Config/route/view cache — run `php artisan optimize:clear` |
| Job not running | Queue worker not started, or `QUEUE_CONNECTION` is `sync` |
| Mail not sent | `MAIL_MAILER=log`? Check laravel.log instead of inbox |
| Env var not loading | `.env` change needs `php artisan config:clear` |
| Wrong value from config | Using `env()` outside config file (cached incorrectly) |

## Red Flags — Stop and Use the Process

| Thought | What to do instead |
|---------|-------------------|
| "Let me just dd() everywhere" | Read the log first, then place one targeted dd() |
| "Probably a cache issue, let me clear" | Investigate first, clear caches as a hypothesis test |
| "It works on my machine" | Compare `.env` files, run `php artisan config:show` |
| "Let me just change X and see" | Form a hypothesis first, then test it minimally |
| "The queue must be broken" | Run `php artisan queue:work --once` to verify |

## Reference files

Telescope setup and query debugging → `references/telescope-guide.md`

---

## Top-10 Pest 4 / Livewire 4 / Flux Pro v2 RED Recipes

When you hit a RED in a Pest 4 test for one of these stack-specific symptoms, this table maps **error signature → root cause → concrete fix**. Use it AFTER you've confirmed the symptom (RCA discipline still applies — these are pattern-matching shortcuts, not skip-the-investigation excuses).

### 1. `expected array to contain 'X'` with a long second arg

**Error signature:** `Failed asserting that array contains 'should include foo'.`

**Root cause:** Pest's `toContain(...$needles)` is variadic. The "message" you passed as arg #2 became a second needle — the assertion now requires both `'X'` AND `'should include foo'` to be present in the array.

**Fix:**
```php
expect($response->json('items'))
    ->toContain('foo')
    ->because('should include foo');
```

**Sibling-canon:** see `laravel-tdd` skill §"Variadic-Expectation Trap" for the full pattern.

---

### 2. `Using $this when not in object context` in view rendering

**Error signature:** PHP fatal: `Using $this when not in object context` raised from a compiled Blade template.

**Root cause:** `view()->with(['this' => $obj])` — `$this` is reserved by PHP and Blade refers to the renderer's render-context. Your `$obj` is unreachable in the template.

**Fix:** rename the key to something meaningful and access it accordingly in the view:
```php
return view('ai.popover', ['ai' => $aiAgent, 'surface' => 'editor']);
// view: {{ $ai->dispatch('foo') }}
```

Other reserved keys to avoid: `loop`, `errors`, `__env`, `app`, `attributes`, `component`, `slot`.

---

### 3. `BadMethodCallException: Method [hasLoading] does not exist`

**Error signature:** runtime exception on first interaction, naming a `$this->X()` method that "should exist" per the plan-doc but doesn't.

**Root cause:** fabricated Livewire API. The method name came from a plausible-sounding hallucination, not vendor source. `hasLoading()` does not exist on `Livewire\Component`; loading state is a **frontend concern** in Livewire 4.

**Fix:** use the template-side directive:
```blade
<button wire:click="save" wire:loading.attr="aria-busy" wire:target="save">Save</button>
```

**Verification:**
```bash
php -r 'echo (new ReflectionClass("Livewire\\Component"))->hasMethod("hasLoading") ? "yes" : "no";'
# → no
```

Invoke `laravel-livewire-specialist` agent for thorough API audit.

---

### 4. `401 Unauthorized` from external API in Pest test

**Error signature:** test failure shows external HTTP 401 (Anthropic, Stripe, etc.) coming from real production endpoints.

**Root cause:** `phpunit.xml` blanks the API key for safety (`<env name="ANTHROPIC_API_KEY" value=""/>`), but your test invoked a code path that calls the real API. `Bus::fake()` doesn't intercept synchronous static calls (e.g., `AiAgentRunner::run(...)` if it's not dispatched as a Job).

**Fix options:**
- Mock the agent layer directly via Mockery: `Mockery::mock('alias:App\AiAgentRunner')->shouldReceive('run')->andReturn(...)`
- OR rely on an `arch()` test to pin method existence + signature, run integration manually
- OR refactor to dispatch as a Job and use `Bus::fake()` + `Bus::assertDispatched(...)`

**Decision:** depends on intent — if the test should verify the code path runs without invoking the API, Mockery is best. If the test should verify Job dispatch, refactor + Bus::fake.

---

### 5. `Route [foo.bar] not defined`

**Error signature:** test fails on `$this->get(route('foo.bar'))` or similar.

**Root cause:** route name mismatch — typo, wrong file, missing `->name('foo.bar')` call, or controller renamed without route update.

**Fix:** verify the route exists and is named correctly:
```bash
php artisan route:list --name=foo
```

If the route exists with a different name, fix the test or the route. If the route doesn't exist, add it.

---

### 6. `Cannot use object of type Model as array` / `array_filter expects parameter 1 to be array, Collection given`

**Error signature:** PHP type juggling error in test or runtime where code treats a model as an array, or treats a collection as a single model.

**Root cause:** relationship mismatch. `hasOne` returns a single model; `hasMany` returns a Collection. Calling `->first()` on a `hasOne` is redundant; iterating a `hasOne` result errors.

**Fix:** check the relationship method in the parent model:
```bash
php artisan model:show User --no-relations  # or inspect app/Models/User.php
```

Adjust caller code: `$user->profile` (singular) vs `$user->posts` (collection). Use `$user->posts()->first()` only if you need a query-builder layer first.

---

### 7. `SQLSTATE[23000]: Foreign key constraint fails`

**Error signature:** integrity constraint violation when creating a model via factory in test.

**Root cause:** factory chain missing required parent. E.g., a `Topic` requires `forum_id` + `user_id` foreign keys; calling `Topic::factory()->create()` without specifying parents auto-creates them, but if your factory has explicit `for(...)` requirements, you need to provide them.

**Fix:**
```php
Topic::factory()
    ->for(Forum::factory()->create())
    ->for(User::factory()->create(), 'author')
    ->create();
```

Or use `->hasParent()` / `->hasChildren()` patterns if the factory defines them.

---

### 8. `Property [xxx] not found on component`

**Error signature:** Livewire 4 component renders, then on interaction throws an exception saying a public property doesn't exist.

**Root cause:** the component template (`*.blade.php` or in-class `render()`) references `$xxx`, but the PHP class has no public `$xxx` property declared.

**Fix:** declare the property:
```php
class MyComponent extends Component
{
    public string $xxx = '';
    // ...
}
```

Note: Livewire requires properties to be **public** and **primitive-serializable** (string, int, bool, array of those, Eloquent model, etc.). Private/protected properties are component-internal only.

---

### 9. Lang key returns the key string verbatim

**Error signature:** view renders the literal `messages.button.save` instead of `"Save"`.

**Root cause:** missing lang key in the active locale's translation file. Laravel falls back to the key string when no translation exists.

**Fix:**
```bash
php -r 'require "vendor/autoload.php"; $app = require "bootstrap/app.php"; $app->setLocale("de"); echo (Lang::hasForLocale("messages.button.save", "de") ? "yes" : "no");'
```

If `no`, add the key to `lang/de/messages.php` (or wherever your translation files live). Verify the locale is set correctly in the test (`App::setLocale('de')` in test setup).

---

### 10. Browser test sees stale DOM / element-not-found / flaky timing

**Error signature:** `assertVisible('@my-button')` fails intermittently; CI flake; the element IS in the DOM when you check manually.

**Root cause:** the element appears asynchronously (Livewire morph, Alpine init, AJAX response), but the assertion ran before it materialized. Manual `->wait(1)` is a smell — Pest 4 already has a **5-second implicit timeout** on `assertVisible`/`assertPresent`/`assertSee`/`assertText`/`assertAttribute`.

**Fix:**
- Remove `->wait(N)` calls
- Verify the selector is specific (prefer `@data-testid` over text or class selectors)
- If the element legitimately takes >5s, add `setUp(fn () => $this->setTimeoutMultiplier(2))` in the test — but flag this for redesign (5s should be enough)

**Sibling-canon:** see `laravel-tdd` skill §"`wait(N)` is a smell" for the full pattern.

---

## Specialist Agents

For deep stack-specific debugging:

| If RED is in... | Dispatch |
|---|---|
| Livewire component | `laravel-livewire-specialist` — reflects on `Livewire\Component` vendor source |
| Pest test (API misuse) | `laravel-pest-specialist` — reflects on `Pest\Expectation` + browser plugin |
| Flux Pro v2 Blade | `laravel-flux-pro-specialist` — reads `vendor/livewire/flux-pro/stubs/resources/views/flux/*.blade.php` |
| Eloquent / architecture | `laravel-architect` — sibling-canon check against `app/Actions/`, `app/Services/` |
| Multi-component review | `laravel-reviewer` — composes specialist invocations + banned-token sweep |

