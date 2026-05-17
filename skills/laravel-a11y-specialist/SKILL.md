---
name: laravel-a11y-specialist
description: "Use in Laravel + Livewire 4 + Flux Pro v2 projects when building any UI surface that has dynamic content, loading states, animations, audio, or user-perceptible state changes. Surfaces WCAG 2.2 + ARIA + reduced-motion patterns systematically (role/aria-live/aria-busy/wire:loading.attr/prefers-reduced-motion/Page-Visibility) instead of leaving them to per-phase audit discovery. In Livewire codebases, use this alongside superpowers:frontend-design (if available) for stack-specific depth. Trigger on any 'AI panel', 'streaming', 'loading state', 'notification', 'modal', 'animation', 'sound', 'toast', or any UI with perceivable state changes."
---

# Laravel + Livewire Accessibility Specialist

You are guiding accessibility decisions for Laravel + Livewire 4 + Flux Pro v2 UIs. Your job is to surface canonical a11y patterns BEFORE the operator implements, so accessibility is built-in rather than retrofitted via audit.

## Core principle

Every dynamic UI surface needs an explicit accessibility decision. The default behavior is usually wrong:
- Streaming content without `aria-live="off"` spams screen readers
- Loading spinners without `aria-busy` leave SR users with no progress signal
- Animations without `prefers-reduced-motion` cause motion-sickness for some users
- Sounds without operator control violate WCAG 2.2 §1.4.2

## The 7 canonical patterns

### 1. Live region for status / streaming text

For containers that update with per-token text (AI responses, streaming output):

```html
<!-- Container: announce changes politely -->
<div role="status" aria-live="polite" aria-atomic="false">
  <!-- Streaming text inside -->
  <pre aria-live="off">{{ $streamingContent }}</pre>
</div>
```

**Why:** `role="status"` is the WCAG-recommended container for transient status messages. `aria-live="polite"` queues announcements rather than interrupting. The INNER `<pre>` overrides with `aria-live="off"` because per-token updates would create SR spam.

**Anti-pattern:** `aria-live="assertive"` on streaming containers — interrupts every other SR announcement.

### 2. Livewire loading-state with aria-busy

For Livewire components that update on user action:

```html
<div wire:loading.attr="aria-busy" wire:target="sendMessage">
  <flux:button wire:click="sendMessage">Send</flux:button>
</div>
```

**Why:** `wire:loading.attr="aria-busy"` automatically sets `aria-busy="true"` on the container during the request. SR users hear "busy" announcement. `wire:target` scopes it to the specific action.

**Anti-pattern:** Building a fake server-side getter like `$this->isLoading` then binding `aria-busy="{{ $isLoading }}"` — fabricated API that doesn't exist in Livewire's contract.

### 3. Skip-to-content link

Every page needs a keyboard-only escape hatch from the header navigation:

```html
<a href="#main" class="sr-only focus:not-sr-only focus:fixed focus:top-2 focus:left-2 focus:z-50 ...">
  Skip to main content
</a>
<header>...</header>
<main id="main">...</main>
```

**Why:** WCAG 2.1 §2.4.1. Keyboard users tab through every header link before reaching content without this.

### 4. Reduced-motion suppression

For ANY animation longer than ~200ms or any animation that loops:

```css
@media (prefers-reduced-motion: reduce) {
  .animate-pulse, .animate-spin, [class*="transition-"] {
    animation: none !important;
    transition: none !important;
  }
}
```

Combine with Page-Visibility API for resource-saving:

```js
document.addEventListener('visibilitychange', () => {
  if (document.hidden) {
    // pause animations / poll loops / audio
  } else {
    // resume
  }
});
```

**Livewire integration:** In Livewire 4 + Alpine, wrap the listener in an Alpine `x-init` / `x-effect` or in `Alpine.data(...)` so it's cleaned up on component re-render. Bare `document.addEventListener` in a Blade can leak listeners across Livewire morphs.

**Why:** Vestibular disorders, motion sickness, ADHD distraction. WCAG 2.3.3 (Animation from Interactions, AAA).

### 5. Audio Control (WCAG 2.2 §1.4.2)

Only applies to sounds **longer than 3 seconds**. Short notification sounds (<3s) are exempt. For longer audio:

```html
<audio controls preload="metadata">
  <source src="..." type="audio/mpeg">
</audio>
<!-- OR -->
<button @click="pause()" aria-label="Mute notifications">🔇</button>
```

**Why:** Auto-playing audio interferes with SR speech. User MUST have a mute/pause control accessible without skipping the rest of the content.

### 6. Modal focus management

```html
<flux:modal>
  <!-- First focusable element auto-focused on open -->
  <input type="text" autofocus>
  <!-- Trap focus inside modal until close -->
  <!-- Escape key closes (handled by Flux internally) -->
</flux:modal>
```

When implementing your own modal: ensure `<dialog>` element or focus trap + return-focus-to-trigger on close.

**Why:** WCAG 2.4.3 Focus Order. Without trap, keyboard users tab into background content while modal is "open" — confusing AND broken.

### 7. Form validation announcements

```html
<input wire:model.live="email" id="email" aria-describedby="email-error">
@error('email')
  <span id="email-error" role="alert">{{ $message }}</span>
@enderror
```

**Why:** `role="alert"` announces validation errors to SR users immediately. `aria-describedby` links the input to the error so SR users hear the error when the input is focused.

## When in doubt

If you're uncertain whether a specific UI element needs accessibility consideration, run this quick checklist:

1. Does it change without user action? → live region
2. Does it indicate progress? → aria-busy / role="progressbar"
3. Does it animate? → prefers-reduced-motion query
4. Does it produce sound > 3s? → audio control required
5. Does it trap keyboard focus? → focus trap + return-focus

If yes to any → consult the specific pattern above before implementing.

## Resources

- [WCAG 2.2 Quick Reference](https://www.w3.org/WAI/WCAG22/quickref/)
- [Livewire Loading States docs](https://livewire.laravel.com/docs/wire-loading)
- Flux Pro v2 Modal a11y — inspect `vendor/livewire/flux-pro/stubs/` for canonical patterns
- [WAI-ARIA Authoring Practices](https://www.w3.org/WAI/ARIA/apg/)
