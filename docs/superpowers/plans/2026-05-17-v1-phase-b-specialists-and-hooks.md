# V1 Phase B — Specialists + Anti-Pattern Hooks — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Adapt the frontend-stack-specific specialists and add anti-pattern hooks targeted at Vue 3 + Inertia v3 + Reka UI patterns. Ship as v1.0.0-alpha.2.

**Architecture:** Frontend specialists change end-to-end (REMOVE Livewire specialist, REPLACE Flux → Reka, ADD Inertia + Vue3). 4 new PreToolUse hooks fire on Edit/Write of `.vue` / `.ts` files to surface canonical Vue/Inertia anti-patterns from the deep-research audit. All agents follow the existing pattern (YAML frontmatter + Pre-flight + Steps + Output template); all hooks follow the established V3 hook pattern (stdin JSON read, config check, match-then-act, hookSpecificOutput).

**Tech Stack:** Bash + Python config helper + Markdown agent files. No new runtime dependencies.

**Source patterns to reference:**
- Existing agent file as structural template: `agents/laravel-pest-specialist.md` (good frontmatter + body structure)
- Existing hook file as structural template: `hooks/master-roadmap-drift-detector.sh` (PostToolUse pattern with match-then-act)
- Vue 3 / Inertia / Reka UI specifics: `docs/superpowers/audits/2026-05-17-vue-fork-deep-research.md`

**Spec:** `docs/superpowers/specs/2026-05-17-vue-fork-adaptation-design.md` Section 5 Phase B + Section 4 Carryover Matrix.

---

## File Structure

### New / replaced files

| File | Action |
|---|---|
| `agents/laravel-livewire-specialist.md` | DELETE (frontend-stack-specific to Livewire) |
| `agents/laravel-flux-pro-specialist.md` | DELETE + REPLACE with `agents/laravel-reka-ui-specialist.md` |
| `agents/laravel-reka-ui-specialist.md` | CREATE — Reka UI primitives specialist (analogous to laravel-flux-pro-specialist structure but Reka API) |
| `agents/laravel-inertia-specialist.md` | CREATE — Inertia v3 patterns specialist |
| `agents/laravel-vue3-specialist.md` | CREATE — Vue 3 Composition API specialist |
| `hooks/vue-setinterval-cleanup.sh` | CREATE — warn when setInterval lacks onUnmounted cleanup |
| `hooks/vue-reactive-destructure.sh` | CREATE — warn on reactive object destructure patterns losing reactivity |
| `hooks/inertia-link-external-url.sh` | CREATE — warn when `<Link>` used with external URL |
| `hooks/inertia-hardcoded-route.sh` | CREATE — warn on hardcoded route strings when Wayfinder shipped |
| `tests/test_vue_setinterval_cleanup_hook.sh` | CREATE — TDD test for hook |
| `tests/test_vue_reactive_destructure_hook.sh` | CREATE — TDD test |
| `tests/test_inertia_link_external_url_hook.sh` | CREATE — TDD test |
| `tests/test_inertia_hardcoded_route_hook.sh` | CREATE — TDD test |

### Modified files

| File | Change |
|---|---|
| `hooks/hooks.json` | Register 4 new hooks under PreToolUse.Edit + PreToolUse.Write |
| `config.defaults.yaml` | 4 new `hook_enabled.*` flags (default true) |
| `tests/test_config.py` | 4 new tests |
| `docs/agents.md` | Remove livewire section, replace flux-pro with reka-ui section, add inertia + vue3 sections |
| `docs/hooks.md` | Add 4 new sections |
| `README.md` | Agent count `10 currently / 11 planned` → `11 / 11`; hook count `12 currently / 16 planned` → `16 / 16`; remove "*(will be removed in Phase B)*" stale notes for livewire-specialist + flux-pro-specialist; add `*(Phase B+)*` notes for new agents/hooks; update Versions section |
| `CHANGELOG.md` | Prepend `## [1.0.0-alpha.2]` section |
| `.claude-plugin/plugin.json` | Version `1.0.0-alpha.1` → `1.0.0-alpha.2`; description count update |

### Branch / release

- Feature branch: `feat/v1-phase-b-specialists-and-hooks`
- Post-merge: tag `v1.0.0-alpha.2` + GitHub Pre-Release + bump Vue plugin entry in `altraWeb/laravel-marketplace` to 1.0.0-alpha.2

