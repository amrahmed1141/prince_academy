# Code Review

**Status:** active  
**Pack:** [`../templates/review.md`](../templates/review.md)  
**Related lenses:** [`architecture-review.md`](architecture-review.md), [`performance-review.md`](performance-review.md)

## Intent

Judge a concrete diff against the project contract and the originating work pack; emit a severity-tagged verdict.

## Required context packs

- Project contract
- Originating pack report (Feature / Bug Fix / SQL Change) when available
- Domain packs for touched areas
- Standards relevant to the change

## Required inputs

- Diff or file-level change set
- Originating pack name
- Optional risk flags (auth, privileged SQL, cache, payments)

## Output schema

```text
## Review report
- Scope reviewed:
- Lens(es): code
- Verdict: approve | request changes
- Findings:
  - Blocker:
  - Should-fix:
  - Nit:
- Follow-ups:
```

## Constraints

- Review what exists; do not redesign in place.
- Cite paths and symbols or SQL objects.
- Prefer project rules over stylistic preference.
- Security and data-exposure issues default to **Blocker**.
- Nits never block Release alone.

## Stop / escalate

- Escalate secret or privilege issues to Security.
- Escalate unapproved architectural patterns to Architect.
- Stop if the change set cannot be determined.
