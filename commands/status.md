---
description: Show current branch/sprint state, hook compliance, and open follow-ups for the active Laravel project. Read-only.
allowed-tools: ["Read", "Bash"]
---

# laravel-vue-superpowers:status

Surface the current state of the project's active branch, hook compliance, and any pending follow-ups. **Read-only** — never mutate state, never run destructive commands.

Target response time: ≤2 seconds. Use only fast commands (git porcelain, file reads, grep). No network calls beyond a single `gh pr view` if needed for protected-branch state.

## Workflow

### Step 1: Detect git state

Run in parallel:

```bash
git rev-parse --abbrev-ref HEAD               # current branch
git rev-parse HEAD                            # current SHA
git log -1 --format='%h %s'                   # last commit
git status --porcelain                        # dirty state
git rev-list --left-right --count main..HEAD  # ahead/behind main (if main exists)
```

If `main` doesn't exist locally, skip the ahead/behind line and emit "no main ref locally".

### Step 2: Detect active plan-doc

Active plan = a file in `docs/plans/*.md` that's been modified on this branch vs main. Find via:

```bash
git diff main..HEAD --name-only -- 'docs/plans/*.md' 2>/dev/null
```

If multiple, pick the most recently modified. If none, pick the most recently modified `docs/plans/*.md` overall. Read its frontmatter / first 30 lines to extract:
- Title (first `# ` heading)
- Phase count (every `## Phase \d+` heading)
- Current phase (first `## Phase \d+` whose `Status:` line doesn't say "complete")

If no `docs/plans/` directory exists, note "no active plan detected".

### Step 3: Detect hook compliance (config-driven)

Run:

```bash
python3 "${CLAUDE_PLUGIN_ROOT:-./}/lib/config.py" show 2>/dev/null
```

Read the `hook_enabled` block. For each hook, emit one of:
- ✓ enabled
- ✗ disabled (operator opt-out)

If the helper crashes / config helper not available, note: "config unavailable — hook states unknown".

### Step 4: Detect open obligations

- `docs/plans/*.md` deferred-items sections: count any `## Phase N — Deferred Items` blocks that aren't `**None — all tasks completed**` AND have at least one bullet without an issue-link `#N` reference. (Same logic as the `anti-silent-deferral` hook.)
- Filed follow-up issues: not directly queryable from a slash command (would need network); skip this line or emit "TODO: query gh/glab for open issues" if time permits.
- Branch state vs origin: `git for-each-ref --format='%(upstream:track)' refs/heads/$(git symbolic-ref --short HEAD)` to detect ahead/behind upstream.

### Step 5: Emit the status panel

Format (markdown — Claude Code renders it cleanly):

```
## laravel-vue-superpowers status

**Branch:** `<current-branch>` (<title from plan-doc, if any>)
**Last commit:** <sha> <subject>
**Branch state:** <ahead/behind main + working tree status>

**Active plan:** `docs/plans/<filename>.md`
**Phase progress:** <current-phase>/<phase-count>

### Hook compliance

- <✓ enabled / ✗ disabled> banned-token-leak-guard
- <✓ enabled / ✗ disabled> no-claude-attribution
- <✓ enabled / ✗ disabled> teamcity-always
- <✓ enabled / ✗ disabled> anti-silent-deferral
- <✓ enabled / ✗ disabled> visual-companion-default-on

### Open obligations

- <list of uncaptured deferrals OR "none" line>

### Specialist agents

10 agents available: `laravel-best-practices`, `laravel-architect`, `laravel-pest-specialist`, `laravel-inertia-specialist`, `laravel-vue3-specialist`, `laravel-reka-ui-specialist`, `laravel-echo-reverb-specialist`, `laravel-scout-meilisearch-specialist`, `spatie-permission-auditor`, `laravel-package-evaluator`.

Invoke via the Agent tool when the current phase touches the corresponding stack layer. See `docs/agents.md` §"When to route to which specialist" for the task-type → agent mapping.
```

## Important behaviors

**Never mutate state.** This command is read-only. Don't run `git commit`, `git push`, `gh issue create`, or any write operation.

**Be fast.** Target ≤2 seconds. Use parallel Bash invocations where possible. Skip slow operations (full `git log` walks, network calls, large file reads).

**Degrade gracefully.** If `docs/plans/` doesn't exist, if no active plan detected, if config helper crashes — emit a partial panel with "unknown" / "N/A" markers rather than failing the command.

**No prompts.** This is a status read, not an interactive flow. Emit the panel and stop.
