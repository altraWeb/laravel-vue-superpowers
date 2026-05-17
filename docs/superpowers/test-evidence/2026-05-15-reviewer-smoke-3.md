# Smoke Test 3 — Non-Laravel project (Node.js Express)

**Date:** 2026-05-15
**Dispatcher:** Claude Code Task tool, `general-purpose` subagent, `sonnet` model

## Input

> review my Node.js Express controller:
> ```js
> app.get('/users', async (req, res) => {
>     const users = await db.query('SELECT * FROM users');
>     res.json(users);
> });
> ```

## Captured output

```markdown
## Pre-flight: SKIPPED — no composer.json found, cannot confirm Laravel project

The submitted code is a Node.js / Express route handler. No composer.json exists in working directory (/tmp), no Laravel project in scope.

This agent is the Laravel Reviewer — scoped exclusively to Laravel (PHP) codebases. Reviewing Node.js, Express, or other runtimes is outside its mandate.

No Laravel findings will be generated. Doing so would be hallucination — fabricating Laravel-specific issues (mass assignment, $fillable, FormRequests, Eloquent N+1, etc.) against code that uses none of those constructs.

To get a meaningful review:
- Run through a Node.js/Express-specific reviewer (not this agent)
- Or ask Claude directly for a general security/quality review
```

## Verdict

**PASS — clean refusal.**

- Pre-flight SKIPPED with explicit reason
- Agent self-aware: "I am the Laravel Reviewer, this is Node.js, not my scope"
- Did NOT manufacture findings (no false $fillable / N+1 / FormRequest hallucinations on JS code)
- Suggested appropriate alternative (Node.js reviewer or general Claude review)

Trust-critical test: a reviewer that produces Laravel-style findings on JavaScript would damage credibility instantly. Agent correctly refused.
