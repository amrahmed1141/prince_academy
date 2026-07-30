# Bug Fix

**Status:** active  
**Pack:** [`../templates/bug-fix.md`](../templates/bug-fix.md)  
**Prompt:** [`../prompts/bug-fix.md`](../prompts/bug-fix.md)  
**Urgent variant:** [`hot-fix.md`](hot-fix.md)

## When to use

Incorrect behaviour with a reproducible case (or equivalent reliable signal). Not for new capabilities or pure schema work.

## Roles

Implementer (or Database if root cause is SQL) → Reviewer → QA → Documentation? 

## Stages

1. **Reproduce** — capture evidence  
2. **Isolate** — name root cause and owning layer  
3. **Fix** — minimal change  
4. **Regress** — repro + adjacent paths if implicated  
5. **Review** — Review pack  
6. **Document** — only if published truth was wrong  

## Context packs / prompts per stage

| Stage | Prompt / pack | Context |
|-------|---------------|---------|
| Reproduce–Fix | `bug-fix` | domain, pitfalls |
| SQL root cause | `sql` if schema/RPC fix required | data platform |
| Review | `code-review` | contract |
| Document | `documentation` | only when needed |

## Required artifacts

- Bug fix report
- Review report (full or as required by risk)
- Regression evidence

## Gates

- Repro confirmed (or approved exception)
- Root cause named before fix lands
- Diff stays minimal
- Original repro passes after fix

## Definition of done

See Bug Fix pack DoD.
