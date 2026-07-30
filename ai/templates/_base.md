# Template base

Shared section contract for every work-type pack. Packs override only what differs.

**Status:** active

## Intent

One sentence: what this pack produces when run to completion.

## When to use / when not

Routing guardrails. Prefer a more specific pack when two could apply (e.g. SQL Change over Feature when the only change is schema/RPC).

## Primary roles

- **Owner** — accountable for the main artifact
- **Supporters** — optional reviewers or specialists
- Named roles are logical (orchestrator, architect, implementer, reviewer, etc.); map them to the project’s agent roster at runtime

## Required inputs

What the requester must supply before work starts. Treat missing inputs as a stop condition, not a guess.

## Required context

Which domain or platform context documents to load. Load only what the task needs. Prefer links over pasting facts.

## Standards / examples

Pointers to coding standards, examples, and gold-standard modules in the repo. Do not restate them here.

## Stages

Numbered sequence. Each stage names:

1. **Role** — who acts
2. **Action** — what to do
3. **Artifact** — what must exist before the next stage

## Output schema

Exact shape of the deliverable (sections, severity tags, verdicts). Downstream packs (Review, Release) consume this shape without reformatting.

## Constraints

- Obey the project contract (stack, boundaries, secrets, change discipline).
- Implement only the requested change; no drive-by refactors.
- Prefer linking to canonical sources over duplicating them.
- Leave unknown sections as `N/A` or empty — do not invent conventions.

## Gates

Pass/fail checks between stages. A failed gate stops forward progress until resolved or explicitly waived by the release owner.

## Stop / escalate

When to halt, ask the human, or hand off to another role (security, database, architecture).

## Definition of done

Ship checklist for this work type. Release consumes this list; it does not redefine it.

## Index updates

Which indexes or README tables to update when this pack creates or renames artifacts.
