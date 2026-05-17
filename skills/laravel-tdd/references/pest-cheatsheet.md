# Pest + Laravel Quick Reference

## Test File Structure

```php
<?php

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;

uses(RefreshDatabase::class, WithFaker::class);

beforeAll(function () { /* runs once for the file */ });
afterAll(function () { /* runs once for the file */ });
beforeEach(function () { $this->user = User::factory()->create(); });
afterEach(function () { /* cleanup */ });

test('description as statement', function () { ... });
it('does something in plain English', function () { ... });
```

## Pest Expectations Cheatsheet

```php
// Equality
expect($val)->toBe(42);              // strict ===
expect($val)->toEqual([1, 2]);       // loose ==
expect($val)->not->toBe(0);

// Types
expect($val)->toBeString();
expect($val)->toBeInt();
expect($val)->toBeBool();
expect($val)->toBeArray();
expect($val)->toBeNull();
expect($val)->not->toBeNull();
expect($val)->toBeInstanceOf(User::class);

// Truthiness
expect($val)->toBeTrue();
expect($val)->toBeFalse();
expect($val)->toBeTruthy();
expect($val)->toBeFalsy();

// Collections / Arrays
expect($collection)->toHaveCount(3);
expect($array)->toContain('needle');
expect($array)->toHaveKey('email');
expect($array)->toHaveKeys(['id', 'email', 'name']);
expect($array)->toMatchArray(['email' => 'test@test.com']);

// Strings
expect($string)->toContain('substring');
expect($string)->toStartWith('Hello');
expect($string)->toEndWith('!');
expect($string)->toMatch('/regex/');

// Numbers
expect($num)->toBeGreaterThan(0);
expect($num)->toBeGreaterThanOrEqual(1);
expect($num)->toBeLessThan(100);
expect($num)->toBeBetween(1, 100);

// Exceptions
expect(fn () => $sut->call())->toThrow(RuntimeException::class);
expect(fn () => $sut->call())->toThrow(RuntimeException::class, 'message');

// JSON
expect($response->json('data.email'))->toBe('test@test.com');
```

## HTTP Response Assertions

```php
$response->assertOk();                   // 200
$response->assertCreated();              // 201
$response->assertNoContent();            // 204
$response->assertNotFound();             // 404
$response->assertUnauthorized();         // 401
$response->assertForbidden();            // 403
$response->assertUnprocessable();        // 422
$response->assertServerError();          // 500

$response->assertStatus(302);
$response->assertRedirect('/login');
$response->assertRedirectToRoute('dashboard');

// JSON
$response->assertJson(['key' => 'value']);       // partial match
$response->assertExactJson(['key' => 'value']);  // exact match
$response->assertJsonPath('data.email', 'a@b.c');
$response->assertJsonCount(3, 'data');
$response->assertJsonStructure(['data' => [['id', 'name', 'email']]]);
$response->assertJsonValidationErrors(['email', 'password']);
$response->assertJsonMissingValidationErrors(['name']);

// Views
$response->assertViewIs('auth.login');
$response->assertViewHas('user');
$response->assertSeeText('Welcome');

// Cookies / Session
$response->assertCookie('remember_token');
$response->assertSessionHas('status', 'success');
$response->assertSessionHasErrors(['email']);
```

## Database Helpers

```php
$this->assertDatabaseHas('users', ['email' => 'test@test.com']);
$this->assertDatabaseMissing('users', ['email' => 'gone@test.com']);
$this->assertDatabaseCount('posts', 5);
$this->assertSoftDeleted('posts', ['id' => 1]);
$this->assertNotSoftDeleted('posts', ['id' => 2]);
$this->assertModelExists($model);
$this->assertModelMissing($model);
```

## Pest Datasets (Parameterized Tests)

```php
// Inline
it('validates', function (string $input, bool $valid) {
    ...
})->with([
    ['valid@email.com', true],
    ['not-an-email', false],
]);

// Named dataset
dataset('invalid_emails', [
    'no-at'      => ['noat'],
    'no-domain'  => ['no@'],
    'empty'      => [''],
]);

it('rejects invalid emails', function (string $email) {
    ...
})->with('invalid_emails');
```

## Skip / Todo

```php
test('pending feature')->todo();
test('known issue')->skip('Bug #123, fix in next sprint');
test('platform specific')->skipOnWindows();
it('works')->skip(PHP_OS_FAMILY === 'Windows', 'Not on Windows');
```

## Pest Hooks Scope

```php
// File-level scope (most common)
beforeEach(function () { $this->user = User::factory()->create(); });

// Describe-level scope
describe('Admin actions', function () {
    beforeEach(function () { $this->admin = User::factory()->admin()->create(); });
    it('can delete users', function () { ... });
});
```

## Factory Quick Reference

```php
// Create (persisted)
User::factory()->create();
User::factory()->count(5)->create();
User::factory()->admin()->create();          // named state
User::factory()->create(['email' => 'x@y.com']);

// Make (not persisted)
User::factory()->make();

// Relationships
Post::factory()->for($user)->create();             // belongsTo
Post::factory()->has(Comment::factory()->count(3))->create();  // hasMany
Post::factory()->hasComments(3)->create();         // magic has* method

// States (define in factory class)
public function admin(): static {
    return $this->state(['role' => 'admin']);
}
```

## Common Facade Fakes

```php
Mail::fake();
    Mail::assertSent(Mailable::class);
    Mail::assertSent(Mailable::class, 1);  // exactly once
    Mail::assertQueued(Mailable::class);
    Mail::assertNothingSent();
    Mail::assertNothingQueued();

Queue::fake();
    Queue::assertPushed(Job::class);
    Queue::assertPushed(Job::class, fn ($j) => $j->id === 5);
    Queue::assertPushedOn('high', Job::class);
    Queue::assertNotDispatched(Job::class);
    Queue::assertCount(3);

Event::fake();
    Event::assertDispatched(UserRegistered::class);
    Event::assertDispatched(UserRegistered::class, fn ($e) => $e->user->id === 1);
    Event::assertNotDispatched(UserDeleted::class);
    Event::assertListening(UserRegistered::class, SendWelcomeEmail::class);

Notification::fake();
    Notification::assertSentTo($user, InvoicePaid::class);
    Notification::assertNotSentTo($user, InvoicePaid::class);
    Notification::assertCount(2);

Storage::fake('s3');
    Storage::disk('s3')->assertExists('path/file.pdf');
    Storage::disk('s3')->assertMissing('path/gone.pdf');

Http::fake([
    'https://api.example.com/*' => Http::response(['id' => 1], 200),
    'https://slow.api.com/*'    => Http::response([], 503),
]);
    Http::assertSent(fn ($req) => $req->url() === 'https://api.example.com/users');
```
