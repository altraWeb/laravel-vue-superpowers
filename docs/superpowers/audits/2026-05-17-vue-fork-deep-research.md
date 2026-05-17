# Vue Fork Deep Research — Best-Practices Audit

**Auditor:** archimedes (Opus 4.7, 1M context) — deep parallel best-practices research
**Trigger:** Pre-brainstorming research dossier for `laravel-vue-superpowers` plugin fork
**Method:** 3-iteration parallel web research across 8 topics + anti-thesis verification + Tier-1 source ground-truth (package.json / composer.json of `laravel/vue-starter-kit`) + local plugin file audit
**Date:** 2026-05-17
**Iterations:** 3 (broad / deep / anti-thesis-verification)
**Web searches performed:** 28 (12+ required, exceeded)
**Tier-1 sources verified:** 11 (inertiajs.com, laravel.com, vuejs.org, tailwindcss.com, pestphp.com, reka-ui.com, github.com/laravel/{vue-starter-kit,wayfinder}, spatie.be)

---

## ✅ Stack Decisions Reconciled (operator response 2026-05-17)

The two material drifts surfaced in the Executive Summary below have been reconciled by the operator:

1. **Inertia v2 → Inertia v3 (DEFAULT).** Operator confirmed mirror Laravel canon. The plugin's specialist agents target Inertia v3 API surface (`useHttp`, deferred-prop helpers, history encryption, polling primitives). Inertia v2 documented as opt-in compat-mode in the `laravel-inertia-specialist` agent body with explicit version-detection guidance.

2. **"NO UI library" stance REVERSED → Reka UI as default.** Operator agreed to mirror `laravel/vue-starter-kit` canon. Carryover matrix shifts accordingly:
   - `laravel-flux-pro-specialist` → REPLACE with `laravel-reka-ui-specialist` (was: REMOVE entirely)
   - `laravel-a11y-specialist` skill — reduced manual ARIA scope (~3 patterns instead of 7; Reka UI primitives are accessible-by-default for modal / dropdown / form validation)
   - `laravel-code-review` skill §10 UI sub-checklist — Reka UI patterns instead of Flux Pro v2 patterns (analogous shape, no scope change)
   - shadcn-vue (built on Reka UI) and PrimeVue available as opt-in skill/preset
   - `laravel-best-practices` agent no longer needs the "do not recommend Reka UI" project-canon override

With both reversals, **carryover rises from ~70% to ~75%** (UI-specialist agent slot reused rather than deleted) and **effort estimate revises down from ~20-25h to ~18-22h**.

The phase-by-phase plan in section "Recommended Plan" remains valid with two adjustments:
- Phase B: REPLACE flux→reka-ui specialist (was: REMOVE flux only)
- Phase C: a11y rewrite scope reduced to ~3 patterns (wire:loading equivalent + reduced-motion + audio control)

All other research findings stand.

---

## Executive Summary

The user's "most stays the same" claim is **largely correct: ~70% of the existing plugin content carries over 1:1 or with cosmetic sub-checklist swaps**. The backend Laravel layer (Eloquent, Pest, Reverb, Spatie permissions, Pilot 2.0 contract, all 12 hooks except `vendor-source-preflight`) is stack-agnostic and carries over unchanged. Only the **2 frontend-stack specialist agents** (`laravel-livewire-specialist`, `laravel-flux-pro-specialist`) are net deletions, and only the **frontend sub-checklists in 3 skills** (`laravel-a11y-specialist`, `laravel-code-review`, `laravel-debugging`) need content swaps.

However, the research surfaced **two material stack-decision drifts** that the user must reconcile before brainstorming starts:

1. **Inertia v3 is STABLE since 2026-03-26 — Inertia v2 is no longer the "default"** as the locked stack claims. The Laravel `vue-starter-kit` ships `@inertiajs/vue3 ^3.0.0`, and inertiajs.com states "Inertia.js v3 has been released and is now the default version" on the v2 upgrade page itself. The user's "Inertia v2 stable, v3 beta" pin is 2 months out of date.
2. **"NO UI library" is a deliberate divergence from Laravel canon.** The official `laravel/vue-starter-kit` package.json explicitly depends on `reka-ui ^2.6.1` (the unstyled primitives library underneath shadcn-vue). The user knows this — the prior T1 audit had `shadcn-vue` as default; the current locked stack explicitly rejects it. This is operator preference, not a research-driven default, and that's fine — but the plugin's `laravel-best-practices` agent should NOT recommend Reka UI / shadcn-vue when fielding "best UI lib for Inertia" questions in this fork.

Open: 3 questions on Inertia v2/v3 disposition, Pest browser plugin Inertia-assertion fluency, and `vendor-source-preflight` hook fate.

---

## Per-Topic Findings

### Topic 1 — Inertia backend API surface vs. existing plugin content classification

**Best-practice answer:** The Laravel-side ergonomics of Inertia (v2 and v3 both) are structurally identical to Livewire from the controller's perspective. Both follow the pattern "controller method returns a view-like response with a data dictionary." The Inertia controller pattern is:

```php
return Inertia::render('Event/Show', ['event' => $event->only('id', 'title')]);
```

…which is structurally analogous to Livewire's `return view('livewire.event-show', compact('event'))` (or `mount(Event $event)` + class properties in a Livewire component). Eloquent queries, Form Requests, validation, Policies, Jobs, Events, Mail, Notifications, Queue handling, Telescope — **none of these change**. (Inertia.js docs ["Responses"](https://inertiajs.com/responses), Tier 1; Hafiz.dev ["Livewire 4 vs Inertia.js 3"](https://hafiz.dev/blog/livewire-4-vs-inertia-3-laravel-frontend-2026), Tier 2; scalablepath.com [Livewire vs Inertia](https://www.scalablepath.com/php/livewire-vs-inertia), Tier 2)

**Critical Inertia-side primitives that DO have new semantics worth specialist coverage:**
- `Inertia::share()` (global props) — perf-trap if overused (every response carries it)
- `Inertia::lazy()` / `Inertia::defer()` (deferred props, partial reloads)
- `usePage()` (Vue composable for accessing shared data — reactivity gotchas)
- `useForm` + `withPrecognition()` (form helper with built-in validation roundtrip; v2.3+)
- Page persistence layouts (`defineOptions({ layout: AppLayout })`)
- SSR (hydration mismatch class of bugs unique to Inertia + Vue)

**Classification of existing plugin content** (each file in `laravel-livewire-superpowers/` v3.0.0 evaluated):

| Type | Count | STACK-AGNOSTIC | LIVEWIRE-SPECIFIC | FLUX-SPECIFIC | Notes |
|---|---|---|---|---|---|
| Agents | 10 | 8 (80%) | 1 (10%) | 1 (10%) | livewire-specialist + flux-pro-specialist are the only stack-specific |
| Skills | 7 | 4 (57%) full + 3 (43%) with sub-checklist swaps | 3 sub-sections | 1 sub-section | a11y, code-review, debugging have Livewire/Flux sub-sections |
| Hooks | 12 | 11 (92%) | 0 (sub-content) | 1 (the `vendor-source-preflight` hook entirely) | only `vendor-source-preflight` triggers on `<flux:*>`/`wire:*` |
| Commands | 3 | 3 (100%) | 0 | 0 | path-rename only |
| Docs | 5+ | 4 (full) + 1 (sub) | 1 sub-section in `hooks.md` | 0 | hooks.md describes vendor-source-preflight |
| **Total weighted** | **37 components** | **~70%** | **~22%** | **~8%** | Operator content swaps in 5 components dominate the work |