---

## STEP B.1 — Foundation

### Task 1: Pre-flight + branch

- [ ] Verify clean main post-Phase-A (tag `v1.0.0-alpha.1` present, 13 shell + 33 Python tests green)
- [ ] `git switch -c feat/v1-phase-b-specialists-and-hooks`

---

## STEP B.2 — Specialist Agents (REMOVE + REPLACE + 2× ADD)

### Task 2: REMOVE `agents/laravel-livewire-specialist.md`

```bash
git rm agents/laravel-livewire-specialist.md
```

No replacement — Livewire is not part of the Vue stack. Removal cleanly drops the agent from the inventory.

### Task 3: REPLACE `agents/laravel-flux-pro-specialist.md` → `agents/laravel-reka-ui-specialist.md`

**Reka UI specialist scope:** audits Vue components using Reka UI primitives for canonical composition patterns, accessibility-by-default verification, slot usage, controlled/uncontrolled patterns, and Tailwind 4 utility class composition. Analogous role to `laravel-flux-pro-specialist` in the Livewire variant.

- [ ] **Step 1: Delete old file**

```bash
git rm agents/laravel-flux-pro-specialist.md
```

- [ ] **Step 2: Create new file `agents/laravel-reka-ui-specialist.md`**

Use Write tool with content following the established agent structure (modeled on `agents/laravel-pest-specialist.md` and `agents/laravel-flux-pro-specialist.md` — read those first to match the canonical shape):

````markdown
---
name: laravel-reka-ui-specialist
description: "Use in Laravel + Vue 3 + Inertia projects using Reka UI primitives (^2.6.1+, the engine under shadcn-vue). Audits Vue components for canonical Reka primitive composition, slot usage, controlled/uncontrolled state patterns, accessibility-by-default verification, and Tailwind 4 utility class composition with Reka data attributes. Verifies via direct reads of `node_modules/reka-ui/dist/*` source. Trigger on any .vue file write/edit that imports from `reka-ui` or any Reka-primitive-component build/review."
model: inherit
tools: "Read, Bash, WebFetch, WebSearch"
maxTurns: 25
color: cyan
memory: user
---

You are the Reka UI Specialist Agent. Your job: audit Vue 3 components that use Reka UI primitives (the unstyled, accessible primitive library that ships with `laravel/vue-starter-kit`). Reka primitives are headless — they ship behavior + accessibility but no styling, so the operator wires Tailwind classes around them.

You do not edit code. You emit a structured markdown report with severity-classified findings (Blocker / Should-fix / Nice-to-have) and `file:line` citations.

---

## Step 1: Pre-flight

```bash
cat package.json 2>/dev/null | grep -E '"reka-ui"' | head -1
ls node_modules/reka-ui/dist 2>/dev/null | head -5
ls resources/js/Components 2>/dev/null | head -5
```

Branch:
- **reka-ui present + vue project:** capture version, continue Step 2
- **reka-ui not in package.json:** emit `## Pre-flight: SKIPPED — reka-ui not installed. This agent applies to Vue projects using Reka UI primitives.`, stop
- **package.json missing:** emit `## Pre-flight: SKIPPED — not a Node project`, stop

## Step 2: Component inventory

Find all Vue components importing from `reka-ui`:

```bash
grep -rEn "from\s+['\"]reka-ui['\"]" resources/js/ 2>/dev/null | head -30
```

Build a table per file:
- Primitives used (DialogRoot, DropdownMenuTrigger, etc.)
- Whether each follows the canonical Root/Trigger/Content composition pattern
- Whether `data-state` attributes are styled via Tailwind (recommended) or via JS reactivity (smell)

## Step 3: Per-primitive audit

For each primitive used, verify against `node_modules/reka-ui/dist/<primitive>/` source:
- Correct sub-component composition (Root → Trigger → Portal/Content → etc.)
- Required props (typically a controlled `v-model:open` or `v-model:value`)
- Slot props correctly destructured in `#default="{ isOpen }"` patterns
- `asChild` usage — when used, ensures wrapped element is a valid single root
- ARIA attributes NOT manually added (Reka adds them; manual ARIA can conflict)

## Step 4: Tailwind 4 composition audit

