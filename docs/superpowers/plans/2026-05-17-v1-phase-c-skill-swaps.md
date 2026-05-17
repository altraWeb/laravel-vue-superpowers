# V1 Phase C — Skill Sub-Section Swaps — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development.

**Goal:** Swap the Livewire-flavored sub-sections inside 4 skills with Vue 3 + Inertia v3 + Reka UI equivalents. Ship as v1.0.0-alpha.3.

**Architecture:** Skills are markdown SKILL.md files. Sub-section swap = find specific Livewire-named sections, replace with semantically-equivalent Vue/Inertia content. Other parts of each skill (Pre-flight, generic Laravel checks, output template) carry over unchanged.

**Spec:** `docs/superpowers/specs/2026-05-17-vue-fork-adaptation-design.md` Section 5 Phase C + Section 4 Carryover Matrix.

**Reference:** `docs/superpowers/audits/2026-05-17-vue-fork-deep-research.md` for canonical Vue/Inertia patterns + anti-patterns.

---

## File Structure

### Modified files

| File | Change |
|---|---|
| `skills/laravel-a11y-specialist/SKILL.md` | 4 patterns removed (modal/dropdown/form-validation/skip-link — handled by Reka UI accessibility-by-default); 3 patterns rewrite (Inertia/Vue equivalent of wire:loading aria-busy; preserved patterns: reduced-motion query + audio-control) |
| `skills/laravel-code-review/SKILL.md` | §9 Livewire sub-checklist → Inertia/Vue sub-checklist; §10 Flux Pro v2 sub-checklist → Reka UI sub-checklist |
| `skills/laravel-debugging/SKILL.md` | Top-10 RED items #3 (fabricated `$this->hasLoading()` Livewire API) → Inertia helper-name typos / fabricated `useHttp()` methods; item #8 (Livewire properties) → Vue 3 reactivity gotchas |
| `skills/laravel-tdd/SKILL.md` | Pest-specifics items #3 (Livewire-specific test helpers) → Inertia testing helpers (`assertInertia`, `assertHas`, `where()`); item #8 (Volt/Livewire browser patterns) → Pest browser + Vue component testing patterns |

### Modified support files

| File | Change |
|---|---|
| `README.md` | Skills section: remove "(adaption in Phase C)" parenthetical from a11y-specialist; Versions section add alpha.3 entry, move `(current)` |
| `CHANGELOG.md` | Prepend `## [1.0.0-alpha.3]` section |
| `.claude-plugin/plugin.json` | Version `1.0.0-alpha.2` → `1.0.0-alpha.3`; description optional update if current-state count changes |

### Branch / release

- Feature branch: `feat/v1-phase-c-skill-swaps`
- Post-merge: tag `v1.0.0-alpha.3` + GitHub Pre-Release + marketplace bump to 1.0.0-alpha.3

---

## STEP C.1 — Foundation

### Task 1: Pre-flight + branch

- [ ] Verify clean main post-Phase-B (tag `v1.0.0-alpha.2` present, 17 shell + 37 Python tests green)
- [ ] `git switch -c feat/v1-phase-c-skill-swaps`

---

## STEP C.2 — `laravel-a11y-specialist` rewrite (3 patterns kept + 4 dropped)

### Task 2: Rewrite `skills/laravel-a11y-specialist/SKILL.md`

The Livewire variant of this skill documented 7 canonical accessibility patterns. In the Vue variant with Reka UI primitives, 4 of those patterns are handled by Reka UI accessibility-by-default (modal focus management, dropdown keyboard navigation, form validation announcements, skip-to-content link). Only 3 patterns require manual operator work:

1. **Live region for streaming content** (Inertia/Vue equivalent of wire:loading aria-busy): use Vue's reactive `aria-busy` binding on async fetch operations (`router.visit`, `useForm.processing`)
2. **Reduced motion query** (`prefers-reduced-motion` CSS query for Vue/Tailwind animations) — UNCHANGED from Livewire variant (stack-agnostic CSS)
3. **Audio control** (WCAG 2.1.1: any audio > 3s needs pause/stop control) — UNCHANGED from Livewire variant (stack-agnostic)

- [ ] **Step 1: Read the current SKILL.md**

```bash
cat skills/laravel-a11y-specialist/SKILL.md
```

Note the existing 7-pattern structure. Each pattern has: heading, what-it-does, example code (Livewire/Blade currently), why-it-matters, source citation.

- [ ] **Step 2: Rewrite the SKILL.md**

Use Write tool with the new structure. Preserve the file's outer shape (frontmatter, role statement, Pre-flight, output template, when-in-doubt section) but REPLACE the 7 patterns section with the 3 patterns below.

