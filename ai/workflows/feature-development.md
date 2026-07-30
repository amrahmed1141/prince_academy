# Feature Development

**Status:** active  
**Pack:** [`../templates/feature.md`](../templates/feature.md)  
**Prompt:** [`../prompts/feature-planning.md`](../prompts/feature-planning.md)

## When to use

New capability spanning planning, implementation, verification, and handoff to Review/Release.

Skip when the work is only a defect (Bug Fix), only SQL (SQL Change), or only docs (Documentation).

## Roles

Orchestrator → Architect → Database? → Implementer → Reviewer ∥ Security? ∥ Performance? → QA → Documentation → Release

## Stages

1. **Scope** — lock inputs, acceptance criteria, out of scope  
2. **Design** — boundaries and contracts; ADR-lite if needed  
3. **Data** — if needed, run or link SQL Change for non-trivial persistence  
4. **Implement** — application changes within boundaries; wire dependencies per project rules  
5. **Review** — apply Review pack (default + optional lenses)  
6. **Verify** — QA evidence against acceptance criteria  
7. **Document** — update docs/context only where truth changed  
8. **Release** — apply Release pack  

## Context packs / prompts per stage

| Stage | Prompt / pack | Context |
|-------|---------------|---------|
| Scope / Design | `feature-planning` | architecture, domain |
| Data | `sql` + SQL Change pack | data platform, security |
| Implement | (implementation standards) | domain, examples |
| Review | `code-review` (+ lenses) | contract, domain |
| Document | `documentation` | docs standards |
| Release | `release` | originating reports |

## Required artifacts

- Feature report (from planning/implementation)
- SQL change report when data changed
- Review report
- QA evidence
- Release report

## Gates

- Scope locked before design completes
- Design approved before implementation
- Data contract ready before client depends on it
- No Review Blockers before Release
- Acceptance evidence before go

## Definition of done

See Feature pack DoD. Release may not redefine it; it only checks it.
