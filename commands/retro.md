---
description: Generate a sprint retrospective report from plan-doc + git history + audit reports. Outputs Pilot 2.0 contract compliance per phase, skill-invocation count vs expected, drift instances, test-suite delta, screenshot artifacts list.
allowed-tools: ["Read", "Bash"]
---

# laravel-livewire-superpowers:retro

Generate an end-of-sprint retrospective report from the active branch's state. Read-only; never mutates anything.

## Workflow

### Step 1: Detect active plan-doc + branch state

```bash
branch="$(git rev-parse --abbrev-ref HEAD)"
topic="${branch#*/}"
plan="docs/superpowers/plans/${topic}.md"
[ -f "$plan" ] || plan="docs/plans/${topic}.md"
commits="$(git log main..HEAD --oneline)"
commit_count="$(echo "$commits" | wc -l)"
```

### Step 2: Per-phase Pilot 2.0 compliance

For each `## Phase N` in the plan-doc, read the Pilot 2.0 Tactic Tracking section:

- T1: dispatched? cite audit path
- T2: VC offered? accepted/skipped?
- T3: review evidence per commit?
- T4: specialist audit per test-write?
- T5: clean push? (banned-token sweep automated)
- T6: clean push? (deferred-items automated)

Tabulate as compliance matrix.

### Step 3: Drift instances

Scan for known drift markers:
- Inline implementation (no Subagent dispatch) — heuristic: commit count > task count
- Amended commits (CLAUDE.md violation) — `git log --pretty='%h %s' | grep -i amend`
- Skipped audits (T1/T3/T4 markers unchecked at sprint close)
- Plan-doc tightening churn — `git log --pretty='%h %s' -- 'docs/superpowers/plans/' | wc -l` (>3 commits suggests churn)

### Step 4: Test-suite delta

```bash
git diff main..HEAD --name-only -- 'tests/' | wc -l   # files touched
for f in $(git diff main..HEAD --name-only -- 'tests/'); do
    grep -cE "(it|test|describe)\(|expect\(" "$f" 2>/dev/null
done | paste -sd+ | bc 2>/dev/null   # total assertions added
```

### Step 5: Screenshot artifacts

```bash
git diff main..HEAD --name-only | grep -iE '\.(png|jpg|jpeg|gif|webp|mp4|webm)$' | head -10
```

### Step 6: Output

```markdown
# Sprint Retro — <branch>

## Sprint metadata

- Branch: <branch>
- Commits: <N>
- Plan-doc: <path>
- Duration: <git log first..last commit date diff>

## Pilot 2.0 contract compliance

| Phase | T1 | T2 | T3 | T4 | T5 | T6 |
|---|---|---|---|---|---|---|
| 1 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 2 | ✓ | skip | ✗ | ✓ | ✓ | ✓ |
| ... | | | | | | |

## Drift instances

- <list, or "None observed">

## Test-suite delta

- Files touched: N
- Assertions added: M

## Screenshot artifacts

- <list of image/video files added in this sprint>

## Recommendations for next sprint

<heuristic recommendations based on drift instances>
```
