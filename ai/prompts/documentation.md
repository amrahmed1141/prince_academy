# Documentation

**Status:** active  
**Pack:** [`../templates/documentation.md`](../templates/documentation.md)  
**Human skeletons:** project docs templates (doc page, ADR)

## Intent

Create or update durable documentation that matches canonical sources, for humans and/or agents, without inventing conventions.

## Required context packs

- Existing docs on the same topic
- Related agent context or memory documents
- Project documentation standards

## Required inputs

- What changed, or what question the page answers
- Canonical sources (code, SQL, config, prior decisions)
- Audience: human, agent, or both
- Artifact hint: doc page / ADR / context pack / memory note (optional)

## Output schema

Produce a **Documentation report**:

- Artifact type(s)
- Paths created or updated
- Sources cited
- Indexes updated
- Verified vs TODO
- Stale siblings noted

## Constraints

- Sources win on conflict; update the doc.
- Link instead of duplicating.
- Docs-only work does not edit application source unless requested.
- Do not edit generated doc trees by hand.
- ADRs are append-only; supersede rather than rewrite history.
- Unknowns stay TODO.

## Stop / escalate

- Stop when material facts lack sources.
- Escalate platform rule changes to Architect (ADR).
- Escalate schema claims to Database when sources are unclear.
