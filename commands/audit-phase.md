---
description: Dispatch a Pilot 2.0 Phase-N audit using the active plan-doc's per-phase scope. Reads the active plan, extracts Phase N's audit prompt, dispatches laravel-best-practices in parallel.
allowed-tools: ["Read", "Bash", "Agent"]
---

# laravel-livewire-superpowers:audit-phase N

Run a Pilot 2.0 T1 audit (best-practices research + anti-patterns + open questions) scoped to a specific Phase of the active plan-doc.

**Argument:** `N` = phase number to audit. Example: `/laravel-livewire-superpowers:audit-phase 3`.

## Workflow

### Step 1: Detect active plan-doc

```bash
branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
topic="${branch#*/}"
# Try docs/superpowers/plans first, then docs/plans
for path in "docs/superpowers/plans/${topic}.md" "docs/plans/${topic}.md"; do
    [ -f "$path" ] && plan="$path" && break
done
```

If no plan-doc found, emit: "No active plan-doc detected. Either you're on `main` or no `docs/superpowers/plans/${topic}.md` exists for branch `${branch}`. Aborting."

### Step 2: Extract Phase N section

```bash
awk -v n="$N" '/^## Phase '"$N"'/{flag=1} /^## Phase [0-9]+/ && !/^## Phase '"$N"'/{flag=0} flag' "$plan"
```

If Phase N doesn't exist in the plan, emit: "Phase $N not found in `${plan}`. Available phases: $(grep -c '^## Phase' "$plan")."

### Step 3: Dispatch laravel-best-practices agent

Use the Agent tool to dispatch `laravel-best-practices` in parallel with prompt:

```
Pilot 2.0 T1 audit for Phase N of active sprint.

Topic: [extracted phase scope from plan-doc Step 2]
Stack: detect from composer.json + package.json
Plan-doc: [path]

Output expectations:
1. Executive summary (3-5 lines)
2. Per-decision findings with Tier-1/2/3 source citations
3. Anti-patterns to avoid
4. Open questions

Search at least 3 sources with year filter (e.g., "Laravel 12 X best practice 2025/2026").
Archive output to docs/superpowers/audits/YYYY-MM-DD-<topic>-phase-N-audit.md.
```

### Step 4: Wait for audit completion + emit summary

Once the agent returns, summarize the top 3 findings to the operator + reference the archived audit path.

### Step 5: Mark Tactic in plan-doc (optional)

If the plan-doc has a Pilot 2.0 Tactic Tracking section for Phase N, suggest the operator update the T1 marker:

```markdown
- [x] T1 dispatched on YYYY-MM-DD (audit: docs/superpowers/audits/YYYY-MM-DD-<topic>-phase-N-audit.md)
```
