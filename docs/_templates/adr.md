# ADR template

Copy to `docs/decisions/NNNN-short-title.md` (next free four-digit number). Replace angle-bracket instructions. Delete this preamble and the author checklist before merge.

---

# NNNN. <Short title>

| Field | Value |
|-------|-------|
| Date | <YYYY-MM-DD> |
| Status | `Proposed` \| `Accepted` \| `Deprecated` \| `Superseded by NNNN` |
| Deciders | <names or roles> |

## Context

What forces the decision. Include technical and product constraints that were true at the time (stack, team size, existing gold standards, security boundary). Link the features or SQL involved.

## Decision

The choice in one or two sentences. State what is mandatory going forward.

## Alternatives considered

| Option | Why rejected or deferred |
|--------|--------------------------|
| <Option A> | |
| <Option B> | |

## Consequences

### Positive

-

### Negative / accepted cost

-

### Follow-ups

Concrete work this ADR implies (docs to update, code to leave alone, migrations that must wait for an explicit request).

## Enforcement

Where this decision is enforced today (e.g. [`AGENTS.md`](../../AGENTS.md), a Cursor rule, review checklist, CI). If it is not enforceable yet, say so.

## References

- Related ADRs:
- Code / SQL:
- Docs:

---

## Author checklist (delete before merge)

- [ ] Number is unique and sequential
- [ ] Filename matches `NNNN-short-title.md`
- [ ] Row added to [`../decisions/README.md`](../decisions/README.md) index
- [ ] Rejects at least one credible alternative (otherwise it may not need an ADR)
- [ ] Does not rewrite history of an earlier ADR — supersede instead
