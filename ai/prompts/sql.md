# SQL

**Status:** active  
**Pack:** [`../templates/sql-change.md`](../templates/sql-change.md)  
**Workflow:** [`../workflows/database-change.md`](../workflows/database-change.md)

## Intent

Define and author a safe database contract (schema, RPC/procedure, or policy) and align callers without placing privileged secrets in the client.

## Required context packs

- Data platform / schema overview
- Security / policy notes
- Domain pack for the product area
- Existing schema or RPC documentation

## Required inputs

- Goal
- Objects involved (best effort)
- Intended callers and roles
- Additive vs breaking expectation
- Rollback or forward-fix preference

## Output schema

Produce an **SQL change report**:

- Summary
- Objects touched
- Contract (args, returns, errors)
- Privilege / policy notes
- Client call sites
- Smoke results
- Rollback / forward-fix notes
- Docs updated

## Constraints

- Canonical SQL scripts are source of truth for structure.
- Justify any elevated-rights function.
- Never embed service/privileged credentials in client apps.
- Prefer additive changes; label breaking changes clearly.
- See pack for full gates.

## Stop / escalate

- Stop when production data migration lacks a plan.
- Escalate policy / definer-rights changes to Security.
- Escalate model changes that imply new app boundaries to Architect.
