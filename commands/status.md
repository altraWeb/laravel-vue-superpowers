---
description: Show current sprint state, Pilot 2.0 obligations, hook compliance, and open follow-ups for the active Laravel project. Read-only.
allowed-tools: ["Read", "Bash"]
---

# laravel-superpowers:status

Surface the current state of the project's active sprint, Pilot 2.0 obligations, hook compliance, and any pending follow-ups. **Read-only** — never mutate state, never run destructive commands.

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

### Step 3: Detect Pilot 2.0 obligations

Read the active plan-doc and look for:

- **T1 (Phase-Start Agent-Audit):** any `## Phase N` section that hasn't had a parallel `laravel-best-practices` Agent dispatched. Check `docs/superpowers/audits/` for a matching audit file by date or topic.
- **T3 (Per-Commit Code Review):** if commits exist on the branch, check whether `laravel-reviewer` was invoked between commits (heuristic: look for review-evidence in plan-doc Tasks marked "T3").
- **T4 (Pre-Test-Write Specialist Audit):** if test-write tasks pending, check if `laravel-pest-specialist` was invoked. Plan-doc Tasks marked "T4".
- **T5 (Pre-Push Banned-Token Sweep):** the `banned-token-leak-guard` hook covers this automatically per commit. Note: "automated".
- **T6 (Pre-Push Deferred-Items Check):** the `anti-silent-deferral` hook covers this. Note: "automated".

Detection is **heuristic** — don't deep-grep, just check for obvious presence/absence of marker tasks in the plan-doc.

### Step 4: Detect hook compliance (config-driven)

Run:

```bash
python3 "${CLAUDE_PLUGIN_ROOT:-./}/lib/config.py" show 2>/dev/null
```

Read the `hook_enabled` block. For each hook, emit one of:
- ✓ enabled
- ✗ disabled (operator opt-out)

If the helper crashes / config helper not available, note: "config unavailable — hook states unknown".

### Step 5: Detect open obligations

- `docs/plans/*.md` deferred-items sections: count any `## Phase N — Deferred Items` blocks that aren't `**None — all tasks completed**` AND have at least one bullet without an issue-link `#N` reference. (Same logic as `anti-silent-deferral` hook.)
- Filed follow-up issues: not directly queryable from a slash command (would need network); skip this line or emit "TODO: query gh/glab for open issues" if time permits.
- Branch state vs origin: `git for-each-ref --format='%(upstream:track)' refs/heads/$(git symbolic-ref --short HEAD)` to detect ahead/behind upstream.

### Step 6: Emit the status panel

Format (markdown — Claude Code renders it cleanly):

```
## laravel-superpowers status

**Sprint:** <title from plan-doc> (branch `<current-branch>`)
**Last commit:** <sha> <subject>
**Branch state:** <ahead/behind main + working tree status>

**Active plan:** `docs/plans/<filename>.md`
**Phase progress:** <current-phase>/<phase-count>

### Pilot 2.0 contract status

- <✓ / ⏸ / N/A> T1 — Phase-Start Agent-Audit dispatched
- <✓ / ⏸ / N/A> T3 — Per-commit code review
- <✓ / ⏸ / N/A> T4 — Pre-test-write specialist audit
- ✓ T5 — Banned-token sweep (automated via hook)
- ✓ T6 — Deferred-items check (automated via hook)

### Hook compliance

- <✓ enabled / ✗ disabled> banned-token-leak-guard
- <✓ enabled / ✗ disabled> no-claude-attribution
- <✓ enabled / ✗ disabled> teamcity-always
- <✓ enabled / ✗ disabled> anti-silent-deferral
- <✓ enabled / ✗ disabled> visual-companion-default-on

### Open obligations

- <list of uncaptured deferrals OR "none" line>
- <pending T1/T3/T4 tasks OR "all current">

### Specialist agents

5 agents available: `laravel-livewire-specialist`, `laravel-pest-specialist`, `laravel-flux-pro-specialist`, `laravel-architect`, `laravel-reviewer`.

Invoke via Task tool when the current phase touches the corresponding stack layer.
```

## Important behaviors

**Never mutate state.** This command is read-only. Don't run `git commit`, `git push`, `gh issue create`, or any write operation.

**Be fast.** Target ≤2 seconds. Use parallel Bash invocations where possible. Skip slow operations (full `git log` walks, network calls, large file reads).

**Degrade gracefully.** If `docs/plans/` doesn't exist, if no active plan detected, if config helper crashes — emit a partial panel with "unknown" / "N/A" markers rather than failing the command.

**No prompts.** This is a status read, not an interactive flow. Emit the panel and stop.
