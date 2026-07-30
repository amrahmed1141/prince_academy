# Feature Planning

**Status:** active  
**Pack:** [`../templates/feature.md`](../templates/feature.md)  
**Workflow:** [`../workflows/feature-development.md`](../workflows/feature-development.md)

## Intent

Turn a capability request into a scoped plan: boundaries, contracts, staged delivery, and a Feature report that Review and Release can consume.

## Required context packs

Load only what applies:

- Platform / architecture overview
- Domain pack for the feature area (if present)
- Data platform pack when persistence is in scope
- Relevant coding standards and examples (state, UI, data access)

## Required inputs

- Desired outcome
- Actors / roles affected
- Testable acceptance criteria
- Persistence in scope? (`yes` / `no` / `unknown`)
- Explicit out-of-scope list

If inputs are missing, stop and ask — do not invent product behaviour.

## Output schema

Produce a **Feature report** (see pack) including:

- Summary, scope / out of scope
- Module boundaries and public contracts
- Data changes (`none` or pointer to SQL Change report)
- Planned files / areas
- Acceptance evidence plan
- Residual risks

## Constraints

- Obey the project contract (stack, layering, secrets, change discipline).
- Remote I/O belongs in the data layer only.
- Prefer extending existing patterns over introducing new frameworks or routers.
- No drive-by refactors.
- See pack for full constraints and gates.

## Stop / escalate

- Stop on incomplete inputs.
- Escalate boundary ambiguity to Architect.
- Hand non-trivial schema/RPC work to the SQL Change pack.
- Escalate privilege or secret concerns to Security.
