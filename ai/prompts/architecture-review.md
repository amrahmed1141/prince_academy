# Architecture Review

**Status:** active  
**Pack:** [`../templates/review.md`](../templates/review.md) (architecture lens)  
**Companion:** [`code-review.md`](code-review.md)

## Intent

Review a diff for boundary integrity, dependency direction, module placement, and whether a lasting decision needs an ADR — using the shared Review output schema.

## Required context packs

- Project contract / architecture overview
- Originating pack report
- Domain packs for touched modules
- Decision log (ADRs) when relevant

## Required inputs

- Diff or change set
- Stated goal of the change
- Whether new modules or public contracts were introduced

## Output schema

Same as Code Review, with `Lens(es): architecture`.

Focus findings on:

- Layering violations (e.g. UI performing remote I/O)
- Misplaced types or dependencies
- Unapproved new frameworks or patterns
- Missing ADR when a platform-level decision was made

## Constraints

- Do not demand large rewrites unrelated to the diff.
- Distinguish Blockers (contract breaks) from Nits (naming preference).
- Follow Review pack severity and verdict rules.

## Stop / escalate

- Escalate to Security when boundary issues expose data or secrets.
- Request an ADR draft when the change silently sets a new platform rule.
