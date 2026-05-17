# Pilot 2.0 Contract — Canonical Reference

`laravel-livewire-superpowers` formalizes a 6-Tactic workflow contract (T1-T6) for Laravel sprints. Tactics are tracked in plan-doc markers; some are automated via hooks, others are operator-or-orchestrator-dispatched.

## The 6 Tactics

| Tactic | Name | When | Mechanism |
|---|---|---|---|
| **T1** | Phase-Start Best-Practices Audit | Brainstorming Step 2 | `brainstorm-t1-audit` hook injects reminder → agent dispatches `laravel-best-practices` parallel |
| **T2** | Visual-Companion Offer | Brainstorming Step 2 | `visual-companion-default-on` hook injects reminder → agent offers VC or justifies skip |
| **T3** | Per-Commit Code Review | After each commit | `pilot-2-contract-enforcer` hook warns/blocks if `laravel-reviewer` not invoked between commits |
| **T4** | Pre-Test-Write Specialist Audit | Before any test-write | `pilot-2-contract-enforcer` hook warns if `laravel-pest-specialist` not invoked |
| **T5** | Pre-Push Banned-Token Sweep | `git push` | `banned-token-leak-guard` PreToolUse hook (automated) |
| **T6** | Pre-Push Deferred-Items Check | `git push` | `anti-silent-deferral` PreToolUse hook (automated) |

## Plan-Doc Tactic-Marker Convention

Every `## Phase N` block in `docs/superpowers/plans/<topic>.md` SHOULD include:

```markdown
**Pilot 2.0 Tactic Tracking:**
- [x] T1 dispatched on YYYY-MM-DD (audit: docs/superpowers/audits/YYYY-MM-DD-<topic>-audit.md)
- [x] T2 VC offered (accepted | skipped — reason)
- [ ] T3 pending for commits: <SHA list>
- [ ] T4 pending for tests: <path list>
- T5: automated (sweep clean per pre-push hook)
- T6: automated (no deferred items unlinked)
```

The `pilot-2-contract-enforcer` hook parses these markers. The `laravel-pilot-orchestrator` agent reads them too.

## audit_aggressiveness Config

`config.defaults.yaml`:

```yaml
audit_aggressiveness: every-phase  # brainstorm-only | every-phase | every-commit
```

- **`brainstorm-only`** (silent) — enforcer treats T3/T4 as advisory; never blocks
- **`every-phase`** (warn — default) — enforcer warns on T3/T4 gaps but doesn't block
- **`every-commit`** (block) — enforcer blocks `git push` when any T3/T4 marker is incomplete

## How the components interact

```
+---------------------------------+
| docs/superpowers/plans/*.md      |  source of truth
| (Pilot 2.0 Tactic Tracking)      |
+----------------+----------------+
                 |
        +--------+----------+
        |                   |
        v                   v
+----------------+   +----------------+
| pilot-2-       |   | laravel-pilot- |
| contract-      |   | orchestrator   |
| enforcer hook  |   | agent          |
+----------------+   +----------------+
        |                   |
        v                   v
[continuous warn/block]  [on-demand structured Tactic-status report]
```

Plus operator-facing:

```
/laravel-livewire-superpowers:audit-phase N  → dispatches T1-style audit scoped to Phase N
/laravel-livewire-superpowers:retro          → end-of-sprint retro report from sprint state
```

## When in doubt

If you're an operator deciding whether to bind Pilot 2.0 to a sprint:

- New feature with > 2 phases → YES, bind contract
- Doc-only update → SKIP (no Tactic markers needed)
- Refactor with tests → bind T3 only (T1 + T2 optional)
- Bugfix one-liner → SKIP

If you're an agent following the contract:
- Phase start → invoke T1 + T2 (brainstorming hooks fire automatically)
- Commit cycle → invoke T3 (`laravel-reviewer`) between commits
- Test-write → invoke T4 (`laravel-pest-specialist`) before writing tests
- Push → T5 + T6 fire automatically