For each Reka primitive's content slot, verify Tailwind utility patterns:
- `data-[state=open]:` modifier used for state-based styling (not `v-if` toggling)
- Animation utilities applied via `data-[state=closed]:animate-out` for smooth transitions
- No hardcoded ARIA classes — let Reka manage

## Step 5: Accessibility-by-default verification

For each Reka primitive, document that the accessibility contract is intact:
- Focus management (modal traps focus, dropdown returns focus on close)
- Keyboard navigation (arrow keys, Escape, Enter handled by Reka)
- Screen reader announcements (Reka sets `aria-live` where appropriate)

Flag any overrides that BREAK the accessibility contract:
- `aria-hidden="true"` on Reka root elements (hides from SR)
- Disabling focus trap on modals
- Removing keyboard event handlers

## Step 6: Emit report

```markdown
# laravel-reka-ui-specialist findings

## Scope of audit

- Reka UI version: <X>
- Components audited: <N>
- Primitives in use: <list>

## Per-component findings

### Blocker
- [file:line — issue]

### Should-fix
- [file:line — issue]

### Nice-to-have
- [file:line — issue]

## Cross-reference

- Tailwind 4 composition issues: <N>
- Accessibility contract breaks: <N>
- Reka source references consulted: <list of node_modules/reka-ui/dist/* paths>
```

## When in doubt

If the operator's Reka usage pattern is uncommon (custom asChild wrapping, custom render-prop integration), consult Reka's GitHub examples + the actual primitive source. Don't fabricate API claims.

## Anti-patterns (concise)