Reference patterns to write:

**Pattern 1: Live region for async operations (Inertia/Vue equivalent)**
- Inertia `router.visit` + `useForm.processing` provide reactive loading state
- Vue template: `<div :aria-busy="form.processing">` for the affected region
- Live region: `<div role="status" aria-live="polite">{{ form.processing ? 'Saving...' : '' }}</div>`
- Anti-pattern: manual `setInterval` polling without aria-busy update (use Inertia `usePoll` instead)

**Pattern 2: Reduced-motion query** (stack-agnostic — keep current content unchanged)
- CSS: `@media (prefers-reduced-motion: reduce) { /* disable animations */ }`
- Tailwind 4: `motion-reduce:` variant for utility classes
- Example: `class="transition-all motion-reduce:transition-none"`

**Pattern 3: Audio control** (stack-agnostic — keep current content unchanged)
- WCAG 2.1.1: audio > 3s needs `<audio controls>` or programmatic pause/stop control
- Example: `<audio controls preload="metadata">`
- For Vue components playing audio: expose mute/pause method via `defineExpose({ pause, resume })`

Add a NEW section after the 3 patterns explaining what Reka UI handles automatically:

```markdown
## What Reka UI handles (NO manual work needed)

Reka UI primitives ship accessibility-by-default. The following patterns are NOT in your scope when using Reka:

- **Modal focus management** — `<DialogRoot>` traps focus on open, returns focus to trigger on close
- **Dropdown keyboard navigation** — `<DropdownMenuRoot>` handles arrow keys, Escape, type-ahead search
- **Form validation announcements** — `<FormRoot>` + `<FormField>` wire `aria-describedby` automatically
- **Skip-to-content** — use the same standalone `<a href="#main" class="sr-only focus:not-sr-only">` pattern (CSS-only, not a primitive)

Trust Reka's accessibility contract. Do NOT add manual `aria-*` attributes to Reka primitives — they conflict with Reka's own ARIA management.
```

Update the frontmatter `description` to reflect the Vue/Reka focus:

```yaml
---
name: laravel-a11y-specialist
description: "Use in Laravel + Vue 3 + Inertia + Reka UI projects when reviewing accessibility patterns. Covers the 3 patterns that require manual operator work (live region for async ops, reduced-motion query, audio control) — Reka UI primitives handle modal focus, dropdown keyboard nav, form validation announcements, and skip-link automatically. Trigger before merging a feature with custom UI, async operations, animations, or audio."
---
```

- [ ] **Step 3: Verify frontmatter valid + body structure**

```bash
python3 -c "
import re, yaml
c = open('skills/laravel-a11y-specialist/SKILL.md').read()
m = re.match(r'^---\n(.*?)\n---\n', c, re.DOTALL)
fm = yaml.safe_load(m.group(1))
assert fm['name'] == 'laravel-a11y-specialist'
# Verify body has exactly 3 patterns + Reka-handles section
patterns = c.count('## Pattern ')
assert patterns == 3, f'expected 3 patterns, got {patterns}'
assert 'Reka UI handles' in c
print(f'✓ a11y rewrite: {patterns} patterns, Reka-handles section present, {c.count(chr(10))} body lines')
"
```

---

## STEP C.3 — `laravel-code-review` §9 + §10 swap

### Task 3: Swap §9 (Livewire sub-checklist) + §10 (Flux Pro v2 sub-checklist) in `skills/laravel-code-review/SKILL.md`

- [ ] **Step 1: Read the current SKILL.md**

```bash
cat skills/laravel-code-review/SKILL.md
```

Locate §9 (Livewire sub-checklist) and §10 (Flux Pro v2 sub-checklist).

- [ ] **Step 2: Replace §9 with Inertia/Vue sub-checklist**

New §9 content covers Vue/Inertia review concerns:

```markdown
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
```

- [ ] **Step 3: Replace §10 with Reka UI sub-checklist**

```markdown
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
```

- [ ] **Step 4: Verify the swap**

```bash
grep -E "^## §9 — |^## §10 — " skills/laravel-code-review/SKILL.md
```

Expected: §9 line mentions "Inertia + Vue 3", §10 line mentions "Reka UI".

---

## STEP C.4 — `laravel-debugging` items #3 + #8 swap

### Task 4: Swap Top-10 RED items #3 + #8 in `skills/laravel-debugging/SKILL.md`

- [ ] **Step 1: Read the current SKILL.md, locate Top-10 table**

```bash
grep -nE "^\\| ?#?[1-9]" skills/laravel-debugging/SKILL.md | head -15
```

