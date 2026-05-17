# Smoke Test 3 — Non-Laravel project (Spring Boot)

**Date:** 2026-05-15
**Dispatcher:** Claude Code Task tool, `general-purpose` subagent, `sonnet` model

## Input

> audit: Spring Boot + JPA architecture review for our user microservice. We have UserController, UserService, UserRepository. Should we add a UserFacade?

## Captured output

```markdown
## Pre-flight: SKIPPED — no composer.json found, cannot confirm Laravel project

The audit input describes a Spring Boot + JPA stack — Java enterprise architecture. This agent is the Laravel Architect Agent — it audits Eloquent models, Laravel architectural patterns, Laravel-specific performance concerns. None of those concepts apply to Spring Boot.

To get a useful answer:
- Spring Boot UserFacade decision requires Spring/Java-aware agent
- UserController → UserService → UserRepository is idiomatic Spring layered architecture

This agent does not produce findings for non-Laravel projects.
```

## Verdict

**PASS — perfect refusal.**

- Pre-flight correctly SKIPPED.
- Agent explicitly recognized Java/Spring stack.
- Explicit "this agent does not produce findings for non-Laravel projects" disclaimer.
- Did NOT hallucinate Eloquent/N+1 findings on a Java codebase.
- Suggested a different (Spring-aware) auditor.

Critical trust property: an architect agent that confused Java Repository with Eloquent Repository would emit confidently wrong advice and erode trust permanently.
