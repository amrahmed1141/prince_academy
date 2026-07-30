# Release

**Status:** active  
**Pack:** [`../templates/release.md`](../templates/release.md)  
**Workflow:** [`../workflows/release.md`](../workflows/release.md)

## Intent

Produce an explicit **go** or **no-go** decision for a ship candidate from evidence, not assumption.

## Required context packs

- Originating pack report(s) and their definition of done
- Review report(s)
- Operations / release conventions if present
- Deprecation notes if behaviour is removed or replaced

## Required inputs

- Change summary
- Review verdict(s)
- QA or smoke evidence
- Data dependency status: `none` | `required and applied` | `required but pending` | `unknown`
- Known residual risks

## Output schema

Produce a **Release report**:

- Decision: `go` | `no-go`
- Date
- Checklist results
- Dependencies
- Residual risks
- Rollback / forward-fix notes
- Conditions (if any)

## Constraints

- Open Review Blockers ⇒ **no-go**.
- Pending required server contracts ⇒ **no-go**.
- Conditional go must list conditions in writing.
- See pack for full gates.

## Stop / escalate

- Issue **no-go** and stop when evidence is incomplete or Blockers remain.
- Escalate irreversible data risk or unresolved security findings to humans.