Find item #3 (currently fabricated Livewire API like `$this->hasLoading()`) and item #8 (currently Livewire properties).

- [ ] **Step 2: Replace item #3**

Old: fabricated `$this->hasLoading()` Livewire API.
New: fabricated Inertia helper method (e.g., `useHttp()` confused with `useForm()` in Inertia v3) or typo'd Vue Composition API method (`computeed` vs `computed`).

Example new row:

```markdown
| #3 | Fabricated framework API | "Method `useHttp().fetchAll()` doesn't exist on this version of Inertia" | Verify the API exists in `vendor/inertiajs/inertia-laravel/src/` OR `node_modules/@inertiajs/vue3/dist/`. Inertia v3 added `useHttp` (was not in v2). Vue typos: `computeed` instead of `computed`, `refrence` instead of `reference`. | `laravel-inertia-specialist` for Inertia surface; `laravel-vue3-specialist` for Vue surface |
```

(Adapt to match actual table column structure.)

- [ ] **Step 3: Replace item #8**

Old: Livewire properties (e.g., `wire:model` reactivity gotchas).
New: Vue 3 reactivity gotchas. Top candidates:
- Destructuring reactive object loses reactivity (`const { count } = reactive({ count: 0 })` → `count` is a plain number, not reactive)
- Refs in arrays don't auto-unwrap (`const arr = [ref(1)]; arr[0]` is a Ref, must `.value`)
- `reactive()` only deep-reactive on plain objects, not on Maps/Sets without explicit wrappers

Example new row:

```markdown
| #8 | Vue 3 reactivity gotcha | "My computed value isn't updating when the underlying ref changes." | (a) Did you destructure reactive? Use `toRefs(state)` to preserve reactivity. (b) Are refs nested in arrays? They don't auto-unwrap — access `.value`. (c) Is the underlying data a Map/Set? Reactive treats them as opaque; use `shallowReactive` + explicit set/delete, or convert to a plain object/array. | `laravel-vue3-specialist` |
```

- [ ] **Step 4: Verify**

```bash
grep -E "^\\| ?#?(3|8) " skills/laravel-debugging/SKILL.md | head -3
```

Expected: item #3 mentions "Inertia" or "Vue", item #8 mentions "Vue 3 reactivity".

---

## STEP C.5 — `laravel-tdd` Pest-specifics items #3 + #8 swap

### Task 5: Swap Pest-specifics items #3 + #8 in `skills/laravel-tdd/SKILL.md`

- [ ] **Step 1: Locate the Pest-specifics section**

```bash
grep -nE "^## .*Pest specifics|^### Pest" skills/laravel-tdd/SKILL.md
```

- [ ] **Step 2: Replace item #3**

Old: Livewire-specific test helpers (e.g., `Livewire::test()`, `assertSet`).
New: Inertia test helpers — `assertInertia(fn ($page) => $page->has('users')->where('user.id', $id))`.

```markdown
**#3 — Inertia page assertions (`assertInertia` + chainable matchers)**

When testing Inertia controllers, use Pest's Inertia integration:

```php
test('users index page shows current user', function () {
    $user = User::factory()->create();

    actingAs($user)
        ->get('/users')
        ->assertInertia(fn ($page) => $page
            ->component('Users/Index')
            ->has('users', 1)
            ->where('users.0.id', $user->id)
            ->where('auth.user.id', $user->id)
        );
});
```

Common matchers:
- `->component('Users/Index')` — verify the right Vue component is rendered
- `->has('users', 5)` — assert exactly 5 items in the prop array
- `->has('users.0.email')` — nested prop existence
- `->where('users.0.id', $id)` — exact value match
- `->missing('secret_field')` — assert a prop is NOT shared
- `->etc()` — assert "checked all expected props, ignore extras"

Anti-pattern: asserting on rendered HTML for Inertia pages. The HTML is Vue-rendered at runtime; Pest browser tests are the right tool for HTML-level assertions, NOT feature tests.
```

- [ ] **Step 3: Replace item #8**

Old: Volt/Livewire browser patterns.
New: Pest 4 browser + Vue component testing.

