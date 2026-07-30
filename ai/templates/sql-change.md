# Pack: SQL Change

Extends [`_base.md`](_base.md).

**Status:** active  
**Prompt:** [`../prompts/sql.md`](../prompts/sql.md)  
**Workflow:** [`../workflows/database-change.md`](../workflows/database-change.md)

## Intent

Change schema, procedures/RPCs, or data policies safely, with an explicit contract for callers and a clear privilege model.

## When to use / when not

**Use when** the primary work is database DDL/DML policy, RPC/function contracts, or multi-step write logic that belongs on the server.

**Do not use when** the change is application-only with no schema/RPC impact, or when the user only needs a behaviour bugfix with no SQL.

If UI/client work is also large, run this pack for the data half and Feature/Bug Fix for the client half, linked by the shared contract.

## Primary roles

| Role | Responsibility |
|------|----------------|
| Database | Schema, RPC, migration/script authorship |
| Security | Privilege model, RLS / definer rights, secret boundaries |
| Implementer | Client call sites and mapping only after contract is stable |
| Reviewer | Diff and contract compliance |
| Documentation | Schema/RPC docs and agent data context |

## Required inputs

- Goal (what becomes possible or correct)
- Objects involved (tables, views, functions) — best effort
- Callers (which app roles or services invoke this)
- Additive vs breaking change expectation
- Rollback or forward-fix preference

## Required context

- Data platform / schema overview
- Security notes for policies and privileged functions
- Domain context for affected product area
- Existing RPC/schema docs

## Stages

1. **Contract** — inputs, outputs, errors, idempotency, who may call  
2. **Author SQL** — scripts in the project’s schema source-of-truth location  
3. **Privilege review** — policies; justified elevated rights; no client secrets  
4. **Client align** — update repositories/datasources to match the contract  
5. **Smoke** — exercise happy path and one failure path  
6. **Document** — human DB docs + agent context as needed  

## Output schema

```text
## SQL change report
- Summary:
- Objects touched (tables / RPCs / policies):
- Contract (args, returns, errors):
- Privilege / RLS notes:
- Client call sites:
- Smoke results:
- Rollback / forward-fix notes:
- Docs updated:
```

## Constraints

- Schema scripts are the source of truth for structure; docs follow them.
- Multi-step writes belong in server procedures when that is project policy.
- Never place privileged service credentials in the client app.
- Elevated-rights functions require an explicit justification in the report.
- Prefer additive, compatible changes; breaking changes must be called out.

## Gates

| Gate | Fail if |
|------|---------|
| Contract clear | Callers lack a stable signature or error model |
| Privilege reviewed | Elevated rights without justification |
| Client aligned | App calls outdated or mismatched contracts |
| Smoke done | No evidence of success/failure paths |

## Stop / escalate

- Stop if the change requires production data migration without a plan.
- Escalate to Security when policies or definer rights change.
- Escalate to Architect when the data model implies new app boundaries.

## Definition of done

- [ ] SQL authored in the canonical location
- [ ] Privilege model documented
- [ ] Client call sites match (or explicitly deferred with owner)
- [ ] Smoke evidence recorded
- [ ] Docs/context updated for contract changes

## Index updates

Database/docs indexes and agent data-context indexes when pages or RPCs are added.
