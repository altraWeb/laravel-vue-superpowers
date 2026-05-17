---
name: laravel-brainstorming
description: "Use in Laravel projects BEFORE designing or implementing any feature, endpoint, or architectural change. Guides Laravel-specific design decisions: which layer owns the logic, Eloquent relationships, Event/Listener patterns, Policy/Gate design, queuing decisions. In Laravel codebases, invoke this alongside superpowers:brainstorming for the framework-specific layer. ALWAYS trigger when adding new functionality, designing a new endpoint, planning a new model relationship, or choosing between architectural patterns in Laravel."
---

# Laravel Architecture Brainstorming

## Purpose

Generic brainstorming surfaces requirements and design. This skill adds the **Laravel-specific layer**: which of Laravel's tools to use, where the logic lives, and how the pieces connect.

Run this **after** the generic `superpowers:brainstorming` flow surfaces what you're building, **before** any code.

## Hard Gate

Do NOT write code or an implementation plan until you've answered the key architectural questions below. Architectural decisions are much cheaper to change on paper than in code.

## Step 1: Explore the Existing Project

```bash
php artisan route:list            # what routes exist already?
php artisan model:show ModelName  # what does the model look like?
ls app/Actions/ app/Services/     # what patterns are already in use?
ls app/Http/Controllers/          # what naming convention?
```

The most important question: **what patterns does this project already use?** Follow them. Don't introduce a new architecture pattern unless the existing one is clearly broken.

## Step 2: The Five Architectural Questions

Ask and answer each of these before proposing implementation:

### Q1: Which layer owns the logic?

| Option | Use When |
|--------|----------|
| **Controller** | Simple CRUD, no business logic beyond validation |
| **Form Request** | The logic is purely about validating and authorizing the request |
| **Action class** (`app/Actions/CreatePost.php`) | Single-purpose business operation, reusable, needs testing in isolation |
| **Service class** (`app/Services/BillingService.php`) | Multiple related operations grouped together, or external API wrapping |
| **Eloquent Model method** | Logic is inherently about that model's data (scopes, accessors, relationship-based) |
| **Job** (`app/Jobs/`) | The operation is slow (>200ms), can fail and retry, or must be async |
| **Event + Listener** | Side effects that should be decoupled (send email after payment, update stats after login) |

**Recommendation heuristic:**
- < 5 lines of logic → inline in controller
- reusable across multiple controllers → Action or Service
- async / can fail → Job
- side effect of something else → Event + Listener

### Q2: What are the Eloquent relationships?

For any new model or relationship:
- What type: `hasOne`, `hasMany`, `belongsTo`, `belongsToMany`, `morphTo`?
- Does it need a pivot table? What extra columns?
- Will it be eager loaded? How to avoid N+1?
- Does it need `withCount`, `withSum`, or other aggregates?

```bash
php artisan model:show ExistingModel   # see existing relationships
```

### Q3: Should any step be queued?

Queue it if:
- It calls an external API (mail, SMS, payment)
- It takes > ~200ms
- It can fail and should retry
- It needs to run after the response is sent
- It's a side effect that shouldn't block the main operation

Don't queue it if:
- The response depends on its result (synchronous by design)
- It's so fast that queue overhead would dominate
- The user needs immediate confirmation it happened

### Q4: What authorization strategy?

| Scenario | Tool |
|----------|------|
| Simple role check | `Gate::define()` in `AuthServiceProvider` |
| Resource-level permission (can this user update this post?) | `Policy` class |
| Row-level scope (only see own posts) | Eloquent global scope or local scope |
| Multi-tenant access | Middleware + Eloquent scope combination |

Always write a test for the authorization path (both allowed and denied case).

### Q5: What validation strategy?

| Scenario | Tool |
|----------|------|
| Simple, used in one place | Inline in controller: `$request->validate([...])` |
| Complex, or reused | `Form Request`: `php artisan make:request StorePostRequest` |
| API — consistent error format | Form Request (auto-returns 422 with JSON errors for API requests) |

Form Requests also handle authorization (`authorize()` method) — useful to keep auth + validation co-located.

## Step 3: Propose 2-3 Approaches

Present the options with trade-offs and a clear recommendation.

**Format:**

**Option A — [Name]**
- How: [brief description]
- Pro: [what's good]
- Con: [what's bad]

**Option B — [Name]**
- ...

**Recommended: Option [X] because [reason]**

## Step 4: Consider Side Effects

For the chosen approach, list every side effect explicitly:
- Emails to send → Mail + Event/Listener or Mailable dispatched directly?
- Notifications → Database, Slack, push?
- Cache to invalidate → which keys?
- Events to fire → who listens?
- Jobs to dispatch → which queue?

Side effects that aren't listed here will be forgotten until production.

## Step 5: Testing Plan

Before writing code, draft the test cases:
- Happy path: what does success look like?
- Auth failure: unauthorized request returns 401/403?
- Validation failure: invalid payload returns 422 with correct errors?
- Side effects: mail sent, job dispatched, event fired?
- Edge cases specific to this feature?

This shapes the implementation — you'll know exactly what you're building toward.

## Common Laravel Architecture Mistakes to Avoid

| Mistake | Better Approach |
|---------|----------------|
| Fat controllers (50+ line methods) | Extract to Action or Service |
| Business logic in Blade templates | Move to controller/service, pass data down |
| `env()` outside config files | Always `config('key')` in application code |
| Relationship queries in loops | Eager load with `with()` |
| Synchronous external API calls in request lifecycle | Queue via Job |
| Using `User::all()` anywhere | Always paginate or limit |
| `$request->all()` for mass assignment | Explicit `$request->validated()` or `$request->only([...])` |
| Checking auth in controller manually | Delegate to Policy + authorize() |

## Patterns Already in the Laravel Ecosystem

**Actions** (popularized by Loris Leiva):
- Single PHP class, single public `execute()` or `handle()` method
- No dependencies except what's constructor-injected
- Easy to test in isolation

**Repository Pattern** (use sparingly in Laravel):
- Adds abstraction over Eloquent
- Rarely worth it unless you need to swap persistence layers
- Most Laravel projects don't need it — Eloquent is already a great abstraction

**CQRS** (Command/Query separation):
- Actions as Commands (write operations)
- Eloquent scopes + Resources as Queries (read operations)
- Good fit for complex domains

**Event-Driven side effects** (Laravel native):
- `OrderPlaced` event → `SendOrderConfirmation`, `UpdateInventory`, `NotifyWarehouse` listeners
- Decoupled, testable, easy to add new reactions without changing core logic

## Design Doc

After alignment, write a brief design note to `docs/laravel/YYYY-MM-DD-<feature>-design.md`:
- Which layer, which pattern, why
- Data model changes (new tables, columns, relationships)
- Auth strategy
- Side effects list
- Test plan

Then proceed to implementation with `superpowers:writing-plans` or `superpowers:executing-plans`.
