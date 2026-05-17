# Laravel Telescope & Query Debugging

## Installing Telescope (dev only)

```bash
composer require laravel/telescope --dev
php artisan telescope:install
php artisan migrate
```

Access at: `http://your-app/telescope`

Restrict to local only (default) via `TelescopeServiceProvider::register()`.

## Telescope Tabs

| Tab | What to look for |
|-----|-----------------|
| **Requests** | Full request payload, headers, session, response body |
| **Commands** | Artisan commands and their output |
| **Queries** | Every SQL query, bindings, execution time |
| **Models** | Eloquent model events (created, updated, deleted) |
| **Jobs** | Dispatched jobs, payload, status, duration |
| **Exceptions** | Full exception with stack trace |
| **Logs** | All Log::* calls |
| **Mail** | Sent mails with rendered content |
| **Notifications** | Dispatched notifications |
| **Cache** | Cache hits, misses, writes |

## Detecting N+1 Queries

In Telescope, look at the **Queries** tab for a specific request.
N+1 pattern: many nearly-identical SELECT queries differing only by ID.

```
SELECT * FROM posts WHERE user_id = 1   ← repeated for each user
SELECT * FROM posts WHERE user_id = 2
SELECT * FROM posts WHERE user_id = 3
```

Fix: add `with('posts')` to the parent query.

## Manual Query Logging

```php
// In a controller or service (temporarily):
DB::enableQueryLog();

// ... code under investigation ...

$queries = DB::getQueryLog();
collect($queries)->each(fn ($q) => Log::info('Query', $q));
```

## Laravel Debugbar (alternative to Telescope for web)

```bash
composer require barryvdh/laravel-debugbar --dev
```

Shows inline in the browser: queries, timing, memory, route info.
Only active when `APP_DEBUG=true`.

## Query Optimization Reference

```php
// BAD: N+1
$users = User::all();
foreach ($users as $user) {
    echo $user->posts->count();  // fires query per user
}

// GOOD: eager loading
$users = User::withCount('posts')->get();
foreach ($users as $user) {
    echo $user->posts_count;    // no extra queries
}

// BAD: loading full models when you need counts/IDs
$user->posts->count();   // loads all posts into memory

// GOOD
$user->posts()->count(); // SELECT COUNT(*) — no model instantiation

// BAD: checking existence by fetching
if ($user->posts->isEmpty()) { ... }

// GOOD
if ($user->posts()->doesntExist()) { ... }  // SELECT 1 LIMIT 1

// Lazy eager loading (after initial query)
$users = User::all();
$users->load('posts', 'comments');   // one query each

// Conditional eager loading
$query = Post::with(['author', 'tags']);
if ($includeComments) {
    $query->with('comments');
}
```
