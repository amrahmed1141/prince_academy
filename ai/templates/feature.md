# Pack: Feature

Extends [`_base.md`](_base.md).

**Status:** active  
**Prompt:** [`../prompts/feature-planning.md`](../prompts/feature-planning.md)  
**Workflow:** [`../workflows/feature-development.md`](../workflows/feature-development.md)

## Intent

Deliver a scoped capability with clear boundaries, minimal surface area, and verifiable acceptance criteria.

## When to use / when not

**Use when** building a new user-facing or admin capability that may span UI, domain logic, persistence, and docs.

**Do not use when** the change is only a defect fix (Bug Fix), only schema/RPC (SQL Change), or only docs (Documentation).

## Primary roles

| Role | Responsibility |
|------|----------------|
| Orchestrator | Route, select pack, enforce gates |
| Architect | Boundaries, module placement, ADR-lite if needed |
| Database | Schema / RPC / policy changes when required |
| Implementer | Application code within approved boundaries |
| Reviewer | Contract and diff compliance |
| Security / Performance | Optional parallel review when risk warrants |
| QA | Behaviour evidence |
| Documentation | Human docs and agent context accuracy |
| Release | Go / no-go |

## Required inputs

- Problem or user outcome (one paragraph)
- Actors / roles affected
- Acceptance criteria (testable)
- Whether persistence or multi-step writes are in scope (`yes` / `no` / `unknown`)
- Out of scope list (explicit)

## Required context

- Architecture / platform overview
- Domain context for the feature area (if it exists)
- Data / API context when persistence is in scope
- Relevant standards and examples for UI, state, and repositories

## Stages

1. **Scope** (Orchestrator + requester) — confirm inputs; write out-of-scope list  
2. **Design** (Architect) — module boundaries; public contracts; ADR-lite if a lasting decision is required  
3. **Data contract** (Database, if needed) — tables/RPC/policies sketched; hand off to SQL Change pack when SQL is non-trivial  
4. **Implement** (Implementer) — UI and domain code; remote I/O only in data layer; register dependencies per project rules  
5. **Review** (Reviewer ∥ Security? ∥ Performance?) — consume Review pack  
6. **Verify** (QA) — acceptance criteria evidence  
7. **Document** (Documentation) — update docs/context only where behaviour changed  
8. **Release** (Release) — consume Release pack

## Output schema

```text
## Feature report
- Summary:
- Scope / out of scope:
- Boundaries (modules, public APIs):
- Data changes (none | link to SQL Change report):
- Files / areas touched:
- DI / wiring notes:
- Acceptance evidence:
- Docs / context updated:
- Residual risks:
```

## Constraints

- Follow project contract for stack, layering, and secrets.
- No remote I/O from widgets or pages.
- Multi-step persistence uses server-side procedures/RPCs when that is the project rule.
- Preserve existing caching and sync patterns for lists and dashboards.
- No unrelated refactors or legacy deletions.

## Gates

| Gate | Fail if |
|------|---------|
| Scope locked | Acceptance criteria or out-of-scope missing |
| Design approved | Boundaries unclear or contract conflict |
| Data ready | Client depends on undeployed or undefined SQL |
| Review clean | Any **Blocker** open |
| QA pass | Acceptance criterion without evidence |

## Stop / escalate

- Stop if inputs are incomplete.
- Escalate to Architect when placement or layering is ambiguous.
- Escalate to Database/Security when privilege, RLS, or secret handling is involved.
- Split into SQL Change pack if schema work dominates.

## Definition of done

- [ ] Acceptance criteria met with evidence
- [ ] Changes stay inside agreed boundaries
- [ ] Reviews have no open Blockers
- [ ] Docs/context updated iff behaviour or contracts changed
- [ ] Indexes updated when new pages or packs were added

## Index updates

Prompt/workflow indexes if status changes; docs or context indexes when those artifacts are added.