```markdown
**#8 — Pest browser tests for Vue components**

For Vue component behavior beyond data-flow (interactions, animations, complex state), use Pest 4 browser plugin (Playwright under the hood):

```php
test('clicking submit shows loading state', function () {
    visit('/contact')
        ->fill('email', 'test@example.com')
        ->click('Submit')
        ->assertVisible('[aria-busy="true"]')
        ->wait()  // wait for response
        ->assertSee('Thanks for your message');
});
```

Common patterns:
- `visit('/path')` — opens the page via Inertia visit
- `fill('field', 'value')` — fills an input by label/name
- `click('Button text')` — clicks by visible text
- `assertVisible('[selector]')` — Reka UI's `data-state` attributes are excellent selectors
- `wait()` — waits for next Inertia response (better than `wait(1000)` arbitrary timeouts)

Anti-patterns:
- `wait(1000)` arbitrary timeouts (use `wait()` or `assertVisible` polling instead)
- Direct DOM manipulation (`$browser->script(...)`) — bypasses Vue reactivity
- Asserting on Vue component internal state — assert on rendered DOM instead
```

- [ ] **Step 4: Verify**

```bash
grep -nE "^\\*\\*#3 —|^\\*\\*#8 —" skills/laravel-tdd/SKILL.md | head -3
```

Expected: #3 mentions "Inertia", #8 mentions "Pest browser" + "Vue".

---

## STEP C.6 — Shared updates

### Task 6: Update README.md

- [ ] Remove `(adaption in Phase C)` parenthetical from `laravel-a11y-specialist` entry (line ~43): rewrite to "WCAG 2.2 + ARIA + reduced-motion patterns adapted for Vue 3 + Reka UI (3 manual patterns; modal/dropdown/form-validation handled by Reka)"
- [ ] Versions section: add `v1.0.0-alpha.3` entry, move `(current)` from alpha.2

### Task 7: Prepend CHANGELOG `## [1.0.0-alpha.3]` section

```markdown
## [1.0.0-alpha.3] — 2026-05-17 — Phase C: Skill Sub-Section Swaps

Phase C swaps the Livewire-flavored sub-sections inside 4 skills with Vue 3 + Inertia v3 + Reka UI equivalents.

### Changed

- `skills/laravel-a11y-specialist/SKILL.md` — rewrote from 7 patterns to 3 (manual): live region for async ops + reduced-motion + audio control. Added "What Reka UI handles" section listing 4 patterns delegated to Reka primitives (modal focus / dropdown keyboard nav / form validation announcements / skip-link).
- `skills/laravel-code-review/SKILL.md` — §9 Livewire sub-checklist → Inertia + Vue 3 sub-checklist (Inertia::share, useForm, Link, usePoll, Wayfinder routes, listener cleanup); §10 Flux Pro v2 sub-checklist → Reka UI sub-checklist (Root/Trigger/Content composition, controlled/uncontrolled, data-[state=*] modifiers, asChild correctness, Portal usage).
- `skills/laravel-debugging/SKILL.md` — Top-10 item #3 swap: fabricated Livewire `$this->hasLoading()` → fabricated Inertia `useHttp().fetchAll()` / Vue Composition API typos. Item #8 swap: Livewire properties → Vue 3 reactivity gotchas (reactive destructure, refs in arrays, Maps/Sets).
- `skills/laravel-tdd/SKILL.md` — Pest-specifics item #3 swap: Livewire test helpers → Inertia `assertInertia` + chainable matchers. Item #8 swap: Volt/Livewire browser patterns → Pest 4 browser plugin + Vue component testing.
- `README.md` — removed "(adaption in Phase C)" parenthetical from a11y-specialist entry.
- `.claude-plugin/plugin.json` — version 1.0.0-alpha.2 → 1.0.0-alpha.3.

### Phase Status

Phase C (this alpha) — ✅ shipped 2026-05-17 as v1.0.0-alpha.3.

Phases D-E remain.

---
```

### Task 8: Bump plugin.json version

`1.0.0-alpha.2` → `1.0.0-alpha.3`. Description current-state counts unchanged (still 11/7/16/3).

### Task 9: Test verify

```bash
for t in tests/test_*.sh; do bash "$t" >/dev/null 2>&1 && echo "✓" || echo "✗ $t"; done
python3 -m pytest tests/ -q
```

Expected: 17 shell + 37 Python green (no test changes in this phase, just doc).

### Task 10: Commit + push + PR

Standard pattern. Commit message: `feat(v1): phase c — skill sub-section swaps (v1.0.0-alpha.3)`.

**STOP. Wait for operator merge.**

---

## STEP C.7 — Post-Merge

### Task 11: Tag v1.0.0-alpha.3 + Pre-Release + marketplace bump

Standard pattern: pull main, tag, push tag, GitHub Pre-Release with awk-extracted CHANGELOG body, bump Vue plugin in `altraWeb/laravel-marketplace` marketplace.json from `1.0.0-alpha.2` to `1.0.0-alpha.3`.

**STOP. Phase C complete.**
