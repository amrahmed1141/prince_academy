# Pack: Release

Extends [`_base.md`](_base.md).

**Status:** active  
**Prompt:** [`../prompts/release.md`](../prompts/release.md)  
**Workflow:** [`../workflows/release.md`](../workflows/release.md)

## Intent

Issue an explicit **go** or **no-go** for shipping a change set, based on originating pack DoD, review verdicts, and verification evidence — not based on optimism.

## When to use / when not

**Use when** Feature, Bug Fix, and/or SQL Change work claims readiness to ship.

**Do not use when** implementation or review is still in progress, or when the requester only wants a design opinion.

## Primary roles

| Role | Responsibility |
|------|----------------|
| Release | Owns the go / no-go decision |
| QA | Supplies verification evidence |
| Reviewer | Confirms no open Blockers |
| Documentation | Confirms critical docs are not stale relative to the ship |
| Database | Confirms required SQL is applied when the client depends on it |

## Required inputs

- Change summary (link or paste originating pack report)
- Review report(s) with verdict
- QA / smoke evidence
- Data dependency flag: `none` | `required and applied` | `required but pending` | `unknown`
- Known residual risks

## Required context

- Originating pack DoD
- Review findings
- Operations / release notes conventions if they exist
- Deprecation list if the ship removes or replaces behaviour

## Stages

1. **Assemble** — originating reports, review verdicts, evidence  
2. **Checklist** — run DoD items from originating pack(s)  
3. **Dependencies** — SQL/config/feature flags required at runtime  
4. **Docs sanity** — user-critical or contract docs not contradicting the ship  
5. **Decide** — go / no-go with dated rationale  

## Output schema

```text
## Release report
- Decision: go | no-go
- Date:
- Change summary:
- Checklist results:
- Dependencies:
- Residual risks:
- Rollback / forward-fix notes:
- Conditions (if go with constraints):
```

## Constraints

- No open Review **Blockers**.
- Do not ship client code that requires unavailable server contracts.
- Secrets and privileged credentials must remain out of the client.
- A conditional go must list conditions explicitly; silent waivers are not allowed.

## Gates

| Gate | Fail if |
|------|---------|
| Evidence present | Missing QA/smoke or review verdict |
| Blockers clear | Any Blocker still open |
| Dependencies met | Required SQL/config pending |
| Decision explicit | Ambiguous “looks fine” without go/no-go |

## Stop / escalate

- **No-go** and stop when Blockers or unmet dependencies exist.
- Escalate to humans for production data risk, irreversible migrations, or unresolved security findings.
- Defer Documentation nits only when Release explicitly accepts residual doc risk.

## Definition of done

- [ ] Written go or no-go
- [ ] Checklist completed against originating DoD
- [ ] Residual risks listed
- [ ] Owner named for any post-ship follow-ups

## Index updates

Release/ops indexes only when a durable release record or checklist page is added.