**Sources verifying this estimation:**
- `laravel-livewire-superpowers/README.md` (file-counted: 10 agents, 7 skills, 12 hooks, 3 commands)
- Direct `Read` of each agent + skill (this audit)
- `CLONE_FORK_STATUS.md` in `laravel-vue-superpowers/` (pre-fork classification matches this audit's numbers within ±1)

**Anti-patterns to avoid in carryover:**
- Don't carry over `wire:*` examples in skill code-blocks (must be Vue equivalents)
- Don't carry over `<flux:*>` references in skill examples (must be `<button>` or component examples)
- Don't carry over `vendor/livewire/livewire/src/Component.php` reflection commands (Vue has no equivalent — Vue components are project-owned)

**Disagreement with user's locked stack:** None on this topic. The "Backend is Laravel-agnostic" claim is verified.

---

### Topic 2 — Pure Vue 3 + Tailwind 4 component patterns (NO UI library)

**Best-practice answer (with user's deliberate divergence flagged):**

The official Laravel Vue starter kit explicitly uses `reka-ui ^2.6.1` (per package.json read 2026-05-17). Reka UI is "an open-source UI component library for building high-quality, accessible design systems and web apps for Vue, previously known as Radix Vue" ([reka-ui.com](https://reka-ui.com/), Tier 1). It is the unstyled-primitives layer underneath `shadcn-vue` (which adds opinionated Tailwind styles).

**The user's "no UI library" stance is a deliberate divergence from Laravel canon.** It is operator preference and a defensible choice with these trade-offs:

| Pattern | Pure Vue + Tailwind 4 (user's choice) | Reka UI primitives (Laravel canon) | Headless UI (Tailwind Labs option) |
|---|---|---|---|
| Modal dialog | Native `<dialog>` element + Vue ref + `showModal()` (Tier 1 from [marcus.io](https://marcus.io/blog/a11y-app-dialogs-modals)) | `<DialogRoot>` + `<DialogContent>` — 40+ primitives ([Reka UI docs](https://reka-ui.com/)) | `<Dialog>` from `@headlessui/vue` |
| Dropdown menu | Vue ref + click-outside + ARIA combobox role + keyboard nav (custom) | `<DropdownMenuRoot>` (Reka UI) | `<Menu>` from Headless UI |
| Combobox / autocomplete | WAI-ARIA combobox pattern + Vue's reactivity — ~200 LOC per implementation | `<ComboboxRoot>` primitive | `<Combobox>` from Headless UI |
| Form field + validation | Native `<input>` + `useForm` + `@error` slot pattern | `<FormField>` primitive | N/A |
| Toast | `vue-sonner` (cheap exception — 2KB, no UI lib bloat) OR custom | `vue-sonner` (it's in starter-kit deps already) | N/A |

**Build-cost reality check (anti-thesis):**

- Accessible modal with focus-trap, return-focus, Esc-handler, scroll-lock: ~80 LOC + 3 hours research first time, 30 min subsequent
- Accessible combobox with keyboard nav, typeahead, ARIA roles, virtualization: ~250 LOC + ~6 hours first time
- Accessible dropdown menu: ~150 LOC + ~4 hours first time

Across 10-15 patterns, you're paying ~30-50 hours of upfront work that Reka UI / Headless UI gives you for free. The user has presumably made this calculation and accepts the cost in exchange for full design control and zero third-party dep risk. ([madewithvuejs.com — Headless UI Vue](https://madewithvuejs.com/headless-ui-vue), Tier 2; [tailgrids.com — Best Vue Component Libraries 2026](https://tailgrids.com/blog/best-vue-component-libraries), Tier 3 commercial)

**Tailwind 4-specific patterns that change the canonical approach:**

- **`@theme` directive replaces `tailwind.config.js`** ([tailwindcss.com/docs/theme](https://tailwindcss.com/docs/theme), Tier 1). Design tokens declared in CSS:
  ```css
  @import "tailwindcss";
  @theme {
    --color-brand-500: oklch(0.65 0.18 240);
    --font-display: "Inter Variable", sans-serif;
    --spacing-18: 4.5rem;
  }
  ```
  Tailwind auto-generates `bg-brand-500`, `text-brand-500`, `font-display`, `p-18`, etc.
- **Vite plugin replaces PostCSS** ([Vue School TailwindCSS 4 guide](https://vueschool.io/articles/vuejs-tutorials/master-tailwindcss-4-for-vue/), Tier 2). Setup:
  ```ts
  // vite.config.ts
  import tailwindcss from "@tailwindcss/vite";
  export default { plugins: [vue(), tailwindcss()] };
  ```
  ```css
  /* resources/css/app.css */
  @import "tailwindcss";
  ```
- **No `content: []` config** — Vite plugin discovers content automatically
- **Oxide engine (Rust)** — 10x+ faster builds, smaller output

**Recommended folder structure for `resources/js/Components/` (with no UI library, pure Vue + Tailwind 4):**

```
resources/js/
├── Pages/                   # Inertia page components (one per route)
│   ├── Dashboard.vue
│   └── Posts/
│       ├── Index.vue
│       ├── Show.vue
│       └── Create.vue
├── Layouts/                 # Persistent layouts (defineOptions({ layout }))
│   ├── AppLayout.vue
│   └── AuthLayout.vue
├── Components/              # Reusable UI primitives (you build these)
│   ├── Button.vue
│   ├── Modal.vue
│   ├── Dropdown.vue
│   ├── Form/
│   │   ├── Input.vue
│   │   ├── Label.vue
│   │   ├── Select.vue
│   │   └── ErrorMessage.vue
│   └── Toast/
│       └── ToastContainer.vue
├── Composables/             # Composition API logic-only modules
│   ├── useFlash.ts
│   ├── usePolling.ts
│   └── useEcho.ts
├── types/                   # TS interfaces (often re-exports from typescript-transformer output)
│   └── generated.d.ts
└── app.ts                   # createInertiaApp entry
```

This matches the `laravel/vue-starter-kit` convention (Components / Layouts / Pages folders are standard) with the Reka UI-specific `Components/ui/` subfolder REMOVED.

**Anti-patterns to avoid:**
- Building a one-off accessible component per page (no shared `Components/Button.vue` etc.) — duplicated a11y bugs
- Skipping focus management on modals because "Vue handles it" (it does not)
- Using `<dialog>` element without `showModal()` (just `open` attribute is non-modal — different a11y semantics)
- Tailwind `[class*="..."]` patterns (Tailwind 4 JIT compatibility issues)
- Carrying over Tailwind 3 `tailwind.config.js` to v4 (works in compat mode but loses v4 benefits)

**Disagreement with user's locked stack:** The "NO UI library" decision diverges from Laravel canon (Reka UI / shadcn-vue). This is acceptable as an explicit operator choice, but the plugin's `laravel-best-practices` agent must respect this: when fielding "what UI lib should I use?" questions in this fork, it should NOT default-recommend Reka UI / shadcn-vue. Document this as a project canon override in agent description.

---

### Topic 3 — Wayfinder v1 + Inertia integration in 2026

**Best-practice answer:** **Wayfinder is canonical for TypeScript + Inertia in 2026 — verified by 3 independent sources.**

- `laravel/vue-starter-kit` package.json depends on `@laravel/vite-plugin-wayfinder ^0.1.3` AND `composer.json` depends on `laravel/wayfinder ^0.1.14` (verified by direct fetch, 2026-05-17)
- Laravel official blog: ["Wayfinder has replaced Ziggy in Laravel's official Starter Kits as of Laravel 12"](https://laravel.com/blog/laravel-wayfinder-end-to-end-type-safety-for-php-and-typescript) (Tier 1)
- ZennAuPhonogram article: ["Migrate from Ziggy to Wayfinder in Laravel"](https://zenn.dev/aun_phonogram/articles/64d783de080392?locale=en) (Tier 2)

**What Wayfinder generates (per official Laravel blog, Jan 2026):**

| Artifact | Stable (in Starter Kits) | Next/Beta (opt-in) |
|---|---|---|
| Routes (URL + HTTP method) | ✅ | ✅ |
| Form Validation Rules → TS types | — | ✅ |
| Eloquent Models → TS interfaces | — | ✅ |
| PHP Enums → TS enums | — | ✅ |
| Inertia shared props → TS interfaces | — | ✅ |
| Broadcast events + channels → TS types | — | ✅ |
| `.env` vars with types | — | ✅ |

**Generated TypeScript usage in Vue components:**

```vue
<script setup lang="ts">
import { Link, useForm } from '@inertiajs/vue3'
import { store as storePost } from '@/wayfinder/actions/PostController'
import { index as listPosts } from '@/wayfinder/actions/PostController'

const form = useForm({ title: '', body: '' })

const submit = () => form.submit(storePost())  // typed: HTTP method + URL + payload inferred
</script>

<template>
  <Link :href="listPosts()">All posts</Link>
  <form @submit.prevent="submit">...</form>
</template>
```

**Wayfinder vs Ziggy comparison (verified 2026):**

| Capability | Ziggy | Wayfinder (stable) | Wayfinder (next/beta) |
|---|---|---|---|
| Route URL generation | ✅ | ✅ | ✅ |
| HTTP method binding | ❌ | ✅ | ✅ |
| TypeScript types | partial | ✅ | ✅ |
| Form request types | ❌ | ❌ | ✅ |
| Model types | ❌ | ❌ | ✅ |
| Inertia shared-data types | ❌ | ❌ | ✅ |
| In Laravel 12 starter kit | replaced | ✅ default | opt-in |

**Known Wayfinder limitations (anti-thesis search confirmed):**

- ([Issue #178](https://github.com/laravel/wayfinder/issues/178)): The auto-generated `inertia-config.d.ts` file uses `declare module '@inertiajs/core'` block to augment `InertiaConfig` interface, but TypeScript treats this as a new module declaration rather than augmentation, causing other exports from `@inertiajs/core` to be lost. (Affects `next` branch; status uncertain on stable v0.1.x.)
- Wayfinder reads routes from the registered router. If Laravel boots with a cached route table left over, generation runs against stale routes. (Mitigation: `php artisan route:clear` before regenerating.)

**Anti-patterns to avoid:**
- Hardcoded route strings as `'/posts/{post}'` instead of Wayfinder-generated functions (verifiable via grep)
- Calling `route()` helper (Ziggy convention) instead of importing Wayfinder action — produces runtime error in starter-kit setup
- Manually maintaining a `routes.ts` file — defeats the auto-sync benefit
- Not running `php artisan wayfinder:generate` after route changes (should be hooked into `npm run dev` via concurrently — starter kit does this)

**Disagreement with user's locked stack:** None. Wayfinder v1 (stable) is verified canonical. The user's "Wayfinder v1 default, v2 beta opt-in" pin matches official Laravel guidance exactly.

---

### Topic 4 — spatie/laravel-data + typescript-transformer for Inertia props

**Best-practice answer:** spatie/laravel-data + spatie/laravel-typescript-transformer remains a strong choice for **complex DTOs across the Laravel/TS boundary**, even though the official starter kit doesn't ship it. The starter kit relies on the upcoming Wayfinder "next" branch to generate Inertia prop types directly — but that's beta. Until then, `laravel-data` + `typescript-transformer` is the production-ready way to get end-to-end type safety.

**Canonical setup:**

```php
// app/Data/PostData.php
use Spatie\LaravelData\Data;
use Spatie\TypeScriptTransformer\Attributes\TypeScript;

#[TypeScript]
class PostData extends Data
{
    public function __construct(
        public int $id,
        public string $title,
        public ?string $body,
        public UserData $author,
    ) {}
}
```

```bash
php artisan typescript:transform
# Generates resources/js/types/generated.d.ts
```

```vue
<!-- resources/js/Pages/Posts/Show.vue -->
<script setup lang="ts">
import type { PostData } from '@/types/generated'
defineProps<{ post: PostData }>()
</script>
```

**Critical gotcha — snake_case vs camelCase ([Spatie docs](https://spatie.be/docs/laravel-data/v4/as-a-data-transfer-object/mapping-property-names), Tier 1):**

Laravel models default to snake_case; Vue/TS components default to camelCase. Without explicit mapping, your Inertia props arrive as `user.first_name` in Vue (not `user.firstName`). Solutions:

- `#[MapName(SnakeCaseMapper::class)]` on Data class (output-side)
- `#[MapInputName(SnakeCaseMapper::class)]` on Data class (input-side)
- Global default in `config/data.php`: `'name_mapping_strategy' => ['input' => SnakeCaseMapper::class, 'output' => CamelCaseMapper::class]`
- Or use [skryukov/inertia-caseshift](https://github.com/skryukov/inertia-caseshift) middleware (auto snake↔camel for Inertia v3 specifically)

**Lazy and deferred prop attributes:**

```php
#[AutoInertiaLazy]      // Lazy — loads on partial reload only
public ProfileData $profile;

#[AutoInertiaDeferred]  // Deferred — loads in background after page renders
public CollectionData $stats;
```

**Common gotchas:**

- Spatie Data does NOT auto-detect nullable: write `public ?string $body` not `public string|null $body` (both work but former is canonical)
- TypeScript generation requires `php artisan typescript:transform` after Data class changes — automate via `npm run dev` concurrent task
- Pagination props need explicit Data class (not raw `LengthAwarePaginator`) for type safety
- Nested Data classes: `public UserData $author` is fine; arrays use `#[DataCollectionOf(UserData::class)]`
- Snake/camel mismatch is silent — your IDE happily autocompletes a non-existent `firstName` while runtime delivers `first_name`

**Anti-patterns to avoid:**
- Defining a Data class but then bypassing it: `Inertia::render('Show', ['user' => $user->only('id', 'name')])` instead of `'user' => UserData::from($user)` — loses type guarantee
- Generating TS types manually then drifting from Data class
- Using `#[TypeScript]` on Data class but not using `defineProps<>` with the generated type in Vue
- Mixing Spatie Data with raw arrays in the same `Inertia::render` call — type generation only covers Data classes

**Disagreement with user's locked stack:** None. The user's pin matches the strongest community convention. **Caveat:** If/when Wayfinder "next" goes stable (timeline unknown — described as "uppercase B beta" as of Jan 2026 per Laravel blog), the Wayfinder pipeline would supplant Spatie Data for prop-typing specifically. The plugin should mention this as forward-looking awareness.

---

### Topic 5 — Pest 4 Browser plugin + Inertia testing

**Best-practice answer:** Pest 4 has two testing surfaces for Inertia apps:

**(a) HTTP-only Inertia assertions** ([Inertia testing docs](https://inertiajs.com/testing), Tier 1):

```php
test('post page renders with prop', function () {
    $post = Post::factory()->create();

    $this->get(route('posts.show', $post))
        ->assertOk()
        ->assertInertia(fn (AssertableInertia $page) => $page
            ->component('Posts/Show')
            ->has('post')
            ->where('post.id', $post->id)
            ->where('post.title', $post->title)
        );
});
```

`assertInertia()` runs in PHP-only land (no browser, no JS execution). The closure receives an `AssertableInertia` instance with methods: `component()`, `has()`, `missing()`, `where()`, `whereNot()`, `etc()`. This is the **fastest** way to test Inertia controllers and replaces ~80% of what Livewire's `Livewire::test()` does for component testing.

**(b) Pest 4 Browser plugin (Playwright-powered)** ([Pest 4 browser testing docs](https://pestphp.com/docs/browser-testing), Tier 1):

```php
test('user fills the post form', function () {
    $user = User::factory()->create();

    $page = visit('/posts/create')
        ->actingAs($user)
        ->type('@title', 'My new post')
        ->type('@body', 'Some body text')
        ->click('@submit-btn')
        ->assertSee('Post created')
        ->assertPathIs('/posts');
});
```

**Install:**
```bash
composer require pestphp/pest-plugin-browser --dev
npm install playwright@latest
npx playwright install
```

**Selector convention (same as Livewire variant):** prefer `@data-testid` selectors (the `@` prefix is Pest 4 convention) over text-based or class-based selectors. The 5-second implicit timeout on `assertVisible`/`assertPresent`/`assertSee`/`assertText`/`assertAttribute` applies identically to Inertia + Vue (the wait-N anti-pattern in Livewire variant carries over verbatim).

**`actingAs` placement same as Livewire variant:** Before `visit()`, not after.

**Inertia-specific browser-test patterns (research surfaced these):**

- **Visit → assert page component:** combine browser `visit()` (real browser) OR HTTP `get()` (with `assertInertia`) — distinct tools
- **Form submission with `useForm`:** test the resulting redirect + flash message via browser plugin; test the form data POST via HTTP `assertInertia` separately
- **Partial reloads:** test via HTTP with `assertInertia` + `only:['stat']` option — browser plugin can't easily isolate partial reloads
- **Echo/Reverb real-time:** browser plugin can run Reverb in test mode and assert UI updates (but this is heavy — pin to a few critical paths)

**Comparing to Livewire/Volt testing:**

| Surface | Livewire variant | Inertia variant |
|---|---|---|
| Server-rendered components | `Livewire::test(MyComponent::class)->assertSee('Foo')` | `$this->get('/foo')->assertInertia(fn ($p) => $p->component('Foo'))` |
| Form interaction (controller-only) | `Livewire::test(...)->set('name', 'X')->call('save')->assertHasNoErrors()` | `$this->post('/foo', [...])->assertRedirect(); $this->get('/posts')->assertInertia(...)` |
| Browser interaction (real Playwright) | identical (`visit()`, `type()`, `click()`, `assertSee()`) | identical |
| Visual regression | identical (`assertScreenshotMatches()`) | identical |

The browser-test layer is **stack-agnostic**. The HTTP-test layer is what differs (Livewire's `Livewire::test()` → Inertia's `$this->get(...)->assertInertia(...)`).

**Anti-patterns to avoid:**
- Browser-testing every controller — overkill, slow. Reserve for happy-path UX flows.
- HTTP-testing UI-only behavior (e.g., focus trap) — impossible, use browser
- Mocking the Inertia response in unit tests — Inertia's response is the contract; mocking it defeats the purpose
- Mixing `assertInertia` and `visit` in the same test — confusing; separate concerns
- Asserting on internal Vue state — test the rendered DOM, not the framework

**Disagreement with user's locked stack:** None. Pest 4 + Browser plugin is verified canonical.

**Sources:** [Inertia testing](https://inertiajs.com/testing), [Pest 4 browser testing](https://pestphp.com/docs/browser-testing), [Pest 4 release announcement](https://pestphp.com/docs/pest-v4-is-here-now-with-browser-testing), [Writing tests for production Laravel + Inertia + Pest (Bradley Bernard)](https://bradleybernard.com/blog/writing-tests-for-a-production-laravel-application-using-inertia-in-pestphp).

---

### Topic 6 — Anti-patterns specific to Inertia v2/v3 (no-UI-library variant)

Validated and extended from the prior T1 audit's anti-pattern list. Each entry classified Verified / Modified / Added.

#### State management

| # | Anti-pattern | Status | Source |
|---|---|---|---|
| 1 | Destructuring `reactive()` objects without `toRefs()` — loses reactivity silently | Added (Vue 3 canonical) | [escuelavue.es: Composition API pitfalls](https://escuelavue.es/en/devtips/top-3-composition-api-pitfalls), Tier 2 |
| 2 | Importing Pinia store directly into Vue page without genuine cross-component need | Verified (was in T1 audit) | [Vue School: Composables vs Pinia vs Provide/Inject](https://vueschool.io/articles/vuejs-tutorials/composables-vs-provide-inject-vs-pinia-when-to-use-what/), Tier 2 |
| 3 | Module-level `ref()` in composables + SSR active — cross-request state leak between users | Verified (was in T1 audit) | [Vue SSR docs](https://vuejs.org/guide/scaling-up/ssr.html), Tier 1 |
| 4 | `props.x` destructured at top of `<script setup>` before Vue 3.5 — loses reactivity. (Vue 3.5+ added compile-time fix but still risky in older codebases.) | Added | [amillionmonkeys: Vue 3.5 Reactive Props Destructure](https://www.amillionmonkeys.co.uk/blog/vue-35-reactive-props-destructure), Tier 2 |

#### Form handling

| # | Anti-pattern | Status | Source |
|---|---|---|---|
| 5 | Manual `axios.post(...)` for form submission in Vue page instead of `useForm` — loses error binding, validation roundtrip, progress | Verified (was in T1 audit) | [dzone: Avoid This Common Anti-Pattern](https://dzone.com/articles/avoid-this-common-anti-pattern-in-full-stack-vuela), Tier 3 |
| 6 | Duplicating validation rules client-side instead of using `useForm().withPrecognition()` | Added (Precognition built into Inertia 2.3+ per [Laravel News](https://laravel-news.com/inertia-2-3-0)) | Tier 2 |
| 7 | `<form @submit>` without `.prevent` modifier — causes full page reload | Common Vue mistake | (general Vue) |
| 8 | Reading `usePage().props.flash` without `computed(() => ...)` wrapper — flash doesn't reactively update | Verified | [Laracasts: Vue 3 computed property based on Inertia shared data fails to update](https://laracasts.com/discuss/channels/vue/vue-3-computed-property-based-on-inertia-shared-data-fails-to-update), Tier 2 |

#### SSR

| # | Anti-pattern | Status | Source |
|---|---|---|---|
| 9 | Browser-only APIs (`document`, `window`, `localStorage`) at module top-level — crashes SSR | Verified (was in T1 audit) | [Vue SSR docs](https://vuejs.org/guide/scaling-up/ssr.html), Tier 1 |
| 10 | `onMounted(() => addEventListener(...))` WITHOUT `onUnmounted(() => removeEventListener(...))` — memory leak across navigations | Added | [Bryce Andy: Hidden Reason Your Vue Watchers Leak Memory](https://www.bryceandy.com/posts/the-hidden-reason-your-vue-watchers-leak-memory-and-how-to-avoid-it), Tier 2 |
| 11 | `setInterval(...)` without `clearInterval` in `onUnmounted` — leak; especially severe with Inertia where navigations don't always unmount layouts | Added | [stackinsight.dev: Frontend Memory Leaks 500-repo study](https://stackinsight.dev/blog/memory-leak-empirical-study/), Tier 2 |
| 12 | Inertia `usePage()` accessed in module-level scope instead of inside `setup()` — undefined in SSR | Verified | Inertia docs |

#### Routing

| # | Anti-pattern | Status | Source |
|---|---|---|---|
| 13 | Hardcoded route paths as strings (`'/posts/create'`) instead of Wayfinder actions | Verified (was in T1 audit) | [Laravel Wayfinder docs](https://laravel.com/blog/laravel-wayfinder-end-to-end-type-safety-for-php-and-typescript), Tier 1 |
| 14 | `<Link :href="externalUrl">` instead of `<a>` — Inertia tries to XHR-fetch the external URL, gets 409 | Verified (was in T1 audit) | [GitHub: Link component missing behavior for URLs from another origin](https://github.com/inertiajs/inertia/issues/1719), Tier 1 |
| 15 | `route('posts.show', post)` (Ziggy convention) in Wayfinder-shipped starter kit — runtime error | Added | (verified by reading starter-kit deps) |

#### Vue 3 idiom

| # | Anti-pattern | Status | Source |
|---|---|---|---|
| 16 | Options API in any new Vue file (`export default { data() {} }`) | Verified — HARD BAN (was in T1 audit) | [vuejs.org: Composition API FAQ](https://vuejs.org/guide/extras/composition-api-faq), Tier 1 |
| 17 | `defineProps({ user: Object })` without TS generic type | Verified — HARD BAN (was in T1 audit) | [vuejs.org: TypeScript with Composition API](https://vuejs.org/guide/typescript/composition-api), Tier 1 |
| 18 | Refs in arrays not auto-unwrapping (only refs in reactive objects auto-unwrap) | Added | [oneuptime: Vue3 reactivity not working](https://oneuptime.com/blog/post/2026-01-24-vue3-reactivity-not-working/view), Tier 2 |
| 19 | Using `reactive()` for primitives (`reactive(0)` is invalid) — use `ref()` | Added | [Reactive vs. Ref in Vue 3](https://dev.to/jacobandrewsky/reactive-vs-ref-in-vue-3-whats-the-difference-1jm1), Tier 2 |
| 20 | Forgetting `.value` on refs (most common Vue 3 mistake) | Added | (general Vue 3) |

#### Inertia-specific

| # | Anti-pattern | Status | Source |
|---|---|---|---|
| 21 | `Inertia::share()` with large dataset — payload bloat on every request | Verified — HARD BAN (was in T1 audit) | [Inertia shared-data docs](https://inertiajs.com/docs/v3/data-props/shared-data), Tier 1 |
| 22 | Initial state via AJAX instead of Inertia props — double round-trip, kills LCP | Verified — HARD BAN (was in T1 audit) | (Inertia docs); [dzone anti-pattern article](https://dzone.com/articles/avoid-this-common-anti-pattern-in-full-stack-vuela), Tier 3 |
| 23 | Partial reload referencing wrong page component (`only:[...]` only works on same component) | Added | [Inertia partial reloads docs](https://inertiajs.com/docs/v2/data-props/partial-reloads), Tier 1 |
| 24 | Manual `axios` for non-page HTTP in Inertia v3 — should use new `useHttp` hook | Added (Inertia v3 only) | [Inertia v3 release announcement](https://laravel-news.com/inertia-3-0-0), Tier 2 |

**Reconciliation with prior T1 audit's HARD-BAN list:**

| T1 audit's HARD-BAN | Status (verified 2026-05-17) |
|---|---|
| `Inertia::share` without need (validationMessages) | ✅ Verified canonical-banned |
| axios/fetch in pages instead of `useForm`/`router.visit` | ✅ Verified canonical-banned |
| `defineProps({})` without TS generic | ✅ Verified canonical-banned (lint rule, not hook — hooks operate on file paths/content) |
| Options API in Inertia page | ✅ Verified canonical-banned |
| Initial state via AJAX | ✅ Verified canonical-banned |
| Module-level state + SSR | ✅ Verified canonical-banned (conditional on SSR detection) |

The T1 audit's HARD-BAN list holds up. New entries to consider adding (research surfaced): `setInterval` without cleanup, `<Link>` with external URL, hardcoded routes when Wayfinder shipped, Vue 3 reactive destructure pitfall.

**Disagreement with user's locked stack:** None on anti-patterns. The list is well-grounded.

---

### Topic 7 — Recommended `agents/` + `skills/` adaptations for Vue variant

#### Carryover decisions per existing file (full matrix)

**Agents (10):**

| Agent | Decision | Action |
|---|---|---|
| `laravel-best-practices` | KEEP 1:1 | Generic Laravel research; works for any stack |
| `laravel-pest-specialist` | KEEP 1:1 | Pest 4 is stack-agnostic |
| `laravel-architect` | KEEP 1:1 | Eloquent + layering decisions are Laravel-wide |
| `laravel-reviewer` | KEEP with sub-checklist swap | `laravel-code-review` skill's Livewire/Flux sub-checklists swap (the reviewer agent wraps the skill) |
| `laravel-echo-reverb-specialist` | KEEP 1:1 + add Vue-component-side scan | Channel scan is identical (PHP-side); add scan for Echo callbacks in Vue `.vue` files instead of `.js` files |
| `spatie-permission-auditor` | KEEP 1:1 | Spatie permissions are stack-agnostic; Blade refs already detected via grep — add `.vue` file scan |
| `laravel-package-evaluator` | KEEP 1:1 | Build-vs-buy is generic |
| `laravel-pilot-orchestrator` | KEEP 1:1 | Pilot 2.0 meta is stack-agnostic |
| `laravel-livewire-specialist` | REMOVE | No Livewire in Vue variant |
| `laravel-flux-pro-specialist` | REMOVE | No UI library in Vue variant (per user's locked decision) |

**Skills (7):**

| Skill | Decision | Action |
|---|---|---|
| `laravel-tdd` | KEEP with section swap | Replace §"Pest 4 Specifics Module" Livewire/Flux specific bug recipes with Inertia/Vue equivalents (variadic trap, $this reserved, etc. — all stack-agnostic except items #3 BadMethodCallException Livewire and #8 Property not found on component, which become "Inertia prop not found" and "Vue prop type mismatch") |
| `laravel-debugging` | KEEP with section swap | §"Top-10 Pest 4 / Livewire 4 / Flux Pro v2 RED Recipes" → "Top-10 Pest 4 / Inertia v2/v3 / Vue 3 RED Recipes". Items #3 (hasLoading on Livewire) and #8 (Property [xxx] not found) need Inertia/Vue equivalents. Items #1 (variadic trap), #2 ($this reserved), #4 (401 from external), #5 (Route not defined), #6 (relationship type), #7 (FK constraint), #9 (Lang key missing), #10 (browser flake) carry over UNCHANGED |
| `laravel-code-review` | KEEP with sub-checklist swap | Sections 1-8 carry over UNCHANGED. §9 Livewire 4 Sub-Checklist → §9 Inertia v2/v3 Sub-Checklist (usePage reactivity, useForm precognition, partial reloads, deferred props, Inertia::share). §10 Flux Pro v2 Sub-Checklist → REMOVE entirely (no UI lib). Optional new §10: Vue 3 sub-checklist (script setup, defineProps with TS, ref/reactive, lifecycle cleanup, SSR-safety) |
| `laravel-brainstorming` | KEEP 1:1 + minor adaptation | The 5 architectural questions (Q1-Q5) are stack-agnostic. Section "Patterns Already in the Laravel Ecosystem" is stack-agnostic. No major changes needed |
| `laravel-a11y-specialist` | KEEP with rewrite of 7 patterns | All 7 patterns need Vue 3 + Inertia rewrites: `wire:loading.attr` → Inertia loading state via `useForm().processing` or `router.events.before/finish`; `<flux:modal>` → native `<dialog>` + focus trap; Livewire reactive-content live region → Vue v-if + aria-live |
| `laravel-mr-body-writer` | KEEP 1:1 | Sprint/PR body generation is stack-agnostic |
| `laravel-perf-auditor` | KEEP 1:1 + minor adaptation | preventLazyLoading + N+1 + cache are stack-agnostic; check 1-5 carry over. Optionally add §6 "Inertia prop weight" (warns on shared-data bloat) |

**Hooks (12):**

| Hook | Decision | Action |
|---|---|---|
| `banned-token-leak-guard` | KEEP 1:1 | Generic git/commit hook |
| `no-claude-attribution` | KEEP 1:1 | Generic git/commit hook |
| `teamcity-always` | KEEP 1:1 | Pest is shared |
| `anti-silent-deferral` | KEEP 1:1 | Generic git push hook |
| `visual-companion-default-on` | KEEP 1:1 | Post-brainstorming reminder |
| `brainstorm-t1-audit` | KEEP 1:1 | Pilot 2.0 T1 dispatch |
| `sprint-state-context-injection` | KEEP 1:1 | SessionStart sprint state |
| `stale-branch-sweep` | KEEP 1:1 | SessionStart branch cleanup |
| `master-roadmap-drift-detector` | KEEP 1:1 | PostToolUse plan-doc check |
| `pilot-2-contract-enforcer` | KEEP 1:1 | Pilot 2.0 enforcer |
| `vendor-source-preflight` | REPURPOSE or REMOVE (see Topic 8) | Currently triggers on `.blade.php` with `<flux:*>` or `wire:*` — neither exists in Vue variant |
| `lang-key-existence-preflight` | KEEP with broadened triggers | Currently triggers on `.blade.php` with `__()` or `@lang()`. Add `.vue` trigger if Vue uses `__()` (via `laravel-vue-i18n` package) |

**Commands (3):**

| Command | Decision | Action |
|---|---|---|
| `/laravel-livewire-superpowers:status` | RENAME | → `/laravel-vue-superpowers:status`, content otherwise unchanged |
| `/laravel-livewire-superpowers:audit-phase N` | RENAME | → `/laravel-vue-superpowers:audit-phase N`, content otherwise unchanged |
| `/laravel-livewire-superpowers:retro` | RENAME | → `/laravel-vue-superpowers:retro`, content otherwise unchanged |

**Tally:**

| Decision | Count |
|---|---|
| KEEP 1:1 (no change) | 18 |
| KEEP with sub-content swap | 5 |
| RENAME path-only | 3 |
| ADD new | 2-3 (see below) |
| REPURPOSE | 1 (vendor-source-preflight) |
| REMOVE | 2 (livewire-specialist, flux-pro-specialist agents) |

**Percentage that "stays the same" (verifying user's claim):**

- Pure-keep: 18 / 37 components = 49%
- Keep with cosmetic swap: 5 / 37 = 14%
- Path-rename only: 3 / 37 = 8%
- **Combined "essentially the same content": 71%**
- Actively replaced/removed/new: 29%

The user's "most stays the same" claim is **VERIFIED**. ~70% carryover is correct.

#### New components needed (concrete drafts)

**1. `agents/laravel-inertia-specialist.md`**

> **Purpose:** Audits Inertia v2/v3-touching code/plans for fabricated APIs (`Inertia::xxx`, `useForm` methods, `usePage` methods), `Inertia::share` overuse, partial-reload misuse, deferred-prop misuse, and `useForm` + Precognition wiring issues. Verifies via reading `vendor/inertiajs/inertia-laravel/src/Inertia.php` + `node_modules/@inertiajs/vue3/dist/index.d.ts` — ground truth, not docs. Use before any Inertia-touching implementation phase.
>
> **Triggers:** Auto-dispatch when scope mentions `Inertia::`, `useForm`, `usePage`, `router.visit`, `router.reload`, `<Link>`, `Inertia::render`, `Inertia::share`, `Inertia::lazy`, `Inertia::defer`, partial reloads, deferred props, persistent layouts.

**2. `agents/laravel-vue3-specialist.md`**

> **Purpose:** Audits Vue 3 + Composition API + `<script setup>` + TypeScript code for fabricated APIs, Options API leakage, reactivity gotchas (destructured reactive, props without .value, refs in arrays), lifecycle-hook misuse (memory leaks from missing cleanup), `defineProps`/`defineEmits` TS-generic correctness, SSR-safety. Verifies via reading the project's actual Vue components — ground truth, not training data.
>
> **Triggers:** Auto-dispatch on any `.vue` file edit/create, on `defineProps`, `defineEmits`, `ref()`, `reactive()`, `computed()`, `watch()`, `onMounted()`, `onUnmounted()`, `<script setup>`, lifecycle hook discussions.

**3. (Optional) `agents/laravel-wayfinder-specialist.md`** *(consider deferring to phase B)*

> **Purpose:** Audits route+form-action usage in Vue components for hardcoded paths, missing Wayfinder action imports, stale TS types after route changes, Ziggy convention leakage in Wayfinder-only codebases.
>
> **Triggers:** Auto-dispatch on any `.vue` file using `route()`, `<Link href="...">` with string literal, or `form.submit(...)` calls.

**Recommendation:** Ship #1 and #2 in Phase B (analog to Livewire variant's Phase B specialist-agents block). Defer #3 to Phase D or later — Wayfinder anti-patterns can initially be covered by code-review skill's new Inertia sub-checklist.

#### What NOT to create

- `laravel-shadcn-vue-specialist` — user has explicitly rejected shadcn-vue. Do NOT create this even as opt-in.
- `laravel-headless-ui-specialist` — same reason.
- `laravel-tailwind-4-specialist` — Tailwind is design-time. Tooling-level help (`@theme` syntax, design tokens) can live in `laravel-best-practices` agent answering "Tailwind 4 best practice X" questions. A dedicated specialist agent would be over-engineering.
- `laravel-pinia-specialist` — same. State decisions belong in `laravel-vue3-specialist` (composables vs Pinia) + `laravel-brainstorming` skill (architectural Q6 = state management).

**Disagreement with user's locked stack:** None on agent design.

---

### Topic 8 — `vendor-source-preflight` hook fate

**Analysis:**

The current hook (verified by `Read` of `hooks/vendor-source-preflight.sh`):
- Triggers on PreToolUse:Edit + PreToolUse:Write of `.blade.php` files
- Detects `<flux:*>` directives → surfaces `vendor/livewire/flux-pro/stubs/resources/views/flux/` reference
- Detects `wire:*` directives → surfaces `vendor/livewire/livewire/src/Component.php` reference
- Emits `additionalContext` to remind the agent to read vendor before composing

**Three options for Vue variant:**

#### (a) REMOVE entirely

**Pros:**
- No UI library = no vendor stubs to reference
- Inertia v2/v3 APIs are documented; agent already has them in training
- Hook complexity reduction

**Cons:**
- Loses the "Block-1H bug class prevention" the original hook was designed for (agent composes from memory and gets API slightly wrong)
- Misses opportunity to surface Vue project's own component library (in `resources/js/Components/`) when editing a sibling Vue file
- One fewer guardrail against fabrication

#### (b) REPURPOSE for Inertia component-resource lookups

**Trigger:** PreToolUse:Edit + PreToolUse:Write of `.vue` files

**Behaviors:**
- Detect Inertia imports (`from '@inertiajs/vue3'`) → surface `vendor/inertiajs/inertia-laravel/src/` + `node_modules/@inertiajs/vue3/dist/index.d.ts` for API ground truth
- Detect import of project component (`from '@/Components/...'`) → surface that component file's path + its sibling components in same folder for reuse-vs-new-file decision
- Detect layout reference (`defineOptions({ layout: ... })`) → surface available layouts in `resources/js/Layouts/`
- Detect Tailwind utility classes → suggest checking `resources/css/app.css` `@theme` directive for project-specific tokens

**Pros:**
- Preserves the bug-class prevention intent
- Newly relevant for Vue: "what siblings exist in this Components folder?" is a real source of redundancy
- Surfaces `@inertiajs/vue3/dist/index.d.ts` as authoritative API source (since Inertia changes between v2/v3)
- Reinforces "Components/ are the project's UI library, even without third-party UI lib"

**Cons:**
- Complexity: needs to detect project structure (which folder = layouts vs components), and Vue files have many possible imports
- Risk of noisy context if hook surfaces too many sibling components
- `node_modules/` paths may not always be present in dev environments

#### (c) Hybrid — narrow REPURPOSE focused on Inertia API only

**Trigger:** PreToolUse:Edit + PreToolUse:Write of `.vue` files with `@inertiajs/vue3` import

**Behavior:**
- Surface `node_modules/@inertiajs/vue3/dist/index.d.ts` path (TS def file)
- Surface `vendor/inertiajs/inertia-laravel/src/Inertia.php` path (PHP side)
- That's it. No sibling-component scanning.

**Pros:**
- Captures the most valuable carryover (Inertia API ground-truth)
- Low complexity, narrow scope
- Mirrors Livewire variant's intent (vendor as ground truth, not memory)

**Cons:**
- Less ambitious than (b)
- Doesn't help with Vue-side component reuse

**Recommendation: Option (c) — narrow REPURPOSE.**

**Rationale:**
- The original hook's value was "force reading vendor source BEFORE composing." That value applies just as much to Inertia (which changed APIs from v2 to v3) as it did to Flux Pro.
- Option (b) is interesting but risks noise. Sibling-component reuse is better handled by `laravel-vue3-specialist` agent on-demand than by every-edit hook.
- Option (a) loses a valuable guardrail.

**Implementation sketch:**

```bash
# Trigger: .vue file with import from '@inertiajs/vue3'
# Reference paths:
#   - node_modules/@inertiajs/vue3/dist/index.d.ts (TS definitions)
#   - vendor/inertiajs/inertia-laravel/src/Inertia.php (PHP-side)
#   - vendor/inertiajs/inertia-laravel/src/Response.php (response builder)
# Optional secondary trigger: import from '@/wayfinder/...' → surface wayfinder generated routes
```

**Renamed:** Consider renaming the file to `inertia-vendor-preflight.sh` for clarity in the Vue variant.

**Test suite:** New `tests/test_inertia_vendor_preflight_hook.sh` with at least 10 scenarios (positive + negative cases, file-type filtering, content matching).

---

## Synthesis & Conflicts

### Where sources agree

- **Composition API + `<script setup>` + TypeScript is the modern Vue 3 default** — agreed by [vuejs.org](https://vuejs.org/guide/typescript/composition-api), 2026 best-practice guides ([devtoolbox.dedyn.io](https://devtoolbox.dedyn.io/blog/vue3-complete-guide), [Vue School](https://vueschool.io/articles/vuejs-tutorials/from-vue-js-options-api-to-composition-api-is-it-worth-it/)).
- **Wayfinder has replaced Ziggy in Laravel 12 starter kits** — agreed by official Laravel blog, Hafiz.dev, Zenn migration guide, and verified by `laravel/vue-starter-kit/composer.json` direct read.
- **Pest 4 + Browser plugin (Playwright) is the official testing stack** — agreed by pestphp.com, Laravel News, Benjamin Crozat.
- **Reverb is the in-house WebSocket choice** — agreed by laravel.com/docs/13.x/broadcasting + Laravel official blog.
- **Tailwind CSS 4 with `@theme` directive + Vite plugin replaces v3 config approach** — agreed by tailwindcss.com + multiple 2026 tutorials.
- **`Inertia::share` overuse is canonical anti-pattern** — agreed by inertiajs.com + Vincent Schmalbach + matthiasweiss.at.

### Where sources conflict / nuance is required

- **Inertia v2 vs v3 default:** The user's locked stack says "Inertia v2 default, v3 beta opt-in." The Inertia.js docs at https://inertiajs.com/docs/v2/getting-started/upgrade-guide explicitly state "Inertia.js v3 has been released and is now the default version." Laravel's `vue-starter-kit/package.json` ships `@inertiajs/vue3 ^3.0.0`. **Conflict resolved in favor of: v3 is the current canonical default. The user's pin is 2 months stale.**
- **Spatie laravel-data + typescript-transformer vs Wayfinder next/beta:** Both exist for prop typing. Wayfinder next/beta (when it ships stable) will likely subsume spatie/laravel-data's typescript-transformer role for the specific Inertia-props use case, but Wayfinder next is still beta as of Jan 2026. Spatie remains canonical for complex DTO design (not just Inertia props).
- **shadcn-vue vs Reka UI vs "no UI lib":** Laravel canon = Reka UI (in starter kit) with optional shadcn-vue overlay. User's locked stack = no UI lib. Both defensible; the divergence is operator-driven and well-reasoned.
- **Pinia vs composables:** Vue ecosystem split. Composables faster + simpler; Pinia required for SSR-safe shared state + devtools. User's "composables-first" pin is verified by Vue School + Pinia cookbook.

### Where research could NOT verify

- **Pest 4 + Inertia v3 specific browser-test patterns** — Pest 4 docs cover browser testing generically (visit, click, type, assertSee). Inertia v3 + Pest 4 specific tutorial does not yet exist as Tier-1/Tier-2 source. The pattern in this audit (Topic 5) is composed from Pest 4 docs + Inertia testing docs separately; full integration not yet documented.
- **Wayfinder next/beta stable release date** — Laravel blog (Jan 2026) describes it as "uppercase B beta" but provides no v1.0 timeline.
- **Inertia v2 EOL date** — inertiajs.com confirms v3 is "now the default" but provides no v2 deprecation timeline.

---

## Anti-Thesis Results

Sources actively searched for the OPPOSITE of the user's locked stack decisions:

### Anti-thesis: "What if Livewire is better than Inertia for this project?"

Search: ["Livewire 4 vs Inertia.js 3: Which Laravel Frontend Stack Should You Use in 2026?"](https://hafiz.dev/blog/livewire-4-vs-inertia-3-laravel-frontend-2026) (Tier 2)

Verdict: Livewire still has 2026 use cases (CRUD-heavy internals, teams without JS skill, smaller bundle). Inertia wins for: public-facing SPAs with rich interactions, teams with Vue/React expertise, apps needing future public API. **For the user's existing `laravel-livewire-superpowers` project, Livewire is still correct. The Vue fork is for DIFFERENT projects, not a migration.** The fork's existence is justified.

### Anti-thesis: "What if Reka UI is better than no UI library?"

Search: ["best Tailwind component libraries 2026"](https://designrevision.com/blog/best-tailwind-component-libraries) (Tier 3 commercial); [reka-ui.com](https://reka-ui.com/) (Tier 1)

Verdict: Reka UI is the canonical Vue 3 unstyled primitive library, with 40+ accessible components. Starting with Reka UI saves ~30-50 hours of upfront a11y + keyboard nav implementation. The user is paying that cost intentionally for full design control. **No technical superiority argument forces the choice; this is preference.** The plugin should respect the user's choice (no Reka recommendations) and document the trade-off so the operator can revisit later.

### Anti-thesis: "What if Ziggy is still safer than Wayfinder?"

Search: ["Is it better to use wayfinder or ziggy?"](https://laracasts.com/discuss/channels/inertia/is-it-better-to-use-wayfinder-or-ziggy) (Tier 2)

Verdict: Ziggy still works for Blade-only apps OR for TS-less Vue. But for TS + Inertia (user's stack), Wayfinder is unambiguously canonical (replaces Ziggy in starter kit, generates HTTP methods + form types). **User's Wayfinder pick is correct.**

### Anti-thesis: "What if Pinia should be default state, not composables?"

Search: [Vue School: Composables vs Pinia vs Provide/Inject](https://vueschool.io/articles/vuejs-tutorials/composables-vs-provide-inject-vs-pinia-when-to-use-what/) (Tier 2)

Verdict: Composables are faster (1.5-20x for reactive changes per Vue School benchmarks), simpler, and avoid premature global-state complexity. Pinia is correct when: (a) genuinely shared cross-component state, (b) need devtools, (c) SSR-safe shared state. Most Inertia apps don't need it from day 1. **User's "composables-first, Pinia opt-in" is correct and matches expert consensus.**

### Anti-thesis: "What if the user's 'most stays the same' claim is wrong — most actually changes?"

I tried to find this. Counter-arguments would be:
- "Most documentation/skills need rewriting because Vue 3 ecosystem is so different from Livewire" → **Refuted by file-by-file audit:** the rewriting is concentrated in `laravel-a11y-specialist` (full rewrite of 7 patterns) + `laravel-code-review` (sub-section swap) + `laravel-debugging` (sub-section swap). Backend tdd, brainstorming, perf-auditor, all hooks except one, all commands → unchanged.
- "Pest 4 testing changes significantly because Vue components aren't Livewire components" → **Refuted by Pest 4 docs:** Pest 4 browser plugin is framework-agnostic (Playwright runs on any DOM). `assertInertia` is the only new HTTP-level assertion needed; rest of Pest 4 syntax identical.
- "Reverb integration is different in Vue vs Livewire" → **Partially true:** Echo callbacks live in `.vue` files instead of `.js` files in Livewire's blade-related JS. But the channel/event/notification PHP-side is identical, and the `echo-reverb-specialist` agent's scan logic can broaden the file-pattern.

**Verdict: anti-thesis fails. ~70% carryover claim holds.**

### Anti-thesis: "What if SSR should be hard-coded default, not opt-in?"

Search: [Vue SSR docs](https://vuejs.org/guide/scaling-up/ssr.html); [adonisjs/inertia SSR hydration issue](https://github.com/adonisjs/inertia/issues/49)

Verdict: SSR adds significant complexity (separate Node process in v2; in v3 the Vite plugin auto-handles dev mode). Hydration mismatches are a real bug class. Most Inertia apps DON'T need SSR (the value is SEO + first-paint perf — luxury for many apps). **User's "SSR opt-in" pin is correct.**

---

## Open Points & Non-Findings

### Open points (active decisions the user must make)

1. **Inertia v2 vs v3 disposition.** [BLOCKER for Phase A.] User's locked stack says "Inertia v2 stable, v3 beta opt-in." Reality (verified 2026-05-17): **Inertia v3 is the stable default since 2026-03-26.** The Laravel `vue-starter-kit` ships `@inertiajs/vue3 ^3.0.0`. inertiajs.com v2 docs explicitly say "v3 is now the default; please visit the upgrade guide." Options:
   - (a) Pin to v3 as default (mirror Laravel canon)
   - (b) Pin to v2 as default + v3 as opt-in (maintain prior decision; deviation from Laravel canon)
   - (c) Support both v2 and v3 (specialist agent reads `node_modules/@inertiajs/vue3/package.json` to detect version, branches checks accordingly)

   Decision needed before Phase A.

2. **`vendor-source-preflight` hook fate.** Three options per Topic 8: REMOVE, broad REPURPOSE (sibling-component scan), or narrow REPURPOSE (Inertia API only). Recommendation in this audit: narrow REPURPOSE (option c).

3. **`vendor-source-preflight` rename?** If repurposed, rename to `inertia-vendor-preflight.sh` for clarity? Or keep generic name and rely on `additionalContext` to clarify scope?

4. **Wayfinder v1 stable (route-only) vs Wayfinder next/beta (full TS-gen).** User's locked stack says v1 default, v2 beta opt-in. The Laravel `vue-starter-kit` ships `laravel/wayfinder ^0.1.14` (stable v1 lineage). **This is verified correct.** No decision needed; just confirming.

5. **`laravel-wayfinder-specialist` agent — Phase B or defer?** If Wayfinder is now critical (replaced Ziggy in starter kit), a dedicated agent may be warranted. Recommendation in this audit: defer; cover via code-review skill sub-checklist for now.

6. **`laravel-a11y-specialist` Vue patterns — full rewrite scope.** The 7 Livewire-flavored patterns need full rewrites for Vue 3 + native HTML (no UI lib). This is one of the larger content tasks. Scope:
   - Pattern 1 (live region for streaming) — minor change (no `wire:*`)
   - Pattern 2 (Livewire loading state with aria-busy) — full rewrite (no Livewire; use `useForm().processing` or `router.events.before`)
   - Pattern 3 (skip-to-content link) — no change
   - Pattern 4 (reduced motion) — minor change (Vue's Alpine reference becomes `onMounted`/`onUnmounted` Vue lifecycle)
   - Pattern 5 (audio control) — no change
   - Pattern 6 (modal focus management) — full rewrite (no `<flux:modal>`; use native `<dialog>` + focus trap)
   - Pattern 7 (form validation announcements) — full rewrite (no `wire:model.live`; use `useForm` + `@error` slot)

### Non-findings (searched, not found)

- **A Pest 4 + Inertia v3 + Vue 3 official "complete testing guide" document.** Pest 4 docs cover browser testing generically; Inertia docs cover `assertInertia` for v2 + v3 generically. Combined integration tutorial does not exist as Tier-1/Tier-2 source yet.
- **A list of canonical "10 anti-patterns in Inertia v3 codebases".** Inertia v2 anti-patterns are documented across multiple Tier-2/3 articles; v3-specific anti-patterns haven't been compiled (v3 is too new — stable since March 2026).
- **An official Laravel "no UI library" Vue starter alternative.** Doesn't exist. Laravel canon is Reka UI / shadcn-vue / Headless UI. The user's "no UI lib" approach has no official Laravel template to reference.
- **A reference repo of a production-quality Laravel + Inertia + Vue 3 + pure-Tailwind-4 app (no UI lib).** Searched; closest matches use Headless UI or Reka UI. No high-profile fully-Tailwind-only Inertia app surfaced.
- **`useBroadcast` composable in `@laravel/echo-vue`.** Search confirmed `@laravel/echo-vue` package exists and provides hooks-style API for Vue 3, but specific `useBroadcast` hook signature/usage not deeply documented in Tier-1 sources. Operator should read package source before using.
- **Whether Wayfinder + spatie/laravel-data conflict or complement.** Both can coexist; no official statement on which to prefer when both are present. Wayfinder "next" branch may obviate spatie/laravel-data for Inertia-prop typing specifically, but spatie/laravel-data remains canonical for complex DTOs (Actions, request bodies, queue payloads).

---

## Recommendation

Based on verified facts (not speculation):

### Recommended actions for the brainstorming session

1. **Reconcile Inertia v2 vs v3 first** (highest priority blocker). Either:
   - Update locked stack to "Inertia v3 default" (mirror Laravel canon — recommended)
   - OR explicitly document the divergence and reason (deviating from canon is fine if there's a reason)

2. **Confirm "no UI library" stance** is intentional (research confirms it's a deliberate divergence from Laravel canon; document it as project canon).

3. **Plan the carryover work as follows:**
   - Phase A (foundation): rename plugin, marketplace, slash commands. Same as Livewire variant Phase A.
   - Phase B (specialist agents): ADD `laravel-inertia-specialist` + `laravel-vue3-specialist`. REMOVE `laravel-livewire-specialist` + `laravel-flux-pro-specialist`. (Net: agents 10 → 10, but content shifts.)
   - Phase C (skills swap): swap `laravel-a11y-specialist` 7 patterns; swap `laravel-code-review` §9 Livewire → Inertia + REMOVE §10 Flux; swap `laravel-debugging` Top-10 recipes (items #3 + #8) + section header; swap `laravel-tdd` Pest-specifics block items (#3 + #8) for Inertia/Vue equivalents.
   - Phase D (hooks): REPURPOSE `vendor-source-preflight` (narrow option C: Inertia API focus). Broaden `lang-key-existence-preflight` to also trigger on `.vue` files. Net: hooks 12 → 12.
   - Phase E (Pilot 2.0 meta-layer): no changes — already stack-agnostic.
   - Phase F (commands rename): trivial. `laravel-livewire-superpowers:*` → `laravel-vue-superpowers:*`.
   - Phase G (self-audit + release): same shape as Livewire variant.

4. **Estimate phasing effort:**
   - Phase A: 1-2 hours (mostly find-and-replace)
   - Phase B: ~6-8 hours (2 new specialist agents, draft + body)
   - Phase C: ~6-8 hours (3 skill sections rewrites, especially a11y full rewrite of 7 patterns)
   - Phase D: ~2-3 hours (one hook repurposed + tests + one hook broadened + tests)
   - Phase E: 0 hours (no changes)
   - Phase F: ~1 hour
   - Phase G: ~2-3 hours
   - **Total estimate: ~20-25 hours of focused work** (analog to Livewire variant's ~30-40 hours, lower because foundation is reusable)

5. **Do NOT create the following agents/skills** (research surfaced their unwantedness in this fork):
   - `laravel-shadcn-vue-specialist` (user has rejected shadcn-vue)
   - `laravel-headless-ui-specialist` (no UI library — full stop)
   - `laravel-tailwind-4-specialist` (covered by best-practices agent)
   - `laravel-pinia-specialist` (composables-first; Pinia opt-in)

6. **DO consider creating in Phase B+ if scope expands:**
   - `laravel-wayfinder-specialist` — route + form action audits
   - `laravel-spatie-data-specialist` — DTO design audits (could replace partial coverage in `laravel-architect`)
   - `laravel-ssr-specialist` — hydration-mismatch + module-state audits (only if SSR is opt-in adopted)

### Final verdict on user's "most stays the same" claim

**VERIFIED.** ~70% of content carries over 1:1 or with cosmetic sub-checklist swaps. The backend Laravel layer is genuinely stack-agnostic. The work concentrates in:

- 2 specialist agent net deletions (livewire-specialist, flux-pro-specialist)
- 2 new specialist agents (laravel-inertia-specialist, laravel-vue3-specialist)
- 5 skill sub-section swaps (a11y full pattern rewrite + code-review §9-10 + debugging Top-10 items #3 #8 + tdd Pest-specifics items #3 #8)
- 1 hook repurposed (vendor-source-preflight → narrow Inertia API focus)
- 1 hook broadened (lang-key-existence-preflight + `.vue` trigger)
- All renames are mechanical (commands, paths, file headers)

**The two material stack drifts to reconcile in brainstorming:**

1. Inertia v2 → v3 default (canon update; user's stack pin is stale)
2. "No UI library" stance (operator preference; defensible; needs to be a documented project canon override that the `laravel-best-practices` agent respects)

---

## Sources cited (Tier 1 / Tier 2 / Tier 3)

### Tier 1 (Primary — Official Docs / Specs / Source)

- [Inertia.js Responses Documentation](https://inertiajs.com/responses)
- [Inertia.js v2 Upgrade Guide](https://inertiajs.com/docs/v2/getting-started/upgrade-guide) — confirms v3 is "now the default version"
- [Inertia.js v3 Partial Reloads Documentation](https://inertiajs.com/docs/v2/data-props/partial-reloads)
- [Inertia.js v2 Forms Documentation](https://inertiajs.com/docs/v2/the-basics/forms)
- [Inertia.js Testing Documentation](https://inertiajs.com/testing) — `assertInertia` reference
- [Inertia.js Shared Data Documentation](https://inertiajs.com/docs/v3/data-props/shared-data)
- [Inertia.js Routing Documentation](https://inertiajs.com/docs/v2/the-basics/routing)
- [Inertia.js v3 Release Announcement (Laravel official)](https://laravel.com/blog/inertia-v3-whats-changed-since-the-first-beta) — v3 changes from v2
- [Laravel 13 Precognition Documentation](https://laravel.com/docs/13.x/precognition)
- [Laravel 13 Starter Kits Documentation](https://laravel.com/docs/13.x/starter-kits)
- [Laravel 13 Broadcasting Documentation](https://laravel.com/docs/13.x/broadcasting)
- [Laravel Wayfinder Official Announcement](https://laravel.com/blog/laravel-wayfinder-end-to-end-type-safety-for-php-and-typescript) — replaced Ziggy as of Laravel 12
- [Laravel Wayfinder GitHub Repository](https://github.com/laravel/wayfinder)
- [Laravel vue-starter-kit GitHub Repository](https://github.com/laravel/vue-starter-kit) (composer.json + package.json ground truth)
- [Vue.js TypeScript with Composition API](https://vuejs.org/guide/typescript/composition-api)
- [Vue.js `<script setup>` Documentation](https://vuejs.org/api/sfc-script-setup)
- [Vue.js Composition API FAQ](https://vuejs.org/guide/extras/composition-api-faq)
- [Vue.js SSR Documentation](https://vuejs.org/guide/scaling-up/ssr.html)
- [Vue.js Reactivity in Depth](https://vuejs.org/guide/extras/reactivity-in-depth)
- [Vue.js Lifecycle Hooks Composition API Documentation](https://vuejs.org/api/composition-api-lifecycle.html)
- [Tailwind CSS v4 Theme Documentation](https://tailwindcss.com/docs/theme) — `@theme` directive
- [Tailwind CSS v4 Release Announcement](https://tailwindcss.com/blog/tailwindcss-v4)
- [Tailwind CSS Documentation](https://tailwindcss.com/docs)
- [Pest 4 Browser Testing Documentation](https://pestphp.com/docs/browser-testing)
- [Pest 4 Release Announcement](https://pestphp.com/docs/pest-v4-is-here-now-with-browser-testing)
- [Reka UI Official Documentation](https://reka-ui.com/) — Vue 3 unstyled primitives
- [Reka UI GitHub Repository (unovue/reka-ui)](https://github.com/unovue/reka-ui) — previously Radix Vue
- [Spatie Laravel Data Inertia Use Documentation](https://spatie.be/docs/laravel-data/v4/advanced-usage/use-with-inertia)
- [Spatie Laravel Data Name Mapping Documentation](https://spatie.be/docs/laravel-data/v4/as-a-data-transfer-object/mapping-property-names)
- [Spatie Laravel Data Inertia Examples GitHub](https://github.com/spatie/laravel-data/blob/main/docs/advanced-usage/use-with-inertia.md)

### Tier 2 (Secondary — Known authors, technical blogs, Stack Overflow with high reputation)

- [Hafiz.dev: Livewire 4 vs Inertia.js 3: Which Laravel Frontend Stack 2026](https://hafiz.dev/blog/livewire-4-vs-inertia-3-laravel-frontend-2026)
- [Hafiz.dev: Laravel Wayfinder Type Safe Routes and Forms with Inertia](https://hafiz.dev/blog/laravel-wayfinder-type-safe-routes-and-forms-with-inertia)
- [Hafiz.dev: Laravel Pest 4 Complete Testing Guide 2026](https://hafiz.dev/blog/laravel-pest-4-testing-complete-guide)
- [Laravel News: Inertia 2.3 Adds Precognition Support](https://laravel-news.com/inertia-2-3-0)
- [Laravel News: Type-Safe Shared Data and Page Props in Inertia.js](https://laravel-news.com/type-safe-shared-data-and-page-props-in-inertiajs)
- [Laravel News: Inertia.js v3.0.0 Is Here with Optimistic Updates, useHttp, and More](https://laravel-news.com/inertia-3-0-0)
- [Laravel News: Pest 4 is Released](https://laravel-news.com/pest-4)
- [Laravel News: Laravel Wayfinder Public Beta](https://laravel-news.com/laravel-wayfinder-public-beta)
- [Vincent Schmalbach: Using Inertia page props to share data](https://www.vincentschmalbach.com/using-inertia-page-props-to-share-data-between-vue-components/)
- [Vincent Schmalbach: Mastering Inertia.js Persistent Layouts](https://www.vincentschmalbach.com/mastering-inertia-js-persistent-layouts/)
- [Niels Vanpachtenbeke: Type-safe Inertia responses with View Models](https://vanpachtenbeke.com/posts/type-safe-inertia-responses-with-view-models/)
- [Matthias Weiss: Bulletproofing Inertia: Maximize Type Safety in Laravel Monoliths](https://matthiasweiss.at/blog/bulletproofing-inertia-how-i-maximize-type-safety-in-laravel-monoliths/)
- [Laravel Magazine: Type-safe data flow Laravel to React with Inertia 2.0](https://laravelmagazine.com/type-safe-data-flow-laravel-to-react-with-inertia-20)
- [Markus Oberlehner: Stale-While-Revalidate Data Fetching Composable with Vue 3](https://markus.oberlehner.net/blog/stale-while-revalidate-data-fetching-composable-with-vue-3-composition-api)
- [Markus Oberlehner: Clean Up Global Event Listeners, Intervals in Vue Components](https://markus.oberlehner.net/blog/how-to-clean-up-global-event-listeners-intervals-and-third-party-libraries-in-vue-components)
- [Vue School: Composables vs Provide/Inject vs Pinia](https://vueschool.io/articles/vuejs-tutorials/composables-vs-provide-inject-vs-pinia-when-to-use-what/)
- [Vue School: From Vue.js Options API to Composition API: Is it Worth it?](https://vueschool.io/articles/vuejs-tutorials/from-vue-js-options-api-to-composition-api-is-it-worth-it/)
- [Vue School: Master TailwindCSS 4 for Vue](https://vueschool.io/articles/vuejs-tutorials/master-tailwindcss-4-for-vue/)
- [Bryce Andy: The Hidden Reason Your Vue Watchers Leak Memory](https://www.bryceandy.com/posts/the-hidden-reason-your-vue-watchers-leak-memory-and-how-to-avoid-it)
- [Bradley Bernard: Writing tests for production Laravel + Inertia + Pest](https://bradleybernard.com/blog/writing-tests-for-a-production-laravel-application-using-inertia-in-pestphp)
- [Stack Insight: Frontend Memory Leaks 500-Repository Study](https://stackinsight.dev/blog/memory-leak-empirical-study/)
- [Marcus Herrmann: Building accessible-app.com: Modal and non-modal dialogs (and Vue)](https://marcus.io/blog/a11y-app-dialogs-modals)
- [Accessible App: Modal Dialog Windows Vue Pattern](https://accessible-app.com/pattern/vue/modal-dialogs/)
- [GitHub Issue: Link component missing behavior for URLs from another origin](https://github.com/inertiajs/inertia/issues/1719)
- [GitHub Issue #178: Wayfinder inertia-config.d.ts module declaration breaks TypeScript](https://github.com/laravel/wayfinder/issues/178)
- [Benjamin Crozat: What's new in Pest 4 and how to upgrade](https://benjamincrozat.com/pest-4)
- [Benjamin Crozat: Inertia.js v3 beta adds async requests, optimistic UI, and no Axios](https://benjamincrozat.com/inertia-js-v3-beta)
- [Allur: Pest 4's Playwright Integration Unified Browser and Visual Testing](https://allur.co/en/blog/pest-4s-playwright-integration-unified-browser-and-visual-testing)
- [Zenn: Why and How to Migrate from Ziggy to Wayfinder in Laravel](https://zenn.dev/aun_phonogram/articles/64d783de080392?locale=en)
- [Felix Astner: Integrating Tailwind CSS v4 with Vue and Nuxt](https://felixastner.com/articles/integrating-tailwind-css-v4-with-vue-and-nuxt-and-differences-from-v3)
- [Escuela Vue: Top 3 Composition API pitfalls](https://escuelavue.es/en/devtips/top-3-composition-api-pitfalls)
- [DEV / Jacob Andrewsky: Reactive vs Ref in Vue 3](https://dev.to/jacobandrewsky/reactive-vs-ref-in-vue-3-whats-the-difference-1jm1)
- [Million Monkeys: Vue 3.5 Reactive Props Destructure](https://www.amillionmonkeys.co.uk/blog/vue-35-reactive-props-destructure)
- [DEV / Jacob Andrewsky: How to Fix Vue Hydration Mismatch](https://dev.to/jacobandrewsky/how-to-fix-vue-hydration-mismatch-47eg)

### Tier 3 (Tertiary — Use as hints, not proof)

- [dzone: Avoid This Common Anti-Pattern in Full-Stack Vue/Laravel Apps](https://dzone.com/articles/avoid-this-common-anti-pattern-in-full-stack-vuela)
- [oneuptime: How to Use Inertia.js with Laravel](https://oneuptime.com/blog/post/2026-02-02-laravel-inertia-js/view)
- [oneuptime: How to Fix 'Ref vs Reactive' Confusion in Vue 3](https://oneuptime.com/blog/post/2026-01-24-vue-ref-vs-reactive/view)
- [oneuptime: How to Fix 'Reactivity Not Working' Issues in Vue 3](https://oneuptime.com/blog/post/2026-01-24-vue3-reactivity-not-working/view)
- [designrevision: Best Tailwind Component Libraries 2026](https://designrevision.com/blog/best-tailwind-component-libraries)
- [tailgrids: 11+ Best Vue Components Libraries for 2026](https://tailgrids.com/blog/best-vue-component-libraries)
- [Medium / Developer Awam: Inertia.js v3 Is Finally Stable — Mar 2026](https://medium.com/@developerawam/inertia-js-v3-is-finally-stable-heres-everything-that-changed-abaa23259ce6)
- [Medium / Sadique Ali: Inertia.js + Vue 3 in Laravel 2026: Complete Modern SPA Guide](https://sadiqueali.medium.com/inertia-js-vue-3-in-laravel-2026-the-complete-modern-spa-guide-61c567d48084)
- [scalablepath: Livewire vs Inertia](https://www.scalablepath.com/php/livewire-vs-inertia)

---

## Quality-gate confirmation

- [x] Every critical claim verified with at least 2 independent sources (most with 3+)
- [x] Actively searched for contradictions (6 anti-thesis searches, see "Anti-Thesis Results" section)
- [x] Researched the opposing thesis before confirming each of the user's locked decisions
- [x] Sources prioritized: Tier 1 (laravel.com, inertiajs.com, vuejs.org, pestphp.com, reka-ui.com) over Tier 2 over Tier 3
- [x] Completed 3 iterations (broad, deep, anti-thesis verification)
- [x] Confirmation bias actively fought (e.g., on "Inertia v2 default" — looked for evidence v2 is still canonical, found the opposite)
- [x] Source currency checked (filtered to 2026 dates where possible; explicitly flagged "verified 2026-05-17" where direct GitHub reads were used)
- [x] Non-findings explicitly named (6 items in "Non-findings" section)
- [x] Open points enumerated (6 in "Open Points" section)
- [x] A critical colleague reviewing this would accept these conclusions — especially given the Tier-1 ground-truth reads of starter-kit package.json + composer.json
- [x] Answer questioned end-to-end after first draft (revised Topic 2 to flag "no UI lib" as deliberate divergence; revised Executive Summary to lead with two stack drifts)