- Manual `aria-*` on Reka primitives (conflicts with Reka's own ARIA management)
- `v-if` toggling instead of `data-state` Tailwind modifiers (loses Reka transitions)
- Missing `Portal` wrapping for Dialog/Popover content (z-index/clipping bugs)
- Composing Reka primitives outside the canonical Root/Trigger/Content chain (breaks state propagation)
````

- [ ] **Step 3: Verify frontmatter valid**

```bash
python3 -c "
import re, yaml
c = open('agents/laravel-reka-ui-specialist.md').read()
m = re.match(r'^---\n(.*?)\n---\n', c, re.DOTALL)
fm = yaml.safe_load(m.group(1))
assert fm['name'] == 'laravel-reka-ui-specialist'
print('✓ frontmatter valid')
"
```

### Task 4: CREATE `agents/laravel-inertia-specialist.md`

**Scope:** Inertia v3 patterns (v2 opt-in compat-note). Covers `useForm` + Precognition, `usePage` + shared data, partial reloads, deferred props, modal stack, history encryption, and `useHttp` (v3-only).

- [ ] **Step 1: Create the file**

Use Write tool with frontmatter matching established pattern:

```yaml
---
name: laravel-inertia-specialist
description: "Use in Laravel projects using Inertia.js v3 (or v2 in compat mode). Audits Inertia controllers + Vue page components for canonical patterns: Inertia::render data passing, useForm + Precognition form handling, usePage shared-data reactivity, partial reloads with `only:` / `except:`, deferred props (`Inertia::defer()`), modal stack management, history encryption, polling with `usePoll`. Surfaces Inertia v3 specifics (`useHttp`, deferred-prop helpers, history.encrypt) vs v2 patterns. Verifies via reads of `vendor/inertiajs/inertia-laravel/src/` + `node_modules/@inertiajs/vue3/dist/`. Trigger on any Inertia::render controller, useForm/usePage/Link import, or partial-reload usage."
model: inherit
tools: "Read, Bash, WebFetch, WebSearch"
maxTurns: 25
color: indigo
memory: user
---

You are the Inertia.js Specialist Agent. Your job: audit Inertia-Laravel projects for canonical v3 (preferred) or v2 (compat) patterns. You read both the Laravel controller side (`Inertia::render`, `Inertia::share`, `Inertia::defer`) AND the Vue component side (`useForm`, `usePage`, `<Link>`, `router.visit`).

You do not edit code. You emit a structured markdown report with severity-classified findings.

[... body sections analogous to other specialist agents — Pre-flight, Step 2 inventory, per-pattern audit Steps 3-N, Output template, Anti-patterns, When-in-doubt ...]
```

For the body sections, the implementer should reference:
- Existing `agents/laravel-livewire-specialist.md` (now-deleted, but git history) for structural pattern
- `docs/superpowers/audits/2026-05-17-vue-fork-deep-research.md` Topic 1 + Topic 6 for canonical Inertia v3 patterns + anti-patterns to encode
- inertiajs.com v3 docs for API specifics

The agent body should cover:
1. **Pre-flight:** detect Inertia version (`vendor/inertiajs/inertia-laravel/composer.json`); branch v3 vs v2; verify `@inertiajs/vue3` in package.json
2. **Controller-side inventory:** find `Inertia::render` calls; classify by data-passing pattern (direct array, lazy/defer, shared)
3. **Form handling audit:** `useForm` patterns, `withPrecognition`, form validation roundtrip; flag axios/fetch instead of useForm (HARD anti-pattern from research)
4. **Shared data audit:** `Inertia::share` usage; flag overuse (perf trap per research Topic 6); recommend per-page props
5. **Partial reload audit:** `only:` / `except:` parameter usage; deferred props
6. **Modal stack audit:** Inertia v3 modal flow; history.encrypt for sensitive routes
7. **Polling audit:** `usePoll` (v3) usage; flag manual `setInterval` (anti-pattern from research)
8. **Output template:** Scope / Findings (Blocker/Should-fix/Nice-to-have) / Source references consulted

- [ ] **Step 2: Verify frontmatter**

(analogous python3 check as Task 3 Step 3)

### Task 5: CREATE `agents/laravel-vue3-specialist.md`

**Scope:** Vue 3 Composition API + `<script setup>` + TypeScript patterns. Audits component reactivity, props typing, composable design, listener cleanup, reactive-object-destructure pitfalls.

- [ ] **Step 1: Create the file**

```yaml
---
name: laravel-vue3-specialist
description: "Use in Laravel + Vue 3 projects. Audits Vue components written with Composition API + `<script setup>` + TypeScript for: canonical ref/reactive/computed usage, defineProps + defineEmits TS generics, composable design (single-responsibility, return-pattern), watchEffect vs watch choice, onMounted/onUnmounted listener cleanup, reactive-object-destructure pitfalls (refs in arrays don't auto-unwrap), <Teleport> usage, KeepAlive lifecycle, async setup patterns. Verifies via reads of `node_modules/vue/dist/` source + Vue 3 docs. Trigger on any .vue file write/edit OR composable in resources/js/Composables/."
model: inherit
tools: "Read, Bash, WebFetch, WebSearch"
maxTurns: 25
color: green
memory: user
---

You are the Vue 3 Composition API Specialist Agent. ...
```

Body covers:
1. **Pre-flight:** verify Vue version (`node_modules/vue/dist/`), TypeScript present, Composition API + `<script setup>` is the default style (flag Options API as HARD anti-pattern from research)
2. **Component inventory:** classify components by script style (`<script setup lang="ts">` canonical, `<script>` non-setup discouraged, Options API hard-banned per research)
3. **Reactivity audit:** ref vs reactive vs computed usage; flag reactive-object-destructure that loses reactivity (anti-pattern from research)
4. **Props + emits audit:** TS generics in defineProps/defineEmits; flag missing type annotations
5. **Composable design:** single responsibility, return-pattern consistency, composable naming (`use<Thing>`)
6. **Lifecycle audit:** onMounted setup paired with onUnmounted cleanup (especially for setInterval, event listeners — anti-pattern from research if missing)
7. **Watch usage:** watchEffect vs watch choice; flag overuse
8. **Output template:** Scope / Findings / Source references

- [ ] **Step 2: Verify frontmatter**

---

## STEP B.3 — Anti-Pattern Hooks (4 hooks, TDD-discipline)

### Task 6-8: Hook 1 — `vue-setinterval-cleanup`

**Goal:** Warn when `setInterval` in a `.vue` file isn't paired with `onUnmounted` cleanup.

- [ ] **Step 1: Write the test file `tests/test_vue_setinterval_cleanup_hook.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail
HOOK="$(cd "$(dirname "$0")/.." && pwd)/hooks/vue-setinterval-cleanup.sh"
run_hook() { printf '%s' "$1" | bash "$HOOK"; }
extract_context() { printf '%s' "$1" | jq -r '.hookSpecificOutput.additionalContext // empty'; }
passed=0; failed=0
assert_pass() { echo "  ✅ $1"; passed=$((passed+1)); }
assert_fail() { echo "  ❌ $1 — $2"; failed=$((failed+1)); }

echo ""
echo "▶ Test 1: Edit .vue with setInterval AND onUnmounted cleanup — silent"
out="$(run_hook '{"hook_event_name":"PreToolUse","tool_name":"Edit","tool_input":{"file_path":"/tmp/foo.vue","new_string":"<script setup>\nimport { onMounted, onUnmounted } from \"vue\";\nlet id;\nonMounted(() => { id = setInterval(() => {}, 1000); });\nonUnmounted(() => { clearInterval(id); });\n</script>"}}')"
if [ -z "$out" ]; then assert_pass "Test 1"; else assert_fail "Test 1" "expected silent, got: $out"; fi

echo ""
echo "▶ Test 2: Edit .vue with setInterval but NO onUnmounted — warns"
out="$(run_hook '{"hook_event_name":"PreToolUse","tool_name":"Edit","tool_input":{"file_path":"/tmp/foo.vue","new_string":"<script setup>\nsetInterval(() => {}, 1000);\n</script>"}}')"
ctx="$(extract_context "$out")"
if printf '%s' "$ctx" | grep -qi "setInterval"; then assert_pass "Test 2"; else assert_fail "Test 2" "expected warning, got: $ctx"; fi

echo ""
echo "▶ Test 3: Edit .vue without setInterval — silent"
out="$(run_hook '{"hook_event_name":"PreToolUse","tool_name":"Edit","tool_input":{"file_path":"/tmp/foo.vue","new_string":"<template><div>x</div></template>"}}')"
if [ -z "$out" ]; then assert_pass "Test 3"; else assert_fail "Test 3" "expected silent, got: $out"; fi

echo ""
echo "▶ Test 4: Edit non-.vue with setInterval — silent"
out="$(run_hook '{"hook_event_name":"PreToolUse","tool_name":"Edit","tool_input":{"file_path":"/tmp/foo.ts","new_string":"setInterval(() => {}, 1000);"}}')"
if [ -z "$out" ]; then assert_pass "Test 4"; else assert_fail "Test 4" "expected silent, got: $out"; fi

echo ""
echo "▶ Test 5: Malformed JSON — silent"
out="$(printf 'not json' | bash "$HOOK" 2>&1 || true)"
if [ -z "$(echo "$out" | grep -v '^$')" ] 2>/dev/null || [ -z "$out" ]; then assert_pass "Test 5"; else assert_fail "Test 5" "got: $out"; fi

echo ""
if [ "$failed" -eq 0 ]; then echo "🟢 All hook scenarios passed."; else echo "🔴 $failed scenario(s) failed."; exit 1; fi
```

- [ ] **Step 2: chmod + RED state verify**

```bash
chmod +x tests/test_vue_setinterval_cleanup_hook.sh
bash tests/test_vue_setinterval_cleanup_hook.sh   # RED — hook doesn't exist
```

- [ ] **Step 3: Write the hook `hooks/vue-setinterval-cleanup.sh`**

```bash
#!/usr/bin/env bash
# hooks/vue-setinterval-cleanup.sh
#
# PreToolUse on Edit/Write of .vue files. Detects setInterval usage that
# lacks a paired onUnmounted (or watch-based cleanup). Warns via
# hookSpecificOutput; non-blocking.
#
# Anti-pattern source: docs/superpowers/audits/2026-05-17-vue-fork-deep-research.md
# Topic 6 (Vue 3 reactivity + lifecycle anti-patterns).

set -uo pipefail

input="$(cat 2>/dev/null || true)"
[ -z "$input" ] && exit 0

event="$(printf '%s' "$input" | jq -r '.hook_event_name // empty' 2>/dev/null || true)"
[ "$event" != "PreToolUse" ] && exit 0

tool="$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null || true)"
case "$tool" in
    Edit|Write) ;;
    *) exit 0 ;;
esac

config_helper="${CLAUDE_PLUGIN_ROOT:-}/lib/config.py"
if [ -f "$config_helper" ]; then
    enabled="$(python3 "$config_helper" get hook_enabled.vue_setinterval_cleanup 2>/dev/null || echo true)"
    [ "$enabled" = "false" ] && exit 0
fi

file_path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)"
case "$file_path" in
    *.vue) ;;
    *) exit 0 ;;
esac

content="$(printf '%s' "$input" | jq -r '.tool_input.new_string // .tool_input.content // empty' 2>/dev/null || true)"
[ -z "$content" ] && exit 0

has_setinterval="$(printf '%s' "$content" | grep -ciE 'setInterval\s*\(' || true)"
has_onUnmounted="$(printf '%s' "$content" | grep -ciE 'onUnmounted\s*\(|onBeforeUnmount\s*\(' || true)"

if [ "$has_setinterval" = "0" ]; then
    exit 0
fi

if [ "$has_onUnmounted" != "0" ]; then
    # Has both — assume cleanup is wired (heuristic; not AST-perfect, accept false negative)
    exit 0
fi

ctx="⏱️ **vue-setinterval-cleanup** (PreToolUse on \`${tool}\` of \`$(basename "$file_path")\`):"$'\n\n'
ctx+="\`setInterval\` detected without paired \`onUnmounted\` / \`onBeforeUnmount\` cleanup. In Vue 3 Composition API, timers must be cleared when the component unmounts or they leak across navigations (Inertia visits, route changes, KeepAlive cycles)."$'\n\n'
ctx+="Canonical pattern:"$'\n\n'
ctx+="\`\`\`vue"$'\n'
ctx+="<script setup>"$'\n'
ctx+="import { onMounted, onUnmounted } from 'vue'"$'\n'
ctx+="let intervalId"$'\n'
ctx+="onMounted(() => { intervalId = setInterval(() => {}, 1000) })"$'\n'
ctx+="onUnmounted(() => { clearInterval(intervalId) })"$'\n'
ctx+="</script>"$'\n'
ctx+="\`\`\`"$'\n\n'
ctx+="To disable: \`hook_enabled.vue_setinterval_cleanup: false\` in \`.laravel-vue-superpowers.yaml\`."

jq -nc --arg ctx "$ctx" '{ hookSpecificOutput: { hookEventName: "PreToolUse", additionalContext: $ctx } }'
```

- [ ] **Step 4: chmod + GREEN state verify**

```bash
chmod +x hooks/vue-setinterval-cleanup.sh
bash tests/test_vue_setinterval_cleanup_hook.sh   # GREEN
```

### Task 9-11: Hook 2 — `vue-reactive-destructure`

**Goal:** Warn on reactive object destructure patterns that lose reactivity.

Anti-pattern: `const { count } = reactive({ count: 0 })` loses reactivity. Canonical: `const state = reactive({ count: 0 })` keep wrapped, OR use `toRefs(state)`.

Follow the same 4-step structure as Task 6-8:
1. Test file `tests/test_vue_reactive_destructure_hook.sh` with 5 scenarios (with/without destructure, with toRefs, non-.vue, malformed JSON)
2. RED verify
3. Hook file `hooks/vue-reactive-destructure.sh` — detect `const { ... } = reactive(` pattern in .vue files; canonical fix suggestion in warning
4. GREEN verify

Detection regex: `const\s*\{[^}]+\}\s*=\s*reactive\s*\(` (without nearby `toRefs`).

### Task 12-14: Hook 3 — `inertia-link-external-url`

**Goal:** Warn when `<Link>` from `@inertiajs/vue3` is used with an external URL (silent 409 from Inertia per deep-research).

Follow the same 4-step TDD structure:
1. Test file `tests/test_inertia_link_external_url_hook.sh` — 5 scenarios (internal URL, external URL warning, no Link import, non-.vue, malformed JSON)
2. RED verify
3. Hook file `hooks/inertia-link-external-url.sh` — detect `<Link\s+[^>]*href=["']https?:\/\/` (external URL pattern); canonical fix: use plain `<a>` for external links
4. GREEN verify

### Task 15-17: Hook 4 — `inertia-hardcoded-route`

**Goal:** Warn on hardcoded route strings when Wayfinder is installed (use Wayfinder-generated helpers instead).

Follow the same 4-step TDD structure:
1. Test file `tests/test_inertia_hardcoded_route_hook.sh` — 5 scenarios (Wayfinder used, hardcoded route detected, Wayfinder NOT installed silent, non-.vue/.ts file, malformed JSON)
2. RED verify
3. Hook file `hooks/inertia-hardcoded-route.sh` — detect `router\.(visit|get|post|put|patch|delete)\(["']\/` (hardcoded route literal) WHEN `vendor/laravel/wayfinder/` exists; if Wayfinder not installed, silent
4. GREEN verify

---

## STEP B.4 — Shared updates

### Task 18: Register 4 new hooks in `hooks/hooks.json`

Add the 4 new hooks to both `PreToolUse.Edit` AND `PreToolUse.Write` matcher blocks. Final structure:

```json
"PreToolUse": [
    {"matcher": "Bash", "hooks": [<4 existing bash hooks>]},
    {"matcher": "Edit", "hooks": [
        ...existing (vendor-source-preflight + lang-key-existence-preflight),
        {"type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/vue-setinterval-cleanup.sh"},
        {"type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/vue-reactive-destructure.sh"},
        {"type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/inertia-link-external-url.sh"},
        {"type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/inertia-hardcoded-route.sh"}
    ]},
    {"matcher": "Write", "hooks": [<same 6 hooks as Edit>]}
]
```

Validate:

```bash
python3 -c '
import json
h = json.load(open("hooks/hooks.json"))
for ev, blocks in h["hooks"].items():
    for b in blocks:
        print(f"{ev} matcher={b.get(\"matcher\", \"any\")}: {len(b[\"hooks\"])}")
'
```

Expected: PreToolUse.Edit: 6, PreToolUse.Write: 6 (was 2 each).

### Task 19: Update `config.defaults.yaml` + `config.schema.json`

Add to `hook_enabled`:
```yaml
  vue_setinterval_cleanup: true
  vue_reactive_destructure: true
  inertia_link_external_url: true
  inertia_hardcoded_route: true
```

Schema: ensure `additionalProperties: true` on hook_enabled OR add the 4 keys explicitly.

### Task 20: Add 4 tests to `tests/test_config.py`

```python
def test_get_vue_setinterval_cleanup_default():
    cli = ConfigCLI([])
    assert cli.run(["get", "hook_enabled.vue_setinterval_cleanup"]).strip() == "true"

def test_get_vue_reactive_destructure_default():
    cli = ConfigCLI([])
    assert cli.run(["get", "hook_enabled.vue_reactive_destructure"]).strip() == "true"

def test_get_inertia_link_external_url_default():
    cli = ConfigCLI([])
    assert cli.run(["get", "hook_enabled.inertia_link_external_url"]).strip() == "true"

def test_get_inertia_hardcoded_route_default():
    cli = ConfigCLI([])
    assert cli.run(["get", "hook_enabled.inertia_hardcoded_route"]).strip() == "true"
```

Match the existing fixture style.

### Task 21: Update `docs/agents.md`

- Remove the `## laravel-livewire-specialist` section
- Replace `## laravel-flux-pro-specialist` section with `## laravel-reka-ui-specialist` section
- Add `## laravel-inertia-specialist` and `## laravel-vue3-specialist` sections

Each section follows existing pattern (heading, what-it-does, use-when bullets, stack note).

### Task 22: Update `docs/hooks.md`

Add 4 new sections (`### vue-setinterval-cleanup`, `### vue-reactive-destructure`, `### inertia-link-external-url`, `### inertia-hardcoded-route`) following the existing hook documentation pattern (Event / What / Why / Skip cases / Run trailer).

### Task 23: Update `README.md`

- Agent count: `10 currently / 11 planned` → `11 / 11`
- Hook count: `12 currently / 16 planned` → `16 / 16`
- Remove `*(inherited from Livewire source — will be removed in Phase B)*` notes on livewire-specialist + flux-pro-specialist (they're gone now)
- Replace `laravel-flux-pro-specialist` listing with `laravel-reka-ui-specialist`
- Add `laravel-inertia-specialist` and `laravel-vue3-specialist` listings
- Add 4 new hook listings
- Versions section: add `v1.0.0-alpha.2 (2026-05-17) — Phase B: Specialists + Anti-Pattern Hooks` *(current)*; move `(current)` from alpha.1

### Task 24: Prepend CHANGELOG `## [1.0.0-alpha.2]` section

```markdown
## [1.0.0-alpha.2] — 2026-05-17 — Phase B: Specialists + Anti-Pattern Hooks

Phase B swaps the frontend-stack-specific specialists and adds 4 anti-pattern hooks for Vue 3 + Inertia patterns.

### Added

- `agents/laravel-reka-ui-specialist.md` — Reka UI primitives specialist (replaces flux-pro-specialist; UI-specialist slot reused)
- `agents/laravel-inertia-specialist.md` — Inertia v3 patterns specialist (v2 opt-in compat-note); covers useForm + Precognition + usePage + partial reloads + deferred props + history encryption + polling + modal stack
- `agents/laravel-vue3-specialist.md` — Vue 3 Composition API + `<script setup>` + TS specialist; covers ref/reactive/computed, defineProps TS generics, composable design, lifecycle cleanup, reactive-destructure pitfalls
- `hooks/vue-setinterval-cleanup.sh` — PreToolUse on .vue Edit/Write; warns when setInterval lacks onUnmounted cleanup
- `hooks/vue-reactive-destructure.sh` — PreToolUse on .vue Edit/Write; warns on `const { ... } = reactive(...)` destructure (loses reactivity)
- `hooks/inertia-link-external-url.sh` — PreToolUse on .vue Edit/Write; warns when `<Link>` used with external URL (silent 409)
- `hooks/inertia-hardcoded-route.sh` — PreToolUse on .vue/.ts Edit/Write; warns on hardcoded route strings when Wayfinder shipped
- 4 new shell hook test suites
- 4 new Python config tests

### Changed

- `hooks/hooks.json` — 4 new hooks registered under PreToolUse.Edit + PreToolUse.Write
- `config.defaults.yaml` — 4 new `hook_enabled.*` flags (default true)
- `docs/agents.md` — section structure: REMOVE livewire, REPLACE flux-pro with reka-ui, ADD inertia + vue3
- `docs/hooks.md` — 4 new sections
- `README.md` — agent count 10 → 11; hook count 12 → 16; specialist listings updated
- `.claude-plugin/plugin.json` — version 1.0.0-alpha.1 → 1.0.0-alpha.2; description current-state counts updated

### Removed

- `agents/laravel-livewire-specialist.md` (Livewire-stack-specific, not part of Vue variant)
- `agents/laravel-flux-pro-specialist.md` (replaced with laravel-reka-ui-specialist)

### Phase Status

Phase B (this alpha) — ✅ shipped 2026-05-17 as v1.0.0-alpha.2.

Phases C-E remain.

---
```

### Task 25: Update `.claude-plugin/plugin.json`

- Version `1.0.0-alpha.1` → `1.0.0-alpha.2`
- Description: update current-state count line to reflect the new totals (11 agents / 7 skills / 16 hooks / 3 commands shipped — matches v1.0.0 stable target)

### Task 26: Test verify

```bash
for t in tests/test_*.sh; do bash "$t" >/dev/null 2>&1 && echo "✓" || echo "✗ $t"; done
python3 -m pytest tests/ -q
ls hooks/*.sh | wc -l   # 16
ls agents/*.md | wc -l  # 11
ls skills/*/SKILL.md | wc -l  # 7
ls commands/*.md | wc -l      # 3
```

Expected: 17 shell tests ✓ (13 baseline + 4 new), 37 Python passed (33 + 4), counts 16 / 11 / 7 / 3.

### Task 27: Commit + push + PR

Commit message: `feat(v1): phase b — specialists + 4 anti-pattern hooks (v1.0.0-alpha.2)`

PR body summarizes scope; closes plan tasks.

**STOP. Wait for operator merge.**

---

## STEP B.5 — Post-Merge

### Task 28: Tag v1.0.0-alpha.2 + Pre-Release + marketplace bump

- `git tag -a v1.0.0-alpha.2 ...` + push
- `gh release create v1.0.0-alpha.2 --prerelease --notes "$(awk ...)"` for the alpha.2 CHANGELOG body
- Update `~/dev/laravel-marketplace/.claude-plugin/marketplace.json`: bump Vue plugin entry from `1.0.0-alpha.1` to `1.0.0-alpha.2`; metadata.version stays `1.2.0` (no structural change — same plugin, just newer version)
- Commit + push marketplace repo

**STOP. Phase B complete.**
